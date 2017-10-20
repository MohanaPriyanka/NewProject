/*************************************************************************************
 + * Created By:  Jordan Pentaleri 
 + * This class is fired by the conga conductor record, when an user has QCed the 
 + * pdf bills created by Conga. When the pdf is created, it marks Ready_For_Email_Send__c 
 + * and this class sends the bill pdfs by email in a batch (100s of records at once)
 + * 
 + * Tested By: BatchCSBillEmailHandlerTest
 + *************************************************************************************/

 public without sharing class BatchCSBillEmailHandler implements
    Database.Batchable<sObject>, Database.Stateful { 

    List<SObject> sObjectList = new List<SObject>();

    public List<Messaging.SendEmailError> finalErrorList;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Name,Property_Account_Name__c, Property_Account_ID__c, '+
        'Link_To_File__c, Credits_on_Bill_Period__c, '+
        'Parent_Account__r.Send_Bills_Contact__r.Email '+
        'FROM Account_Bill__c WHERE Ready_for_Email_Send__c = TRUE';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Account_Bill__c> scope){
        List<Messaging.SingleEmailMessage> emailstosend =  new List<Messaging.SingleEmailMessage> ();
        List<Messaging.SendEmailError> errorList = new List<Messaging.SendEmailError>();
        List<Task> emailLogList = new List<Task>();
        List<String> addressList = new List<String>();
        String errorCode;
        String htmlBody;

        EmailTemplate template = [  SELECT Id, HtmlValue, Body, DeveloperName
                                    FROM EmailTemplate
                                    WHERE DeveloperName = : 'CS_Monthly_Invoice_Email' LIMIT 1]; 

        String originalHtmlbody = template.HtmlValue;

        OrgWideEmailAddress senderEmail = [ SELECT Id, Address 
                                            FROM OrgWideEmailAddress
                                            WHERE Address = : 'customercare@bluewavesolar.com' 
                                            LIMIT 1];

        for (Account_Bill__c acctBill : scope) {
            system.debug(acctBill);
            errorCode = '';
            htmlBody = originalHtmlbody;
            addressList.clear();
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            if (acctBill.Parent_Account__r.Send_Bills_Contact__r.Email != NULL) {
                if (acctBill.Link_To_File__c != NULL) {
                    addressList.add(acctBill.Parent_Account__r.Send_Bills_Contact__r.Email);  
                    htmlBody = htmlBody.replace('{!URL_TO_FILE}', acctBill.Link_To_File__c);
                    htmlBody = htmlBody.replace('{!AccountName}', acctBill.Property_Account_Name__c);
                    htmlBody = htmlBody.replace('{!Account_Bill_Property_Id}', acctBill.Property_Account_ID__c);
                    htmlBody = htmlBody.replace('{!Credits_Period}', acctBill.Credits_on_Bill_Period__c ); 
                    acctBill.Published__c = true;
                    acctBill.Ready_for_Email_Send__c = false;
                } else {
                    addressList.add('communitysolar@bluewavesolar.com');
                    errorCode = 'EMAIL SEND FAILED FOR: ' + acctBill.Id + ' because there was no link to the pdf file.';
                    htmlBody = errorCode;
                }
            } else {
                addressList.add('communitysolar@bluewavesolar.com');
                errorCode = 'EMAIL SEND FAILED FOR: ' + acctBill.Id + ' because no email was found on the Send Bills Contact';
                htmlBody = errorCode;
            }
            mail.setOrgWideEmailAddressId(senderEmail.Id); 
            mail.setSubject(acctBill.Property_Account_Name__c + ', Your Community Solar Share Has Posted');
            mail.setHtmlBody(htmlBody);
            mail.setToAddresses(addressList);   
            emailstosend.add(mail);
            Task newTask = new Task(WhatId = acctBill.Id,
                                    Status = 'Completed');
            if (errorCode != ''){
                newTask.Subject = 'Error:' + errorCode;
            } else {
                newTask.Subject = 'Email Send Initiated';
            }
            emailLogList.add(newTask);        
        }

        List<Messaging.SendEmailResult> result = MessagingService.sendEmail(emailstosend);
        for (Messaging.SendEmailResult rr: result){ 
          if (!rr.IsSuccess()) {
            for (Messaging.SendEmailError error: rr.getErrors()) {
              finalErrorList.add(error);
            }
          } 
        }
        update scope;
        insert emailLogList; 
    }

    public void finish(Database.BatchableContext bc){
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, 
                            JobItemsProcessed,
                            TotalJobItems, CreatedBy.Email
                            FROM AsyncApexJob
                            WHERE Id = :bc.getJobId()];

        if(!Test.isRunningTest()){
            String concatenatedErrorMessage = 'Email Errors: ';
            if (finalErrorList != NULL) {
                for (Messaging.SendEmailError error : finalErrorList) {
                    concatenatedErrorMessage = concatenatedErrorMessage + error.getMessage();
                }
            }

            String emailBody = 'CS Bill Emails Have Been Sent! Job Id: '+ job.Id 
                                + '  Errors: ' + job.NumberOfErrors 
                                + '  Total Jobs Processed (groups of 10): ' + job.JobItemsProcessed
                                + '  ' + concatenatedErrorMessage ;
            List<String> postJobEmailAddresses = new List<String>{'product@bluewavesolar.com' , 'communitysolar@bluewavesolar.com'};   
            MessagingService.createAndSendEmail(emailBody, 'customercare@bluewavesolar.com', 'CS Bill Email Send Processing Complete', postJobEmailAddresses);
        }
    } 
}