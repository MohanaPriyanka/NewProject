/**
 * Created by mstackhouse on 8/1/2018.
 * Description: Scheduled Job to send account bills that need to be mailed to customers. We send PDFs of the account
 * bills to LetterStream, who packages and mails the hard copies. Calls QueueAccountBillLetterStreamMailer which makes
 * the HttpRequest to the endpoint.
 * Test: LetterStreamServiceTest
 */


global without sharing class ScheduledAccountBillLetterStreamMailer implements Database.Batchable<sObject>, Database.Stateful {
    // Max size is 12Mb, but need to give buffer for csv file. So, 10 Mb * 1000 Kb/Mb * 1000 b/Kb
    public Integer maxPackageSize = 1*1000*1000;
    public Boolean makeCallout = true;
    public CaseFactory caseFactory = new CaseFactory();

    webservice static void batchAccountBills(){
        ScheduledAccountBillLetterStreamMailer batchJob = new ScheduledAccountBillLetterStreamMailer();
        Database.executeBatch(batchJob, 50);
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Parent_Account__c, Parent_Account__r.Name, Parent_Account__r.BillingStreet,' +
            'Parent_Account__r.BillingCity, Parent_Account__r.BillingState, Parent_Account__r.BillingPostalCode,' +
            'Bill_PDF_Page_Count__c, Calendar_Month__c, Year__c, Bill_Attach_Document__c' +
            ' FROM Account_Bill__c' +
            ' WHERE Published__c = TRUE' +
            ' AND Ready_For_Paper_Bill_Queue__c = TRUE' +
            ' AND Bill_Attach_Document__c != NULL' +
            ' AND Parent_Account__r.Opt_Out_of_Paper_Billing__c != TRUE';

        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext bc, List<Account_Bill__c> accountBills) {
        batchAccountBillsByDocumentSize(accountBills);
        }

    public void finish(Database.BatchableContext bc) {
        Logger.flushLogs();
    }

    public void batchAccountBillsByDocumentSize(List<Account_Bill__c> accountBills) {
        Map<Id, Account_Bill__c> accountBillsByDocIds = new Map<Id, Account_Bill__c>();
        Set<Id> docIds = new Set<Id>();

        List<Case> newCases = new List<Case>();
        for (Account_Bill__c accountBill : accountBills) {
            if (checkBillAccountAddressValid(accountBill)) {
                docIds.add(accountBill.Bill_Attach_Document__c);
                accountBillsByDocIds.put(accountBill.Bill_Attach_Document__c, accountBill);
            } else {
                newCases.add(createCaseForInvalidAddress(accountBill));
            }
        }

        if (!newCases.isEmpty()) {
            insert newCases;
        }

        List<ContentDocument> documents = [
            SELECT Id, LatestPublishedVersion.Title, LatestPublishedVersion.VersionData, ContentSize
            FROM ContentDocument
            WHERE Id IN : docIds
        ];

        Integer packageSize = 0;
        Set<Id> packageAccountBills = new Set<Id>();
        Set<Id> packageContentDocuments = new Set<Id>();

        for (ContentDocument doc : documents) {
            packageSize += doc.ContentSize;
            packageAccountBills.add(accountBillsByDocIds.get(doc.Id).Id);
            packageContentDocuments.add(doc.Id);
            // avoid max heap size by sending package and starting over
            if (packageSize >= maxPackageSize) {
                Id jobId = System.enqueueJob(new QueueAccountBillLetterStreamMailer(packageAccountBills, packageContentDocuments, makeCallout));
                packageAccountBills.clear();
                packageContentDocuments.clear();
                packageSize = 0;
                Logger.logLater('ScheduleAccountBillLetterStreamMailer', 'batchAccountBills', queuedLogMessage(packageSize, jobId));
            }
        }
        // if we never hit max heap size, send at end
        if (!packageAccountBills.isEmpty() && !packageContentDocuments.isEmpty()) {
            Id jobId = System.enqueueJob(new QueueAccountBillLetterStreamMailer(packageAccountBills, packageContentDocuments, makeCallout));
            Logger.logLater('ScheduleAccountBillLetterStreamMailer', 'batchAccountBills', queuedLogMessage(packageSize, jobId));
        }

        if (packageAccountBills.isEmpty() || packageContentDocuments.isEmpty()) {
            String message = 'Bills: ' + packageAccountBills + ', Docs: ' + packageContentDocuments;
            Logger.logLater('ScheduleAccountBillLetterStreamMailer', 'batchAccountBills', message);
        }
    }

    public String queuedLogMessage(Decimal packageSize, Id JobId) {
        Decimal sizeInKB = (packageSize/1000).setScale(3);
        String message = 'Package of ' + sizeInKB + ' kB queued for letter stream. ' + 'JobID: ' + jobId;
        return message;
    }

    @TestVisible
    private Boolean checkBillAccountAddressValid(Account_Bill__c accountBill) {
        if (accountBill.Parent_Account__r != null
            && accountBill.Parent_Account__r.BillingStreet != null
            && accountBill.Parent_Account__r.BillingCity != null
            && accountBill.Parent_Account__r.BillingPostalCode != null
            && accountBill.Parent_Account__r.BillingState != null) {
            return true;
        } else {
            return false;
        }
    }

    @TestVisible
    private Case createCaseForInvalidAddress(Account_Bill__c accountBill) {
        Case newCase = caseFactory.getCase('Customer_Care');

        newCase.Subject = 'Cannot send bill to Community Solar customer.';
        newCase.Priority = 'Medium';
        newCase.Product_Line__c = 'Community Solar';
        newCase.Category__c = 'Billing';
        String description = 'The customer address is invalid, so bills cannot be sent to customer. Please update ' +
            'the address on the related Account. If the customer does not want to receive paper bills, ' +
            'please use the \'Opt Out of Paper Billing\' checkbox. [Auto-generated]' ;
        newCase.Description = description;
        newCase.Origin = 'Other';
        newCase.Case_Type__c = 'BlueWave';
        newCase.Disable_Followup_Email__c = true;
        newCase.AccountId = accountBill.Parent_Account__c;

        return newCase;
    }
}