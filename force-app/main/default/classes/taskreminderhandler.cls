global class taskreminderhandler {

    webservice static void taskreminder(Id TaskKey) { 
        Task t = [select Id, Subject, OwnerID from Task where id =:TaskKey];     
    
          string ownerid = T.OwnerID;
          system.debug(ownerid);
          string taskid = T.Id;
          string subject = T.Subject;
          string currentuser = UserInfo.getFirstName(); 

          User u = [SELECT Id, Email, FirstName FROM User WHERE id = : OwnerID];
          system.debug(u);

          
                EmailTemplate et = [Select id, HtmlValue, Body from EmailTemplate where DeveloperName = 'Task_Reminder_Email'];
                  system.debug(et);
                  string htmlbody = et.HtmlValue;
                  htmlBody = htmlBody.replace('{!Task.Who}', u.FirstName);
                  htmlBody = htmlBody.replace('{!Activity.Id}', taskid);
                  htmlBody = htmlBody.replace('{!Task.Subject}', subject);
                  htmlBody = htmlBody.replace('{CurrentUser}', currentuser);
               //   htmlBody = htmlBody.replace('{!User.FirstName}', );
               //   htmlBody = htmlBody.replace('{!User.LastName}', userlast);

                     Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        //  String[] toAddresses;
                        //   toAddresses.add(email);
                        // mail.setToAddresses(toAddresses);
                        // mail.setReplyTo('info@bluewave-capital.com');
                        // setOrgWideEmailAddressId(0D2j00000004JnV);
                        // mail.setSenderDisplayName('BlueWave Customer Care');
                        // mail.setTemplateId(et.Id);
                        mail.setHtmlBody(htmlBody);
                                                                                  
                        string subject2 = 'Task Reminder!'; 
                        mail.setSubject(subject2);
                        mail.setTargetObjectId(u.Id);  
                        mail.saveAsActivity = false;                                                           
                        Messaging.sendEmail(new Messaging.SingleEmailMessage[] {mail});
             
    }
}