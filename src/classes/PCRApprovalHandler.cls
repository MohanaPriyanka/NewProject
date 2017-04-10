/*************************************************************************************
 * Description: Personal Credit Check Approval Status
 * Tested By: TestPCRapproval
 *************************************************************************************/

public with sharing class PCRApprovalHandler {
    public static final String UNABLETOPREQUALIFY = 'Unable to Pre-Qualify';
    public static final String PREQUALIFIED = 'Pre-Qualified';
    public static final String PENDINGREVIEW = 'Pending Review';
    public static final String DECLINED = 'Declined';
    public static final String APPROVED = 'Approved';
    public static final String READYFORCREDITCHECK = 'Ready for Credit Check';
    public static final String PENDINGCREDITREVIEW = 'Pending Credit Review';
    public static final String UNQUALIFIED = 'Unqualified';
    public static final String PENDINGINFORMATION = 'Pending Information';
    
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
                                    Income_Support__c
                                    FROM Lead 
                                    WHERE Id  IN : leadlist];
        for (Lead lead : relatedLeads) {
            leadMap.put(lead.Id, lead);
        }

        ProductRepo productRepo = new ProductRepo(relatedLeads);

        for (LASERCA__Personal_Credit_Report__c pcr : newPCR) {
            if (pcr.Annual_Income_From_Lead__c != NULL &&
                !pcr.Do_not_trigger_PCRApprovalHandler__c && 
                pcr.LASERCA__Lead__c != NULL &&
                pcr.LASERCA__Sum_of_monthly_Personal_Debt__c != NULL &&
                pcr.LASERCA__Sum_of_monthly_Personal_Debt__c != 0) {

                String bwApproval, doerApproval;
                String conglomerate = 
                    pcr.LASERCA__Code__c + ' ' + pcr.LASERCA__Code_2__c + ' ' +
                    pcr.LASERCA__Code_3__c + ' ' + pcr.LASERCA__Code_4__c;
                Decimal monthlyIncome = pcr.Annual_Income_From_Lead__c/12;
                if (pcr.Co_Applicant__c || pcr.LASERCA__Contact__c != NULL) {
                    monthlyIncome = pcr.Co_Applicant_Income__c/12;
                }
                Integer creditScore = 
                    pcr.LASERCA__Credit_Score_TransUnion__c==null?0:
                    Integer.valueof(pcr.LASERCA__Credit_Score_TransUnion__c);

                // If a lead doesn't have an associated product, we can't calculate the DTI after
                // the loan is selected, so we'll look through all applicable products for the lead
                // and see the best we can do.
                System.debug(LoggingLevel.ERROR, '--- ');
                bwApproval = productRepo.bestApprovalStatusForBW(leadMap.get(pcr.LASERCA__Lead__c), 
                                                                 creditScore, monthlyIncome, pcr.LASERCA__Sum_of_monthly_Personal_Debt__c);
                doerApproval = productRepo.bestApprovalStatusForDOER(leadMap.get(pcr.LASERCA__Lead__c), 
                                                                     creditScore, monthlyIncome, pcr.LASERCA__Sum_of_monthly_Personal_Debt__c);

                if (bwApproval == APPROVED || 
                    doerApproval == APPROVED) {
                    if (conglomerate.contains('018') || 
                        conglomerate.contains('020') ||
                        conglomerate.contains('021') ||
                        conglomerate.contains('022') ||
                        conglomerate.contains('031') ||
                        conglomerate.contains('034') ||
                        conglomerate.contains('040') ||
                        conglomerate.contains('039')) {
                        bwApproval = PENDINGREVIEW;
                        doerApproval = PENDINGREVIEW;
                    }
                }

                if (pcr.Avidia_Review_Status__c == 'Reviewed - PreApproved') {
                    // DOERPrequal_approval = PREQUALIFIED;
                    // BWPrequal_approval = PREQUALIFIED;
                } else if (pcr.Solar_Loan_Manual_Decline__c) {
                    bwApproval = DECLINED;
                    doerApproval = DECLINED;
                } else if (pcr.Solar_Loan_Manual_Approval__c) {
                    bwApproval = APPROVED;
                    doerApproval = APPROVED;
                }

                // ** SET THE APPROVAL STATUS ON THE PCR
                if (pcr.DOER_Application__c) {
                    pcr.Solar_Loan_Approval_Status__c = doerApproval;
                } else {
                    pcr.Solar_Loan_Approval_Status__c = bwApproval;
                }

                Lead ld = leadMap.get(pcr.LASERCA__Lead__c);
                if (ld.Status == READYFORCREDITCHECK) {
                    if (!ld.Pre_Approval_Form__c && !ld.DOER_Solar_Loan__c) { 
                        setLeadStatus(bwApproval, ld);
                    } else if (!ld.Pre_Approval_Form__c && ld.DOER_Solar_Loan__c) { 
                        setLeadStatus(doerApproval, ld);
                    } else if (!ld.DOER_Solar_Loan__c) { 
                        setLeadStatus(bwApproval, ld);
                    } else if (ld.DOER_Solar_Loan__c) { 
                        setLeadStatus(doerApproval, ld);
                    }
                    leadsToUpdate.add(ld);
                }

                // SEND PREAPPROVAL EMAIL 
                if (!pcr.Credit_PreApproval_Email_Sent__c &&
                    pcr.PreApproval_Form__c &&
                    pcr.LASERCA__Contact__c == NULL &&
                    pcr.First_Name_from_Lead__c != NULL &&
                    pcr.Last_Name_from_Lead__c != NULL &&
                    pcr.Email_from_Lead__c != NULL) {
                        
                    if (pcr.DOER_Application__c && doerApproval == APPROVED) {
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
                    } else if (bwApproval == APPROVED) {
                        String htmlbody = standardEmailTemplate.HtmlValue;
                        htmlBody = htmlBody.replace('{!Lead.Name}', pcr.First_Name_from_Lead__c);
                        htmlBody = htmlBody.replace('{!Lead.Email}', pcr.Email_from_Lead__c);
                        htmlBody = htmlBody.replace('{!Lead.Lead_ID__c}',pcr.PCR_Lead_ID__c );

                        sendEmail(pcr.First_Name_from_Lead__c, 'BlueWave Mass Solar Loan', 
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

    @TestVisible
    private class ProductRepo {
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
            products = [SELECT Id, Product_Type__c, Program__c, State__c, 
                        Credit_Minimum__c, Credit_Maximum__c, Loan_Interest_Rate__c, Loan_Term__c
                        FROM Product2
                        WHERE isActive = true
                        AND Product_Type__c IN :productList
                        AND Program__c IN :programList
                        AND State__c IN :stateList];
        }

        public String bestApprovalStatusForBW(Lead lead, Integer creditScore, Decimal monthlyIncome, Decimal monthlyDebt) {
            String bestStatus = PCRApprovalHandler.DECLINED;
            String latestStatus;
            for (Product2 product : getApplicableProducts(lead, creditScore)) {
                latestStatus = checkFICOandDTIForBW(creditScore, calcDTIAfter(product, lead, monthlyIncome, monthlyDebt));
                if (betterThan(latestStatus, bestStatus)) {
                    bestStatus = latestStatus;
                }
            }
            return bestStatus;
        }
        public String bestApprovalStatusForDOER(Lead lead, Integer creditScore, Decimal monthlyIncome, Decimal monthlyDebt) {
            String bestStatus = PCRApprovalHandler.DECLINED;
            String latestStatus;
            for (Product2 product : getApplicableProducts(lead, creditScore)) {
                latestStatus = checkFICOandDTIForDOER(creditScore, calcDTIAfter(product, lead, monthlyIncome, monthlyDebt));
                if (betterThan(latestStatus, bestStatus)) {
                    bestStatus = latestStatus;
                }
            }
            return bestStatus;
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

        private String checkFICOandDTIForBW(Integer creditScore, Decimal DTIafter) {
            if (creditScore >= 700 && DTIafter <= 50) {
                return(APPROVED);
            } else if (creditScore >= 690 && DTIafter <= 45) {
                return(DECLINED);
            } else if (creditScore >= 680 && DTIafter <= 40) {
                return(DECLINED);
            } else if (creditScore >= 700 && DTIafter > 50) {
                return(PENDINGREVIEW);
            } else if (creditScore <=680 && DTIafter >= 40) {
                return(DECLINED);
            } else {
                return(DECLINED);
            }
        }

        private String checkFICOandDTIForDOER(Integer creditScore, Decimal DTIafter) {
            if (creditScore >= 700 && DTIafter <= 50) {
                return(APPROVED);
            } else if (creditScore >= 690 && DTIafter <= 45) {
                return(APPROVED);
            } else if (creditScore >= 680 && DTIafter <= 40) {
                return(APPROVED);
            } else if (creditScore >= 700 && DTIafter > 50) {
                return(DECLINED);
            } else if (creditScore <=680 && DTIafter >= 40) {
                return(DECLINED);
            } else {
                return(DECLINED);
            }
        }

        @TestVisible
        private List<Product2> getApplicableProducts(Lead lead, Integer creditScore) {
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

        @TestVisible
        private Decimal calcDTIAfter(Product2 product, Lead leadRecord, Decimal monthlyIncome, Decimal monthlyDebt) {
            Double paymentDenominatorVar1, paymentDenominatorVar2, paymentDenominatorVar3, paymentDenominator;
            Decimal paymentNumerator, dtiNumerator, dtiDenominator, dtiAfter, monthlyPayment;
            if (product.Program__c == 'MSLP' && leadRecord.Income_Support__c == 'Category 1') {
                paymentNumerator = (leadRecord.Loan_Principal__c * 0.7 * product.Loan_Interest_Rate__c/12);
            } else if (product.Program__c == 'MSLP' && leadRecord.Income_Support__c == 'Category 2') {
                paymentNumerator = (leadRecord.Loan_Principal__c * 0.8 * product.Loan_Interest_Rate__c/12);
            } else {
                paymentNumerator = leadRecord.Loan_Principal__c * product.Loan_Interest_Rate__c/12;
            }        
            paymentDenominatorVar1 = ( 1 + product.Loan_Interest_Rate__c/12);
            paymentDenominatorVar2 = (-1 * product.Loan_Term__c);
            paymentDenominatorVar3 = Math.pow(paymentDenominatorVar1, paymentDenominatorVar2);
            paymentDenominator = 1 - paymentDenominatorVar3;
            monthlyPayment = paymentNumerator/paymentDenominator;
            dtiNumerator = monthlyDebt + monthlyPayment;
            dtiDenominator = monthlyIncome;
            dtiAfter = 100*(dtiNumerator/dtiDenominator);
            return dtiAfter;
        }

    }
}