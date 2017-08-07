public without sharing class SLPAddCoApplicant {
      @AuraEnabled 
      public static String checkForCoApps (String leadId) { 
        String queryResult;

        Lead mainApplicant = [SELECT Id, Name, Partner_Sent_Co_Signer_Link__c, CoApplicant_Contact__c, Co_Applicant_First_Name__c
                                FROM Lead 
                                WHERE Id = : leadId];

        if (mainApplicant.CoApplicant_Contact__c != NULL || mainApplicant.Co_Applicant_First_Name__c != NULL) { 
          queryResult = 'hasCoApp';
        } else if (mainApplicant.Partner_Sent_Co_Signer_Link__c) {
          queryResult = 'sentEmail';
        } else {
          queryResult = 'clear';
        }

        return queryResult;
      }

      @AuraEnabled 
      public static String getCoAppLink (Contact coAppInfo, String leadId) { 
        Map<String, String> faParametersMap = new Map<String, String>();
        String falink;
        faParametersMap.put('571', coAppInfo.FirstName);
        faParametersMap.put('572', coAppInfo.LastName);
        faParametersMap.put('574', coAppInfo.Email);
        faParametersMap.put('526', leadId);
        falink = FormAssemblyHelper.createFormAssemblyUrl('381505', faParametersMap);
        return falink;
      }

      @AuraEnabled 
      public static String sendCoAppEmail (Contact coAppInfo,  String leadId) {
        String linkToForm;
        String emailSent;

        Lead mainApplicant = [SELECT Id, Name, Partner_Sent_Co_Signer_Link__c                                
                                FROM Lead 
                                WHERE Id = : leadId];

        linkToForm = getCoAppLink(coAppInfo, leadId);
        List<String> addressList = new List<String>{coAppInfo.Email};       

        EmailTemplate template = [SELECT Id, HtmlValue, Body 
                                  FROM EmailTemplate 
                                  WHERE DeveloperName = 'RS_CoApplicant_Please_Fill_out_Form'];

        String htmlBody = template.HtmlValue;
            htmlBody = htmlBody.replace('{!SLP.FirstName}', coAppInfo.FirstName);
            htmlBody = htmlBody.replace('{!SLP.LeadName}', mainApplicant.Name);
            htmlBody = htmlBody.replace('{!SLP.FALink}', linkToForm);

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setHtmlBody(htmlBody);
        for (OrgWideEmailAddress senderEmail : [SELECT Id, Address 
                                                FROM OrgWideEmailAddress
                                                WHERE Address = 'customercare@bluewavesolar.com'  
                                                LIMIT 1]) {
          mail.setOrgWideEmailAddressId(senderEmail.Id); 
        }  
        String emailSubject = 'Request to Add Co-Applicant to Solar Loan Application'; 
        mail.setSubject(emailSubject);
        mail.setToAddresses(addressList);
        Messaging.SendEmailResult[] result;
        result = MessagingService.sendEmail(new List<Messaging.SingleEmailMessage>{mail}); 
        system.debug(result);
        for (Messaging.SendEmailResult rr: result){ 
          if (rr.IsSuccess()) {
            emailSent = 'success';
            mainApplicant.Partner_Sent_Co_Signer_Link__c = TRUE;
            update mainApplicant;
          }
        }
        system.debug(emailSent);
        return emailSent;       
      }

      @AuraEnabled 
      public static Contact addNewCoApplicant (Contact newContact, String leadId) { 
        RecordType coAppRecordType = [ SELECT Id 
                                        FROM RecordType 
                                        WHERE Name = 'Contact - Co-Applicant'
                                        LIMIT 1];

        Lead mainApplicant = [SELECT Id, Name, Co_Applicant_First_Name__c, Co_Applicant_Last_Name__c,
                                Co_Applicant_Email__c, Co_Applicant_Phone__c, Co_Applicant_Social_Security__c,
                                Co_Applicant_Income__c, Co_Applicant_Address__c, Application_Type__c, 
                                CoApplicant_Contact__c, Joint_Applicant_Type__c, 
                                Co_Applicant_Date_of_Birth__c, Status
                                FROM Lead 
                                WHERE Id = : leadId];

        newContact.RecordTypeId = coAppRecordType.Id;
        newContact.Lead__c = leadId;
        newContact.AccountId = '001g000001iaKpG'; // Co-Applicant Placeholder Account

        insert newContact;

        String concatenatedAddress = newContact.LASERCA__Home_Address__c +', '+ newContact.LASERCA__Home_City__c
                                      +' '+  newContact.LASERCA__Home_State__c +' '+ newContact.LASERCA__Home_Zip__c;

        mainApplicant.Co_Applicant_First_Name__c = newContact.FirstName;
        mainApplicant.Co_Applicant_Last_Name__c = newContact.LastName;
        mainApplicant.Co_Applicant_Email__c = newContact.Email;
        mainApplicant.Co_Applicant_Social_Security__c = newContact.LASERCA__Social_Security_Number__c  ;
        mainApplicant.Co_Applicant_Income__c = newContact.Income__c;
        mainApplicant.Co_Applicant_Date_of_Birth__c = newContact.LASERCA__Co_Applicant_DOB__c ;
        mainApplicant.Co_Applicant_Address__c = concatenatedAddress;
        mainApplicant.Application_Type__c = 'Joint';
        mainApplicant.CoApplicant_Contact__c = newContact.Id;
        mainApplicant.Joint_Applicant_Type__c = 'Co-Signer';
        mainApplicant.Status = 'Pending Credit Review';

        update mainApplicant;
        return newContact;
      }


}