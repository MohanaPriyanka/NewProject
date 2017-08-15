/*************************************************************************************
 * Created By: Peter Yao
 * 
 * Description: Controller for the LoanUnderwriting lightning component to help Avidia
 *              review loans
 *
 Tested By: LoanUnderwritingControllerTest
 *************************************************************************************/

public without sharing class LoanUnderwriting {
    public static Map<String, Schema.SObjectType> globalDescribe = Schema.getGlobalDescribe();

    @AuraEnabled 
    public static LeadWithPCRAttachments getLead(Id leadId) {
        List<Lead> leads = [SELECT FirstName, LastName, Name, 
                            Product__r.Name, Product__r.Credit_Minimum__c, Product__r.Debt_To_Income_Maximum__c,
                            Annual_Income_Currency__c, Co_Applicant_Income__c, Monthly_Payment__c,
                            Manual_Credit_Decline__c, Co_App_Manual_Credit_Decline__c,
                            Personal_Credit_Report__c, Personal_Credit_Report_Co_Applicant__c,
                            lived_residence_six_months__c,
                            Employed_for_more_than_six_months__c, Employed_for_more_than_one_year__c,
                            Requested_Loan_Amount__c, System_Cost__c,
                            Co_Applicant_First_Name__c, Co_Applicant_Last_Name__c,
                            Personal_Credit_Report__r.Id,
                            Personal_Credit_Report__r.Name,
                            Personal_Credit_Report__r.DTI_Before__c,
                            Personal_Credit_Report__r.DTI_After__c,
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
                            Personal_Credit_Report_Co_Applicant__r.Adjusted_Monthly_Personal_Debt__c,
                            Personal_Credit_Report_Co_Applicant__r.Annual_Income_from_Lead__c,
                            Personal_Credit_Report_Co_Applicant__r.Adjusted_Income__c,
                            Personal_Credit_Report_Co_Applicant__r.Adjusted_DTI__c,
                            Personal_Credit_Report_Co_Applicant__r.Adjustments_Comments__c,
                            Personal_Credit_Report_Co_Applicant__r.LASERCA__Sum_of_monthly_Personal_Debt__c,
                            Personal_Credit_Report_Co_Applicant__r.LASERCA__Total_High_Credit__c,
                            Personal_Credit_Report_Co_Applicant__r.LASERCA__Installment_Balance__c,
                            Personal_Credit_Report_Co_Applicant__r.LASERCA__Revolving_Balance__c,
                            Personal_Credit_Report_Co_Applicant__r.LASERCA__Real_Estate_Payment__c,
                            (SELECT Id, Name from Attachments)
                            FROM Lead
                            WHERE ID = :leadId];

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
            return(new LeadWithPCRAttachments(lead, mainPCRAttachment, coAppPCRAttachment));
        } else {
            return new LeadWithPCRAttachments();
        }
    }

    private static Attachment getAttachment(Id pcrId) {
        List<Attachment> attachments = [SELECT Id 
                                        FROM Attachment 
                                        WHERE ParentID = :pcrId
                                        AND ContentType = 'application/pdf' LIMIT 1];
        if (!attachments.isEmpty()) {
            return(attachments[0]);
        } else {
            return null;
        }
    }
     
    @AuraEnabled 
    public static void updateManualCreditDecline(Lead lead, Boolean coApplicant) {
        if (coApplicant) {
            lead.Co_App_Manual_Credit_Decline__c = true;
        } else {
            lead.Manual_Credit_Decline__c = true;
        }
        update lead;
    }

    @AuraEnabled 
    public static LASERCA__Personal_Credit_Report__c getPCRDebt(Id pcrId) {
        List<LASERCA__Personal_Credit_Report__c> pcrList =
            [SELECT Id, LASERCA__Sum_of_monthly_Personal_Debt__c, Adjusted_Monthly_Personal_Debt__c,
             DTI_Before__c, DTI_After__c,
             (SELECT Id, Name, LASERCA__Account_Balance__c, LASERCA__Monthly_Payment__c,
              LASERCA__Account_Ownership_Type__c, LASERCA__Credit_Loan_Type__c, Exclude_From_Rollup__c
              FROM LASERCA__Trade_Accounts__r
              WHERE LASERCA__Account_Balance__c > 0 OR LASERCA__Monthly_Payment__c > 0)
             FROM LASERCA__Personal_Credit_Report__c
             WHERE Id = :pcrId];
        if (!pcrList.isEmpty()) {
            return pcrList[0];
        } else {
            throw new AuraHandledException('LoanUnderwriting.getPCRDebt, Personal Credit Report not found with ID: ' + pcrId);
        }
    }

    public class LeadWithPCRAttachments {
        @AuraEnabled 
        public Lead lead;
        @AuraEnabled 
        public Attachment mainPCRAttachment;
        @AuraEnabled 
        public Attachment coAppPCRAttachment;

        public LeadWithPCRAttachments() {
        }

        public LeadWithPCRAttachments(Lead l, Attachment mainAttachment, Attachment coAppAttachment) {
            lead = l;
            mainPCRAttachment = mainAttachment;
            coAppPCRAttachment = coAppAttachment;
        }
    }
}