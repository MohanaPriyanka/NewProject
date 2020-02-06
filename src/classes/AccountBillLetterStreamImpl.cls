/**
 * Created by mstackhouse on 8/1/2018.
 * Description: Implementation to send account bills that need to be mailed to customers. We send PDFs of the account
 * bills to LetterStream, who packages and mails the hard copies. Calls QueueAccountBillLetterStreamMailer which makes
 * the HttpRequest to the endpoint.
 *
 * This is the main class that starts sending documents to letterstream. We need to queue in order to compress files
 * without hitting heap size limits. Because we can only queue 50 jobs before hitting the queueable limit, we chain jobs
 * one at a time (a chained job can only start a single child job). To improve performance, we have a batch job start
 * multiple chained chained jobs at the same time.
 *
 * Account Bill Service starts AccountBillLetterStreamImpl batch with Account Bills to send. For example, for 400 bills:
 *   - Batch 1 (100 Account Bills) ->
 *         Queueable Job 1 (10 bills) -> AccountBillLetterStreamImpl ->
 *         Queueable Job 5 (10 bills) ->  AccountBillLetterStreamImpl -> etc
 *   - Batch 2 (100 Account Bills)
 *         Queueable Job 2 (10 bills) -> AccountBillLetterStreamImpl ->
 *         Queueable Job 6 (10 bills) ->  AccountBillLetterStreamImpl -> etc
 *   - Batch 3 (100 Account Bills)
 *         Queueable Job 3 (10 bills) -> AccountBillLetterStreamImpl ->
 *         Queueable Job 7 (10 bills) ->  AccountBillLetterStreamImpl -> etc
 *   - Batch 4 (100 Account Bills)
 *         Queueable Job 4 (10 bills) -> AccountBillLetterStreamImpl ->
 *         Queueable Job 8 (10 bills) ->  AccountBillLetterStreamImpl -> etc
 *
 *  When the batch is finished, the first four queueable jobs would have been scheduled, and they'll until all the bills
 *  have been sent
 *
 *  We need to take care to avoid hitting a limit exception (which can't be caught). If we do, any remaining bills
 *  wouldn't been queued.
 *
 * Test: LetterStreamServiceTest
 */


public without sharing class AccountBillLetterStreamImpl implements Queueable, Database.Batchable<Account_Bill__c> {
    // Max size is 12Mb, but need to give buffer for csv file. So, 10 Mb * 1000 Kb/Mb * 1000 b/Kb
    public Integer maxPackageSize = 1*1000*1000;
    public Boolean makeCallout = true;
    public CaseFactory caseFactory = new CaseFactory();
    public List<Account_Bill__c> accountBillsToSend;
    public Set<Id> accountBillsAlreadySent;

    public AccountBillLetterStreamImpl() {
        accountBillsToSend = new List<Account_Bill__c>();
        accountBillsAlreadySent = new Set<Id>();
    }

    public AccountBillLetterStreamImpl(List<Account_Bill__c> accountBillsToSend, Set<Id> accountBillsAlreadySent) {
        this.accountBillsToSend = accountBillsToSend;
        this.accountBillsAlreadySent = accountBillsAlreadySent;
    }

    // Allows us to continue queueing account bills, and relies on setting docsAlreadySent before execution
    public void execute(QueueableContext context) {
        queueAccountBillsToSend(accountBillsToSend);
    }

    public Iterable<Account_Bill__c> start(Database.BatchableContext context) {
        return accountBillsToSend;
    }

    public void execute(Database.BatchableContext context, List<Account_Bill__c> scope) {
        queueAccountBillsToSend(scope);
    }

    public void finish(Database.BatchableContext context) {
    }

    public void queueAccountBillsToSend(List<Account_Bill__c> accountBills) {
        Map<Id, Account_Bill__c> accountBillsByDocIds = new Map<Id, Account_Bill__c>();
        Set<Id> docIds = new Set<Id>();
        List<Case> newCases = new List<Case>();

        Logger.logLater(
            'AccountBillLetterStreamImpl',
            'queueAccountBillsToSend',
            'Starting to queue ' + accountBills.size() + ' Account Bills with ' +
                accountBillsAlreadySent.size() + ' Account Bills already sent',
            Logger.INFO
        );
        if (accountBills.isEmpty()) {
            Logger.flushLogs();
            return;
        }

        for (Account_Bill__c accountBill : accountBills) {
            if (!accountBillsAlreadySent.contains(accountBill.Id)) {
                if (checkBillAccountAddressValid(accountBill)) {
                    docIds.add(accountBill.Bill_Attach_Document__c);
                    accountBillsByDocIds.put(accountBill.Bill_Attach_Document__c, accountBill);
                } else {
                    newCases.add(createCaseForInvalidAddress(accountBill));
                }
            }
        }
        if (!newCases.isEmpty()) {
            insert newCases;
        }

        List<ContentDocument> documents = [
            SELECT Id, ContentSize
            FROM ContentDocument
            WHERE Id IN : docIds
            ORDER BY ContentSize DESC
        ];

        Logger.logLater(
            'AccountBillLetterStreamImpl',
            'queueAccountBillsToSend',
            'Found ' + accountBillsByDocIds.size() + ' Account Bills to queue',
            Logger.INFO
        );

        Decimal packageSize = 0;
        Set<Id> packageAccountBills = new Set<Id>();
        Set<Id> packageContentDocuments = new Set<Id>();

        // We hit the max heap size if we trying to send too many documents at the same time (when compressing)
        for (ContentDocument doc : documents) {
            packageSize += doc.ContentSize;
            Id accountBillId = accountBillsByDocIds.get(doc.Id).Id;
            packageAccountBills.add(accountBillId);
            packageContentDocuments.add(doc.Id);
            accountBillsAlreadySent.add(accountBillId);
            if (packageSize >= maxPackageSize) {
                break;
            }
        }

        if (!packageAccountBills.isEmpty() && !packageContentDocuments.isEmpty()) {
            QueueAccountBillLetterStreamMailer.Params params = new QueueAccountBillLetterStreamMailer.Params();
            params.accountBills = packageAccountBills;
            params.documentsIds = packageContentDocuments;
            params.makeCallout = makeCallout;
            params.allAccountBills = accountBillsByDocIds.values();
            params.accountBillsAlreadySent = accountBillsAlreadySent;
            Id jobId = System.enqueueJob(new QueueAccountBillLetterStreamMailer(params));

            Decimal sizeInKB = (packageSize/1000).setScale(0);
            String message = 'Package of ' + sizeInKB + ' kB with ' + packageContentDocuments.size() + ' documents queued for letter stream. ' + 'JobID: ' + jobId;
            Logger.logLater('AccountBillLetterStreamImpl', 'queueAccountBillsToSend', message, Logger.INFO);
        }
        Logger.flushLogs();
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