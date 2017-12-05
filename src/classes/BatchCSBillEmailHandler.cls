/*************************************************************************************
 + * Created By:  Jordan Pentaleri 
 + * This class is fired by the conga conductor record, when an user has QCed the 
 + * pdf bills created by Conga. When the pdf is created, it marks Ready_For_Email_Send__c 
 + * and this class sends the bill pdfs by email in a batch (100s of records at once)
 + * 
 + * Tested By: BatchCSBillEmailHandlerTest
 + *************************************************************************************/

 public without sharing class BatchCSBillEmailHandler implements Database.Batchable<sObject> { 
    public List<Messaging.SendEmailError> finalErrorList;

    public BatchCSBillEmailHandler(Map<Id,APXT_BPM__Conductor__c> oldMap, List<APXT_BPM__Conductor__c> newList) {
        for (APXT_BPM__Conductor__c conductor : newList) {  
            if (conductor.Emails_Sent__c && !oldMap.get(conductor.Id).Emails_Sent__c) {
                Database.executeBatch(this, 10);
            }
        }
    } 

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Name,Property_Account_Name__c, Property_Account_ID__c, '+
        'Bill_Attach_Version__c, Credits_on_Bill_Period__c, '+
        'Parent_Account__r.Send_Bills_Contact__r.Email '+
        'FROM Account_Bill__c WHERE Ready_for_Email_Send__c = TRUE';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<Account_Bill__c> scope){
        List<Messaging.SingleEmailMessage> emailstosend =  new List<Messaging.SingleEmailMessage> ();
        List<Messaging.SendEmailError> errorList = new List<Messaging.SendEmailError>();
        List<Task> emailLogList = new List<Task>();
        List<String> addressList = new List<String>();
        List<String> attachmentIds = new List<String>();
        Map<String, String> attachIDMap = new Map<String, String>();
        String errorCode;
        String htmlBody;

        for (Account_Bill__c bill : scope) {
            attachIDMap.put(bill.Id, bill.Bill_Attach_Version__c);
        }

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
            attachmentIds.clear();
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            if (acctBill.Parent_Account__r.Send_Bills_Contact__r.Email != NULL) {
                if ( attachIDMap.containsKey(acctBill.Id) ) {
                    addressList.add(acctBill.Parent_Account__r.Send_Bills_Contact__r.Email);  
                    htmlBody = htmlBody.replace('{!AccountName}', acctBill.Property_Account_Name__c);
                    htmlBody = htmlBody.replace('{!Account_Bill_Property_Id}', acctBill.Property_Account_ID__c);
                    htmlBody = htmlBody.replace('{!Credits_Period}', acctBill.Credits_on_Bill_Period__c ); 
                    acctBill.Published__c = true;
                    acctBill.Ready_for_Email_Send__c = false;
                    attachmentIds.add(attachIDMap.get(acctBill.Id));
                } else {
                    addressList.add('communitysolar@bluewavesolar.com');
                    errorCode = 'EMAIL SEND FAILED FOR: ' + acctBill.Id + ' because there was no pdf file.';
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
            mail.setEntityAttachments(attachmentIds);
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

        update scope;
        insert emailLogList; 
    }

    public void finish(Database.BatchableContext bc){
            AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, 
                            JobItemsProcessed,
                            TotalJobItems, CreatedBy.Email
                            FROM AsyncApexJob
                            WHERE Id = :bc.getJobId()];

            String emailBody = 'CS Bill Emails Have Been Sent! Job Id: '+ job.Id 
                                + '  Errors: ' + job.NumberOfErrors 
                                + '  Total Jobs Processed (groups of 10): ' + job.JobItemsProcessed;
            List<String> postJobEmailAddresses = new List<String>{'product@bluewavesolar.com' , 'communitysolar@bluewavesolar.com'};   
        if(!Test.isRunningTest()){
            MessagingService.createAndSendEmail(emailBody, 'customercare@bluewavesolar.com', 'CS Bill Email Send Processing Complete', postJobEmailAddresses);
        }
    }  
}