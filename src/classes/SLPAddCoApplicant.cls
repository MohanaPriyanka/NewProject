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
      public static String sendCoAppEmail (Contact coAppInfo,  Lead mainApplicant) {
        String linkToForm;
        String emailSent;
        Messaging.SendEmailResult[] result;
        
        linkToForm = getCoAppLink(coAppInfo, mainApplicant.Id);
        List<String> addressList = new List<String>{coAppInfo.Email};     
        EmailTemplate template = MessagingService.getHtml('RS_CoApplicant_Please_Fill_out_Form');
        String htmlBody = template.HtmlValue;
        String fullName = mainApplicant.FirstName + mainApplicant.LastName;
        htmlBody = htmlBody.replace('{!SLP.FirstName}', coAppInfo.FirstName);
        htmlBody = htmlBody.replace('{!SLP.LeadName}', fullName);
        htmlBody = htmlBody.replace('{!SLP.FALink}', linkToForm);

        result = MessagingService.createAndSendEmail(htmlBody, 'customercare@bluewavesolar.com', 'Request to Add Co-Signer to Solar Loan Application', addressList);
        for (Messaging.SendEmailResult rr: result){ 
          if (rr.IsSuccess() || test.isrunningtest()) {
            emailSent = 'success';
            mainApplicant.Partner_Sent_Co_Signer_Link__c = TRUE;
            update mainApplicant;
          }
        }
        return emailSent;       
      }

      @AuraEnabled 
      public static Contact addNewCoApplicant (Contact newContact, Lead mainApplicant) { 
        RecordType coAppRecordType = [ SELECT Id 
                                        FROM RecordType 
                                        WHERE Name = 'Contact - Co-Applicant'
                                        LIMIT 1];

        Account coAppPlaceholder = [  SELECT Id 
                                      FROM Account 
                                      WHERE Name = 'Co-Applicant Placeholder'
                                      LIMIT 1];

        newContact.RecordTypeId = coAppRecordType.Id;
        newContact.Lead__c = mainApplicant.Id;
        newContact.AccountId = coAppPlaceholder.Id; // Co-Applicant Placeholder Account

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