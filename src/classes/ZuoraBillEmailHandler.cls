public without sharing class ZuoraBillEmailHandler implements Database.Batchable<sObject> {
    public List<Zuora__ZInvoice__c> invoicesToSend;
    public Map<String, EmailTemplate> templatesMap;

    public List<Zuora__ZInvoice__c> start(Database.BatchableContext bc) {
        return invoicesToSend;
    }

    public Map<String, EmailTemplate> setTemplateMap(){
        templatesMap = new Map<String, EmailTemplate>();
        List<EmailTemplate> templates = [
            SELECT Id, HtmlValue, Body, DeveloperName
            FROM EmailTemplate
            WHERE DeveloperName LIKE '%CS_Monthly_Invoice_Email%'
        ];
        for (EmailTemplate template : templates) {
            templatesMap.put(template.DeveloperName, template);
        }
        return templatesMap;
    }

    public ZuoraBillEmailHandler() {
        if (invoicesToSend == null){
            invoicesToSend = ZuoraInvoiceSelector.getInvoicesForEmail();
        }
        if (templatesMap == null){
            templatesMap = setTemplateMap();
        }
    }

    public void executeBatch() {
        if (invoicesToSend != null){
            Database.executeBatch(this, 10);
        }
    }

    public void sendInvoicesViaEmail(List<Zuora__ZInvoice__c> invoices){
        List<Messaging.SingleEmailMessage> emailsToSend =  new List<Messaging.SingleEmailMessage> ();
        List<Task> tasksToCreate = new List<Task>();
        List<Case> casesToCreate = new List<Case>();
        String emailStatusMessage;

        OrgWideEmailAddress senderEmail = MessagingService.getCustomerCareEmail();

        for (Zuora__ZInvoice__c invoice : invoices) {
            if (invoice.Zuora__BillingAccount__r.Zuora__Account__r.Bill_Delivery_Preference__c == 'Paper Only') {
                emailStatusMessage = 'Not sent via email because bill delivery preferences are set to Paper Only';
                invoice.Email_Sent__c = false;
            } else if (invoice.Bill_Document_Content_Version_ID__c == null) {
                emailStatusMessage = 'EMAIL SEND FAILED FOR: ' + invoice.Id + ' because there was no pdf file.';
                casesToCreate.add(createCase(emailStatusMessage, invoice));
                invoice.Email_Sent__c = false;
            } else if (invoice.Zuora__BillingAccount__r.Zuora__Account__r.Send_Bills_Contact__r.Email == null) {
                emailStatusMessage = 'EMAIL SEND FAILED FOR: ' + invoice.Id + ' because no email was found on the Send Bills Contact';
                casesToCreate.add(createCase(emailStatusMessage, invoice));
                invoice.Email_Sent__c = false;
            } else {
                emailStatusMessage = 'Email Send Initiated';
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                mail.setUseSignature(false);
                mail.setOrgWideEmailAddressId(senderEmail.Id);
                mail.setSubject(invoice.Zuora__BillingAccount__r.Zuora__Account__r.Name + ', Your Community Solar Share Has Posted');
                mail.setHtmlBody(getHTML(invoice));
                mail.setToAddresses(getAddresses(invoice));
                mail.setEntityAttachments(getAttachments(invoice));
                emailsToSend.add(mail);
                invoice.Email_Sent__c = true;
            }
            // Always log a task to show activity on invoice. Only log cases when there is an error:
            tasksToCreate.add(createTask(emailStatusMessage,invoice));
            invoice.Ready_for_Email_Send__c = false;
        }

        if (emailsToSend.size() > 0) {
            MessagingService.sendEmail(emailsToSend);
        }

        update invoices;
        insert tasksToCreate;
        insert casesToCreate;
    }

    public void execute(Database.BatchableContext bc, List<Zuora__ZInvoice__c> scope) {
        try {
            sendInvoicesViaEmail(scope);
        } catch (Exception excep) {
            Logger.logNow('ZuoraBillEmailHandler','execute',excep.getMessage() + excep.getStackTraceString());
        }
    }

    private Case createCase(String subject, Zuora__ZInvoice__c invoice) {
        Case customerCareCase = new CaseFactory().getCase('Customer Care');
        customerCareCase.Subject = subject;
        customerCareCase.Priority = 'Medium';
        customerCareCase.Product_Line__c = 'Community Solar';
        customerCareCase.AccountId = invoice.Zuora__BillingAccount__r.Zuora__Account__r.Id;
        customerCareCase.Category__c = 'Billing-Issue';
        customerCareCase.Origin = 'Other';
        customerCareCase.Case_Type__c = 'BlueWave';
        customerCareCase.Disable_Followup_Email__c = true;
        customerCareCase.Description = 'Account Bill ' + invoice.Name + ' (' + invoice.Id + ') had an error ' +
            'when emailing account bills.';
        return customerCareCase;
    }

    private Task createTask(String emailStatusMessage, Zuora__ZInvoice__c invoice){
        Task newTask = new Task (
            WhatId = invoice.Id,
            Status = 'Completed',
            Subject = emailStatusMessage
        );
        return newTask;
    }

    private String getHTML(Zuora__ZInvoice__c zuoraInvoice){
        String htmlBody;
        String billTemplateName = 'CS_Monthly_Invoice_Email_' + zuoraInvoice.Zuora__BillingAccount__r.Zuora__Account__r.Client_Brand_Key__c;
        if (zuoraInvoice.Zuora__BillingAccount__r.Zuora__Account__r.Client_Brand_Key__c != null) {
            if (templatesMap.containsKey(billTemplateName)){
                htmlBody = templatesMap.get(billTemplateName).HtmlValue;
            } else {
                Logger.logNow('BatchCSBillEmailHandler', 'execute', 'Cannot Find Email Template: ' + billTemplateName);
            }
        } else {
            htmlBody = templatesMap.get('CS_Monthly_Invoice_Email_BluewaveLogo').HtmlValue;
        }
        htmlBody = htmlBody.replace('{!AccountName}', zuoraInvoice.Zuora__BillingAccount__r.Zuora__Account__r.Name);
        htmlBody = htmlBody.replace('{!Account_Bill_Property_Id}', zuoraInvoice.Zuora__BillingAccount__r.Zuora__Account__r.Id);
        return htmlBody;
    }

    private List<String> getAddresses(Zuora__ZInvoice__c zuoraInvoice){
        List<String> addressList = new List<String>();
        addressList.add(zuoraInvoice.Zuora__BillingAccount__r.Zuora__Account__r.Send_Bills_Contact__r.Email);
        if(zuoraInvoice.Zuora__BillingAccount__r.Zuora__Account__r.Additional_Contact__r.Email != null){
            addressList.add(zuoraInvoice.Zuora__BillingAccount__r.Zuora__Account__r.Additional_Contact__r.Email);
        }
        return addressList;
    }

    private List<String> getAttachments(Zuora__ZInvoice__c zuoraInvoice){
        List<String> attachmentIds = new List<String>();
        attachmentIds.add(zuoraInvoice.Bill_Document_Content_Version_ID__c);
        // TO DO
        /*
           if (invoice.WelcomeLetterIdField != null){
               attachmentIds.add(invoice.WelcomeLetterIdField);
           }
        */
        return attachmentIds;
    }

    public void finish(Database.BatchableContext bc){
        // nothing to do
    }
}