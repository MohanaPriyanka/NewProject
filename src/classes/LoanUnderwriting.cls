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
    public static Lead getLead(Id leadId) {
        List<Lead> leads = [SELECT FirstName, LastName, Name, 
                            Product__r.Name, Product__r.Credit_Minimum__c, Product__r.Debt_To_Income_Maximum__c,
                            Annual_Income_Currency__c, Co_Applicant_Income__c,
                            Manual_Credit_Decline__c, Co_App_Manual_Credit_Decline__c,
                            Personal_Credit_Report__c, Personal_Credit_Report_Co_Applicant__c,
                            lived_residence_six_months__c,
                            Employed_for_more_than_six_months__c, Employed_for_more_than_one_year__c,
                            Personal_Credit_Report__r.Id,
                            Personal_Credit_Report__r.Name,
                            Personal_Credit_Report__r.DTI_Before__c,
                            Personal_Credit_Report__r.DTI_After__c,
                            Personal_Credit_Report__r.DTI_After_Notes__c,
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
                            Personal_Credit_Report__r.Adjusted_Income__c,
                            Personal_Credit_Report__r.LASERCA__Sum_of_monthly_Personal_Debt__c,
                            Personal_Credit_Report__r.LASERCA__Total_High_Credit__c,
                            Personal_Credit_Report__r.LASERCA__Installment_Balance__c,
                            Personal_Credit_Report__r.LASERCA__Revolving_Balance__c,
                            Personal_Credit_Report__r.LASERCA__Real_Estate_Payment__c,
                            Personal_Credit_Report_Co_Applicant__r.Id,
                            Personal_Credit_Report_Co_Applicant__r.Name,
                            Personal_Credit_Report_Co_Applicant__r.DTI_Before__c,
                            Personal_Credit_Report_Co_Applicant__r.DTI_After__c,
                            Personal_Credit_Report_Co_Applicant__r.DTI_After_Notes__c,
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
                            Personal_Credit_Report_Co_Applicant__r.Adjusted_Income__c,
                            Personal_Credit_Report_Co_Applicant__r.LASERCA__Sum_of_monthly_Personal_Debt__c,
                            Personal_Credit_Report_Co_Applicant__r.LASERCA__Total_High_Credit__c,
                            Personal_Credit_Report_Co_Applicant__r.LASERCA__Installment_Balance__c,
                            Personal_Credit_Report_Co_Applicant__r.LASERCA__Revolving_Balance__c,
                            Personal_Credit_Report_Co_Applicant__r.LASERCA__Real_Estate_Payment__c,
                            (SELECT Id, Name from Attachments)
                            FROM Lead
                            WHERE ID = :leadId];

        if (!leads.isEmpty()) {
            Lead lead = leads[0];
            lead.Personal_Credit_Report__r.DTI_Before__c = lead.Personal_Credit_Report__r.DTI_Before__c.setScale(2);
            lead.Personal_Credit_Report__r.DTI_After__c = lead.Personal_Credit_Report__r.DTI_After__c.setScale(2);
            if (lead.Personal_Credit_Report_Co_Applicant__c != null) {
                lead.Personal_Credit_Report_Co_Applicant__r.DTI_Before__c =
                    lead.Personal_Credit_Report_Co_Applicant__r.DTI_Before__c.setScale(2);
                lead.Personal_Credit_Report_Co_Applicant__r.DTI_After__c =
                    lead.Personal_Credit_Report_Co_Applicant__r.DTI_After__c.setScale(2);
            }
            return leads[0];
        } else {
            return new Lead();
        }
    }   

    @AuraEnabled 
    public static List<String> getAvidiaReviewStatus() {
        return getPicklistFields('LASERCA__Personal_Credit_Report__c', 'Avidia_Review_Status__c');
    }

    @AuraEnabled 
    public static List<String> getSLApprovalStatus() {
        return getPicklistFields('LASERCA__Personal_Credit_Report__c', 'Solar_Loan_Approval_Status__c');
    }

    @AuraEnabled 
    public static List<String> getCreditNoticeOptions() {
        return getPicklistFields('LASERCA__Personal_Credit_Report__c', 'Adverse_Credit_Notice_1__c');
    }

    @AuraEnabled 
    public static void updatePCR(LASERCA__Personal_Credit_Report__c pcr) {
        update pcr;
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

    public static List<String> getPicklistFields(String objectName, String fieldName){
        Schema.SObjectType ctype = globalDescribe.get(objectName); 
        Map<String, Schema.SobjectField> fmap = ctype.getDescribe().fields.getMap();

        List<String> options = new List<String>();
        Schema.DescribeFieldResult fieldResult = fmap.get(fieldName).getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry f: ple) {
            options.add(f.getLabel());
        }

        return options;
    }


}
