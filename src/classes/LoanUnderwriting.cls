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
    public String renderAs {get;set;}
    public Id leadId;
    public LeadWithPCRAttachments lead {get;set;}
    public Decimal monthlyPayment {get;set;}
    public Boolean hasCoApp {get;set;}
    public Integer bestFICO {get;set;}
    public Decimal bestDTI {get;set;}
    public Decimal combinedIncome {get;set;}
    public String primaryFifthCode {get;set;}
    public String primaryFifthDetail {get;set;}
    public String coAppFifthCode {get;set;}
    public String coAppfifthDetail {get;set;}
    public LASERCA__Personal_Credit_Report__c primaryPCR {get;set;}
    public LASERCA__Personal_Credit_Report__c coAppPCR {get;set;}
    public Boolean employedYear {get;set;}
    public Boolean employedSixMonths {get;set;}
    public Boolean residedSixMonths {get;set;}

    public LoanUnderwriting() {
        this.leadId = ApexPages.currentPage().getParameters().get('leadId');
        this.renderAs = ApexPages.currentPage().getParameters().get('renderAs');
        this.lead = getLead(leadId);
        this.monthlyPayment = lead.lead.Monthly_Payment__c;
        if (lead.lead.Product__r.DTI_After_Rate_Gross_Up__c != null) {
            this.monthlyPayment =
                (lead.lead.Loan_Principal__c*(lead.lead.Product__r.Loan_Interest_Rate__c+lead.lead.Product__r.DTI_After_Rate_Gross_Up__c)/100/12) /
                    (1-Math.pow((Double) (1+(lead.lead.Product__r.Loan_Interest_Rate__c+lead.lead.Product__r.DTI_After_Rate_Gross_Up__c)/100/12),(Double) (-1*lead.lead.Product__r.Loan_Term__c)));
        }
        if (lead.lead.Personal_Credit_Report_Co_Applicant__r != null &&
            lead.lead.Personal_Credit_Report__r != null) {
            hasCoApp = true;
            bestFICO = Math.max(Integer.valueOf((Util.nullToZero(lead.lead.Personal_Credit_Report_Co_Applicant__r.LASERCA__Credit_Score_TransUnion__c))),
                                Integer.valueOf((Util.nullToZero(lead.lead.Personal_Credit_Report__r.LASERCA__Credit_Score_TransUnion__c))));
            primaryFifthCode = getFifthCode(lead.lead.Personal_Credit_Report__r.LASERCA__TransUnion_Score_Factor__c);
            primaryFifthDetail = getFifthDetail(lead.lead.Personal_Credit_Report__r.LASERCA__TransUnion_Score_Factor__c);
            coAppFifthCode = getFifthCode(lead.lead.Personal_Credit_Report_Co_Applicant__r.LASERCA__TransUnion_Score_Factor__c);
            coAppFifthDetail = getFifthDetail(lead.lead.Personal_Credit_Report_Co_Applicant__r.LASERCA__TransUnion_Score_Factor__c);
            primaryPCR = getPCRDebt(lead.lead.Personal_Credit_Report__r.Id);
            coAppPCR = getPCRDebt(lead.lead.Personal_Credit_Report_Co_Applicant__r.Id);
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

        Decimal mainIncome=0, mainDebt=0, coAppIncome=0, coAppDebt=0;
        Decimal loanPayment = this.monthlyPayment;
        if (primaryPCR.Adjusted_DTI__c != null) {
            bestDTI = primaryPCR.Adjusted_DTI__c;
        } else {
            if (hasCoApp) {
                if (primaryPCR.Adjusted_Income__c != null) {
                    mainIncome = primaryPCR.Adjusted_Income__c/12;
                } else {
                    mainIncome = lead.lead.Annual_Income_Currency__c/12;
                }
                mainDebt = primaryPCR.Adjusted_Monthly_Personal_Debt__c;

                if (coAppPCR.Adjusted_Income__c != null) {
                    coAppIncome = coAppPCR.Adjusted_Income__c/12;
                } else {
                    coAppIncome = lead.lead.Co_Applicant_Income__c/12;
                }
                coAppDebt = coAppPCR.Adjusted_Monthly_Personal_Debt__c;

                if (mainIncome + coAppIncome > 0) {
                    bestDTI = 100 * (mainDebt + coAppDebt + loanPayment) / (mainIncome + coAppIncome);
                }
            } else {
                if (primaryPCR.Adjusted_Income__c != null) {
                    mainIncome = primaryPCR.Adjusted_Income__c/12;
                } else {
                    mainIncome = lead.lead.Annual_Income_Currency__c/12;
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
                Personal_Credit_Report_Co_Applicant__r.LASERCA__Sum_of_monthly_Personal_Debt__c,
                Personal_Credit_Report_Co_Applicant__r.LASERCA__Total_High_Credit__c,
                Personal_Credit_Report_Co_Applicant__r.LASERCA__Installment_Balance__c,
                Personal_Credit_Report_Co_Applicant__r.LASERCA__Revolving_Balance__c,
                Personal_Credit_Report_Co_Applicant__r.LASERCA__Real_Estate_Payment__c,
            (SELECT Id, Name FROM Attachments)
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
     
    // Can be called from custom buttons on the Lead page, or from the LoanUnderwriting screen
    @AuraEnabled 
    webservice static void updateManualCreditDecline(Lead lead, Boolean coApplicant) {
        // Copy Transunion factor 5
        lead = [SELECT Id, Personal_Credit_Report__r.LASERCA__TransUnion_Score_Factor__c, 
                Personal_Credit_Report_Co_Applicant__r.LASERCA__TransUnion_Score_Factor__c,
                Credit_Report_Detail_5__c, Co_App_Credit_Report_Detail_5__c
                FROM Lead
                WHERE Id =: lead.Id];
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
        List<LASERCA__Personal_Credit_Report__c> pcrList =
            [SELECT Id, LASERCA__Sum_of_monthly_Personal_Debt__c, Adjusted_Monthly_Personal_Debt__c,
             DTI_Before__c, DTI_After__c, Adjusted_DTI_Notes__c, Adjusted_DTI__c, Adjusted_Income__c,
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
        attach.Body = body;
        attach.Name = 'Underwriting Snapshot as of ' + 
            Date.today().year()+'-'+Date.today().month()+'-'+Date.today().day() + '.pdf';
        attach.ContentType = 'application/pdf';
        attach.isPrivate = false;
        attach.ParentId = leadId;
        insert attach;
    }


    public class LeadWithPCRAttachments {
        @AuraEnabled 
            public Lead lead {get;set;}
        @AuraEnabled 
        public Attachment mainPCRAttachment {get;set;}
        @AuraEnabled 
        public Attachment coAppPCRAttachment {get;set;}

        public LeadWithPCRAttachments() {
        }

        public LeadWithPCRAttachments(Lead l, Attachment mainAttachment, Attachment coAppAttachment) {
            lead = l;
            mainPCRAttachment = mainAttachment;
            coAppPCRAttachment = coAppAttachment;
        }
    }
}
