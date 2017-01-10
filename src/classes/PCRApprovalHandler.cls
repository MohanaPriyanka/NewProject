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
    list<Lead> leadlist = new list <Lead>();



      for(j = 0; j < newPCR.size(); j++){
      
      if(newPCR.get(j).Annual_Income_From_Lead__c != NULL){

        if(newPCR.get(j).LASERCA__Lead__c == NULL && newPCR.get(j).Lead_from_Contact__c != NULL) {
              newPCR.get(j).LASERCA__Lead__c = newPCR.get(j).Lead_from_Contact__c;
        }

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
            string Prequal_approval;
            string code1 = newPCR.get(j).LASERCA__Code__c;
            string code2 = newPCR.get(j).LASERCA__Code_2__c;
            string code3 = newPCR.get(j).LASERCA__Code_3__c;
            string code4 = newPCR.get(j).LASERCA__Code_4__c;
            string conglomerate = code1+' '+code2+' '+code3+' '+code4;

            decimal annualincome = newPCR.get(j).Annual_Income_From_Lead__c;  
                 if(newPCR.get(j).Co_Applicant__c == TRUE || newPCR.get(j).LASERCA__Contact__c != NULL) {annualincome = newPCR.get(j).Co_Applicant_Income__c;}

            decimal monthlypayment = newPCR.get(j).Monthly_Payment_IBLS_From_Lead__c;
            System.debug('The Loan Rate is ' + newPCR.get(j).LASERCA__Lead__r.Loan_Interest_Rate_Product__c);
            System.debug('The Loan Amount is ' + newPCR.get(j).LASERCA__Lead__r.Loan_Amount__c);
            integer creditscore = integer.valueof(newPCR.get(j).LASERCA__Credit_Score_TransUnion__c);
            boolean manualapproval = newPCR.get(j).Solar_Loan_Manual_Approval__c;
            boolean manualdecline = newPCR.get(j).Solar_Loan_Manual_Decline__c;
            boolean problemcode = FALSE;
            boolean DOER = newPCR.get(j).DOER_Application__c;
            string firstname = newPCR.get(j).First_Name_from_Lead__c;  
            string lastname = newPCR.get(j).Last_Name_from_Lead__c;
            string email = newPCR.get(j).Email_from_Lead__c;
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
                      DTIafter = (((monthlydebt + monthlypayment)/(annualincome/12))*100); }

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
                                    Prequal_approval = 'Pre-Qualified'; 
                            } 
                            
                            else if (manualapproval ==FALSE 
                                  && manualdecline ==FALSE    
                                  && creditScore >=690 
                                  && DTIafter <=45 ) {
                                      BW_approval = 'Declined';
                                      DOER_approval = 'Approved';
                                      Prequal_approval = 'Pre-Qualified';
                                } 
               
                                       else if (manualapproval==FALSE 
                                                && manualdecline==FALSE     
                                                && creditScore >=680 
                                                && DTIafter <=40  )  {
                                                    BW_approval = 'Declined';
                                                    DOER_approval = 'Approved';
                                                    Prequal_approval = 'Pre-Qualified';
                                       } 
          
              
                                                    else if (manualapproval ==FALSE 
                                                        && manualdecline ==FALSE 
                                                        && CreditScore >=700 
                                                        && DTIafter >50 )    {
                                                            BW_approval = 'Pending Review';
                                                            DOER_approval = 'Declined';
                                                            Prequal_approval = 'Unable to Pre-Qualify';
                                                    } 
                                                    
              
                                                            else if (manualapproval==FALSE 
                                                                && manualdecline==FALSE 
                                                                && creditScore<=680 
                                                                && DTIafter >=40)     {
                                                                    BW_approval = 'Declined';
                                                                    DOER_approval = 'Declined';
                                                                    Prequal_approval = 'Unable to Pre-Qualify';
                                                            } 


                                                                                         else {
                                                                                               BW_approval = 'Declined';
                                                                                               DOER_approval = 'Declined';
                                                                                               Prequal_approval = 'Unable to Pre-Qualify';
                                                                                                      } 

          if( BW_approval == 'Approved' || DOER_approval == 'Approved' || Prequal_approval == 'Pre-Qualified'){
                if(conglomerate.contains('018')){ problemcode = TRUE; }
                system.debug(problemcode);
                if(conglomerate.contains('020')){ problemcode = TRUE; }
                system.debug(problemcode);
                if(conglomerate.contains('021')){ problemcode = TRUE; }
                system.debug(problemcode);
                if(conglomerate.contains('022')){ problemcode = TRUE; }
                system.debug(problemcode);
                if(conglomerate.contains('031')){ problemcode = TRUE; }
                system.debug(problemcode);
                if(conglomerate.contains('034')){ problemcode = TRUE; }
                system.debug(problemcode);
                if(conglomerate.contains('040')){ problemcode = TRUE; }
                if(conglomerate.contains('039')){ problemcode = TRUE; }
                system.debug(problemcode);


               if(problemcode == TRUE) {
                   BW_approval = 'Pending Review';
                   DOER_approval = 'Pending Review';
                   Prequal_approval = 'Unable to Pre-Qualify';
               }
            }

                           else if (manualdecline==TRUE)      {
                                          BW_approval = 'Declined';
                                          DOER_approval = 'Declined';
                                          Prequal_approval = 'Unable to Pre-Qualify';
                                                                          }    
          
                                                       else if (manualapproval==TRUE)   {
                                                            BW_approval = 'Approved';
                                                            DOER_approval = 'Approved';
                                                            Prequal_approval = 'Pre-Qualified';
                                                                                      }   

            system.debug(BW_approval);
            system.debug(DOER_approval);
            system.debug(Prequal_approval);

          if(DOER == TRUE) {
                newPCR.get(j).Solar_Loan_Approval_Status__c = DOER_approval;
              } 

          else if(DOER != TRUE) {
                newPCR.get(j).Solar_Loan_Approval_Status__c = BW_approval;
              }
          
          newPCR.get(j).Solar_Loan_Pre_Qualification_Status__c = prequal_approval;
        
          if(newPCR.get(j).Credit_PreApproval_Email_Sent__c == FALSE && Prequal_approval == 'Pre-Qualified' && newPCR.get(j).PreApproval_Form__c==TRUE && newPCR.get(j).LASERCA__Contact__c == NULL){
          
    //              if(firstname != NULL && lastname != NULL && email != NULL && referralcode !=NULL){
                  
    //                              EmailTemplate et = [Select id, HtmlValue, Body from EmailTemplate where DeveloperName = 'RS_DOER_PreQualification_Approval'];
    //                          system.debug(et);
    //                          string htmlbody = et.HtmlValue;
    //                          htmlBody = htmlBody.replace('{!Lead.Name}', firstname);
    //                          htmlBody = htmlBody.replace('{!Lead.FirstName}', firstname);
    //                          htmlBody = htmlBody.replace('{!Lead.LastName}', lastname);
    //                          htmlBody = htmlBody.replace('{!Lead.Email}', email);
    //                          htmlBody = htmlBody.replace('{!Lead.Lead_ID__c}',newPCR.get(j).PCR_Lead_ID__c );
    //                          htmlBody = htmlBody.replace('{!Lead.Custom_ID__c}', referralcode);

    //                                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
    //                                        //  String[] toAddresses;
    //                                        //   toAddresses.add(email);
    //                                        // mail.setToAddresses(toAddresses);
    //                                        // mail.setReplyTo('info@bluewave-capital.com');
    //                                        // setOrgWideEmailAddressId(0D2j00000004JnV);
    //                                        // mail.setSenderDisplayName('BlueWave Customer Care');
    //                                        // mail.setTemplateId(et.Id);
    //                                        mail.setHtmlBody(htmlBody);
                                            
    //                                       for(OrgWideEmailAddress owa : [select id, Address from OrgWideEmailAddress]) {
    //                                       if(owa.Address.contains('info')) mail.setOrgWideEmailAddressId(owa.id); 
    //                                       system.debug(owa.id);
    //                                       }

                                            
    //                                        if(newPCR.get(j).Partner_Email__c != NULL){
    //                                        String partneremail = newPCR.get(j).Partner_Email__c;
    //                                        String[] ccAddresses = new String[] {partneremail};
    //                                        mail.setccAddresses(ccAddresses);
    //                                        system.debug(ccAddresses);
    //                                        }
                                            
    //                                        string subject = 'Congrats! ' +  firstname + ', you have been prequalified for a BlueWave Mass Solar Loan'; 
    //                                        mail.setSubject(subject);
    //                                        mail.setTargetObjectId(newPCR.get(j).PCR_Lead_ID__c);
    //                                        system.debug(newPCR.get(j).PCR_Lead_ID__c);
    //                                        system.debug(newPCR.get(j).LASERCA__Lead__c);


                                                
    //                                        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
          

    //          newPCR.get(j).Credit_PreApproval_Email_Sent__c = TRUE;
    //}
  }
    }
    }   // End if statement for null monthly debt
    }   // End if statement for old records to not trigger
    }    // End triggered list for loop  




 }
}