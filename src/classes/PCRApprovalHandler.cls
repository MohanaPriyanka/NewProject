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
    
    private static EmailTemplate doerEmailTemplate;
    private static EmailTemplate standardEmailTemplate;
    private static OrgWideEmailAddress infoEmailAddress;

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
        if (infoEmailAddress == null) {
            infoEmailAddress = [SELECT id, Address 
                                FROM OrgWideEmailAddress
                                WHERE Address like '%info%'
                                LIMIT 1];
        }
    }

    public void OnBeforeUpdate(LASERCA__Personal_Credit_Report__c[] newPCR) {
        List<String> leadlist = new List<String>();
        Map<Id, Lead> leadMap = new Map<Id, Lead>();
        List<Lead> leadstoUpdate = new List<Lead>();
        List<Product2> products;

        for (LASERCA__Personal_Credit_Report__c pcrForLead: newPCR) {
            if (pcrForLead.LASERCA__Lead__c == NULL && pcrForLead.Lead_from_Contact__c != NULL) {
                pcrForLead.LASERCA__Lead__c = pcrForLead.Lead_from_Contact__c;
            }
            if (pcrForLead.LASERCA__Lead__c != NULL) {
                leadlist.add(pcrForLead.LASERCA__Lead__c);
            }
        }

        List<Lead> relatedLeads  = [SELECT Id, DOER_Solar_Loan__c, Pre_Approval_Form__c, Status, 
                                    Personal_Credit_Report__r.LASERCA__Sum_of_monthly_Personal_Debt__c,
                                    Product_Line__c, Product_Program__c, LASERCA__Home_State__c, Loan_Principal__c,
                                    Income_Support__c,
                                    Personal_Credit_Report_Co_Applicant__r.LASERCA__Credit_Score_TransUnion__c,
                                    Personal_Credit_Report__r.LASERCA__Credit_Score_TransUnion__c
                                    FROM Lead 
                                    WHERE Id  IN : leadlist];
        for (Lead lead : relatedLeads) {
            leadMap.put(lead.Id, lead);
        }

        ProductRepo productRepo = new ProductRepo(relatedLeads);

        for (LASERCA__Personal_Credit_Report__c pcr : newPCR) {
            if (!pcr.Do_not_trigger_PCRApprovalHandler__c && 
                pcr.LASERCA__Lead__c != NULL) {
                Lead ld = leadMap.get(pcr.LASERCA__Lead__c);
                String bwApproval, doerApproval;
                String conglomerate = 
                    pcr.LASERCA__Code__c + ' ' + pcr.LASERCA__Code_2__c + ' ' +
                    pcr.LASERCA__Code_3__c + ' ' + pcr.LASERCA__Code_4__c;
                Integer creditScore = 
                    pcr.LASERCA__Credit_Score_TransUnion__c==null?0:
                    Integer.valueOf(pcr.LASERCA__Credit_Score_TransUnion__c);

                Decimal monthlyIncome = (pcr.Adjusted_Income__c==null?pcr.Annual_Income_From_Lead__c:pcr.Adjusted_Income__c)/12;
                if (pcr.LASERCA__Contact__c != NULL) {
                    monthlyIncome = (pcr.Adjusted_Income__c==null?pcr.Co_Applicant_Income__c:pcr.Adjusted_Income__c)/12;
                    creditScore = Math.max(creditScore,
                                           Integer.valueOf(LoanServicer.nullToZero(ld.Personal_Credit_Report__r.LASERCA__Credit_Score_TransUnion__c)));
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
                    productRepo.getCreditSummary(ld, 
                                                 creditScore, monthlyIncome, 
                                                 pcr.Adjusted_Monthly_Personal_Debt__c,
                                                 pcr.DOER_Application__c);

                pcr.DTI_Before__c = 100 * pcr.Adjusted_Monthly_Personal_Debt__c / monthlyIncome;
                pcr.DTI_After__c = creditSummary.highestDTI;
                pcr.DTI_After_Notes__c = creditSummary.toString();

                if (creditSummary.bestStatus == APPROVED) {
                    if (conglomerate.contains('018') || 
                        conglomerate.contains('020') ||
                        conglomerate.contains('021') ||
                        conglomerate.contains('022') ||
                        conglomerate.contains('031') ||
                        conglomerate.contains('034') ||
                        conglomerate.contains('040') ||
                        conglomerate.contains('039')) {
                        creditSummary.bestStatus = PENDINGREVIEW;
                    }
                }

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

                if (ld.Status == READYFORCREDITCHECK || 
                    ld.Status == PENDINGCREDITREVIEW || 
                    ld.Status == UNQUALIFIED ||
                    ld.Status == PREQUALIFIED ||
                    pcr.Avidia_Review_Status__c == 'Reviewed - Declined') {
                    setLeadStatus(pcr.Solar_Loan_Approval_Status__c, ld);
                    leadsToUpdate.add(ld);
                }

                // SEND PREAPPROVAL EMAIL 
                if (!pcr.Credit_PreApproval_Email_Sent__c &&
                    pcr.PreApproval_Form__c &&
                    pcr.LASERCA__Contact__c == NULL &&
                    pcr.First_Name_from_Lead__c != NULL &&
                    pcr.Last_Name_from_Lead__c != NULL &&
                    pcr.Email_from_Lead__c != NULL &&
                    pcr.Solar_Loan_Approval_Status__c == APPROVED) {
                        
                    if (pcr.DOER_Application__c) {
                        String htmlbody = doerEmailTemplate.HtmlValue;
                        htmlBody = htmlBody.replace('{!Lead.Continue_Loan_Application_Link__c}', 
                                                    pcr.Continue_Loan_Application_Link__c);
                        htmlBody = htmlBody.replace('{!Lead.Name}', pcr.First_Name_from_Lead__c);
                        htmlBody = htmlBody.replace('{!Lead.FirstName}', pcr.First_Name_from_Lead__c);
                        htmlBody = htmlBody.replace('{!Lead.LastName}', pcr.Last_Name_from_Lead__c);
                        htmlBody = htmlBody.replace('{!Lead.Email}', pcr.Email_from_Lead__c);
                        htmlBody = htmlBody.replace('{!Lead.Lead_ID__c}',pcr.PCR_Lead_ID__c );

                        sendEmail(pcr.First_Name_from_Lead__c, 'BlueWave Mass Solar Loan', 
                                  htmlBody, pcr.Partner_Email__c, pcr.PCR_Lead_ID__c);
                        pcr.Credit_PreApproval_Email_Sent__c = TRUE;
                    } else {
                        String htmlbody = standardEmailTemplate.HtmlValue;
                        htmlBody = htmlBody.replace('{!Lead.Name}', pcr.First_Name_from_Lead__c);
                        htmlBody = htmlBody.replace('{!Lead.Email}', pcr.Email_from_Lead__c);
                        htmlBody = htmlBody.replace('{!Lead.Lead_ID__c}',pcr.PCR_Lead_ID__c );

                        sendEmail(pcr.First_Name_from_Lead__c, 'BlueWave Solar Loan', 
                                  htmlBody, pcr.Partner_Email__c, pcr.PCR_Lead_ID__c);
                        pcr.Credit_PreApproval_Email_Sent__c = TRUE;
                    }
                }
            }
        }
        if (!leadsToUpdate.isEmpty()) {
            update leadsToUpdate;
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

    private void sendEmail(String firstname, String loanType, String body, String partnerEmail, Id targetObjectId) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setHtmlBody(body);
        mail.setOrgWideEmailAddressId(infoEmailAddress.id); 

        if (partnerEmail != NULL) {
            String[] ccAddresses = new String[] {partnerEmail};
            mail.setccAddresses(ccAddresses);
        }
                                                          
        String subject = 'Congrats! ' +  firstname + ', you have been prequalified for a ' + loanType; 
        mail.setSubject(subject);
        mail.setTargetObjectId(targetObjectId);
        MessagingService.sendEmail(new Messaging.SingleEmailMessage[] {mail});
    }

    // 
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
        public PCRApprovalHandler.ProductRepo repo;
        public List<PCRApprovalHandler.CreditStatusResult> resultList;

        public CreditResultSummary(Lead lead, Integer creditScore, 
                                   Decimal monthlyIncome, Decimal monthlyDebt, Boolean doer) {
            this.incomeSupport = lead.Income_Support__c;
            this.loanPrincipal = lead.Loan_Principal__c;
            this.monthlyIncome = monthlyIncome.setScale(2);
            this.monthlyDebt = monthlyDebt.setScale(2);
            this.creditScore = creditScore;
            this.doer = doer;
            this.highestDTI = 0;
            this.bestStatus = PCRApprovalHandler.DECLINED;
            this.resultList = new List<PCRApprovalHandler.CreditStatusResult>();
        }

        public void checkAndaddResult(PCRApprovalHandler.CreditStatusResult result,
                                      Integer creditMinimum, Decimal dtiMaximum) {
            String latestStatus = checkFICOandDTI(creditScore, result.dtiAfter, doer,
                                                  creditMinimum, dtiMaximum);
            resultList.add(result);
            if (betterThan(latestStatus, bestStatus)) {
                bestStatus = latestStatus;
            }
            if (result.dtiAfter > highestDTI) {
                highestDTI = result.dtiAfter;
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

        private String checkFICOandDTI(Integer creditScore, Decimal DTIafter, boolean doer,
                                       Integer creditMinimum, Decimal dtiMaximum) {
            if (doer) {
                if (creditScore >= 700 && DTIafter <= dtiMaximum) {
                    return APPROVED;
                } else if (creditScore >= 690 && DTIafter <= 45) {
                    return APPROVED;
                } else if (creditScore >= creditMinimum && DTIafter <= 40) {
                    return APPROVED;
                } else {
                    return DECLINED;
                }
            } else {
                if (creditScore >= creditMinimum && DTIafter <= dtiMaximum) {
                    return APPROVED;
                } else if (creditScore >= 700 && DTIafter > dtiMaximum) {
                    return PENDINGREVIEW;
                } else {
                    return DECLINED;
                }
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
        List<lead> leadList = [SELECT Id, DOER_Solar_Loan__c, Pre_Approval_Form__c, Status, Co_Applicant_Income__c,
                               Personal_Credit_Report__r.LASERCA__Sum_of_monthly_Personal_Debt__c, Personal_Credit_Report__r.Adjusted_Income__c,
                               LASER_Credit_Score__c, Annual_Income_Currency__c, Income_Support__c, Personal_Credit_Report__r.Adjusted_DTI__c,
                               Product_Line__c, Product_Program__c, LASERCA__Home_State__c, Loan_Principal__c,
                               Personal_Credit_Report__r.Adjusted_Monthly_Personal_Debt__c,
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
            income = creditMetric.Lead.Co_Applicant_Income__c;                                               
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
            products = [SELECT Id, Name, Product_Type__c, Program__c, State__c, Debt_To_Income_Maximum__c,
                        Credit_Minimum__c, Credit_Maximum__c, Loan_Interest_Rate__c, Loan_Term__c
                        FROM Product2
                        WHERE isActive = true
                        AND Product_Type__c IN :productList
                        AND Program__c IN :programList
                        AND State__c IN :stateList];
        }

        public PCRApprovalHandler.CreditResultSummary getCreditSummary(Lead lead, Integer creditScore, 
                                                                       Decimal monthlyIncome, Decimal monthlyDebt,
                                                                       Boolean doer) {
            PCRApprovalHandler.CreditResultSummary creditResultSummary = 
                new PCRApprovalHandler.CreditResultSummary(lead, creditScore, monthlyIncome, monthlyDebt, doer);

            for (Product2 product : getApplicableProducts(lead, creditScore)) {
                PCRApprovalHandler.CreditStatusResult result = calcDTIAfter(product, lead, monthlyIncome, monthlyDebt);
                creditResultSummary.checkAndAddResult(result,
                                                      Integer.valueOf(product.Credit_Minimum__c),
                                                      product.Debt_To_Income_Maximum__c);
            }
            return creditResultSummary;
        }


        public List<Product2> getApplicableProducts(Lead lead, Integer creditScore) {
            List<Product2> applicableProducts = new List<Product2>();
            for (Product2 product : products) {
                if (product.Product_Type__c == lead.Product_Line__c &&
                    product.Program__c == lead.Product_Program__c &&
                    product.State__c == lead.LASERCA__Home_State__c) {
                    if (Integer.valueOf(product.Credit_Minimum__c) <= creditScore &&
                        Integer.valueOf(product.Credit_Maximum__c) >= creditScore) {
                        applicableProducts.add(product);
                    }
                }
            }
            return applicableProducts;
        }

        public PCRApprovalHandler.CreditStatusResult calcDTIAfter(Product2 product, Lead leadRecord, 
                                                                   Decimal monthlyIncome, Decimal monthlyDebt) {
            Double paymentDenominatorVar1, paymentDenominatorVar2, paymentDenominatorVar3, paymentDenominator;
            Decimal paymentNumerator, dtiNumerator, dtiDenominator, dtiAfter, monthlyPayment;
            Decimal interestRate = product.Loan_Interest_Rate__c / 100;
            if (product.Program__c == 'MSLP' && leadRecord.Income_Support__c == 'Category 1') {
                paymentNumerator = leadRecord.Loan_Principal__c * 0.7 * interestRate / 12;
            } else if (product.Program__c == 'MSLP' && leadRecord.Income_Support__c == 'Category 2') {
                paymentNumerator = leadRecord.Loan_Principal__c * 0.8 * interestRate / 12;
            } else {
                paymentNumerator = leadRecord.Loan_Principal__c * interestRate / 12;
            }
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