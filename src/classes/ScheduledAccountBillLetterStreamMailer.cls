/**
 * Created by mstackhouse on 8/1/2018.
 * Description: Scheduled Job to send account bills that need to be mailed to customers. We send PDFs of the account
 * bills to LetterStream, who packages and mails the hard copies. Calls QueueAccountBillLetterStreamMailer which makes
 * the HttpRequest to the endpoint.
 * Test:
 */


public with sharing class ScheduledAccountBillLetterStreamMailer Implements Schedulable {
    // Max size is 12Mb, but need to give buffer for csv file. So, 10 Mb * 1000 Kb/Mb * 1000 b/Kb
    public Integer maxPackageSize = 10*1000*1000;

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
        Integer jobNumber = 1;
        Map<Id, Account_Bill__c> packageAccountBills = new Map<Id, Account_Bill__c>();
        List<ContentDocument> packageContentDocuments = new List<ContentDocument>();

        for (ContentDocument doc : documents) {
            packageSize += doc.ContentSize;
            packageAccountBills.put(doc.Id, accountBillsByDocIds.get(doc.Id));
            packageContentDocuments.add(doc);

            if (packageSize >= maxPackageSize) {
                System.enqueueJob(new QueueAccountBillLetterStreamMailer(packageAccountBills, packageContentDocuments, jobNumber));
                packageAccountBills.clear();
                packageContentDocuments.clear();
                jobNumber += 1;
                packageSize = 0;
            }
        }
    }
}