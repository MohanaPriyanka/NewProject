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
    
    private EmailTemplate doerEmailTemplate;
    private EmailTemplate standardEmailTemplate;
    private OrgWideEmailAddress infoEmailAddress;

    public PCRApprovalHandler() {
        doerEmailTemplate = [SELECT id, HtmlValue, Body 
                             FROM EmailTemplate 
                             WHERE DeveloperName = 'RS_DOER_PreQualification_Approval'
                             LIMIT 1];
        standardEmailTemplate = [SELECT id, HtmlValue, Body 
                                 FROM EmailTemplate 
                                 WHERE DeveloperName = 'RS_PreQualification_Approval'
                                 LIMIT 1];
        infoEmailAddress = [SELECT id, Address 
                            FROM OrgWideEmailAddress
                            WHERE Address like '%info%'
                            LIMIT 1];

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

        List<Lead> relatedlead  = [SELECT Id, DOER_Solar_Loan__c, Pre_Approval_Form__c, Status
                                   FROM Lead 
                                   WHERE Id  IN : leadlist];
        for (Lead lead : relatedLead) {
            leadMap.put(lead.Id, lead);
        }

        for (LASERCA__Personal_Credit_Report__c pcr : newPCR) {
            if (pcr.Annual_Income_From_Lead__c != NULL &&
                !pcr.Do_not_trigger_PCRApprovalHandler__c && 
                pcr.LASERCA__Lead__c != NULL &&
                pcr.LASERCA__Sum_of_monthly_Personal_Debt__c != NULL &&
                pcr.LASERCA__Sum_of_monthly_Personal_Debt__c != 0) {

                Decimal DTIbefore, DTIafter;
                String BW_approval, DOER_approval, DOERPrequal_approval, BWPrequal_approval;
                String conglomerate = pcr.LASERCA__Code__c +' '+pcr.LASERCA__Code_2__c+' '+pcr.LASERCA__Code_3__c+' '+pcr.LASERCA__Code_4__c;
                Decimal annualincome = pcr.Annual_Income_From_Lead__c;  
                if (pcr.Co_Applicant__c || pcr.LASERCA__Contact__c != NULL) {
                    annualincome = pcr.Co_Applicant_Income__c;
                }
                Integer creditscore = 
                    pcr.LASERCA__Credit_Score_TransUnion__c==null?0:
                    Integer.valueof(pcr.LASERCA__Credit_Score_TransUnion__c);
                Boolean manualapproval = pcr.Solar_Loan_Manual_Approval__c;
                Boolean manualdecline = pcr.Solar_Loan_Manual_Decline__c;

                if (annualincome != NULL && annualincome != 0) {
                    DTIbefore = ((pcr.LASERCA__Sum_of_monthly_Personal_Debt__c/(annualincome/12))*100);
                    DTIafter = (((pcr.LASERCA__Sum_of_monthly_Personal_Debt__c + pcr.Monthly_Payment_IBLS_From_Lead__c)/(annualincome/12))*100); 
                }

                pcr.DTI_After__c = DTIafter;
                pcr.DTI_Before__c = DTIbefore;

                if (!manualapproval && !manualdecline && creditScore >= 700 && DTIafter <= 50) {
                    BW_approval = APPROVED;
                    DOER_approval = APPROVED;
                    DOERPrequal_approval = PREQUALIFIED; 
                    BWPrequal_approval = PREQUALIFIED;
                } else if (!manualapproval && !manualdecline && creditScore >= 690 && DTIafter <= 45) {
                    BW_approval = DECLINED;
                    DOER_approval = APPROVED;
                    DOERPrequal_approval = PREQUALIFIED;
                    BWPrequal_approval = UNABLETOPREQUALIFY;
                } else if (!manualapproval && !manualdecline && creditScore >= 680 && DTIafter <= 40) {
                    BW_approval = DECLINED;
                    DOER_approval = APPROVED;
                    DOERPrequal_approval = PREQUALIFIED;
                    BWPrequal_approval = UNABLETOPREQUALIFY;
                } else if (!manualapproval && !manualdecline && creditScore >= 700 && DTIafter > 50) {
                    BW_approval = PENDINGREVIEW;
                    DOER_approval = DECLINED;
                    // DOERPrequal_approval = UNABLETOPREQUALIFY;
                    // BWPrequal_approval = UNABLETOPREQUALIFY;
                } else if (!manualapproval && !manualdecline && creditScore<=680 && DTIafter >= 40) {
                    BW_approval = DECLINED;
                    DOER_approval = DECLINED;
                    // DOERPrequal_approval = UNABLETOPREQUALIFY;
                    // BWPrequal_approval = UNABLETOPREQUALIFY;
                } else {
                    BW_approval = DECLINED;
                    DOER_approval = DECLINED;
                    // DOERPrequal_approval = UNABLETOPREQUALIFY;
                    // BWPrequal_approval = UNABLETOPREQUALIFY;
                } 

                if (BW_approval == APPROVED || 
                    DOER_approval == APPROVED || 
                    DOERPrequal_approval == PREQUALIFIED || 
                    BWPrequal_approval == PREQUALIFIED) {
                    if (conglomerate.contains('018') || 
                        conglomerate.contains('020') ||
                        conglomerate.contains('021') ||
                        conglomerate.contains('022') ||
                        conglomerate.contains('031') ||
                        conglomerate.contains('034') ||
                        conglomerate.contains('040') ||
                        conglomerate.contains('039')) {
                        BW_approval = PENDINGREVIEW;
                        DOER_approval = PENDINGREVIEW;
                        DOERPrequal_approval = UNABLETOPREQUALIFY;
                        BWPrequal_approval = UNABLETOPREQUALIFY;
                    }
                }

                if (pcr.Avidia_Review_Status__c == 'Reviewed - PreApproved') {
                    DOERPrequal_approval = PREQUALIFIED;
                    BWPrequal_approval = PREQUALIFIED;
                } else if (manualdecline) {
                    BW_approval = DECLINED;
                    DOER_approval = DECLINED;
                    DOERPrequal_approval = UNABLETOPREQUALIFY;
                    BWPrequal_approval = UNABLETOPREQUALIFY;
                } else if (manualapproval) {
                    BW_approval = APPROVED;
                    DOER_approval = APPROVED;
                    DOERPrequal_approval = PREQUALIFIED;
                    BWPrequal_approval = PREQUALIFIED; 
                }

                // ** SET THE APPROVAL STATUS ON THE PCR
                if (pcr.DOER_Application__c) {
                    pcr.Solar_Loan_Approval_Status__c = DOER_approval;
                    // pcr.Solar_Loan_Pre_Qualification_Status__c = DOERprequal_approval;
                } else {
                    pcr.Solar_Loan_Approval_Status__c = BW_approval;
                    // pcr.Solar_Loan_Pre_Qualification_Status__c = BWprequal_approval;
                }

                Lead ld = leadMap.get(pcr.LASERCA__Lead__c);
                if (ld.Status == READYFORCREDITCHECK) {
                    if (!ld.Pre_Approval_Form__c && !ld.DOER_Solar_Loan__c) { 
                        setLeadStatus(BW_approval, ld);
                    } else if (!ld.Pre_Approval_Form__c && ld.DOER_Solar_Loan__c == TRUE) { 
                        setLeadStatus(DOER_approval, ld);
                    } else if (!ld.DOER_Solar_Loan__c) { 
                        setLeadStatus(BW_approval, ld);
                    } else if (ld.DOER_Solar_Loan__c) { 
                        setLeadStatus(DOER_approval, ld);
                    }
                    leadsToUpdate.add(ld);
                }

                // SEND PREAPPROVAL EMAIL 
                if (!pcr.Credit_PreApproval_Email_Sent__c &&
                    DOERPrequal_approval == PREQUALIFIED &&
                    pcr.PreApproval_Form__c &&
                    pcr.LASERCA__Contact__c == NULL &&
                    pcr.First_Name_from_Lead__c != NULL &&
                    // pcr.Last_Name_from_Lead__c != NULL &&
                    pcr.Email_from_Lead__c != NULL) {
                        
                    if (pcr.DOER_Application__c) {
                        String htmlbody = doerEmailTemplate.HtmlValue;
                        htmlBody = htmlBody.replace('{!Lead.Continue_Loan_Application_Link__c}', 
                                                    pcr.Continue_Loan_Application_Link__c);
                        htmlBody = htmlBody.replace('{!Lead.Name}', pcr.First_Name_from_Lead__c);
                        htmlBody = htmlBody.replace('{!Lead.FirstName}', pcr.First_Name_from_Lead__c); // used?
                        htmlBody = htmlBody.replace('{!Lead.LastName}', pcr.Last_Name_from_Lead__c); // used?
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
}