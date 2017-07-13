global class MonthlyEmailHandler Implements Schedulable {
  
      global void execute(SchedulableContext sc){
       
            system.debug('entered');
            string fromemailid;
            List <string> paraccidlist = new list <string> ();
            map <string, Contact> contactmap = new map <string, Contact> ( );


            RecordType rt = [ SELECT Id
                              FROM RecordType
                              WHERE DeveloperName = 'Property'];
            system.debug(rt);

            
            List <Account> propacclist =  [ SELECT id, Name, Parent_Account__c, RecordTypeId, Total_Billed__c
                                            FROM Account 
                                            WHERE Id IN ( SELECT AccountId  
                                                          FROM Opportunity 
                                                          WHERE Product_line__c = 'Community Solar' AND StageName = 'Complete' AND Disable_Emails__c = False)
                                            AND Total_Billed__c < 1 ];
            system.debug(propacclist);

            if(propacclist.size()>0){
                  for (Account acc : propacclist){
                      if(acc.RecordTypeID == rt.Id){
                            system.debug(acc);
                            paraccidlist.add(acc.Parent_Account__c);
                      }
                  }
            }   

            List <Account> paracclist =  [  SELECT id, Name,  RecordTypeId, Total_Billed__c
                                            FROM Account 
                                            WHERE Id IN : paraccidlist];
            system.debug(paracclist);

            List <Contact> contactlist =  [   SELECT id, FirstName, LastName, Email, AccountId
                                              FROM Contact 
                                              WHERE AccountId IN : paraccidlist];
            system.debug(contactlist);

            List <EmailTemplate> templatelist = [Select id, HtmlValue, Body, DeveloperName
                                                FROM EmailTemplate
                                                WHERE DeveloperName = 'Monthly_Check_In']; 

            for(OrgWideEmailAddress owa : [SELECT id, Address 
                                           FROM OrgWideEmailAddress]) {
              if(owa.Address.contains('customercare')){ 
                      fromemailid = owa.id;
                      system.debug(owa.id);
              }
            }
            
            for(Contact con : contactlist){
                if(con.Email != null){
                 contactmap.put (con.AccountId, con);
                 system.debug(contactmap);
                }
            }

            if(paracclist.size()>0){
                  for (Account act : paracclist){
                    if(contactmap.containsKey(act.id)){
                      system.debug(act);
                      string email;
                      string htmlbody; 
                      string contactid;
                      string fullname = act.Name;
                      string subject = 'Your BlueWave Community Solar Project';

                      if(contactmap.containsKey(act.id)){ 
                          contactid = contactmap.get(act.id).id;
                          system.debug(contactid);
                      }  

                      for(EmailTemplate et : templatelist){
                            if(et.DeveloperName == 'Monthly_Check_In'){
                                system.debug(et);
                                htmlbody = et.HtmlValue;
                            }
                      }

                      if(fullname != null){
                          htmlBody = htmlBody.replace('{!Account.Name}', fullname);
                      }

                      Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();

                      mail.setHtmlBody(htmlBody);
                                                        
                      if(fromemailid != null){
                        mail.setOrgWideEmailAddressId(fromemailid); 
                      }
                                                        
                      String[] ccAddresses = new String[] {'compliance@bluewave-capital.com', 'cgosline@bluewavesolar.com'};
                      mail.setccAddresses(ccAddresses);
                      system.debug(ccAddresses);      
                      mail.setSubject(subject);
                      mail.setTargetObjectId(contactid);

                      List <Messaging.SingleEmailMessage> messages = new List <Messaging.SingleEmailMessage>();
                      messages.add(mail);

                     // Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
                      MessagingService.sendEmail(messages);

                    }
                  }
            }     

      }
}
