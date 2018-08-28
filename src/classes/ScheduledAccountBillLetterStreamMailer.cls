/**
 * Created by mstackhouse on 8/1/2018.
 * Description: Scheduled Job to send account bills that need to be mailed to customers. We send PDFs of the account
 * bills to LetterStream, who packages and mails the hard copies. Calls QueueAccountBillLetterStreamMailer which makes
 * the HttpRequest to the endpoint.
 * Test:
 */


public without sharing class ScheduledAccountBillLetterStreamMailer implements Schedulable {
    // Max size is 12Mb, but need to give buffer for csv file. So, 10 Mb * 1000 Kb/Mb * 1000 b/Kb
    public Integer maxPackageSize = 1*1000*1000;
    public Boolean makeCallout = true;

    public void execute(SchedulableContext sc){
        batchAccountBills();
    }

    public void batchAccountBills() {
        Map<Id, Account_Bill__c> accountBillsByDocIds = new Map<Id, Account_Bill__c>();
        Set<Id> docIds = new Set<Id>();

        List<Account_Bill__c> accountBills = [
            SELECT Id, Parent_Account__r.Name, Parent_Account__r.BillingStreet, Parent_Account__r.BillingCity,
                Parent_Account__r.BillingState, Parent_Account__r.BillingPostalCode, Number_of_Pages_in_Template__c,
                Calendar_Month__c, Year__c, Bill_Attach_Document__c
            FROM Account_Bill__c
            WHERE Published__c = TRUE
            AND Ready_For_Paper_Bill_Queue__c = TRUE
            AND Bill_Attach_Document__c != NULL
        ];

        if (accountBills.isEmpty()) {
            return ;
        }

        for (Account_Bill__c accountBill : accountBills) {
            docIds.add(accountBill.Bill_Attach_Document__c);
            accountBillsByDocIds.put(accountBill.Bill_Attach_Document__c, accountBill);
        }

        List<ContentDocument> documents = [
            SELECT Id, LatestPublishedVersion.Title, LatestPublishedVersion.VersionData, ContentSize
            FROM ContentDocument
            WHERE Id IN : docIds
        ];

        Integer packageSize = 0;
        Set<Id> packageAccountBills = new Set<Id>();
        Set<Id> packageContentDocuments = new Set<Id>();
        Integer jobNumber = 1;

        for (ContentDocument doc : documents) {
            packageSize += doc.ContentSize;
            packageAccountBills.add(accountBillsByDocIds.get(doc.Id).Id);
            packageContentDocuments.add(doc.Id);
            // avoid max heap size by sending package and starting over
            if (packageSize >= maxPackageSize) {
                Id jobId = System.enqueueJob(new QueueAccountBillLetterStreamMailer(packageAccountBills, packageContentDocuments, makeCallout, jobNumber));
                packageAccountBills.clear();
                packageContentDocuments.clear();
                packageSize = 0;
                jobNumber += 1;
                Logger.logLater('ScheduleAccountBillLetterStreamMailer', 'batchAccountBills', queuedLogMessage(packageSize, jobId));
            }
        }
        // if we never hit max heap size, send at end
        if (!packageAccountBills.isEmpty() && !packageContentDocuments.isEmpty()) {
            Id jobId = System.enqueueJob(new QueueAccountBillLetterStreamMailer(packageAccountBills, packageContentDocuments, makeCallout, jobNumber));
            Logger.logLater('ScheduleAccountBillLetterStreamMailer', 'batchAccountBills', queuedLogMessage(packageSize, jobId));
        }
        Logger.flushLogs();
    }

    public String queuedLogMessage(Decimal packageSize, Id JobId) {
        Decimal sizeInKB = (packageSize/1000).setScale(3);
        String message = 'Package of ' + sizeInKB + ' kB queued for letter stream. ' + 'JobID: ' + jobId;
        return message;
    }
}