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

    private static EmailTemplate doerEmailTemplate;
    private static EmailTemplate standardEmailTemplate;
    private static EmailTemplate denialEmailTemplate;
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
            standardEmailTemplate = [SELECT id, HtmlValue, Body 
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

    public static void calcDTIAndEmailIfComplete(Map<Id, LASERCA__Credit_Report_Log__c> triggerNewMap, 
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
        List<LASERCA__Personal_Credit_Report__c> pcrs = 
            [SELECT Id, Name, LASERCA__Lead__c, Lead_from_Contact__c, Do_not_trigger_PCRApprovalHandler__c, 
             LASERCA__Code__c, LASERCA__Code_2__c, LASERCA__Code_3__c, LASERCA__Code_4__c,
             LASERCA__Credit_Score_TransUnion__c, Adjusted_Income__c, Annual_Income_From_Lead__c,
             DTI_Before__c, DTI_After__c, DTI_After_Notes__c, Co_Applicant_Income__c,
             Adjusted_Monthly_Personal_Debt__c, DOER_Application__c, 
             Avidia_Review_Status__c, Solar_Loan_Manual_Approval__c, Solar_Loan_Approval_Status__c,
             Solar_Loan_Manual_Decline__c, Credit_PreApproval_Email_Sent__c,
             LASERCA__Contact__c, First_Name_from_Lead__c, Last_Name_from_Lead__c, Email_from_Lead__c,
             PCR_Lead_ID__c, Partner_Email__c,
             Credit_Denial_Email_Sent__c
             FROM LASERCA__Personal_Credit_Report__c
             WHERE Id = :pcrIds];
        pcrAH.onBeforeUpdate(pcrs);
        update pcrs;
    }

    // Since we want updates to happen in real-time (to support the Loan Underwriting page), this method checks that
    // the update happens out of the insert cycle (by making sure the PCR it's 10 seconds old)
    @TestVisible
    private static boolean noDelay = false;
    public static void calcDTIAndEmailOnlyOld(List<LASERCA__Personal_Credit_Report__c> newPCR) {
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
            pcrAH.onBeforeUpdate(oldPCRs);
        }
    }

    private void onBeforeUpdate(LASERCA__Personal_Credit_Report__c[] newPCR) {
        List<String> leadlist = new List<String>();
        Map<Id, Lead> leadMap = new Map<Id, Lead>();
        List<Lead> leadstoUpdate = new List<Lead>();
        List<Product2> products;
        Boolean hasCoApp = FALSE;

        for (LASERCA__Personal_Credit_Report__c pcrForLead: newPCR) {
            if (pcrForLead.LASERCA__Lead__c == NULL && pcrForLead.Lead_from_Contact__c != NULL) {
                pcrForLead.LASERCA__Lead__c = pcrForLead.Lead_from_Contact__c;
            }
            if (pcrForLead.LASERCA__Lead__c != NULL) {
                leadlist.add(pcrForLead.LASERCA__Lead__c);
            }
        }

        List<Lead> relatedLeads  = [SELECT Id, DOER_Solar_Loan__c, Status, Product__c,
                                    Personal_Credit_Report__r.LASERCA__Sum_of_monthly_Personal_Debt__c,
                                    Product_Line__c, Product_Program__c, LASERCA__Home_State__c, Loan_Principal__c,
                                    Income_Support__c, Annual_Income_Currency__c, Co_Applicant_Income__c,
                                    Personal_Credit_Report_Co_Applicant__r.LASERCA__Credit_Score_TransUnion__c,
                                    Co_Applicant_First_Name__c, CoApplicant_Contact__c, Application_Type__c,
                                    Personal_Credit_Report__r.LASERCA__Credit_Score_TransUnion__c, Partner_Lookup__c,
                                    IBLS_Category__c, Avidia_Executive__c, Avidia_Service_Provider__c, Other_Bank_Executive__c
                                    FROM Lead 
                                    WHERE Id  IN : leadlist];
        for (Lead lead : relatedLeads) {
            leadMap.put(lead.Id, lead);
        }

        ProductRepo productRepo = new ProductRepo(relatedLeads);

        for (LASERCA__Personal_Credit_Report__c pcr : newPCR) {
            if (!pcr.Do_not_trigger_PCRApprovalHandler__c && 
                pcr.LASERCA__Lead__c != NULL &&
                leadMap.get(pcr.LASERCA__Lead__c).Product_Line__c != 'Community Solar') {
                Lead lead = leadMap.get(pcr.LASERCA__Lead__c);
                String bwApproval, doerApproval;
                Integer creditScore;
                if (pcr.LASERCA__Credit_Score_TransUnion__c == null) {
                    creditScore = 0;
                } else {
                    creditScore = Integer.valueOf(pcr.LASERCA__Credit_Score_TransUnion__c);
                }

                Decimal monthlyIncome;
                if (pcr.Adjusted_Income__c == null) {
                    monthlyIncome = LoanServicer.nullToZero(lead.Annual_Income_Currency__c) / 12;
                } else {
                    monthlyIncome = pcr.Adjusted_Income__c / 12;
                }

                if (pcr.LASERCA__Contact__c != NULL) {
                    if (pcr.Adjusted_Income__c == null) {
                        monthlyIncome = LoanServicer.nullToZero(lead.Co_Applicant_Income__c) / 12;
                    } else {
                        monthlyIncome = pcr.Adjusted_Income__c/12;
                    }
                    Integer primaryAppCreditScore = Integer.valueOf(LoanServicer.nullToZero(lead.Personal_Credit_Report__r.LASERCA__Credit_Score_TransUnion__c));
                    creditScore = Math.max(creditScore, primaryAppCreditScore);
                }

                if (monthlyIncome == 0) {
                    pcr.DTI_Before__c = null;
                    pcr.DTI_After__c = null;
                    pcr.DTI_After_Notes__c = null;
                    continue;
                }

                // If a lead doesn't have an associated product, we can't calculate the DTI after
                // the loan is selected, so we'll look through all applicable products for the lead
                // and see the best we can do.
                PCRApprovalHandler.CreditResultSummary creditSummary = 
                    productRepo.getCreditSummary(lead,
                                                 creditScore, monthlyIncome, 
                                                 pcr.Adjusted_Monthly_Personal_Debt__c);

                pcr.DTI_Before__c = 100 * pcr.Adjusted_Monthly_Personal_Debt__c / monthlyIncome;
                pcr.DTI_Before__c = pcr.DTI_Before__c>99999.99?99999.99:pcr.DTI_Before__c;
                pcr.DTI_After__c = creditSummary.highestDTI;
                pcr.DTI_After__c = pcr.DTI_After__c>99999.99?99999.99:pcr.DTI_After__c;
                pcr.DTI_After_Notes__c = creditSummary.toString();

                if (lead.Product__c == null) {
                    // whats the point of this?
                    if (creditSummary.bestStatus == APPROVED) {
                        lead.Product__c = creditSummary.mostExpensiveQualifiedProduct;
                    } else {
                        lead.Product__c = creditSummary.leastExpensiveQualifiedProduct;
                    }
                } else {
                    if (creditSummary.bestStatus == APPROVED && !creditSummary.approvedProducts.contains(lead.Product__c)) {
                        lead.Product__c = creditSummary.mostExpensiveQualifiedProduct;
                    }
                }

                boolean declinedFromFICO = deniedBecauseFICO(creditScore, 680);

                // set to pending if any codes are present
                if (creditSummary.bestStatus == APPROVED &&
                    flaggedCreditCodes != null &&
                    (flaggedCreditCodes.contains(pcr.LASERCA__Code__c) ||
                     flaggedCreditCodes.contains(pcr.LASERCA__Code_2__c) ||
                     flaggedCreditCodes.contains(pcr.LASERCA__Code_3__c) ||
                     flaggedCreditCodes.contains(pcr.LASERCA__Code_4__c))) {
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
                // If lead is in any stage of the process update the status
                if (lead.Status == READYFORCREDITCHECK ||
                    lead.Status == PENDINGCREDITREVIEW ||
                    lead.Status == UNQUALIFIED ||
                    lead.Status == PREQUALIFIED ||
                    pcr.Avidia_Review_Status__c == 'Reviewed - Declined') {
                    setLeadStatus(pcr.Solar_Loan_Approval_Status__c, lead);
                    leadsToUpdate.add(lead);
                }

                if (leadMap.get(pcr.LASERCA__Lead__c).CoApplicant_Contact__c != NULL || leadMap.get(pcr.LASERCA__Lead__c).Co_Applicant_First_Name__c != NULL) { 
                    hasCoApp = TRUE;
                }

                // SEND PREAPPROVAL EMAIL 
                if (!pcr.Credit_PreApproval_Email_Sent__c &&
                    pcr.LASERCA__Contact__c == NULL &&
                    pcr.First_Name_from_Lead__c != NULL &&
                    pcr.Last_Name_from_Lead__c != NULL &&
                    pcr.Email_from_Lead__c != NULL &&
                    pcr.Solar_Loan_Approval_Status__c == APPROVED) {

                    String continueApplicationUrl =
                        Util.getCommunitySiteURL('Apply') + '/s/loan-application?leadId=' + pcr.PCR_Lead_ID__c;

                    if (pcr.DOER_Application__c) {
                        String htmlbody = doerEmailTemplate.HtmlValue;
                        htmlBody = htmlBody.replace('{!Lead.Continue_Loan_Application_Link__c}', continueApplicationUrl);
                        htmlBody = htmlBody.replace('{!Lead.Name}', pcr.First_Name_from_Lead__c);
                        htmlBody = htmlBody.replace('{!Lead.FirstName}', pcr.First_Name_from_Lead__c);
                        htmlBody = htmlBody.replace('{!Lead.LastName}', pcr.Last_Name_from_Lead__c);
                        htmlBody = htmlBody.replace('{!Lead.Email}', pcr.Email_from_Lead__c);
                        htmlBody = htmlBody.replace('{!Lead.Lead_ID__c}',pcr.PCR_Lead_ID__c );
                        string massLoanSubject = 'Congrats! ' +  pcr.First_Name_from_Lead__c + 
                                                ', you have been prequalified for a BlueWave Mass Solar Loan'; 
                        sendEmail(pcr.First_Name_from_Lead__c, massLoanSubject, 
                                  htmlBody, pcr.Partner_Email__c, pcr.PCR_Lead_ID__c);
                        pcr.Credit_PreApproval_Email_Sent__c = TRUE;

                    } else {
                        String htmlbody = standardEmailTemplate.HtmlValue;
                        htmlBody = htmlBody.replace('{!Lead.Continue_Loan_Application_Link__c}', continueApplicationUrl);
                        htmlBody = htmlBody.replace('{!Lead.Name}', pcr.First_Name_from_Lead__c);
                        htmlBody = htmlBody.replace('{!Lead.Email}', pcr.Email_from_Lead__c);
                        htmlBody = htmlBody.replace('{!Lead.Lead_ID__c}',pcr.PCR_Lead_ID__c );
                        string doerSubject = 'Congrats! ' +  pcr.First_Name_from_Lead__c + 
                                            ', you have been prequalified for a BlueWave Solar Loan'; 
                        sendEmail(pcr.First_Name_from_Lead__c, doerSubject, 
                                  htmlBody, pcr.Partner_Email__c, pcr.PCR_Lead_ID__c);
                        pcr.Credit_PreApproval_Email_Sent__c = TRUE;
                    }
                } else if (!pcr.Credit_PreApproval_Email_Sent__c &&
                           !pcr.Credit_Denial_Email_Sent__c &&
                           pcr.LASERCA__Contact__c == NULL &&
                           pcr.First_Name_from_Lead__c != NULL &&
                           pcr.Last_Name_from_Lead__c != NULL &&
                           pcr.Email_from_Lead__c != NULL &&
                           pcr.Solar_Loan_Approval_Status__c == DECLINED &&
                           declinedFromFICO &&
                           !hasCoApp) {
                    String htmlbody = denialEmailTemplate.HtmlValue;
                    htmlBody = htmlBody.replace('{!Lead.FirstName}', pcr.First_Name_from_Lead__c);
                    htmlBody = htmlBody.replace('{!Lead.Id}',pcr.PCR_Lead_ID__c );
                    string denialSubject = pcr.First_Name_from_Lead__c + 
                        ', your BlueWave Solar Loan Pre-Approval Application was not able to be Pre-Approved'; 
                    sendEmail(pcr.First_Name_from_Lead__c, denialSubject, 
                              htmlBody, pcr.Partner_Email__c, pcr.PCR_Lead_ID__c);
                    pcr.Credit_Denial_Email_Sent__c = TRUE;
                }
            }
        }
        if (!leadsToUpdate.isEmpty()) {
            update leadsToUpdate;
        }
    }

    private Boolean deniedBecauseFICO (Integer creditScore, Integer creditMinimum) {
        if (creditScore < 300 || creditScore == NULL) {
            return (FALSE);
        } else {
            return (creditScore < creditMinimum);
        }
    } 

    private void setLeadStatus(String approval, Lead lead) {
        if (approval == APPROVED) {
            lead.Status = PREQUALIFIED;
        } else if (approval == PENDINGREVIEW) {
            lead.Status = PENDINGCREDITREVIEW;
        } else if (approval == DECLINED) {
            lead.Status = UNQUALIFIED;
        }
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

    @TestVisible
    public class CreditResultSummary {
        public String bestStatus;
        public Decimal highestDTI;
        public String incomeSupport;
        public Decimal monthlyIncome;
        public Decimal monthlyDebt;
        public Decimal loanPrincipal;
        public Integer creditScore;
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
            this.creditScore = creditScore;
            this.doer = lead.DOER_Solar_Loan__c;
            this.highestDTI = 0;
            this.bestStatus = PCRApprovalHandler.DECLINED;
            this.resultList = new List<PCRApprovalHandler.CreditStatusResult>();
            this.approvedProducts = new Set<Id>();
        }

        public void checkAndaddResult(PCRApprovalHandler.CreditStatusResult result, Product2 product) {
            Integer creditMinimum = Integer.valueOf(product.Credit_Minimum__c);
            Decimal dtiMaximum = product.Debt_To_Income_Maximum__c;
            String latestStatus = checkFICOandDTI(creditScore, result.dtiAfter, creditMinimum, dtiMaximum);
            resultList.add(result);
            if (latestStatus == APPROVED) {
                approvedProducts.add(product.Id);
            }
            if (betterThan(latestStatus, bestStatus)) {
                bestStatus = latestStatus;
            }
            if (result.dtiAfter > highestDTI) {
                highestDTI = result.dtiAfter;
            }
            // huh??
            if (result.dtiAfter <= dtiMaximum && 
                creditScore >= creditMinimum) {
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
            if (lead.Application_Type__c == 'Joint') {
                if (latestStatus == DECLINED && (bestStatus == null || bestStatus == DECLINED)) {
                    bestStatus = latestStatus;
                } else {
                    bestStatus = PENDINGREVIEW;
                }
            }
        }

        public override String toString() {
            String summary = 'PCRApprovalHandler Summary: ' +
                'CreditScore: ' + creditScore + ', ' +
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
            // 650 - 680 => 45%, 681+ => 50% and handle low product as a non-DOER product for purposes of pre-approval
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
                if (creditMetric.creditScore < Integer.valueOf(LoanServicer.nullToZero(creditReport.LASERCA__Credit_Score_TransUnion__c))) {
                    creditMetric.creditScore = Integer.valueOf(LoanServicer.nullToZero(creditReport.LASERCA__Credit_Score_TransUnion__c));   
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
