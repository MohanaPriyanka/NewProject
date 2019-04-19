/*************************************************************************************
 * Description: Personal Credit Check Approval Status
 *              For each Credit Report being updated, the handler gets a CreditResultSummary
 *              which has a list of applicable products for that lead and the associated DTI
 *              (we can add maximum loan value later on). It can use the max DTI and also see
 *              if there are any products that meet the DTI threshold, and use that when updating
 *              the lead status
 * Tested By: PCRApprovalHandlerTest
 *************************************************************************************/

public without sharing class PCRApprovalHandler {
    public static final String UNABLETOPREQUALIFY = 'Unable to Pre-Qualify';
    public static final String PREQUALIFIED = 'Pre-Qualified';
    public static final String PENDINGREVIEW = 'Pending Review';
    public static final String DECLINED = 'Declined';
    public static final String APPROVED = 'Approved';
    public static final String READYFORCREDITCHECK = 'Ready for Credit Check';
    public static final String PENDINGCREDITREVIEW = 'Pending Credit Review';
    public static final String UNQUALIFIED = 'Unqualified';
    public static final String REVIEWEDAPPROVED = 'Reviewed - Approved';
    public static final String REVIEWEDPREAPPROVED = 'Reviewed - PreApproved';
    public static final String NOTYETREVIEWED = 'Not Yet Reviewed';

    private static EmailTemplate doerEmailTemplate;
    private static EmailTemplate standardEmailTemplate;
    private static EmailTemplate denialEmailTemplate;
    private static EmailTemplate coAppDenialEmailTemplate;
    private static OrgWideEmailAddress customerCareAddress;
    private static Set<String> flaggedCreditCodes;
    @TestVisible
    private static Boolean alreadyRan = false;

    public PCRApprovalHandler() {
        if (doerEmailTemplate == null) {
            doerEmailTemplate = [SELECT id, HtmlValue, Body
            FROM EmailTemplate
            WHERE DeveloperName = 'RS_DOER_PreQualification_Approval'
            LIMIT 1];
        }
        if (standardEmailTemplate == null) {
            standardEmailTemplate = [SELECT id, HtmlValue, Body, TemplateType
            FROM EmailTemplate
            WHERE DeveloperName = 'RS_PreQualification_Approval'
            LIMIT 1];
        }
        if (denialEmailTemplate == null) {
            denialEmailTemplate = [SELECT id, HtmlValue, Body
            FROM EmailTemplate
            WHERE DeveloperName = 'RS_Customer_PreApplication_Denial'
            LIMIT 1];
        }
        if (coAppDenialEmailTemplate == null) {
            coAppDenialEmailTemplate = [SELECT id, HtmlValue, Body
            FROM EmailTemplate
            WHERE DeveloperName = 'RS_Customer_PreApplication_Denial_Joint'
            LIMIT 1];
        }
        if (customerCareAddress == null) {
            customerCareAddress = [SELECT id, Address
            FROM OrgWideEmailAddress
            WHERE Address = : 'customercare@bluewavesolar.com'
            LIMIT 1];
        }
        if (flaggedCreditCodes == null) {
            List<System_Properties__c> systemProperties = System_Properties__c.getall().values();
            if (systemProperties != null &&
                !systemProperties.isEmpty() &&
                systemProperties[0].Flagged_Credit_Codes__c != null) {
                flaggedCreditCodes = new Set<String>(systemProperties[0].Flagged_Credit_Codes__c.split(','));
            }
        }
    }

    // Use alreadyRan to make sure we don't run the trigger twice
    public static Boolean alreadyRan() {
        if (!alreadyRan) {
            alreadyRan = true;
            return false;
        }
        return true;
    }

    public static void calcDTIAndEmailIfComplete(
        Map<Id, LASERCA__Credit_Report_Log__c> triggerNewMap ,
        Map<Id, LASERCA__Credit_Report_Log__c> triggerOldMap) {
        Set<Id> pcrIds = new Set<Id>();
        if (triggerOldMap == null) {
            for (LASERCA__Credit_Report_Log__c crl : triggerNewMap.values()) {
                pcrIds.add(crl.LASERCA__Personal_Credit_Report__c);
            }
        } else {
            for (Id oldId : triggerOldMap.keySet()) {
                if (triggerNewMap.get(oldId).LASERCA__Status__c == 'Completed' &&
                    triggerOldMap.get(oldId).LASERCA__Status__c != 'Completed') {
                    pcrIds.add(triggerNewMap.get(oldId).LASERCA__Personal_Credit_Report__c);
                }
            }
        }

        PCRApprovalHandler pcrAH = new PCRApprovalHandler();
        List<LASERCA__Personal_Credit_Report__c> pcrs = getPCRsForCreditAnalysis(pcrIds);
        pcrs = pcrAH.onBeforeUpdate(pcrs);
        update pcrs;
    }

    // Since we want updates to happen in real-time (to support the Loan Underwriting page), this method checks that
    // the update happens out of the insert cycle (by making sure the PCR it's 10 seconds old)
    @TestVisible
    private static boolean noDelay = false;
    public static void calcDTIAndEmailOnlyOld(List<LASERCA__Personal_Credit_Report__c> newPCR) {
        System.debug('Already Ran = ' + alreadyRan);
        if (alreadyRan) {
            return;
        }
        List<LASERCA__Personal_Credit_Report__c> oldPCRs = new List<LASERCA__Personal_Credit_Report__c>();
        Datetime d1 = DateTime.now();
        for (LASERCA__Personal_Credit_Report__c pcr : newPCR) {
            if ((d1.getTime() - pcr.CreatedDate.getTime())/1000 > 10 || noDelay) {
                oldPCRs.add(pcr);
            }
        }
        if (!oldPCRs.isEmpty()) {
            PCRApprovalHandler pcrAH = new PCRApprovalHandler();
            oldPCRs = pcrAH.onBeforeUpdate(oldPCRs);
        }
    }

    private List<LASERCA__Personal_Credit_Report__c> onBeforeUpdate(LASERCA__Personal_Credit_Report__c[] newPCRs) {
        Set<Id> leadIds = new Set<Id>();
        Map<Id, Lead> leadMap = new Map<Id, Lead>();
        Map<Id, Lead> leadsToUpdate = new Map<Id, Lead>();

        for (LASERCA__Personal_Credit_Report__c pcrForLead: newPCRs) {
            if (pcrForLead.LASERCA__Lead__c == null && pcrForLead.Lead_from_Contact__c != null) {
                pcrForLead.LASERCA__Lead__c = pcrForLead.Lead_from_Contact__c;
            }
            if (pcrForLead.LASERCA__Lead__c != null) {
                leadIds.add(pcrForLead.LASERCA__Lead__c);
            }
        }

        Set<Id> pcrIds = new Set<Id>();
        List<Lead> relatedLeads  = getLeadsForCreditAnalysis(leadIds);
        for (Lead lead : relatedLeads) {
            leadMap.put(lead.Id, lead);
            pcrIds.add(lead.Personal_Credit_Report__c);
            if (lead.Personal_Credit_Report_Co_Applicant__c != null) {
                pcrIds.add(lead.Personal_Credit_Report_Co_Applicant__c);
            }
        }

        Map<Id, List<LASERCA__Trade_Accounts__c>> tradeAccountsByPCRIds = getTradeAccountsForPCRs(pcrIds);

        ProductRepo productRepo = new ProductRepo(relatedLeads);

        for (LASERCA__Personal_Credit_Report__c pcr : newPCRs) {
            if (!pcr.Do_not_trigger_PCRApprovalHandler__c &&
                pcr.LASERCA__Lead__c != null &&
                leadMap.get(pcr.LASERCA__Lead__c).Product_line__c != 'Community Solar') {
                Lead lead = leadMap.get(pcr.LASERCA__Lead__c);
                Decimal householdMonthlyIncome = calculateHouseholdMonthlyIncome(lead);

                // prevent divide by zero errors on DTI calcs
                if (householdMonthlyIncome == 0) {
                    pcr.DTI_Before__c = null;
                    pcr.DTI_After__c = null;
                    pcr.DTI_After_Notes__c = null;
                    continue;
                }

                if (leadReadyForPrequalCheck(lead)
                    && pcr.Id == lead.Personal_Credit_Report__c) {
                    List<LASERCA__Trade_Accounts__c> tradeAccounts = new List<LASERCA__Trade_Accounts__c>();
                    if (tradeAccountsByPCRIds.get(lead.Personal_Credit_Report__c) != null) {
                        tradeAccounts.addAll(tradeAccountsByPCRIds.get(lead.Personal_Credit_Report__c));
                    }
                    if (lead.Personal_Credit_Report_Co_Applicant__c != null &&
                        tradeAccountsByPCRIds.get(lead.Personal_Credit_Report_Co_Applicant__c) != null) {
                        tradeAccounts.addAll(tradeAccountsByPCRIds.get(lead.Personal_Credit_Report_Co_Applicant__c));
                    }
                    lead = runCreditReviewProcess(lead, pcr, productRepo, tradeAccounts);
                    leadsToUpdate.put(lead.Id, lead);
                    pcr.Credit_PreApproval_Email_Sent__c = lead.Personal_Credit_Report__r.Credit_PreApproval_Email_Sent__c;
                    pcr.Credit_Denial_Email_Sent__c = lead.Personal_Credit_Report__r.Credit_Denial_Email_Sent__c;
                } else if (pcr.Id == lead.Personal_Credit_Report__c) {
                    // This prevents starting a queue for each PCR, we only need to queue once. Emails were getting sent twice.
                    System.enqueueJob(new QueueableApplicationReview(lead));
                }
            }
        }
        updateOppStagesVoid(newPCRs);
        if (!leadsToUpdate.isEmpty()) {
            update leadsToUpdate.values();
        }
        return newPCRs;
    }

    public Lead runCreditReviewProcess(Lead lead, LASERCA__Personal_Credit_Report__c pcr, ProductRepo productRepo, List<LASERCA__Trade_Accounts__c> tradeAccounts) {
        lead = getCreditReviewedLead(lead, pcr, productRepo, tradeAccounts);
        lead = sendCreditDecisionEmails(lead);
        return lead;
    }

    public Lead getCreditReviewedLead(Lead lead, LASERCA__Personal_Credit_Report__c pcr, ProductRepo productRepo, List<LASERCA__Trade_Accounts__c> tradeAccounts ) {
        List<LASERCA__Personal_Credit_Report__c> leadPCRs = getPCRsForCreditAnalysis(new Set<Id>{
            lead.Personal_Credit_Report__c,
            lead.Personal_Credit_Report_Co_Applicant__c
        });

        if (pcr == null) {
            for (LASERCA__Personal_Credit_Report__c leadPCR : leadPCRs) {
                if (leadPCR.Id == lead.Personal_Credit_Report__c) {
                    pcr = leadPCR;
                }
            }
        }

        if (productRepo == null) {
            productRepo = new ProductRepo(new List<Lead>{lead});
        }

        Integer creditScore = setAppMaximumCreditScore(lead);
        Decimal householdMonthlyIncome = calculateHouseholdMonthlyIncome(lead);
        Decimal householdMonthlyDebt = PCRTradeAccountHandler.calculateHouseholdMonthlyDebt(lead, tradeAccounts);

        /*
        If a lead doesn't have an associated product, we can't calculate the DTI after
        the loan is selected, so we'll look through all applicable products for the lead
        and see the best we can do.
        */

        CreditResultSummary creditSummary = productRepo.getCreditSummary(lead, creditScore, householdMonthlyIncome, householdMonthlyDebt);
        setPcrDti(lead, creditSummary, pcr);

        if (lead.Product__c == null) {
            if (creditSummary.bestStatus == APPROVED) {
                lead.Product__c = creditSummary.mostExpensiveQualifiedProduct;
            } else {
                lead.Product__c = creditSummary.leastExpensiveQualifiedProduct;
            }
        }

        // set to pending if any codes are present
        if (creditSummary.bestStatus == APPROVED &&
            flaggedCreditCodes != null &&
            checkLeadFlaggedCreditCodes(lead)) {
            creditSummary.bestStatus = PENDINGREVIEW;
        }

        // If credit has been approved & their associated with a bank
        if (creditSummary.bestStatus == APPROVED &&
            (lead.Avidia_Executive__c || lead.Avidia_Service_Provider__c || lead.Other_Bank_Executive__c)) {
            creditSummary.bestStatus = PENDINGREVIEW;
        }

        if (creditScore == 0 || creditScore == NULL) {
            creditSummary.bestStatus = PENDINGREVIEW;
        }
        // overwrite statuses if Avidia has reviewed
        if (pcr.Avidia_Review_Status__c == 'Reviewed - PreApproved' ||
            pcr.Solar_Loan_Manual_Approval__c) {
            pcr.Solar_Loan_Approval_Status__c = APPROVED;
        } else if (pcr.Avidia_Review_Status__c == 'Reviewed - Declined' ||
            pcr.Solar_Loan_Manual_Decline__c) {
            pcr.Solar_Loan_Approval_Status__c = DECLINED;
        } else if (pcr.Avidia_Review_Status__c == PENDINGREVIEW) {
            pcr.Solar_Loan_Approval_Status__c = PENDINGREVIEW;
        } else {
            pcr.Solar_Loan_Approval_Status__c = creditSummary.bestStatus;
        }

        // Per Nader: We don't have clear criteria from Avidia on how to automate co-signer applications
        if (lead.Application_Type__c == 'Joint' && lead.Joint_Applicant_Type__c == 'Co-Signer') {
            pcr.Solar_Loan_Approval_Status__c = PENDINGREVIEW;
        }

        if (PCRPublicRecordHandler.appHasCurrentBankruptcy(leadPCRs)) {
            pcr.Solar_Loan_Approval_Status__c = DECLINED;
        }

        // If lead is in any stage of the process update the status
        if (lead.Status == READYFORCREDITCHECK ||
            lead.Status == PENDINGCREDITREVIEW ||
            lead.Status == UNQUALIFIED ||
            lead.Status == PREQUALIFIED ||
            pcr.Avidia_Review_Status__c == 'Reviewed - Declined') {
            lead = setLeadStatus(pcr.Solar_Loan_Approval_Status__c, lead);
        }

        return lead;
    }

    public static void addMortgage(
        Map<Id, LASERCA__Credit_Report_Log__c> triggerNewMap ,
        Map<Id, LASERCA__Credit_Report_Log__c> triggerOldMap) {
        List<LASERCA__Trade_Accounts__c> mortgagesList = new List<LASERCA__Trade_Accounts__c>();
        Set<Id> pcrIds = new Set<Id>();
        if (triggerOldMap == null) {

            for (LASERCA__Credit_Report_Log__c crl : triggerNewMap.values()) {
                if (crl.LASERCA__Personal_Credit_Report__c != null) {
                    pcrIds.add(crl.LASERCA__Personal_Credit_Report__c);
                }
            }

            if (pcrIds.isEmpty()) {
                return;
            }

            List<LASERCA__Personal_Credit_Report__c> pcrs = getPCRsForCreditAnalysis(pcrIds);

            List<Lead> leadList = [
                SELECT Id, Monthly_Mortgage_Tax_and_Insurance__c, Co_App_Monthly_Mortgage__c
                FROM Lead
                WHERE Id = :pcrs[0].LASERCA__Lead__c
                LIMIT 1
            ];

            Lead lead;

            if (leadList.size() > 0) {
                lead = leadList[0];
            } else {
                return;
            }


            for( LASERCA__Personal_Credit_Report__c pcr : pcrs ){
                LASERCA__Trade_Accounts__c mortgage = new LASERCA__Trade_Accounts__c();
                if (pcr.LASERCA__Contact__c != null) {
                    mortgage.Name = 'Self-Reported Mortgage';
                    mortgage.LASERCA__Personal_Credit_Report__c = pcr.Id;
                    mortgage.LASERCA__Monthly_Payment__c = lead.Co_App_Monthly_Mortgage__c;
                    mortgage.Exclude_From_Rollup__c = true;
                } else {
                    mortgage.Name = 'Self-Reported Mortgage';
                    mortgage.LASERCA__Personal_Credit_Report__c = pcr.Id;
                    mortgage.LASERCA__Monthly_Payment__c = lead.Monthly_Mortgage_Tax_and_Insurance__c;
                    mortgage.Exclude_From_Rollup__c = true;
                }

                mortgagesList.add(mortgage);
            }
            insert mortgagesList;

        }
    }

    public Lead sendCreditDecisionEmails(Lead lead) {
        Boolean hasCoApp = false;
        String firstName = lead.FirstName;
        String lastName = lead.LastName;
        String email = lead.Email;
        if (lead.CoApplicant_Contact__c != null || lead.Personal_Credit_Report_Co_Applicant__c != null) {
            hasCoApp = true;
        }
        if (!lead.Personal_Credit_Report__r.Credit_PreApproval_Email_Sent__c &&
            firstName != NULL &&
            lastName!= NULL &&
            email != NULL &&
            lead.Status == PREQUALIFIED) {

            String continueApplicationUrl =
                Util.getCommunitySiteURL('Apply') + '/s/loan-application?leadId=' + lead.Id;

            String htmlBody, subject;
            if (lead.DOER_Solar_Loan__c) {
                htmlBody = doerEmailTemplate.HtmlValue;
                subject = 'Congrats! ' +  firstName +
                    ', you have been prequalified for a BlueWave Mass Solar Loan';

            } else {
                htmlbody = standardEmailTemplate.HtmlValue;
                subject = 'Congrats! ' +  firstName +
                    ', you have been prequalified for a BlueWave Solar Loan';
            }
            htmlBody = htmlBody.replace('{!Lead.Continue_Loan_Application_Link__c}', continueApplicationUrl);
            htmlBody = htmlBody.replace('{!Lead.Name}', firstName);
            htmlBody = htmlBody.replace('{!Lead.FirstName}', firstName);
            htmlBody = htmlBody.replace('{!Lead.LastName}', lastName);
            htmlBody = htmlBody.replace('{!Lead.Email}', email);
            htmlBody = htmlBody.replace('{!Lead.Lead_ID__c}', lead.Id);
            sendEmail(firstName, subject,
                htmlBody, lead.Partner_Email__c, lead.Id);
            lead.Personal_Credit_Report__r.Credit_PreApproval_Email_Sent__c = TRUE;
        } else if (!lead.Personal_Credit_Report__r.Credit_PreApproval_Email_Sent__c &&
            !lead.Personal_Credit_Report__r.Credit_Denial_Email_Sent__c &&
            firstName != NULL &&
            lastName != NULL &&
            email != NULL &&
            lead.Status  == UNQUALIFIED) {
            String htmlbody;
            if (hasCoApp) {
                htmlbody = coAppDenialEmailTemplate.HtmlValue;
            } else {
                htmlbody = denialEmailTemplate.HtmlValue;
            }
            htmlBody = htmlBody.replace('{!Lead.Name}', firstName);
            htmlBody = htmlBody.replace('{!Lead.FirstName}', firstName );
            htmlBody = htmlBody.replace('{!Lead.Id}',lead.Id );
            string denialSubject = firstName +
                ', your BlueWave Solar Loan Pre-Approval Application was not able to be Pre-Approved';
            sendEmail(firstName, denialSubject,
                htmlBody, lead.Partner_Email__c, lead.Id);
            lead.Personal_Credit_Report__r.Credit_Denial_Email_Sent__c = TRUE;
        }
        return lead;
    }

    public Boolean checkLeadFlaggedCreditCodes(Lead lead) {
        if (lead.Application_Type__c != 'Joint') {
            return checkPCRforFlaggedCreditCodes(lead.Personal_Credit_Report__r);
        } else {
            return(
                checkPCRforFlaggedCreditCodes(lead.Personal_Credit_Report__r)
                    || checkPCRforFlaggedCreditCodes(lead.Personal_Credit_Report_Co_Applicant__r)
            );
        }
    }

    public Boolean checkPCRforFlaggedCreditCodes (LASERCA__Personal_Credit_Report__c pcr) {
        return(
            flaggedCreditCodes.contains(pcr.LASERCA__Code__c)
                || flaggedCreditCodes.contains(pcr.LASERCA__Code_2__c)
                || flaggedCreditCodes.contains(pcr.LASERCA__Code_3__c)
                || flaggedCreditCodes.contains(pcr.LASERCA__Code_4__c)
        );
    }

    public static List<LASERCA__Personal_Credit_Report__c> getPCRsForCreditAnalysis (Set<Id> pcrIds) {
        List<LASERCA__Personal_Credit_Report__c> pcrs = [
            SELECT Id, Name, LASERCA__Lead__c, Lead_from_Contact__c, Do_not_trigger_PCRApprovalHandler__c,
                LASERCA__Code__c, LASERCA__Code_2__c, LASERCA__Code_3__c, LASERCA__Code_4__c,
                LASERCA__Credit_Score_TransUnion__c, Adjusted_Income__c, Annual_Income_From_Lead__c,
                DTI_Before__c, DTI_After__c, DTI_After_Notes__c, Co_Applicant_Income__c,
                Adjusted_Monthly_Personal_Debt__c, DOER_Application__c,
                Avidia_Review_Status__c, Solar_Loan_Manual_Approval__c, Solar_Loan_Approval_Status__c,
                Solar_Loan_Manual_Decline__c, Credit_PreApproval_Email_Sent__c,
                LASERCA__Contact__c, First_Name_from_Lead__c, Last_Name_from_Lead__c, Email_from_Lead__c,
                PCR_Lead_ID__c, Partner_Email__c,
                Credit_Denial_Email_Sent__c,
            (SELECT Id, LASERCA__Type__c, LASERCA__Date_Filed__c, LASERCA__Disposition__c,
                LASERCA__Disposition_Date__c
            FROM LASERCA__Public_Records__r)
            FROM LASERCA__Personal_Credit_Report__c
            WHERE Id IN : pcrIds
        ];
        return pcrs;
    }

    public List<Lead> getLeadsForCreditAnalysis (Set<Id> leadIds) {
        List<Lead> leads = [
            SELECT Id, FirstName, LastName, Email,
                DOER_Solar_Loan__c, Status, Product__c, Monthly_Mortgage_Tax_and_Insurance__c, Joint_Applicant_Type__c,
                Product_line__c, Product_Program__c, LASERCA__Home_State__c, Loan_Principal__c, Avidia_Review_Status__c,
                Income_Support__c, Annual_Income_Currency__c, Co_Applicant_Income__c,
                Co_Applicant_First_Name__c, CoApplicant_Contact__c, Application_Type__c, Partner_Lookup__c,
                IBLS_Category__c, Avidia_Executive__c, Avidia_Service_Provider__c, Other_Bank_Executive__c,
                Personal_Credit_Report__c,
                Personal_Credit_Report_Co_Applicant__c,
                Personal_Credit_Report__r.LASERCA__Contact__c,
                Personal_Credit_Report__r.LASERCA__Credit_Score_TransUnion__c,
                Personal_Credit_Report__r.Adjusted_Income__c,
                Personal_Credit_Report__r.Adjusted_Monthly_Personal_Debt__c,
                Personal_Credit_Report__r.LASERCA__Bankruptcy__c,
                Personal_Credit_Report__r.LASERCA__Sum_of_monthly_Personal_Debt__c,
                Personal_Credit_Report__r.LASERCA__Code__c,
                Personal_Credit_Report__r.LASERCA__Code_2__c,
                Personal_Credit_Report__r.LASERCA__Code_3__c,
                Personal_Credit_Report__r.LASERCA__Code_4__c,
                Personal_Credit_Report__r.Credit_PreApproval_Email_Sent__c,
                Personal_Credit_Report__r.Credit_Denial_Email_Sent__c,
                Personal_Credit_Report__r.Avidia_Review_Status__c,
                Personal_Credit_Report_Co_Applicant__r.Adjusted_Income__c,
                Personal_Credit_Report_Co_Applicant__r.Adjusted_Monthly_Personal_Debt__c,
                Personal_Credit_Report_Co_Applicant__r.LASERCA__Contact__c,
                Personal_Credit_Report_Co_Applicant__r.LASERCA__Credit_Score_TransUnion__c,
                Personal_Credit_Report_Co_Applicant__r.LASERCA__Bankruptcy__c,
                Personal_Credit_Report_Co_Applicant__r.LASERCA__Code__c,
                Personal_Credit_Report_Co_Applicant__r.LASERCA__Code_2__c,
                Personal_Credit_Report_Co_Applicant__r.LASERCA__Code_3__c,
                Personal_Credit_Report_Co_Applicant__r.LASERCA__Code_4__c
            FROM Lead
            WHERE Id  IN : leadIds
        ];
        return leads;
    }

    public Map<Id, List<LASERCA__Trade_Accounts__c>> getTradeAccountsForPCRs (Set<Id> pcrIds) {
        Map<Id, List<LASERCA__Trade_Accounts__c>> tradeAccountsByPCRIds = new Map<Id, List<LASERCA__Trade_Accounts__c>>();
        for (LASERCA__Trade_Accounts__c tradeAccount : [
            SELECT Id, LASERCA__Account_Ownership_Type__c, LASERCA__Account_Status_Type__c, LASERCA__Account_Type__c,
                LASERCA__Open_Date__c, LASERCA__Name_of_the_Institution__c, LASERCA__Last_Activity_Date__c,
                LASERCA__Payment_Pattern_Data__c, LASERCA__Remaining_Term__c, LASERCA__Credit_Text__c,
                LASERCA__Account_Balance__c, LASERCA__Personal_Credit_Report__c, Exclude_From_Rollup__c,
                LASERCA__Credit_Loan_Type__c, LASERCA__Monthly_Payment__c
            FROM LASERCA__Trade_Accounts__c
            WHERE LASERCA__Personal_Credit_Report__c IN : pcrIds
        ]) {
            if (tradeAccountsByPCRIds.containsKey(tradeAccount.LASERCA__Personal_Credit_Report__c)) {
                List<LASERCA__Trade_Accounts__c> tradeAccounts = tradeAccountsByPCRIds.get(tradeAccount.LASERCA__Personal_Credit_Report__c);
                tradeAccounts.add(tradeAccount);
                tradeAccountsByPCRIds.put(tradeAccount.LASERCA__Personal_Credit_Report__c, tradeAccounts);
            } else {
                List<LASERCA__Trade_Accounts__c> tradeAccounts = new List<LASERCA__Trade_Accounts__c>{tradeAccount};
                tradeAccountsByPCRIds.put(tradeAccount.LASERCA__Personal_Credit_Report__c, tradeAccounts);
            }
        }
        return tradeAccountsByPCRIds;
    }

    private Boolean currentBankruptcy (Lead lead) {
        if (lead.Application_Type__c == 'Joint') {
            if (lead.Personal_Credit_Report__r.LASERCA__Bankruptcy__c
                || lead.Personal_Credit_Report_Co_Applicant__r.LASERCA__Bankruptcy__c) {
                return true;
            } else {
                return false;
            }
        } else {
            return lead.Personal_Credit_Report__r.LASERCA__Bankruptcy__c;
        }
    }

    private Integer setAppMaximumCreditScore (Lead lead) {
        Integer creditScore = 0;
        Integer primaryAppCreditScore = Integer.valueOf(Util.nullToZero(lead.Personal_Credit_Report__r.LASERCA__Credit_Score_TransUnion__c));
        if (lead.Application_Type__c == 'Joint'
            && lead.Personal_Credit_Report__r.LASERCA__Credit_Score_TransUnion__c != null
            && lead.Personal_Credit_Report_Co_Applicant__r.LASERCA__Credit_Score_TransUnion__c != null) {
            Integer coAppCreditScore = Integer.valueOf(Util.nullToZero(lead.Personal_Credit_Report_Co_Applicant__r.LASERCA__Credit_Score_TransUnion__c));
// credit score is used to populate the list of products to check qualification against, take maximum to populate more products
            creditScore = Math.max(coAppCreditScore, primaryAppCreditScore);
        } else if (lead.Personal_Credit_Report__r.LASERCA__Credit_Score_TransUnion__c != null) {
            creditScore = primaryAppCreditScore;
        }
        return creditScore;
    }

    private Decimal calculateHouseholdMonthlyIncome (Lead lead) {
        Decimal householdMonthlyIncome = 0;
        if (lead.Personal_Credit_Report__r.Adjusted_Income__c == null) {
            householdMonthlyIncome += Util.nullToZero(lead.Annual_Income_Currency__c) / 12;
        } else {
            householdMonthlyIncome += lead.Personal_Credit_Report__r.Adjusted_Income__c / 12;
        }
        // add coApplicant's income if it is a joint application
        // co-signer's are excluded because automation criteria isn't clear
        if (lead.Application_Type__c == 'Joint' && lead.Joint_Applicant_Type__c == 'Co-Applicant' &&
            lead.Personal_Credit_Report_Co_Applicant__r != null) {
            if (lead.Personal_Credit_Report_Co_Applicant__r.Adjusted_Income__c == null) {
                householdMonthlyIncome += Util.nullToZero(lead.Co_Applicant_Income__c) / 12;
            } else {
                householdMonthlyIncome += lead.Personal_Credit_Report_Co_Applicant__r.Adjusted_Income__c/12;
            }
        }
        return householdMonthlyIncome;
    }

    private Decimal getMonthlyPayment (CreditResultSummary creditSummary) {
        Decimal monthlyPayment;
        if (creditSummary.highestMonthlyPayment == null) {
            monthlyPayment = creditSummary.lowestMonthlyPayment;
        } else {
            monthlyPayment = creditSummary.highestMonthlyPayment;
        }
        return monthlyPayment;
    }

    private Decimal getPersonalDTIAfter (Lead lead, CreditResultSummary creditSummary, LASERCA__Personal_Credit_Report__c pcr){
        Decimal personalDTIAfter;
        Decimal monthlyPayment = Util.nullToZero(getMonthlyPayment(creditSummary));
        Decimal applicantMonthlyIncome = getApplicantMonthlyIncome(lead, pcr);

        if (lead.Application_Type__c == 'Joint'
            && lead.Joint_Applicant_Type__c == 'Co-Signer'
            && pcr.Adjusted_Monthly_Personal_Debt__c != null) {
            personalDTIAfter = (100 * (monthlyPayment + pcr.Adjusted_Monthly_Personal_Debt__c) / applicantMonthlyIncome).setScale(2);
        } else {
            personalDTIAfter = creditSummary.highestDTI;
        }
        return personalDTIAfter;
    }

    private Decimal getApplicantMonthlyIncome (Lead lead, LASERCA__Personal_Credit_Report__c pcr) {
        Decimal applicantMonthlyIncome;
        if (pcr.Adjusted_Income__c == null) {
            if (pcr.LASERCA__Contact__c == null) {
                applicantMonthlyIncome = Util.nullToZero(lead.Annual_Income_Currency__c) /12;
            } else {
                applicantMonthlyIncome = Util.nullToZero(lead.Co_Applicant_Income__c) / 12;
            }
        } else {
            applicantMonthlyIncome = pcr.Adjusted_Income__c / 12;
        }
        return applicantMonthlyIncome;
    }

    private void setPcrDti (Lead lead, CreditResultSummary creditSummary, LASERCA__Personal_Credit_Report__c pcr) {
        Decimal applicantMonthlyIncome = getApplicantMonthlyIncome(lead, pcr);
        if (applicantMonthlyIncome == 0) {
            // prevent divide by zero errors on DTI calcs
            pcr.DTI_Before__c = null;
            pcr.DTI_After__c = null;
            pcr.DTI_After_Notes__c = null;
        } else {
            pcr.DTI_Before__c = 100 * pcr.Adjusted_Monthly_Personal_Debt__c  / applicantMonthlyIncome;
            pcr.DTI_Before__c = pcr.DTI_Before__c>99999.99?99999.99:pcr.DTI_Before__c;
            pcr.DTI_After__c = getPersonalDTIAfter(lead, creditSummary, pcr);
            pcr.DTI_After__c = pcr.DTI_After__c>99999.99?99999.99:pcr.DTI_After__c;
            pcr.DTI_After_Notes__c = creditSummary.toString();
        }

    }

    public Boolean leadReadyForPrequalCheck (Lead lead) {
        if (lead.Application_Type__c != 'Joint'
            && lead.Personal_Credit_Report__c != null) {
            return true;
        } else if (lead.Application_Type__c == 'Joint'
            && lead.Personal_Credit_Report__c != null
            && lead.Personal_Credit_Report_Co_Applicant__c != null) {
            return true;
        } else {
            return false;
        }
    }

    private Boolean deniedBecauseFICO (Integer creditScore, Integer creditMinimum) {
        if (creditScore < 300 || creditScore == NULL) {
            return (FALSE);
        } else {
            return (creditScore < creditMinimum);
        }
    }

    private Lead setLeadStatus(String approval, Lead lead) {
        if (approval == APPROVED) {
            lead.Status = PREQUALIFIED;
        } else if (approval == PENDINGREVIEW) {
            lead.Status = PENDINGCREDITREVIEW;
        } else if (approval == DECLINED) {
            lead.Status = UNQUALIFIED;
        }
        return lead;
    }

    private void sendEmail(String firstname, String subjectLine, String body, String partnerEmail, Id targetObjectId) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setHtmlBody(body);
        mail.setOrgWideEmailAddressId(customerCareAddress.id);

        if (partnerEmail != NULL) {
            String[] ccAddresses = new String[] {partnerEmail};
            mail.setccAddresses(ccAddresses);
        }

        mail.setSubject(subjectLine);
        mail.setTargetObjectId(targetObjectId);
        system.debug(mail);
        MessagingService.sendEmail(new Messaging.SingleEmailMessage[] {mail});
    }

    private static void updateOppStagesVoid(List<LASERCA__Personal_Credit_Report__c> pcrsToCheck){
        List<Opportunity> oppsToUpdate = new List<Opportunity>();
        Set<Id> leadIds = new Set<Id>();

        for(LASERCA__Personal_Credit_Report__c pcr : pcrsToCheck){
            if (pcr.Avidia_Review_Status__c == 'Reviewed - Declined') {
                leadIds.add(pcr.LASERCA__Lead__c);
            }
        }
        for(Opportunity opp : [SELECT Id, Lead__c, StageName FROM Opportunity WHERE Lead__c IN :leadIds]){
            if (opp.StageName != 'Expired' && opp.StageName != 'Dead') {
                opp.StageName = 'Voided';
                oppsToUpdate.add(opp);
            }
        }
        update oppsToUpdate;
    }

    @TestVisible
    public class CreditResultSummary {
        public String bestStatus;
        public Decimal highestDTI;
        public String incomeSupport;
        public Decimal monthlyIncome;
        public Decimal monthlyDebt;
        public Decimal loanPrincipal;
        public Integer primaryAppCreditScore, coAppCreditScore;
        public Boolean doer;
        public Id mostExpensiveQualifiedProduct;
        public Decimal highestMonthlyPayment;
        public Id leastExpensiveQualifiedProduct;
        public Decimal lowestMonthlyPayment;
        public PCRApprovalHandler.ProductRepo repo;
        public List<PCRApprovalHandler.CreditStatusResult> resultList;
        public Set<Id> approvedProducts;
        public Lead lead;

        public CreditResultSummary(Lead lead, Integer creditScore,
            Decimal monthlyIncome, Decimal monthlyDebt) {
            this.lead = lead;
            this.incomeSupport = lead.Income_Support__c;
            this.loanPrincipal = lead.Loan_Principal__c;
            this.monthlyIncome = monthlyIncome.setScale(2);
            this.monthlyDebt = monthlyDebt.setScale(2);
            if (lead.Personal_Credit_Report__c != null) {
                this.primaryAppCreditScore = Integer.valueOf(Util.nullToZero(lead.Personal_Credit_Report__r.LASERCA__Credit_Score_TransUnion__c));
            }
            if (lead.Personal_Credit_Report_Co_Applicant__c != null) {
                this.coAppCreditScore = Integer.valueOf(Util.nullToZero(lead.Personal_Credit_Report_Co_Applicant__r.LASERCA__Credit_Score_TransUnion__c));
            }
            this.doer = lead.DOER_Solar_Loan__c;
            this.highestDTI = 0;
            this.bestStatus = PCRApprovalHandler.DECLINED;
            this.resultList = new List<PCRApprovalHandler.CreditStatusResult>();
            this.approvedProducts = new Set<Id>();
        }

        public void checkAndAddResult(PCRApprovalHandler.CreditStatusResult result, Product2 product) {
            Integer creditMinimum = Integer.valueOf(product.Credit_Minimum__c);
            Decimal dtiMaximum = product.Debt_To_Income_Maximum__c;
            String primaryDecision = checkFICOandDTI(primaryAppCreditScore, result.dtiAfter, creditMinimum, dtiMaximum);
            String jointDecision;
            String appDecision;

            resultList.add(result);
            if (result.dtiAfter > highestDTI) {
                highestDTI = result.dtiAfter;
            }
            if (lead.Application_Type__c == 'Joint' && coAppCreditScore != null) {
                String coAppDecision = checkFICOandDTI(coAppCreditScore, result.dtiAfter, creditMinimum, dtiMaximum);
                if (coAppDecision == primaryDecision && result.dtiAfter <= dtiMaximum) {
                    jointDecision = primaryDecision;
                } else {
                    jointDecision = PENDINGREVIEW;
                }
                appDecision = jointDecision;
            } else if (lead.Application_Type__c != 'Joint') {
                appDecision = primaryDecision;
            }

            if (betterThan(appDecision, bestStatus)) {
                bestStatus = appDecision;
            }

            if (appDecision == APPROVED) {
                approvedProducts.add(product.Id);
                if (highestMonthlyPayment == null ||
                    result.monthlyLoanPayment > highestMonthlyPayment) {
                    highestMonthlyPayment = result.monthlyLoanPayment;
                    mostExpensiveQualifiedProduct = result.productId;
                }
            } else {
                if (lowestMonthlyPayment == null ||
                    result.monthlyLoanPayment < lowestMonthlyPayment) {
                    lowestMonthlyPayment = result.monthlyLoanPayment;
                    leastExpensiveQualifiedProduct = result.productId;
                }
            }

        }



        public override String toString() {
            String summary = 'PCRApprovalHandler Summary: ' +
                'CreditScore: ' + primaryAppCreditScore + ', ' +
                'DOER: ' + doer + ', ' +
                'Income Support if DOER: ' + incomeSupport + ', ' +
                'Monthly Income: ' + monthlyIncome + ', ' +
                'Monthly Debt Before Loan: ' + monthlyDebt + ', ' +
                'Loan Principal: ' + loanPrincipal;
            for (PCRApprovalHandler.CreditStatusResult csr : resultList) {
                summary = summary + '\n' + csr.toString();
            }
            return summary;
        }

        private String checkFICOandDTI(Integer creditScore, Decimal DTIafter, Integer creditMinimum, Decimal dtiMaximum) {
            if (creditScore >= creditMinimum && DTIafter <= dtiMaximum) {
                return APPROVED;
            } else if (creditScore >= 700 && DTIafter > dtiMaximum) {
                return PENDINGREVIEW;
            } else {
                return DECLINED;
            }
        }

        private Boolean betterThan(String newStatus, String oldStatus) {
            if (newStatus == PCRApprovalHandler.DECLINED) {
                return false;
            } else if (newStatus == PCRApprovalHandler.PENDINGREVIEW &&
                oldStatus == PCRApprovalHandler.DECLINED) {
                return true;
            } else if (newStatus == PCRApprovalHandler.APPROVED &&
                (oldStatus == PCRApprovalHandler.PENDINGREVIEW ||
                    oldStatus == PCRApprovalHandler.DECLINED)) {
                return true;
            } else {
                return false;
            }
        }
    }

    @TestVisible
    public class CreditQualifyingMetrics {
        public Lead lead;
        public Decimal adjustedDTI;
        public Integer creditScore;
        public Decimal totalAnnualIncome;
        public Decimal totalMonthlyDebt;
    }

    public static CreditQualifyingMetrics calculateCreditQualifyingMetrics(String leadId) {
        CreditQualifyingMetrics creditMetric = new CreditQualifyingMetrics();
        creditMetric.creditScore = 0;
        creditMetric.totalMonthlyDebt = 0;
        creditMetric.totalAnnualIncome = 0;
        Set<String> socialSecurityVerificationSet = new Set<String>();
        List<Decimal> incomeList = new List<Decimal>();
        List<Product2> productList = new List<Product2>();
        List<LASERCA__Personal_Credit_Report__c> creditReportList = new List<LASERCA__Personal_Credit_Report__c>();
        List<lead> leadList = [SELECT Id, DOER_Solar_Loan__c, Status, Co_Applicant_Income__c,
            Personal_Credit_Report__r.LASERCA__Sum_of_monthly_Personal_Debt__c, Personal_Credit_Report__r.Adjusted_Income__c,
            LASER_Credit_Score__c, Annual_Income_Currency__c, Income_Support__c, Personal_Credit_Report__r.Adjusted_DTI__c,
            Product_Line__c, Product_Program__c, LASERCA__Home_State__c, Loan_Principal__c,
            Personal_Credit_Report__r.Adjusted_Monthly_Personal_Debt__c, Partner_Lookup__c, IBLS_Category__c,
        (SELECT Id, Adjusted_Income__c, Adjusted_DTI__c, LASERCA__Credit_Score_TransUnion__c,
            DTI_After__c, LASERCA__Confirming_Social_Security_Number__c,
            LASERCA__Sum_of_monthly_Personal_Debt__c, LASERCA__Contact__c,
            Adjusted_Monthly_Personal_Debt__c
        FROM LASERCA__Personal_Credit_Reports__r)
        FROM Lead
        WHERE Id = : leadId];
        creditMetric.Lead = leadList[0];
        creditReportList = leadList[0].LASERCA__Personal_Credit_Reports__r;

        if (leadIsCoapplicant(creditReportList)) {
            for (LASERCA__Personal_Credit_Report__c creditReport : creditReportList) {
                if (creditMetric.creditScore < Integer.valueOf(Util.nullToZero(creditReport.LASERCA__Credit_Score_TransUnion__c))) {
                    creditMetric.creditScore = Integer.valueOf(Util.nullToZero(creditReport.LASERCA__Credit_Score_TransUnion__c));
                }
                if (!socialSecurityVerificationSet.contains(creditReport.LASERCA__Confirming_Social_Security_Number__c)) {
                    creditMetric.totalMonthlyDebt = creditMetric.totalMonthlyDebt + creditReport.Adjusted_Monthly_Personal_Debt__c;
                    incomeList.add(identifyCorrectIncomeValue(creditReport, creditMetric));
                    if (creditReport.Adjusted_DTI__c != null && !pcrIsCoApplicant(creditReport)) {
                        creditMetric.adjustedDTI = creditReport.Adjusted_DTI__c;
                    }
                    socialSecurityVerificationSet.add(creditReport.LASERCA__Confirming_Social_Security_Number__c);
                }
            }
            if (!incomeList.isEmpty()) {
                for (Decimal incomeValue : incomeList) {
                    creditMetric.totalAnnualIncome = incomeValue + creditMetric.totalAnnualIncome;
                }
            }
        } else {
            if (creditMetric.Lead.Personal_Credit_Report__r.Adjusted_DTI__c != null) {
                creditMetric.adjustedDTI = creditMetric.Lead.Personal_Credit_Report__r.Adjusted_DTI__c;
            }
            if (creditMetric.Lead.Personal_Credit_Report__r.Adjusted_Income__c != null) {
                creditMetric.totalAnnualIncome = creditMetric.Lead.Personal_Credit_Report__r.Adjusted_Income__c;
            } else {
                creditMetric.totalAnnualIncome = creditMetric.Lead.Annual_Income_Currency__c;
            }
            creditMetric.creditScore = Integer.valueOf(creditMetric.Lead.LASER_Credit_Score__c);
            creditMetric.totalMonthlyDebt = creditMetric.Lead.Personal_Credit_Report__r.Adjusted_Monthly_Personal_Debt__c;
        }
        return creditMetric;
    }

    public static Boolean leadIsCoapplicant (List<LASERCA__Personal_Credit_Report__c> creditReportList) {
        Set<String> socialSecurityVerificationSet = new Set<String>();
        List<LASERCA__Personal_Credit_Report__c> nonDuplicateCreditReportList = new List<LASERCA__Personal_Credit_Report__c>();
        for (LASERCA__Personal_Credit_Report__c creditReport : creditReportList) {
            if (!socialSecurityVerificationSet.contains(creditReport.LASERCA__Confirming_Social_Security_Number__c)) {
                nonDuplicateCreditReportList.add(creditReport);
                socialSecurityVerificationSet.add(creditReport.LASERCA__Confirming_Social_Security_Number__c);
            }
        }
        if (nonDuplicateCreditReportList.size() > 1) {
            return true;
        } else {
            return false;
        }
    }

    public static Boolean pcrIsCoApplicant (LASERCA__Personal_Credit_Report__c creditReport) {
        if (creditReport.LASERCA__Contact__c == null) {
            return false;
        } else {
            return true;
        }
    }

    public static Decimal identifyCorrectIncomeValue (LASERCA__Personal_Credit_Report__c creditReport, PCRApprovalHandler.CreditQualifyingMetrics creditMetric) {
        Decimal income;
        if (creditReport.Adjusted_Income__c != null) {
            income = creditReport.Adjusted_Income__c;
        } else if (creditReport.Adjusted_Income__c == null && !pcrIsCoApplicant(creditReport)){
            income = creditMetric.Lead.Annual_Income_Currency__c;
        } else if (creditReport.Adjusted_Income__c == null && pcrIsCoApplicant(creditReport)){
            income = Util.nullToZero(creditMetric.Lead.Co_Applicant_Income__c);
        }
        return income;
    }

    @TestVisible
    public class CreditStatusResult {
        public String productName;
        public Id productId;
        public Decimal loanInterestRate;
        public Decimal monthlyLoanPayment;
        public Decimal dtiAfter;

        public CreditStatusResult(Product2 product, Decimal monthlyPayment, Decimal dtiAfter) {
            this.productName = product.Name;
            this.productId = product.Id;
            this.loanInterestRate = product.loan_Interest_Rate__c;
            this.monthlyLoanPayment = monthlyPayment.setScale(2);
            this.dtiAfter = dtiAfter.setScale(2);
        }

        public override String toString() {
            return('For ' + productName + ' (' + productId + '), ' +
                'Rate: ' + loanInterestRate + ', ' +
                'Loan Payment: ' + monthlyLoanPayment + ', ' +
                'DTI After Payments: ' + dtiAfter);
        }
    }

    @TestVisible
    public class ProductRepo {
        @TestVisible
        private List<Product2> products;

        public ProductRepo(List<Lead> leads) {
            Set<String> stateSet = new Set<String>();
            Set<String> programSet = new Set<String>();
            Set<String> productSet = new Set<String>();
            List<String> stateList, programList, productList;
            for (Lead lead : leads) {
                productSet.add(lead.Product_Line__c);
                programSet.add(lead.Product_Program__c);
                stateSet.add(lead.LASERCA__Home_State__c);
            }
            productList = new List<String>(productSet);
            programList = new List<String>(programSet);
            stateList = new List<String>(stateSet);

            // This is the superset of all products that might be applicable for the leads being
            // checked. We'll filter them out for a particular lead later on.
            products = [SELECT Id, Name, External_Name__c, Product_Type__c, Program__c, State__c, Debt_To_Income_Maximum__c,
                Credit_Minimum__c, Credit_Maximum__c, Loan_Interest_Rate__c, Loan_Term__c,
                Require_Junctions_to_Enable__c, Maximum_Loan_Size__c, IBLS_Category__c, DTI_After_Rate_Gross_Up__c,
            (SELECT Id, Enabled_Product__c, Partner__c
            FROM Partner_Product_Junctions__r
            WHERE Active__c = true)
            FROM Product2
            WHERE isActive = true
            AND Product_Type__c IN :productList
            AND Program__c IN :programList
            AND State__c IN :stateList];
        }

        public PCRApprovalHandler.CreditResultSummary getCreditSummary(Lead lead, Integer creditScore,
            Decimal monthlyIncome, Decimal monthlyDebt) {
            PCRApprovalHandler.CreditResultSummary creditResultSummary =
                new PCRApprovalHandler.CreditResultSummary(lead, creditScore, monthlyIncome, monthlyDebt);
            // if the credit score returns no products, then it will be declined
            for (Product2 product : getApplicableProducts(lead, creditScore)) {
                PCRApprovalHandler.CreditStatusResult result = calcDTIAfter(product, lead, monthlyIncome, monthlyDebt);
                creditResultSummary.checkAndAddResult(result, product);
            }
            return creditResultSummary;
        }


        public List<Product2> getApplicableProducts(Lead lead, Integer creditScore) {
            List<Product2> applicableProducts = new List<Product2>();
            for (Product2 product : products) {
                if (product.Product_Type__c == lead.Product_Line__c &&
                    product.Program__c == lead.Product_Program__c &&
                    product.State__c == lead.LASERCA__Home_State__c &&
                    (product.Maximum_Loan_Size__c!=null?lead.Loan_Principal__c<=product.Maximum_Loan_Size__c:true) &&
                    (product.IBLS_Category__c!=null?lead.IBLS_Category__c == product.IBLS_Category__c:true) &&
                    enabledForPartner(product, lead.Partner_Lookup__c)) {
                    if (Integer.valueOf(product.Credit_Minimum__c) <= creditScore &&
                        Integer.valueOf(product.Credit_Maximum__c) >= creditScore) {
                        applicableProducts.add(product);
                    }
                }
            }
            return applicableProducts;
        }

        private Boolean enabledForPartner(Product2 prod, Id partnerId) {
            if (prod.Require_Junctions_to_Enable__c) {
                for (Partner_Product_Junction__c ppj : prod.Partner_Product_Junctions__r) {
                    if (ppj.Enabled_Product__c == prod.Id && ppj.Partner__c == partnerId) {
                        return true;
                    }
                }
                return false;
            }
            return true;
        }

        public PCRApprovalHandler.CreditStatusResult calcDTIAfter(Product2 product, Lead leadRecord,
            Decimal monthlyIncome, Decimal monthlyDebt) {
            Double paymentDenominatorVar1, paymentDenominatorVar2, paymentDenominatorVar3, paymentDenominator;
            Decimal paymentNumerator, dtiNumerator, dtiDenominator, dtiAfter, monthlyPayment;
            Decimal interestRate = (product.Loan_Interest_Rate__c + Util.nullToZero(product.DTI_After_Rate_Gross_Up__c)) / 100;
            // IBLS is based on household income. Even if we use joint income, we don't know 
            // if the customer will get IBLS, so don't base DTI After on IBLS
            paymentNumerator = leadRecord.Loan_Principal__c * interestRate / 12;

            paymentDenominatorVar1 = ( 1 + interestRate/12);
            paymentDenominatorVar2 = (-1 * product.Loan_Term__c);
            paymentDenominatorVar3 = Math.pow(paymentDenominatorVar1, paymentDenominatorVar2);
            paymentDenominator = 1 - paymentDenominatorVar3;
            monthlyPayment = paymentNumerator/paymentDenominator;
            dtiNumerator = monthlyDebt + monthlyPayment;
            dtiDenominator = monthlyIncome;
            dtiAfter = 100*(dtiNumerator/dtiDenominator);
            dtiAfter.setScale(2);
            return(new PCRApprovalHandler.CreditStatusResult(product, monthlyPayment, dtiAfter));
        }

    }
}