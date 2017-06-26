/*************************************************************************************
 + * Created By:  Jordan Pentaleri 
 + * Sends collections emails based on how many days late an account is
 + * Meant to be run as scheduled apex once a day.
 + * 
 + * Tested By: CustomerCommunicationHandlerTest
 + *************************************************************************************/


global class CustomerCommunicationHandler Implements Schedulable {
  
      global void execute(SchedulableContext sc){
       
            system.debug('entered');
            decimal outstandingbalance;
            List <Account> billedacclist = new list <Account> ();
            List <Messaging.SingleEmailMessage> emailstosend =  new list <Messaging.SingleEmailMessage> ();    


            RecordType rt = [ SELECT Id
                              FROM RecordType
                              WHERE DeveloperName = 'Property'];
            system.debug(rt);

            List <Account> acclist =  [   SELECT id, Name, Send_Bills_Contact__C, Last_Bill_Send_Date__c, Do_not_Send_Bills__c,
                                           Recurring_Billing__c, Days_Past_Due__c, RecordTypeId, Total_Outstanding_Balance__c, Total_Billed__c
                                          FROM Account 
                                          WHERE Total_Outstanding_Balance__c > 1];
            system.debug(acclist);

            if(acclist.size()>0){
                  for (Account acc : acclist){
                      if(acc.RecordTypeID == rt.Id){
                            system.debug(acc);
                            billedacclist.add(acc);
                            system.debug(acc.Send_Bills_Contact__c);
                      }
                  }
            }   

            List <EmailTemplate> templatelist = [Select id, HtmlValue, Body, DeveloperName
                                                FROM EmailTemplate]; 

            // send your bill is X days past due email, if their bill is X days past due

            if(billedacclist.size()>0){
                for (Account act : billedacclist){
                    if(act.Last_Bill_Send_Date__c != null && act.Send_Bills_Contact__c != null && !act.Do_not_Send_Bills__c){
                      datetime lastbill = act.Last_Bill_Send_Date__c;
                      date lbsd = date.newinstance(lastbill.year(), lastbill.month(), lastbill.day());
                      date duedate = lbsd + 17;
                      system.debug(lbsd);
                      system.debug(duedate);
                      date mydate = system.today();
                      system.debug(mydate);

                      system.debug(act);
                      string contactid = act.Send_Bills_Contact__c;
                      system.debug(contactid);
                      string email;
                      string htmlbody; 
                      string fullname = act.Name;
                      string subject = 'Your BlueWave account is ' + act.Days_Past_Due__c + ' days past due';
                      string dollar = string.valueof(act.Total_Outstanding_Balance__c);
                      string balance = '$' + dollar;
                      
                        // Select the correct template
                      if(contactid != null 
                          && act.Recurring_Billing__c == False
                          && (duedate == mydate
                              || act.Days_Past_Due__c==7 
                              || act.Days_Past_Due__c==15
                              || act.Days_Past_Due__c==30
                              || act.Days_Past_Due__c==45
                              || act.Days_Past_Due__c==60
                              || act.Days_Past_Due__c==67
                              || act.Days_Past_Due__c==74
                              || act.Days_Past_Due__c==81
                              || act.Days_Past_Due__c==88
                              || act.Days_Past_Due__c==90)){  

                        if(duedate == mydate){
                          for(EmailTemplate et : templatelist){
                              if(et.DeveloperName == 'X3_Days_Bill_Due_Notice'){
                                system.debug(et);
                                htmlbody = et.HtmlValue;
                                subject = 'Your Community Solar Bill Is Almost Due';
                              }
                          }
                        }

                        else if(act.Days_Past_Due__c == 7){
                          for(EmailTemplate et : templatelist){
                              if(et.DeveloperName == 'Bill_Late_1_Week'){
                                system.debug(et);
                                htmlbody = et.HtmlValue;
                              }
                          }
                        }

                        else if(act.Days_Past_Due__c == 15){
                          for(EmailTemplate et : templatelist){
                              if(et.DeveloperName == 'Bill_Late_15_Days'){
                                system.debug(et);
                                htmlbody = et.HtmlValue;
                              }
                          }
                        }

                        else if(act.Days_Past_Due__c == 30){
                          for(EmailTemplate et : templatelist){
                              if(et.DeveloperName == 'Bill_Late_30_Days'){
                                system.debug(et);
                                htmlbody = et.HtmlValue;
                              }
                          }
                        }

                        else if(act.Days_Past_Due__c == 45){
                          for(EmailTemplate et : templatelist){
                              if(et.DeveloperName == 'Bill_Late_45_Days'){
                                system.debug(et);
                                htmlbody = et.HtmlValue;
                              }
                          }
                        }

                        else if(act.Days_Past_Due__c == 60){
                          for(EmailTemplate et : templatelist){
                              if(et.DeveloperName == 'Bill_Late_60_Days'){
                                system.debug(et);
                                htmlbody = et.HtmlValue;
                              }
                          }
                        }

                        else if(act.Days_Past_Due__c == 67){
                          for(EmailTemplate et : templatelist){
                              if(et.DeveloperName == 'Bill_Late_67_Days'){
                                system.debug(et);
                                htmlbody = et.HtmlValue;
                              }
                          }
                        }

                        else if(act.Days_Past_Due__c == 74){
                          for(EmailTemplate et : templatelist){
                              if(et.DeveloperName == 'Bill_Late_74_Days'){
                                system.debug(et);
                                htmlbody = et.HtmlValue;
                              }
                          }
                        }

                        else if(act.Days_Past_Due__c == 81){
                          for(EmailTemplate et : templatelist){
                              if(et.DeveloperName == 'Bill_Late_81_Days'){
                                system.debug(et);
                                htmlbody = et.HtmlValue;
                              }
                          }
                        }

                        else if(act.Days_Past_Due__c == 88){
                          for(EmailTemplate et : templatelist){
                              if(et.DeveloperName == 'Bill_Late_88_Days'){
                                system.debug(et);
                                htmlbody = et.HtmlValue;
                              }
                          }
                        }

                        else if(act.Days_Past_Due__c == 90){
                          for(EmailTemplate et : templatelist){
                              if(et.DeveloperName == 'Bill_Late_90_Days'){
                                system.debug(et);
                                htmlbody = et.HtmlValue;
                              }
                          }
                        }

                        if(fullname != null && balance != null){
                              htmlBody = htmlBody.replace('{!Account.Name}', fullname);
                              htmlBody = htmlBody.replace('{!Account.Total_Outstanding_Balance__c}', balance);
                        }
                        
                        if(htmlBody != null && htmlbody != 'DONOTSEND'){
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                       
                        mail.setHtmlBody(htmlBody);
                                                        
                        for(OrgWideEmailAddress owa : [SELECT id, Address 
                                                      FROM OrgWideEmailAddress]) {
                              if(owa.Address.contains('customercare')){ 
                                    mail.setOrgWideEmailAddressId(owa.id); 
                                    system.debug(owa.id);
                              }
                        }
                        
                                                        
                        String[] ccAddresses = new String[] {'jpentaleri@bluewave-capital.com'};
                        mail.setccAddresses(ccAddresses);
                        system.debug(ccAddresses);      
                        mail.setSubject(subject);
                        mail.setTargetObjectId(contactid);                        
                        
                        emailstosend.add(mail);
     
                        }

                        htmlbody = 'DONOTSEND';
                        system.debug(htmlbody);

                      }
                    }
                  }
              MessagingService.sendEmail(emailstosend);
            }     


      }
}