/*************************************************************************************
 * Created By: Peter Yao
 * 
 * Description: Controller for the LoanUnderwriting lightning component to help Avidia
 *              review loans
 *
 Tested By: LoanUnderwritingTest
 *************************************************************************************/

global without sharing class LoanUnderwriting {
    public static Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();
    public static Integer CODE = 0;
    public static Integer DETAIL = 1;

    // For LoanUnderwritingSnapshot page
    public String renderAs { get; set; }
    public Id leadId;
    public Contact coApp;
    public LeadWithPCRAttachments lead { get; set; }
    public Decimal monthlyPayment { get; set; }
    public Boolean hasCoApp { get; set; }
    public Integer bestFICO { get; set; }
    public Decimal bestDTI { get; set; }
    public Decimal combinedIncome { get; set; }
    public String primaryFifthCode { get; set; }
    public String primaryFifthDetail { get; set; }
    public String coAppFifthCode { get; set; }
    public String coAppfifthDetail { get; set; }
    public String regO { get; set; }
    public String coAppRegO { get; set; }
    public String ofac {get; set; }
    public String coAppOFAC { get; set; }
    public LASERCA__Personal_Credit_Report__c primaryPCR { get; set; }
    public LASERCA__Personal_Credit_Report__c coAppPCR { get; set; }
    public Boolean employedYear { get; set; }
    public Boolean employedSixMonths { get; set; }
    public Boolean residedSixMonths { get; set; }

    public LoanUnderwriting() {
        this.leadId = ApexPages.currentPage().getParameters().get('leadId');
        this.renderAs = ApexPages.currentPage().getParameters().get('renderAs');
        this.lead = getLead(leadId);
        this.monthlyPayment = lead.lead.Monthly_Payment__c;
        this.ofac = getOFAC(lead.lead.Personal_Credit_Report__c);
        regO = getRegO(lead.lead, FALSE);
        if (lead.lead.Product__r.DTI_After_Rate_Gross_Up__c != null) {
            this.monthlyPayment =
                (lead.lead.Loan_Principal__c * (lead.lead.Product__r.Loan_Interest_Rate__c + lead.lead.Product__r.DTI_After_Rate_Gross_Up__c) / 100 / 12) /
                    (1 - Math.pow((Double) (1 + (lead.lead.Product__r.Loan_Interest_Rate__c + lead.lead.Product__r.DTI_After_Rate_Gross_Up__c) / 100 / 12), (Double) (-1 * lead.lead.Product__r.Loan_Term__c)));
        }
        if (lead.lead.Personal_Credit_Report_Co_Applicant__r != null &&
            lead.lead.Personal_Credit_Report__r != null) {
            hasCoApp = true;
            coApp = getCoAppContact(lead.lead);
            bestFICO = Math.max(Integer.valueOf((Util.nullToZero(lead.lead.Personal_Credit_Report_Co_Applicant__r.LASERCA__Credit_Score_TransUnion__c))),
                Integer.valueOf((Util.nullToZero(lead.lead.Personal_Credit_Report__r.LASERCA__Credit_Score_TransUnion__c))));
            primaryFifthCode = getFifthCode(lead.lead.Personal_Credit_Report__r.LASERCA__TransUnion_Score_Factor__c);
            primaryFifthDetail = getFifthDetail(lead.lead.Personal_Credit_Report__r.LASERCA__TransUnion_Score_Factor__c);
            coAppFifthCode = getFifthCode(lead.lead.Personal_Credit_Report_Co_Applicant__r.LASERCA__TransUnion_Score_Factor__c);
            coAppFifthDetail = getFifthDetail(lead.lead.Personal_Credit_Report_Co_Applicant__r.LASERCA__TransUnion_Score_Factor__c);
            primaryPCR = getPCRDebt(lead.lead.Personal_Credit_Report__r.Id);
            coAppPCR = getPCRDebt(lead.lead.Personal_Credit_Report_Co_Applicant__r.Id);
            coAppOFAC = getOFAC(lead.lead.Personal_Credit_Report_Co_Applicant__c);
            coAppRegO = getRegO(lead.lead, TRUE);
        } else if (lead.lead.Personal_Credit_Report__r != null) {
            hasCoApp = false;
            bestFICO = Integer.valueOf(Util.nullToZero(lead.lead.Personal_Credit_Report__r.LASERCA__Credit_Score_TransUnion__c));
            primaryFifthCode = getFifthCode(lead.lead.Personal_Credit_Report__r.LASERCA__TransUnion_Score_Factor__c);
            primaryFifthDetail = getFifthDetail(lead.lead.Personal_Credit_Report__r.LASERCA__TransUnion_Score_Factor__c);
            primaryPCR = getPCRDebt(lead.lead.Personal_Credit_Report__r.Id);
        } else {
            // No PCR on the lead - something is wrong
            return;
        }

        Decimal mainIncome = 0, mainDebt = 0, coAppIncome = 0, coAppDebt = 0;
        Decimal loanPayment = this.monthlyPayment;
        if (primaryPCR.Adjusted_DTI__c != null) {
            bestDTI = primaryPCR.Adjusted_DTI__c;
        } else {
            if (hasCoApp) {
                if (primaryPCR.Adjusted_Income__c != null) {
                    mainIncome = primaryPCR.Adjusted_Income__c / 12;
                } else {
                    mainIncome = lead.lead.Annual_Income_Currency__c / 12;
                }
                mainDebt = primaryPCR.Adjusted_Monthly_Personal_Debt__c;

                if (coAppPCR.Adjusted_Income__c != null) {
                    coAppIncome = coAppPCR.Adjusted_Income__c / 12;
                } else {
                    coAppIncome = lead.lead.Co_Applicant_Income__c / 12;
                }
                coAppDebt = coAppPCR.Adjusted_Monthly_Personal_Debt__c;

                if (mainIncome + coAppIncome > 0) {
                    bestDTI = 100 * (mainDebt + coAppDebt + loanPayment) / (mainIncome + coAppIncome);
                }
            } else {
                if (primaryPCR.Adjusted_Income__c != null) {
                    mainIncome = primaryPCR.Adjusted_Income__c / 12;
                } else {
                    mainIncome = lead.lead.Annual_Income_Currency__c / 12;
                }

                mainDebt = primaryPCR.Adjusted_Monthly_Personal_Debt__c;

                if (mainIncome > 0) {
                    bestDTI = 100 * (mainDebt + loanPayment) / (mainIncome);
                }
            }
        }

        if (lead.lead.Personal_Credit_Report__r.Adjusted_Income__c != null) {
            mainIncome = lead.lead.Personal_Credit_Report__r.Adjusted_Income__c;
        } else {
            mainIncome = Util.nullToZero(lead.lead.Annual_Income_Currency__c);
        }

        if (hasCoApp) {
            if (lead.lead.Personal_Credit_Report_Co_Applicant__r.Adjusted_Income__c != null) {
                coAppIncome = lead.lead.Personal_Credit_Report_Co_Applicant__r.Adjusted_Income__c;
            } else {
                coAppIncome = Util.nullToZero(lead.lead.Co_Applicant_Income__c);
            }
        }
        combinedIncome = mainIncome + coAppIncome;

    }


    @AuraEnabled
    public static LeadWithPCRAttachments getLead(Id leadId) {
        List<Lead> leads = [
            SELECT FirstName, LastName, Name, Loan_Principal__c,
                Product__r.Name, Product__r.Credit_Minimum__c, Product__r.Debt_To_Income_Maximum__c,
                Product__r.Loan_Interest_Rate__c, Product__r.DTI_After_Rate_Gross_Up__c,
                Product__r.Loan_Term__c, Property_Type__c,
                Avidia_Service_Provider__c, Other_Bank_Executive__c, Type_of_Avidia_Service_Provider__c,
                Annual_Income_Currency__c, Co_Applicant_Income__c, Monthly_Payment__c,
                Manual_Credit_Decline__c, Co_App_Manual_Credit_Decline__c,
                Personal_Credit_Report__c, Personal_Credit_Report_Co_Applicant__c,
                lived_residence_six_months__c,
                Employed_for_more_than_six_months__c, Employed_for_more_than_one_year__c,
                Requested_Loan_Amount__c, System_Cost__c,
                Co_Applicant_First_Name__c, Co_Applicant_Last_Name__c, CoApplicant_Contact__c,
                Personal_Credit_Report__r.Id,
                Personal_Credit_Report__r.Name,
                Personal_Credit_Report__r.DTI_Before__c,
                Personal_Credit_Report__r.DTI_After__c,
                Personal_Credit_Report__r.Adjusted_DTI_Notes__c,
                Personal_Credit_Report__r.Avidia_Review_Status__c,
                Personal_Credit_Report__r.LASERCA__Credit_Score_TransUnion__c,
                Personal_Credit_Report__r.Adverse_Credit_Notice_1__c,
                Personal_Credit_Report__r.Adverse_Credit_Notice_2__c,
                Personal_Credit_Report__r.Adverse_Credit_Notice_3__c,
                Personal_Credit_Report__r.LASERCA__Code__c,
                Personal_Credit_Report__r.LASERCA__Code_2__c,
                Personal_Credit_Report__r.LASERCA__Code_3__c,
                Personal_Credit_Report__r.LASERCA__Code_4__c,
                Personal_Credit_Report__r.LASERCA__Detail_1__c,
                Personal_Credit_Report__r.LASERCA__Detail_2__c,
                Personal_Credit_Report__r.LASERCA__Detail_3__c,
                Personal_Credit_Report__r.LASERCA__Detail_4__c,
                Personal_Credit_Report__r.LASERCA__TransUnion_Alert_Message__c,
                Personal_Credit_Report__r.LASERCA__TransUnion_Score_Factor__c,
                Personal_Credit_Report__r.Adjusted_Monthly_Personal_Debt__c,
                Personal_Credit_Report__r.Annual_Income_from_Lead__c,
                Personal_Credit_Report__r.Adjusted_Income__c,
                Personal_Credit_Report__r.Adjustments_Comments__c,
                Personal_Credit_Report__r.Adjusted_DTI__c,
                Personal_Credit_Report__r.LASERCA__Sum_of_monthly_Personal_Debt__c,
                Personal_Credit_Report__r.LASERCA__Total_High_Credit__c,
                Personal_Credit_Report__r.LASERCA__Installment_Balance__c,
                Personal_Credit_Report__r.LASERCA__Revolving_Balance__c,
                Personal_Credit_Report__r.LASERCA__Real_Estate_Payment__c,
                Personal_Credit_Report_Co_Applicant__r.Id,
                Personal_Credit_Report_Co_Applicant__r.Name,
                Personal_Credit_Report_Co_Applicant__r.DTI_Before__c,
                Personal_Credit_Report_Co_Applicant__r.DTI_After__c,
                Personal_Credit_Report_Co_Applicant__r.Adjusted_DTI_Notes__c,
                Personal_Credit_Report_Co_Applicant__r.LASERCA__Credit_Score_TransUnion__c,
                Personal_Credit_Report_Co_Applicant__r.Adverse_Credit_Notice_1__c,
                Personal_Credit_Report_Co_Applicant__r.Adverse_Credit_Notice_2__c,
                Personal_Credit_Report_Co_Applicant__r.Adverse_Credit_Notice_3__c,
                Personal_Credit_Report_Co_Applicant__r.LASERCA__Code__c,
                Personal_Credit_Report_Co_Applicant__r.LASERCA__Code_2__c,
                Personal_Credit_Report_Co_Applicant__r.LASERCA__Code_3__c,
                Personal_Credit_Report_Co_Applicant__r.LASERCA__Code_4__c,
                Personal_Credit_Report_Co_Applicant__r.LASERCA__Detail_1__c,
                Personal_Credit_Report_Co_Applicant__r.LASERCA__Detail_2__c,
                Personal_Credit_Report_Co_Applicant__r.LASERCA__Detail_3__c,
                Personal_Credit_Report_Co_Applicant__r.LASERCA__Detail_4__c,
                Personal_Credit_Report_Co_Applicant__r.LASERCA__TransUnion_Score_Factor__c,
                Personal_Credit_Report_Co_Applicant__r.Adjusted_Monthly_Personal_Debt__c,
                Personal_Credit_Report_Co_Applicant__r.Annual_Income_from_Lead__c,
                Personal_Credit_Report_Co_Applicant__r.Adjusted_Income__c,
                Personal_Credit_Report_Co_Applicant__r.Adjusted_DTI__c,
                Personal_Credit_Report_Co_Applicant__r.Adjustments_Comments__c,
                Personal_Credit_Report_Co_Applicant__r.LASERCA__TransUnion_Alert_Message__c,
                Personal_Credit_Report_Co_Applicant__r.LASERCA__Sum_of_monthly_Personal_Debt__c,
                Personal_Credit_Report_Co_Applicant__r.LASERCA__Total_High_Credit__c,
                Personal_Credit_Report_Co_Applicant__r.LASERCA__Installment_Balance__c,
                Personal_Credit_Report_Co_Applicant__r.LASERCA__Revolving_Balance__c,
                Personal_Credit_Report_Co_Applicant__r.LASERCA__Real_Estate_Payment__c,
                ConvertedContactId, Change_Order_Status__c, (SELECT Id, Name FROM Attachments)
            FROM Lead
            WHERE ID = :leadId
        ];
        if (!leads.isEmpty()) {
            Attachment mainPCRAttachment, coAppPCRAttachment;
            Lead lead = leads[0];
            if (lead.Personal_Credit_Report__c != null) {
                mainPCRAttachment = getAttachment(lead.Personal_Credit_Report__c);
                if (lead.Personal_Credit_Report__r.DTI_Before__c != null) {
                    lead.Personal_Credit_Report__r.DTI_Before__c = lead.Personal_Credit_Report__r.DTI_Before__c.setScale(2);
                }
                if (lead.Personal_Credit_Report__r.DTI_After__c != null) {
                    lead.Personal_Credit_Report__r.DTI_After__c = lead.Personal_Credit_Report__r.DTI_After__c.setScale(2);
                }
            }
            if (lead.Personal_Credit_Report_Co_Applicant__c != null) {
                coAppPCRAttachment = getAttachment(lead.Personal_Credit_Report_Co_Applicant__c);
                if (lead.Personal_Credit_Report_Co_Applicant__r.DTI_Before__c != null) {
                    lead.Personal_Credit_Report_Co_Applicant__r.DTI_Before__c = lead.Personal_Credit_Report_Co_Applicant__r.DTI_Before__c.setScale(2);
                }
                if (lead.Personal_Credit_Report_Co_Applicant__r.DTI_After__c != null) {
                    lead.Personal_Credit_Report_Co_Applicant__r.DTI_After__c = lead.Personal_Credit_Report_Co_Applicant__r.DTI_After__c.setScale(2);
                }
            }
            List<Attachment> contactAttachments = null;
            if (lead.ConvertedContactId != null) {
                contactAttachments = getAttachments(lead.ConvertedContactId);
            }
            return(new LeadWithPCRAttachments(lead, mainPCRAttachment, coAppPCRAttachment, contactAttachments));
        } else {
            return new LeadWithPCRAttachments();
        }
    }

    private static Attachment getAttachment(Id pcrId) {
        List<Attachment> attachments = getAttachments(pcrId);
        for (Attachment attachment : attachments) {
            if (attachment.ContentType == 'application/pdf') {
                return attachment;
            }
        }
        return null;
    }

    private static List<Attachment> getAttachments(Id parentId) {
        List<Attachment> attachments = [
            SELECT Id, ContentType, Name
            FROM Attachment
            WHERE ParentID = :parentId
        ];
        return attachments;
    }

    public static String getRegO(Lead lead, Boolean isCoApp){
        String regOString;
        if (isCoApp){
            Contact coApp = getCoAppContact(lead);
            if (coApp.Avidia_Service_Provider__c) {
                regOString = 'Avidia Service Provider: ' + coApp.Type_of_Avidia_Service_Provider__c;
            } else if ( coApp.Other_Bank_Executive__c) {
                regOString= 'Other Bank Executive';
            } else {
                regOString = 'NA';
            }
        } else {
            if (lead.Avidia_Service_Provider__c) {
                regOString = 'Avidia Service Provider: ' + lead.Type_of_Avidia_Service_Provider__c;
            } else if ( lead.Other_Bank_Executive__c) {
                regOString = 'Other Bank Executive';
            } else {
                regOString = 'NA';
            }
        }
        return regOString;
    }

    @AuraEnabled
    public static String getOFAC(Id pcrId) {
        List<LASERCA__Regulatory_Product__c> regProducts = [
            SELECT Id, Name, LASERCA__Result_Status_Type__c
            FROM LASERCA__Regulatory_Product__c
            WHERE LASERCA__Personal_Credit_Report__c = :pcrId
        ];
        if (regProducts.isEmpty()) {
            String message = 'No OFAC on file';
            return message;
        } else if (regProducts.size() > 1){
            throw new AuraHandledException('LoanUnderwriting.getOFAC, Multiple Regulatory Products found with ID: ' + pcrId);
        } else {
            return regProducts[0].LASERCA__Result_Status_Type__c;
        }
    }

    @AuraEnabled
    public static Contact getCoAppContact(Lead lead) {

        Contact coAppContact = [
            SELECT Id, Avidia_Service_Provider__c, Type_of_Avidia_Service_Provider__c, Other_Bank_Executive__c,
                LASERCA__Social_Security_Number__c
            FROM Contact
            WHERE Id = :lead.CoApplicant_Contact__c
            LIMIT 1
        ];
        return coAppContact;
    }

    // Can be called from custom buttons on the Lead page, or from the LoanUnderwriting screen
    @AuraEnabled
    webservice static void updateManualCreditDecline(Lead lead, Boolean coApplicant) {
        // Copy Transunion factor 5
        lead = [
            SELECT Id, Personal_Credit_Report__r.LASERCA__TransUnion_Score_Factor__c,
                Personal_Credit_Report_Co_Applicant__r.LASERCA__TransUnion_Score_Factor__c,
                Credit_Report_Detail_5__c, Co_App_Credit_Report_Detail_5__c
            FROM Lead
            WHERE Id = :lead.Id
        ];
        if (coApplicant) {
            lead.Co_App_Credit_Report_Detail_5__c =
                getFifthFactor(lead.Personal_Credit_Report_Co_Applicant__r.LASERCA__TransUnion_Score_Factor__c);
            lead.Co_App_Manual_Credit_Decline__c = true;
        } else {
            lead.Credit_Report_Detail_5__c =
                getFifthFactor(lead.Personal_Credit_Report__r.LASERCA__TransUnion_Score_Factor__c);
            lead.Manual_Credit_Decline__c = true;
        }
        update lead;
    }

    // Parses out the fifth TransUnion Factor since the current version of LASERCA only has four factors
    @AuraEnabled
    public static String getFifthCode(String tuScoreFactor) {
        return(getFifthFactor(tuScoreFactor, CODE));
    }

    @AuraEnabled
    public static String getFifthDetail(String tuScoreFactor) {
        return(getFifthFactor(tuScoreFactor, DETAIL));
    }

    private static String getFifthFactor(String tuScoreFactor) {
        if (getFifthCode(tuScoreFactor) != null) {
            return getFifthCode(tuScoreFactor) + ' - ' + getFifthDetail(tuScoreFactor);
        } else {
            return null;
        }
    }

    private static String getFifthFactor(String tuScoreFactor, Integer codeOrDetail) {
        if (tuScoreFactor != null) {
            List<String> factors = tuScoreFactor.split('\\n');
            if (factors.size() == 5) {
                List<String> factorParts = factors[4].split(' - ');
                if (factorParts.size() == 2) {
                    return factorParts[codeOrDetail];
                } else {
                    return factors[4];
                }
            }
        }
        return null;
    }

    @AuraEnabled
    public static LASERCA__Personal_Credit_Report__c getPCRDebt(Id pcrId) {
        List<LASERCA__Personal_Credit_Report__c> pcrList = [
            SELECT Id, LASERCA__Sum_of_monthly_Personal_Debt__c, Adjusted_Monthly_Personal_Debt__c,
                DTI_Before__c, DTI_After__c, Adjusted_DTI_Notes__c, Adjusted_DTI__c, Adjusted_Income__c,
                LASERCA__TransUnion_Alert_Message__c, (
                SELECT Id, Name, LASERCA__Account_Balance__c, LASERCA__Monthly_Payment__c,
                    LASERCA__Account_Ownership_Type__c, LASERCA__Credit_Loan_Type__c, Exclude_From_Rollup__c
                FROM LASERCA__Trade_Accounts__r
                WHERE LASERCA__Account_Balance__c > 0 OR LASERCA__Monthly_Payment__c > 0
            )
            FROM LASERCA__Personal_Credit_Report__c
            WHERE Id = :pcrId
        ];
        if (!pcrList.isEmpty()) {
            return pcrList[0];
        } else {
            throw new AuraHandledException('LoanUnderwriting.getPCRDebt, Personal Credit Report not found with ID: ' + pcrId);
        }
    }

    @AuraEnabled
    public static void renderPDFAndAttach(Id leadId) {
        PageReference luSnapshot = Page.LoanUnderwriting;
        luSnapshot.getParameters().put('leadId', leadId);
        luSnapshot.getParameters().put('renderAs', 'pdf');
        Attachment attach = new Attachment();
        Blob body;
        if (Test.isRunningTest()) {
            body = Blob.valueOf('UNIT TEST');
        } else {
            body = luSnapshot.getContentAsPDF();
        }
        Lead lead = [SELECT Id, ConvertedContactId FROM Lead WHERE Id = :leadId];
        attach.Body = body;
        attach.Name = 'Underwriting Snapshot as of ' +
            Date.today().year() + '-' + Date.today().month() + '-' + Date.today().day() + '.pdf';
        attach.ContentType = 'application/pdf';
        attach.IsPrivate = false;
        attach.ParentId = (lead.ConvertedContactId!=null?lead.ConvertedContactId:leadId);
        insert attach;
    }

    // Set Lead Status to Qualified and Under BlueWaveReview task to Complete
    // leads just needs ids
    @AuraEnabled
    public static void approveLead(Id leadId) {
        Lead lead = new Lead(Id = leadId);
        approveLeads(new List<Lead>{lead});
    }
    public static void approveLeads(List<Lead> leads) {
        List<String> leadIds = new List<String>();
        for (Lead lead : leads) {
            leadIds.add(lead.Id);
            lead.Status = 'Qualified';
        }
        update leads;
        LoanHandler.updatePartnerTaskUnderBlueWaveReview(leads, LoanHandler.getPartnerTasks(leadIds));
    }

    public class LeadWithPCRAttachments {
        @AuraEnabled 
        public Lead lead {get;set;}
        @AuraEnabled 
        public Attachment mainPCRAttachment {get;set;}
        @AuraEnabled 
        public Attachment coAppPCRAttachment {get;set;}
        @AuraEnabled
        public List<Attachment> contactAttachments {get;set;}

        public LeadWithPCRAttachments() {
        }

        public LeadWithPCRAttachments(Lead l, Attachment mainAttachment, Attachment coAppAttachment, List<Attachment> attachments) {
            lead = l;
            mainPCRAttachment = mainAttachment;
            coAppPCRAttachment = coAppAttachment;
            contactAttachments = attachments;
        }
    }
}
