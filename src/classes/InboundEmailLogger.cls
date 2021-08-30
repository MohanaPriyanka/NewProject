/**
 * @description Saves inbound emails to a contact with that email address. Intended to be used to save UCB
 * statements sent by Marketing Cloud
 * Tested by: InboundEmailLoggerTest
 */
public without sharing class InboundEmailLogger implements Messaging.InboundEmailHandler {
    /**
     * @description Creates an EmailMessage and relates it to a Contact or Lead with an email address of the
     * first toAddress of the email.
     * InboundEnvelope.toAddress is the Email Sender address (e.g. emaillogger@3-30xyz.7j-4xv8eam.cs203.apex.sandbox.salesforce.com),
     * and not the address we want.
     * @param email InboundEmail
     * @param envelope InboundEnvelope
     * @return InboundEmailResult
     */
    public Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        try {
            return innerHandleInboundEmail(email, envelope);
        } catch (Exception e) {
            Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
            // If success is false, a message will be send to the original sender. But the sender should not care
            // about this class logging emails to Salesforce
            // https://salesforce.stackexchange.com/questions/170932/email-service-not-routing-error-email
            result.success = true;
            Logger.logNow(
                'InboundEmailLogger',
                'handleInboundEmail',
                'Received email with subject "' + email.subject + '" from ' + envelope.fromAddress + ', to ' +
                    JSON.serializePretty(email.toAddresses) + ' but ran into this error when logging:\n' +
                    e.getMessage() + '\n' + e.getStackTraceString(),
                Logger.ERROR
            );
            return result;
        }
    }

    private Messaging.InboundEmailResult innerHandleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailResult();
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
            new List<SObjectType>{
                EmailMessage.SObjectType,
                EmailMessageRelation.SObjectType,
                ContentVersion.SObjectType,
                ContentDocumentLink.SObjectType
            }
        );
        FilesUnitOfWorkHelper customWork = new FilesUnitOfWorkHelper();
        uow.registerWork(new Logger());
        uow.registerWork(customWork);
        List<List<SObject>> searchList = [
            FIND :email.toAddresses[0]
            IN EMAIL FIELDS
                RETURNING Contact(Name), Lead(Name)
        ];
        Id parentId = getParentId(searchList, email);
        EmailMessage emailMessage = new EmailMessage(
            Status = '3', // sent
            ToAddress = email.toAddresses[0],
            FromAddress = envelope.fromAddress,
            FromName = email.fromName,
            Subject = email.subject,
            HtmlBody = email.htmlBody,
            TextBody = email.plainTextBody
        );
        uow.registerNew(emailMessage);
        // Since the ParentId of an EmailMessage has to be a Case, and the RelatedToId has to be a non-human object (Account,
        // Opp, Campaign, etc), we need to use an EmailMessageRelation
        EmailMessageRelation relation = new EmailMessageRelation(
            RelationId = parentId,
            RelationAddress = email.toAddresses[0],
            RelationType = 'ToAddress'
        );
        uow.registerNew(relation, EmailMessageRelation.EmailMessageId, emailMessage);
        if (email.binaryAttachments != null) {
            for (Messaging.InboundEmail.BinaryAttachment binaryAttachment : email.binaryAttachments) {
                ContentVersion contentVersion = new ContentVersion(
                    ContentLocation = 'S',
                    VersionData = binaryAttachment.body,
                    Title = binaryAttachment.fileName,
                    PathOnClient = '/' + binaryAttachment.fileName
                );
                uow.registerNew(contentVersion);
                customWork.registerContentDocumentLinkInsert(emailMessage, contentVersion, 'V', 'AllUsers');
            }
        }
        uow.commitWork();
        result.success = true;
        return result;
    }

    private Id getParentId(List<List<SObject>> searchList, Messaging.InboundEmail email) {
        Id parentId;
        if (searchList[0].isEmpty() && searchList[1].isEmpty()) {
            throw new Util.BWException('could not find a contact or lead with email ' + email.toAddresses[0]);
        } else if (searchList[0].size() > 1) {
            Logger.logLater(
                'InboundEmailLogger',
                'handleInboundEmail',
                'Received email with subject "' + email.subject + '" from ' + email.fromAddress +
                    ', found multiple contacts with with email ' + email.toAddresses[0] + ', and attaching to the first one',
                Logger.WARN
            );
        }
        if (!searchList[0].isEmpty()) {
            parentId = searchList[0][0].Id;
        } else {
            parentId = searchList[1][0].Id;
        }
        return parentId;
    }
}