/*************************************************************************************
 + * Created By:  Jordan Pentaleri 
 + * This class is fired by the conga conductor record, when an user has QCed the 
 + * pdf bills created by Conga. When the pdf is created, it marks Ready_For_Email_Send__c 
 + * and this class sends the bill pdfs by email in a batch (100s of records at once)
 + * 
 + * Tested By: BatchCSBillEmailHandlerTest
 + *************************************************************************************/

public without sharing class BatchCSBillEmailHandler implements Database.Batchable<sObject> {
    @TestVisible
    private static Id batchJobId;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        batchJobId = bc.getJobId();
        String query = 'SELECT Id, Name,Property_Account_Name__c, Property_Account_ID__c, '+
            'Bill_Attach_Version__c, Credits_on_Bill_Period__c, '+
            'Parent_Account__r.Client_Brand_Key__c, ' +
            'Parent_Account__r.Bill_Delivery_Preference__c, '+
            'Parent_Account__r.Send_Bills_Contact__r.Email, '+
            'Parent_Account__r.Additional_Contact__r.Email ' +
            'FROM Account_Bill__c WHERE Ready_for_Email_Send__c = TRUE';
        // Prevent System.UnexpectedException: No more than one executeBatch can be called from within a test method.
        if (Test.isRunningTest()) {
            query += ' LIMIT 10';
        }
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Account_Bill__c> scope){
        List<Messaging.SingleEmailMessage> emailsToSend =  new List<Messaging.SingleEmailMessage> ();
        List<Task> emailLogList = new List<Task>();
        List<Case> casesToCreate = new List<Case>();
        List<String> addressList = new List<String>();
        List<String> attachmentIds = new List<String>();
        Map<String, String> attachIDMap = new Map<String, String>();
        String errorCode;
        String htmlBody;

        for (Account_Bill__c bill : scope) {
            attachIDMap.put(bill.Id, bill.Bill_Attach_Version__c);
        }

        Map<String, EmailTemplate> templatesMap = new Map<String, EmailTemplate>();
        List<EmailTemplate> templates = [
            SELECT Id, HtmlValue, Body, DeveloperName
            FROM EmailTemplate
            WHERE DeveloperName LIKE '%CS_Monthly_Invoice_Email%'
        ];
        for (EmailTemplate template : templates) {
            templatesMap.put(template.DeveloperName, template);
        }

        OrgWideEmailAddress senderEmail = MessagingService.getCustomerCareEmail();

        for (Account_Bill__c acctBill : scope) {
            String billTemplateName = 'CS_Monthly_Invoice_Email_' + acctBill.Parent_Account__r.Client_Brand_Key__c;
            if (acctBill.Parent_Account__r.Client_Brand_Key__c != null) {
                if (templatesMap.containsKey(billTemplateName)){
                    htmlBody = templatesMap.get(billTemplateName).HtmlValue;
                } else {
                    Logger.logNow('BatchCSBillEmailHandler', 'execute', 'Cannot Find Email Template: ' + billTemplateName);
                    break;
                }
            } else {
                htmlBody = templatesMap.get('CS_Monthly_Invoice_Email_BluewaveLogo').HtmlValue;
            }
            errorCode = '';
            addressList.clear();
            attachmentIds.clear();
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            if (acctBill.Parent_Account__r.Send_Bills_Contact__r.Email != null &&
                acctBill.Parent_Account__r.Bill_Delivery_Preference__c != 'Paper Only') {
                if ( attachIDMap.containsKey(acctBill.Id) ) {
                    addressList.add(acctBill.Parent_Account__r.Send_Bills_Contact__r.Email);
                    if(acctBill.Parent_Account__r.Additional_Contact__r.Email != null){
                        addressList.add(acctBill.Parent_Account__r.Additional_Contact__r.Email);
                    }
                    htmlBody = htmlBody.replace('{!AccountName}', acctBill.Property_Account_Name__c);
                    htmlBody = htmlBody.replace('{!Account_Bill_Property_Id}', acctBill.Property_Account_ID__c);
                    htmlBody = htmlBody.replace('{!Credits_Period}', acctBill.Credits_on_Bill_Period__c );
                    attachmentIds.add(attachIDMap.get(acctBill.Id));
                } else {
                    addressList.add('communitysolar@bluewavesolar.com');
                    errorCode = 'EMAIL SEND FAILED FOR: ' + acctBill.Id + ' because there was no pdf file.';
                    htmlBody = errorCode;
                    casesToCreate.add(createCase(errorCode, acctBill));
                }
            } else {
                addressList.add('communitysolar@bluewavesolar.com');
                errorCode = 'EMAIL SEND FAILED FOR: ' + acctBill.Id + ' because no email was found on the Send Bills Contact';
                htmlBody = errorCode;
                if (acctBill.Parent_Account__r.Bill_Delivery_Preference__c != 'Paper only') {
                    casesToCreate.add(createCase(errorCode, acctBill));
                }
            }
            acctBill.Published__c = true;
            acctBill.Ready_for_Email_Send__c = false;
            mail.setUseSignature(false);
            mail.setOrgWideEmailAddressId(senderEmail.Id);
            mail.setSubject(acctBill.Property_Account_Name__c + ', Your Community Solar Share Has Posted');
            mail.setHtmlBody(htmlBody);
            mail.setToAddresses(addressList);
            mail.setEntityAttachments(attachmentIds);
            // If the account is set to paper only, we don't want to send it
            if (acctBill.Parent_Account__r.Bill_Delivery_Preference__c != 'Paper Only') {
                emailsToSend.add(mail);
                Task newTask = new Task(WhatId = acctBill.Id,
                    Status = 'Completed');
                if (errorCode != ''){
                    newTask.Subject = 'Error:' + errorCode;
                } else {
                    newTask.Subject = 'Email Send Initiated';
                }
                emailLogList.add(newTask);
            }
        }

        MessagingService.sendEmail(emailsToSend);

        update scope;
        insert emailLogList;
        insert casesToCreate;
    }

    private Case createCase(String subject, Account_Bill__c accountBill) {
        Case customerCareCase = new CaseFactory().getCase('Customer Care');
        customerCareCase.Subject = subject;
        customerCareCase.Priority = 'Medium';
        customerCareCase.Product_Line__c = 'Community Solar';
        customerCareCase.AccountId = accountBill.Parent_Account__c;
        customerCareCase.Category__c = 'Billing-Issue';
        customerCareCase.Origin = 'Other';
        customerCareCase.Case_Type__c = 'BlueWave';
        customerCareCase.Disable_Followup_Email__c = true;
        customerCareCase.Description = 'Account Bill ' + accountBill.Name + ' (' + accountBill.Id + ') had an error ' +
            'when emailing account bills.';
        return customerCareCase;

    }

    public void finish(Database.BatchableContext bc){
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors,
            JobItemsProcessed,
            TotalJobItems, CreatedBy.Email
        FROM AsyncApexJob
        WHERE Id = :bc.getJobId()];

        String emailBody = 'CS Bill Processing has Completed. Job Id: '+ job.Id
            + '  Errors: ' + job.NumberOfErrors
            + '  Total Jobs Processed (groups of 10): ' + job.JobItemsProcessed
            + '  *If the template does not exist, an error log will be created'
            + ' and the account bill will not be marked as published';
        List<String> postJobEmailAddresses = new List<String>{'product@bluewavesolar.com' , 'communitysolar@bluewavesolar.com'};
        if(!Test.isRunningTest()){
            MessagingService.createAndSendEmail(emailBody, 'customercare@bluewavesolar.com', 'CS Bill Email Send Processing Complete', postJobEmailAddresses);
        }
    }
}