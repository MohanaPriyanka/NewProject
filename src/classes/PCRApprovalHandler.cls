// Personal Credit Check Approval Status
// https://cs4.salesforce.com/01pP0000000Bcvg
// Test class: https://cs4.salesforce.com/01pP0000000Bcvq


public with sharing class PCRApprovalHandler {
  private boolean m_isExecuting = false;
  private Integer BatchSize = 0;
    
  public PCRApprovalHandler (boolean isExecuting, Integer size){
      m_isExecuting = isExecuting;
      BatchSize = size;
  }

  public void OnBeforeUpdate(LASERCA__Personal_Credit_Report__c[] newPCR){
      PCRApproval(newPCR);
  }

  private void PCRApproval(List<LASERCA__Personal_Credit_Report__c> newPCR){ 
    integer j;
    integer m;
    string stringid;
    decimal debt = 0;
    list<string> listpcrIds = new list<string>();
    list<LASERCA__Personal_Credit_Report__c> toupdatelist = new list <LASERCA__Personal_Credit_Report__c>();
    list<string> leadlist = new list <string>();

      for(LASERCA__Personal_Credit_Report__c pcr: newPCR){
            if(pcr.LASERCA__Lead__c == NULL && pcr.Lead_from_Contact__c != NULL){
                  pcr.LASERCA__Lead__c = pcr.Lead_from_Contact__c;
            }
            if(pcr.LASERCA__Lead__c != NULL){
                  leadlist.add(pcr.LASERCA__Lead__c);
            }
      }

      List <Lead> relatedlead  = [ SELECT Id, DOER_Solar_Loan__c, Pre_Approval_Form__c, Status
                                    FROM Lead 
                                    WHERE Id  IN : leadlist ];

      for(j = 0; j < newPCR.size(); j++){
      
        if(newPCR.get(j).Annual_Income_From_Lead__c != NULL){

          if(newPCR.get(j).Do_not_trigger_PCRApprovalHandler__c == FALSE && newPCR.get(j).LASERCA__Lead__c != NULL){

              decimal monthlydebt = newPCR.get(j).LASERCA__Sum_of_monthly_Personal_Debt__c;
              system.debug(monthlydebt);

              if(monthlydebt == NULL || monthlydebt == 0) {
                 toupdatelist.add(newPCR.get(j));
                 system.debug(toupdatelist);
              }

              if(monthlydebt != NULL && monthlydebt != 0){
                decimal DTIbefore;
                decimal DTIafter;
                string BW_approval; 
                string DOER_approval;
                string DOERPrequal_approval;
                string BWPrequal_approval;
                string code1 = newPCR.get(j).LASERCA__Code__c;
                string code2 = newPCR.get(j).LASERCA__Code_2__c;
                string code3 = newPCR.get(j).LASERCA__Code_3__c;
                string code4 = newPCR.get(j).LASERCA__Code_4__c;
                string conglomerate = code1+' '+code2+' '+code3+' '+code4;
                decimal annualincome = newPCR.get(j).Annual_Income_From_Lead__c;  
                  if(newPCR.get(j).Co_Applicant__c == TRUE || newPCR.get(j).LASERCA__Contact__c != NULL) {
                            annualincome = newPCR.get(j).Co_Applicant_Income__c;
                  }
                decimal monthlypayment = newPCR.get(j).Monthly_Payment_IBLS_From_Lead__c;
                integer creditscore = integer.valueof(newPCR.get(j).LASERCA__Credit_Score_TransUnion__c);
                boolean manualapproval = newPCR.get(j).Solar_Loan_Manual_Approval__c;
                boolean manualdecline = newPCR.get(j).Solar_Loan_Manual_Decline__c;
                boolean problemcode = FALSE;
                boolean DOER = newPCR.get(j).DOER_Application__c;
                string firstname = newPCR.get(j).First_Name_from_Lead__c;  
                string lastname = newPCR.get(j).Last_Name_from_Lead__c;
                string email = newPCR.get(j).Email_from_Lead__c;
                string link = 'www.bluewavesolar.com';
                string referralcode = newPCR.get(j).Related_Partner__c;

                system.debug(code1);
                system.debug(code2);
                system.debug(code3);
                system.debug(code4);
                system.debug(monthlydebt);
                system.debug(annualincome);
                system.debug(conglomerate);
                system.debug(monthlypayment);
                system.debug(creditscore);
                system.debug(manualapproval);
                system.debug(manualdecline);
                system.debug(problemcode);
                system.debug(DOER);


                if (annualincome != NULL && annualincome != 0){
                        DTIbefore = ((monthlydebt/(annualincome/12))*100);
                        DTIafter = (((monthlydebt + monthlypayment)/(annualincome/12))*100); 
                }

                system.debug(DTIbefore);
                system.debug(DTIafter);
                    
                newPCR.get(j).DTI_After__c = DTIafter;
                newPCR.get(j).DTI_Before__c = DTIbefore;

                if (manualapproval==FALSE 
                    && manualdecline==FALSE  
                    && creditScore >=700 
                    && DTIafter <=50) {
                              BW_approval = 'Approved';
                              DOER_approval = 'Approved';
                              DOERPrequal_approval = 'Pre-Qualified'; 
                              BWPrequal_approval = 'Pre-Qualified';
                } 
                              
                else if (manualapproval ==FALSE 
                          && manualdecline ==FALSE    
                          && creditScore >=690 
                          && DTIafter <=45 ) {
                              BW_approval = 'Declined';
                              DOER_approval = 'Approved';
                              DOERPrequal_approval = 'Pre-Qualified';
                              BWPrequal_approval = 'Unable to Pre-Qualify';
                } 
                 
                else if (manualapproval==FALSE 
                          && manualdecline==FALSE     
                          && creditScore >=680 
                          && DTIafter <=40  )  {
                              BW_approval = 'Declined';
                              DOER_approval = 'Approved';
                              DOERPrequal_approval = 'Pre-Qualified';
                              BWPrequal_approval = 'Unable to Pre-Qualify';
                } 
                
                else if (manualapproval ==FALSE 
                          && manualdecline ==FALSE 
                          && CreditScore >=700 
                          && DTIafter >50 )    {
                              BW_approval = 'Pending Review';
                              DOER_approval = 'Declined';
                              DOERPrequal_approval = 'Unable to Pre-Qualify';
                              BWPrequal_approval = 'Unable to Pre-Qualify';
                } 
                                                      
                
                else if (manualapproval==FALSE 
                          && manualdecline==FALSE 
                          && creditScore<=680 
                          && DTIafter >=40)     {
                                BW_approval = 'Declined';
                                DOER_approval = 'Declined';
                                DOERPrequal_approval = 'Unable to Pre-Qualify';
                                BWPrequal_approval = 'Unable to Pre-Qualify';
                } 


                else {
                          BW_approval = 'Declined';
                          DOER_approval = 'Declined';
                          DOERPrequal_approval = 'Unable to Pre-Qualify';
                          BWPrequal_approval = 'Unable to Pre-Qualify';
                } 

                if( BW_approval == 'Approved' || DOER_approval == 'Approved' || DOERPrequal_approval == 'Pre-Qualified' || BWPrequal_approval == 'Pre-Qualified'){
                      if(conglomerate.contains('018')){ 
                        problemcode = TRUE; 
                      }
                      if(conglomerate.contains('020')){ 
                        problemcode = TRUE; 
                      }
                      if(conglomerate.contains('021')){ 
                        problemcode = TRUE; 
                      }
                      if(conglomerate.contains('022')){ 
                        problemcode = TRUE; 
                      }
                      if(conglomerate.contains('031')){ 
                        problemcode = TRUE; 
                      }
                      if(conglomerate.contains('034')){ 
                        problemcode = TRUE; 
                      }
                      if(conglomerate.contains('040')){ 
                        problemcode = TRUE; 
                      }
                      if(conglomerate.contains('039')){ 
                        problemcode = TRUE; 
                      }
                      system.debug(problemcode);


                     if(problemcode == TRUE) {
                         BW_approval = 'Pending Review';
                         DOER_approval = 'Pending Review';
                         DOERPrequal_approval = 'Unable to Pre-Qualify';
                         BWPrequal_approval = 'Unable to Pre-Qualify';
                     }
                }

                if(newPCR.get(j).Avidia_Review_Status__c == 'Reviewed - PreApproved'){
                        DOERPrequal_approval = 'Pre-Qualified';
                        BWPrequal_approval = 'Pre-Qualified';
                }                             

                else if (manualdecline==TRUE){
                        BW_approval = 'Declined';
                        DOER_approval = 'Declined';
                        DOERPrequal_approval = 'Unable to Pre-Qualify';
                        BWPrequal_approval = 'Unable to Pre-Qualify';
                }    
            
                else if (manualapproval==TRUE){
                        BW_approval = 'Approved';
                        DOER_approval = 'Approved';
                        DOERPrequal_approval = 'Pre-Qualified';
                        BWPrequal_approval = 'Pre-Qualified'; 
                }   

                system.debug(BW_approval);
                system.debug(DOER_approval);
                system.debug(DOERPrequal_approval);
                system.debug(BWPrequal_approval);
                
                // ** SET THE APPROVAL STATUS ON THE PCR
                if(DOER == TRUE) {
                      newPCR.get(j).Solar_Loan_Approval_Status__c = DOER_approval;
                      newPCR.get(j).Solar_Loan_Pre_Qualification_Status__c = DOERprequal_approval;
                } 

                else if(DOER != TRUE) {
                      newPCR.get(j).Solar_Loan_Approval_Status__c = BW_approval;
                      newPCR.get(j).Solar_Loan_Pre_Qualification_Status__c = BWprequal_approval;
                }

                for(Lead ld : relatedlead){
                      if(ld.Id == newPCR.get(j).LASERCA__Lead__c 
                        && ld.Pre_Approval_Form__c == FALSE  
                        && ld.DOER_Solar_Loan__c == FALSE
                        && ld.Status == 'Ready for Credit Check'){ 
                              if(BW_approval == 'Approved'){
                                    ld.Status = 'Pending Information';
                              }
                              else if(BW_approval == 'Pending Review'){
                                    ld.Status = 'Pending Credit Review';
                              }
                              else if(BW_approval == 'Declined'){
                                    ld.Status = 'Unqualified';
                              }
                      }

                      else if(ld.Id == newPCR.get(j).LASERCA__Lead__c 
                        && ld.Pre_Approval_Form__c == FALSE  
                        && ld.DOER_Solar_Loan__c == TRUE
                        && ld.Status == 'Ready for Credit Check'){ 
                              if(DOER_approval == 'Approved'){
                                    ld.Status = 'Pending Information';
                              }
                              else if(DOER_approval == 'Pending Review'){
                                    ld.Status = 'Pending Credit Review';
                              }
                              else if(DOER_approval == 'Declined'){
                                    ld.Status = 'Unqualified';
                              }
                      }

                      else if(ld.Id == newPCR.get(j).LASERCA__Lead__c 
                        && ld.DOER_Solar_Loan__c == FALSE  
                        && ld.Status == 'Ready for Credit Check'){ 
                              if(BW_approval == 'Approved'){
                                    ld.Status = 'Pre-Qualified';
                              }
                              else if(BW_approval == 'Pending Review'){
                                    ld.Status = 'Pending Credit Review';
                              }
                              else if(BW_approval == 'Declined'){
                                    ld.Status = 'Unqualified';
                              }
                      }
                      
                      else if(ld.Id == newPCR.get(j).LASERCA__Lead__c 
                        && ld.DOER_Solar_Loan__c == TRUE
                        && ld.Status == 'Ready for Credit Check'){ 
                              if(DOER_approval == 'Approved'){
                                    ld.Status = 'Pre-Qualified';
                              }
                              else if(DOER_approval == 'Pending Review'){
                                    ld.Status = 'Pending Credit Review';
                              }
                              else if(DOER_approval == 'Declined'){
                                    ld.Status = 'Unqualified';
                              }
                      }

                }

                update relatedlead;
            
                system.debug(firstname);
                system.debug(lastname);
                system.debug(email);
                system.debug(referralcode);

                // SEND PREAPPROVAL EMAIL 

                if(newPCR.get(j).Credit_PreApproval_Email_Sent__c == FALSE 
                    && DOER == TRUE 
                    && DOERPrequal_approval == 'Pre-Qualified' 
                    && newPCR.get(j).PreApproval_Form__c==TRUE 
                    && newPCR.get(j).LASERCA__Contact__c == NULL){
                        
                    if(firstname != NULL 
                        && lastname != NULL 
                        && email != NULL 
                        && referralcode !=NULL){
                                
                          EmailTemplate et = [SELECT id, HtmlValue, Body 
                                              FROM EmailTemplate 
                                              WHERE DeveloperName = 'RS_DOER_PreQualification_Approval'];

                          system.debug(et);
                          string htmlbody = et.HtmlValue;
                          htmlBody = htmlBody.replace('{!Lead.Name}', firstname);
                          htmlBody = htmlBody.replace('{!Lead.FirstName}', firstname);
                          htmlBody = htmlBody.replace('{!Lead.LastName}', lastname);
                          htmlBody = htmlBody.replace('{!Lead.Email}', email);
                          htmlBody = htmlBody.replace('{!Lead.Lead_ID__c}',newPCR.get(j).PCR_Lead_ID__c );
                          htmlBody = htmlBody.replace('{!Lead.Custom_ID__c}', referralcode);

                          Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                          mail.setHtmlBody(htmlBody);
                                                          
                          for(OrgWideEmailAddress owa : [SELECT id, Address 
                                                         FROM OrgWideEmailAddress]) {
                              if(owa.Address.contains('info')){
                                  mail.setOrgWideEmailAddressId(owa.id); 
                              }
                                system.debug(owa.id);
                          }

                                                          
                          if(newPCR.get(j).Partner_Email__c != NULL){
                                String partneremail = newPCR.get(j).Partner_Email__c;
                                String[] ccAddresses = new String[] {partneremail};
                                mail.setccAddresses(ccAddresses);
                                system.debug(ccAddresses);
                          }
                                                          
                          string subject = 'Congrats! ' +  firstname + ', you have been prequalified for a BlueWave Mass Solar Loan'; 
                          mail.setSubject(subject);
                          mail.setTargetObjectId(newPCR.get(j).PCR_Lead_ID__c);
                          system.debug(newPCR.get(j).PCR_Lead_ID__c);
                          system.debug(newPCR.get(j).LASERCA__Lead__c);
                                   
                          Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
                        
                          newPCR.get(j).Credit_PreApproval_Email_Sent__c = TRUE;
                          system.debug(newPCR.get(j).Credit_PreApproval_Email_Sent__c);
                    }
                } // END DOER EMAIL

                if(newPCR.get(j).Credit_PreApproval_Email_Sent__c == FALSE 
                    && DOER == FALSE 
                    && BWPrequal_approval == 'Pre-Qualified' 
                    && newPCR.get(j).PreApproval_Form__c==TRUE 
                    && newPCR.get(j).LASERCA__Contact__c == NULL){  

                        if(email != NULL){
                          
                            EmailTemplate et = [SELECT id, HtmlValue, Body 
                                                FROM EmailTemplate 
                                                WHERE DeveloperName = 'RS_PreQualification_Approval'];

                            system.debug(et);
                            string htmlbody = et.HtmlValue;
                            htmlBody = htmlBody.replace('{!Lead.Name}', firstname);
                            htmlBody = htmlBody.replace('{!Lead.Email}', email);
                            htmlBody = htmlBody.replace('{!Lead.Lead_ID__c}',newPCR.get(j).PCR_Lead_ID__c );

                            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                            mail.setHtmlBody(htmlBody);
                                                          
                            for(OrgWideEmailAddress owa : [SELECT id, Address 
                                                          FROM OrgWideEmailAddress]) {
                                if(owa.Address.contains('info')) {
                                  mail.setOrgWideEmailAddressId(owa.id); 
                                }
                                system.debug(owa.id);
                            }

                            if(newPCR.get(j).Partner_Email__c != NULL){
                                String partneremail = newPCR.get(j).Partner_Email__c;
                                String[] ccAddresses = new String[] {partneremail};
                                mail.setccAddresses(ccAddresses);
                                system.debug(ccAddresses);
                            }
                                                          
                            string subject = 'Congrats! ' +  firstname + ', you have been prequalified for a BlueWave Mass Solar Loan'; 
                            mail.setSubject(subject);
                            mail.setTargetObjectId(newPCR.get(j).PCR_Lead_ID__c);
                            system.debug(newPCR.get(j).PCR_Lead_ID__c);
                            system.debug(newPCR.get(j).LASERCA__Lead__c);
                                          
                            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
                            newPCR.get(j).Credit_PreApproval_Email_Sent__c = TRUE;
                        }
                } // END BW LOAN EMAIL
                 
              } 
          } 
        } 
      } 
  } 
}