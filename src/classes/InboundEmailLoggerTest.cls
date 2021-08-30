/**
 * @description Created by PeterYao on 8/27/2021.
 */
@IsTest
private with sharing class InboundEmailLoggerTest {
    @IsTest private static void testEmailLogging() {
        Contact testContact = new Contact(
            LastName = 'Test',
            Email = 'test@test.com'
        );
        Contact duplicateTestContact = new Contact(
            LastName = 'Test',
            Email = 'test@test.com'
        );
        insert new List<Contact>{testContact, duplicateTestContact};
        List<Id> fixedSearchResults = new List<Id>{
            testContact.Id,
            duplicateTestContact.Id
        };
        Test.setFixedSearchResults(fixedSearchResults);

        List<EmailMessageRelation> relations = [
            SELECT Id
            FROM EmailMessageRelation
            WHERE RelationId = :testContact.Id
        ];
        System.assertEquals(0, relations.size(), 'Expected to start with no email messages related to the contact');

        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        email.subject = 'Test Subject';
        email.fromName = 'From Name';
        email.plainTextBody = 'Test Body';
        email.toAddresses = new List<String>{'test@test.com'};
        email.binaryAttachments = new List<Messaging.InboundEmail.BinaryAttachment>();
        Messaging.InboundEmail.BinaryAttachment binaryAttachment = new Messaging.InboundEmail.BinaryAttachment();
        binaryAttachment.fileName = 'test.txt';
        binaryAttachment.body = Blob.valueOf('test');
        email.binaryAttachments.add(binaryAttachment);
        envelope.fromAddress = 'user@marektingcloud.com';

        InboundEmailLogger emailLogger = new InboundEmailLogger();
        Messaging.InboundEmailResult result = emailLogger.handleInboundEmail(email, envelope);
        System.assertEquals(true, result.success,
            'InboundEmailLogger should always return a successful result, ' +
                'otherwise Salesforce will send an email to the sender with result.message');
        System.assertEquals(null, result.message,
            'Result.message needs to be null, otherwise Salesforce will send the message back to the sender');
        relations = [
            SELECT Id, EmailMessageId, EmailMessage.Subject, EmailMessage.TextBody, EmailMessage.FromName
            FROM EmailMessageRelation
            WHERE RelationId = :testContact.Id
        ];
        System.assertEquals(1, relations.size(),
            'Expected one email message related to the contact after handling an inbound email');
        System.assertEquals(email.subject, relations[0].EmailMessage.Subject, 'Expected to set the subject');
        System.assertEquals(email.fromName, relations[0].EmailMessage.FromName, 'Expected to set the From Name');
        System.assertEquals(email.plainTextBody, relations[0].EmailMessage.TextBody, 'Expected to set the text body');
        EmailMessage message = [
            SELECT Id, (SELECT Id, Name FROM Attachments)
            FROM EmailMessage
            WHERE Id = :relations[0].EmailMessageId
        ];
        System.assertEquals(1, message.Attachments.size(), 'Should have saved the test attachment to the email message');

        List<Error_Log__c> errorLogs = [
            SELECT Id, Message__c
            FROM Error_Log__c
            WHERE Class__c = 'InboundEmailLogger'
            AND Severity__c = :Logger.WARN
        ];
        System.assertEquals(1, errorLogs.size(), 'Expected a warning about multiple contacts with the same email');
        System.assert(errorLogs[0].Message__c.contains('multiple contacts'),
            'Should be an warning about multiple contacts, but got this: ' + errorLogs[0].Message__c);
    }

    @IsTest private static void testEmailLoggingForUnknownEmail() {
        Messaging.InboundEmail email = new Messaging.InboundEmail();
        Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        email.subject = 'Test Subject';
        email.fromName = 'From Name';
        email.plainTextBody = 'Test Body';
        email.toAddresses = new List<String>{'test@test.com'};
        email.binaryAttachments = new List<Messaging.InboundEmail.BinaryAttachment>();
        Messaging.InboundEmail.BinaryAttachment binaryAttachment = new Messaging.InboundEmail.BinaryAttachment();
        binaryAttachment.fileName = 'test.txt';
        binaryAttachment.body = Blob.valueOf('test');
        email.binaryAttachments.add(binaryAttachment);
        envelope.fromAddress = 'user@marketingcloud.com';

        InboundEmailLogger emailLogger = new InboundEmailLogger();
        Messaging.InboundEmailResult result = emailLogger.handleInboundEmail(email, envelope);
        System.assertEquals(true, result.success,
            'InboundEmailLogger should always return a successful result, ' +
                'otherwise Salesforce will send an email to the sender with result.message');
        System.assertEquals(null, result.message,
            'Result.message needs to be null, otherwise Salesforce will send the message back to the sender');

        List<Error_Log__c> errorLogs = [
            SELECT Id, Message__c
            FROM Error_Log__c
            WHERE Class__c = 'InboundEmailLogger'
            AND Severity__c = :Logger.ERROR
        ];
        System.assertEquals(1, errorLogs.size(),
            'Expected a error about not finding a contact or lead to attach to');
        System.assert(errorLogs[0].Message__c.contains('could not find a contact or lead'),
            'Should be an error about not finding a contact or lead, but got this: ' + errorLogs[0].Message__c);
    }

}