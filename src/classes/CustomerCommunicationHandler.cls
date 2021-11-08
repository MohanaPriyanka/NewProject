/*************************************************************************************
 + * Created By:  Jordan Pentaleri
 + * Sends collections emails based on how many days late an account is
 + * Meant to be run as scheduled apex once a day.
 + *
 + * Tested By: CustomerCommunicationHandlerTest
 + *************************************************************************************/

public class CustomerCommunicationHandler implements Database.Batchable<SObject>, Schedulable {
    private Map<String, String> templateMap;

    public void execute(SchedulableContext sc) {
        Database.executeBatch(this, 10);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Name, Send_Bills_Contact__c, ' +
            'Recurring_Billing__c, Days_Past_Due__c, ' +
            'RecordTypeId, Total_Outstanding_Balance_Merge__c, ' +
            'Total_Billed__c, Client_Brand_Key__c, ' +
            'Collection_Call_Today__c, Collection_Email_To_Fire_Today__c, ' +
            'Max_Overdue_Due_Date_Merge__c, ' +
            'Collection_Email_Text__c ' +
            'FROM Account ' +
            'WHERE Total_Outstanding_Balance_Merge__c > 1 ' +
            'AND Send_Bills_Contact__c != null ' +
            'AND (Collection_Email_To_Fire_Today__c = true ' +
            'OR Collection_Call_Today__c = true) ' +
            'AND Recurring_Billing__c = false ';
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Account> scope) {
        List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();
        List<Case> caseToInsertList = new List<Case>();
        templateMap = new Map<String, String>();

        for (EmailTemplate template : [
            SELECT Id, HtmlValue, Body, DeveloperName
            FROM EmailTemplate
            WHERE DeveloperName LIKE 'Bill_Late%'
        ]) {
            templateMap.put(template.DeveloperName, template.HtmlValue);
        }

        for (Account account : scope) {
            if (account.Collection_Call_Today__c) {
                caseToInsertList.add(createCollectionsCallCase(account));
            }
            if (account.Collection_Email_To_Fire_Today__c) {
                try {
                    emailsToSend.add(getEmailToSend(account));
                } catch (Exception e) {
                    Logger.logLater('CustomerCommunicationHandler', 'execute', e.getMessage() + '\n' + e.getStackTraceString());
                }
            }
        }

        MessagingService.logErrors(MessagingService.sendEmail(emailsToSend), 'CustomerCommunicationHandler');
        insert caseToInsertList;

        Logger.flushLogs();
    }

    private Messaging.SingleEmailMessage getEmailToSend(Account account) {
        Date sendBillReminderDate = account.Max_Overdue_Due_Date_Merge__c - 3;
        String htmlBody;
        String subject;
        String balance = formatMoney(account.Total_Outstanding_Balance_Merge__c);
        String days = String.valueOf((account.Days_Past_Due__c).setScale(0));

        if (sendBillReminderDate == System.today()) {
            htmlBody = getTemplate('Bill_Late_3DayReminder_' + account.Client_Brand_Key__c, account);
            subject = 'Your Community Solar Bill Is Almost Due';
        } else {
            htmlBody = getTemplate('Bill_Late_' + account.Client_Brand_Key__c, account);
            subject = 'Your Community Solar Bill Is ' + (account.Days_Past_Due__c).setScale(0) + ' Days Past Due';
        }
        htmlBody = replace(htmlBody, '{{{Recipient.Name}}}', account.Name);
        htmlBody = replace(htmlBody, '{{{Recipient.Total_Outstanding_Balance_Merge}}}', balance);
        htmlBody = replace(htmlBody, '{{{Recipient.Days_Past_Due}}}', days);
        htmlBody = replace(htmlBody, '{{{Recipient.Custom_Email_Text}}}', account.Collection_Email_Text__c);

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setHtmlBody(htmlBody);
        mail.setOrgWideEmailAddressId(MessagingService.getCustomerCareEmail().Id);
        mail.setSubject(subject);
        mail.setTargetObjectId(account.Send_Bills_Contact__c);
        return mail;
    }

    @SuppressWarnings('PMD.EmptyStatementBlock')
    public void finish(Database.BatchableContext bc) {
    }

    private String replace(String htmlBody, String stringToReplace, String replaceWith) {
        if (replaceWith != null) {
            return htmlBody.replace(stringToReplace, replaceWith);
        }
        return htmlBody;
    }

    private Case createCollectionsCallCase(Account acct) {
        CaseFactory caseFactory = new CaseFactory();
        Case newCase;
        newCase = caseFactory.getCase('Collections');
        newCase.ContactId = acct.Send_Bills_Contact__c;
        newCase.Subject = 'Collections Call: ' + acct.Days_Past_Due__c + ' Days';
        newCase.Priority = 'Medium';
        newCase.Product_Line__c = 'Community Solar';
        newCase.Category__c = 'Billing-Payment';
        newCase.Description =
            'Remind them their payment is Past due' + ' / ' +
                'Ask if they have sent payment and if so when and note check number' + ' / ' +
                'Note this info on the case in the chatter' + ' / ' +
                'If there is no reply leave a voice note';
        newCase.Origin = 'Other';
        newCase.Case_Type__c = 'BlueWave';
        newCase.Disable_Followup_Email__c = true;
        return newCase;
    }

    private String getTemplate(String templateKey, Account acct) {
        if (templateMap.containsKey(templateKey)) {
            return templateMap.get(templateKey);
        }
        throw new Util.BWException('Missing template ' + templateKey + ' for account: ' + acct.Id);
    }

    @TestVisible
    private static String formatMoney(Decimal originalDecimal) {
        String decimalAsString = '$' + originalDecimal.format();
        if (!decimalAsString.contains('.')) {
            return decimalAsString + '.00';
        } else {
            Integer decimalPointIndex = decimalAsString.indexOf('.');
            if (decimalAsString.length() - decimalPointIndex < 3) {
                return decimalAsString + '0';
            }
        }
        return decimalAsString;
    }
}