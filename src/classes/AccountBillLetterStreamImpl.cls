/**
 * Created by mstackhouse on 8/1/2018.
 * Description: Implementation to send account bills that need to be mailed to customers. We send PDFs of the account
 * bills to LetterStream, who packages and mails the hard copies. Calls QueueAccountBillLetterStreamMailer which makes
 * the HttpRequest to the endpoint.
 * Test: LetterStreamServiceTest
 */


public without sharing class AccountBillLetterStreamImpl {
    // Max size is 12Mb, but need to give buffer for csv file. So, 10 Mb * 1000 Kb/Mb * 1000 b/Kb
    public Integer maxPackageSize = 1*1000*1000;
    public Boolean makeCallout = true;
    public CaseFactory caseFactory = new CaseFactory();

    public void queueAccountBillsToSend(List<Account_Bill__c> accountBills) {
        Map<Id, Account_Bill__c> accountBillsByDocIds = new Map<Id, Account_Bill__c>();
        Set<Id> docIds = new Set<Id>();
        List<Case> newCases = new List<Case>();

        if (accountBills.isEmpty()) {
            return ;
        }

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
            SELECT Id, ContentSize
            FROM ContentDocument
            WHERE Id IN : docIds
        ];

        Integer packageSize = 0;
        Set<Id> packageAccountBills = new Set<Id>();
        Set<Id> packageContentDocuments = new Set<Id>();
        Integer jobNumber = 1;

        for (ContentDocument doc : documents) {
            if (Limits.getQueueableJobs() == 50) {
                Logger.logLater('AccountBillLetterStreamImpl', 'queueAccountBillsToSend', 'Maximum Jobs Queued, need to queue bills again');
                continue;
            }
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
                Logger.logLater('AccountBillLetterStreamImpl', 'queueAccountBillsToSend', queuedLogMessage(packageSize, jobId));
            }
        }
        // if we never hit max heap size, send at end
        if (!packageAccountBills.isEmpty() && !packageContentDocuments.isEmpty() && Limits.getQueueableJobs() < 50) {
            Id jobId = System.enqueueJob(new QueueAccountBillLetterStreamMailer(packageAccountBills, packageContentDocuments, makeCallout, jobNumber));
            Logger.logLater('AccountBillLetterStreamImpl', 'queueAccountBillsToSend', queuedLogMessage(packageSize, jobId));
        }

        if (packageAccountBills.isEmpty() || packageContentDocuments.isEmpty()) {
            String message = 'Bills: ' + packageAccountBills + ', Docs: ' + packageContentDocuments;
            Logger.logLater('AccountBillLetterStreamImpl', 'queueAccountBillsToSend', message);
        }
        Logger.flushLogs();
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
        newCase.Category__c = 'Billing-Issue';
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