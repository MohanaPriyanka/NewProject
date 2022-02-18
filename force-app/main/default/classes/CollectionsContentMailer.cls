/**
 * @description This automates mailing collections (delinquency) letters generated from Conga batch jobs so that
 * Customer Ops does not need to upload and send via LetterStream manually. Assumes Conga relates an individual letter pdf to
 * the Property Account where it gets the mailing address.
 * Tested By: CollectionsContentMailerTest
 */
public without sharing class CollectionsContentMailer implements Schedulable {
    ContentDocumentSelector contentDocumentSelector = new ContentDocumentSelector();
    AccountsSelector accountsSelector = new AccountsSelector();

    public void execute(SchedulableContext context) {
        try {
            List<ContentMailerService.Param> docsToMail = getContentDocsToMail();
            if (!docsToMail.isEmpty()) {
                System.enqueueJob(new ContentMailerAsyncService(docsToMail));
            }
        } catch (Exception e) {
            Logger.logNow('CollectionsContentMailer', 'execute', e.getMessage() + '\n' + e.getStackTraceString(), Logger.ERROR);
        } finally {
            Logger.flushLogs();
        }
    }

    public List<ContentMailerService.Param> getContentDocsToMail() {
        List<ContentDocument> contentDocuments = contentDocumentSelector.selectForMailing();
        Set<Id> accountIds = getLinkedAccountsFromContentDocs(contentDocuments);
        Map<Id, Account> accountMap = new Map<Id, Account>(accountsSelector.selectAll(accountIds));
        Map<Id, Account> contentDocIdToAccountMap = getContentDocToAccountMap(contentDocuments, accountMap);

        List<ContentMailerService.Param> docsToMail = new List<ContentMailerService.Param>();
        for (ContentDocument contentDocument : contentDocuments) {
            Account propertyAccount = contentDocIdToAccountMap.get(contentDocument.Id);
            if (propertyAccount == null) {
                Logger.logLater('CollectionsContentMailer', 'execute', 'Did not find an Account related to Content Doc ' +
                    contentDocument.Id + ' so we could not get an address to send to LetterStream', Logger.ERROR);
                continue;
            }
            docsToMail.add(getContentMailerParam(contentDocument, propertyAccount));
        }
        return docsToMail;
    }

    private ContentMailerService.Param getContentMailerParam(ContentDocument contentDocument, Account propertyAccount) {
        ContentMailerService.Param param = new ContentMailerService.Param();
        param.contentDocumentId = contentDocument.Id;
        param.fileName = contentDocument.LatestPublishedVersion.Title.replace(' ', '_') + '.pdf';
        param.contentSize = contentDocument.ContentSize;
        param.linkedEntityId = contentDocument.LatestPublishedVersionId;
        param.recipientName = propertyAccount.Send_Bills_Contact__r.FirstName + ' ' + propertyAccount.Send_Bills_Contact__r.LastName;
        param.street = propertyAccount.BillingStreet;
        param.city = propertyAccount.BillingCity;
        param.state = propertyAccount.BillingState;
        param.postalCode = propertyAccount.BillingPostalCode;
        param.mailType = contentDocument.LatestPublishedVersion.Mail_Type__c;
        return param;
    }

    private Set<Id> getLinkedAccountsFromContentDocs(List<ContentDocument> contentDocuments) {
        Set<Id> accountIds = new Set<Id>();
        for (ContentDocument contentDocument : contentDocuments) {
            for (ContentDocumentLink cdl : contentDocument.ContentDocumentLinks) {
                if (cdl.LinkedEntityId.getSobjectType() == Account.SObjectType) {
                    accountIds.add(cdl.LinkedEntityId);
                }
            }
        }
        return accountIds;
    }

    private Map<Id, Account> getContentDocToAccountMap(List<ContentDocument> contentDocuments, Map<Id, Account> accountMap) {
        Map<Id, Account> contentDocIdToAccountMap = new Map<Id, Account>();
        for (ContentDocument contentDocument : contentDocuments) {
            for (ContentDocumentLink cdl : contentDocument.ContentDocumentLinks) {
                if (cdl.LinkedEntityId.getSobjectType() == Account.SObjectType) {
                    contentDocIdToAccountMap.put(contentDocument.Id, accountMap.get(cdl.LinkedEntityId));
                }
            }
        }
        return contentDocIdToAccountMap;
    }
}