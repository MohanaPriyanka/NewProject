/**
 * Created by mstackhouse on 8/1/2018.
 * Description: Sends collections of accountBills with their pdf versions (ContentDocument) for sending to LetterStream.
 * Called from AccountBillLetterStreamImpl which queues these collections to avoid Apex heap size limits.
 *
 * Test: LetterStreamServiceTests
 */


public without sharing class QueueAccountBillLetterStreamMailer implements Queueable, Database.AllowsCallouts {
    public Set<Id> accountBills;
    public Set<Id> documentsIds;
    public Boolean makeCallout;
    public List<Account_Bill__c> allAccountBills;
    public Set<Id> accountBillsAlreadySent;

    public QueueAccountBillLetterStreamMailer(Params param) {
        this.accountBills = param.accountBills;
        this.documentsIds = param.documentsIds;
        this.makeCallout = param.makeCallout;
        this.allAccountBills = param.allAccountBills;
        this.accountBillsAlreadySent = param.accountBillsAlreadySent;
    }

    public void execute(QueueableContext context) {
        if (makeCallout) {
            try {
                Logger.logLater(
                    'QueueAccountBillLetterStreamMailer',
                    'sendAccountBills',
                    'Queued job ' + context.getJobId() + ' starting with ' + allAccountBills.size() + ' account bills',
                    Logger.FINE
                );
                sendAccountBills();
            } catch (Exception e) {
                Logger.logLater('QueueAccountBillLetterStreamMailer', 'execute', e.getMessage() + '\n' + e.getStackTraceString(), Logger.ERROR);
            } finally {
                Logger.flushLogs();
            }
        }
    }

    public void sendAccountBills() {
        Map<Id, Account_Bill__c> accountBillsByDocIds = new Map<Id, Account_Bill__c>();
        List<Account_Bill__c> accountBills = [
            SELECT Id, Parent_Account__r.Name, Parent_Account__r.BillingStreet, Parent_Account__r.BillingCity,
                Parent_Account__r.BillingState, Parent_Account__r.BillingPostalCode, Bill_PDF_Page_Count__c,
                Calendar_Month__c, Year__c, Bill_Attach_Document__c
            FROM Account_Bill__c
            WHERE Id IN : accountBills
        ];

        if (accountBills.isEmpty()) {
            return ;
        }

        Set<Id> accountBillIds = new Set<Id>();
        for (Account_Bill__c accountBill : accountBills) {
            accountBillsByDocIds.put(accountBill.Bill_Attach_Document__c, accountBill);
            accountBillIds.add(accountBill.Id);
        }

        List<ContentDocument> documents = [
            SELECT Id, LatestPublishedVersion.Title, LatestPublishedVersion.VersionData, ContentSize
            FROM ContentDocument
            WHERE Id IN : documentsIds
        ];

        LetterStreamService lss = new LetterStreamService();

        Logger.logLater('QueueAccountBillLetterStreamMailer', 'sendAccountBills', Util.getHeapLimit('Before making package'), Logger.FINE);

        Zippex lettersToSend = new Zippex();

        for (ContentDocument document : documents) {
            Account_Bill__c accountBill = accountBillsByDocIds.get(document.Id);
            LetterStreamService.LetterParameters letterParams = new LetterStreamService.LetterParameters();
            letterParams.generateFromAccountBill(accountBill, document);
            lss.addLetterToCSV(letterParams);
            String fileName = Util.prepForCSV(letterParams.fileName);
            // Can't have ' in file names to letterstream
            fileName = fileName.replace('\'', '');
            lettersToSend.addFile(fileName, document.LatestPublishedVersion.VersionData, null);
        }

        Blob csvBlob = Blob.valueOf(lss.csv);

        // This is used for the LetterStream batch id, and needs to be unique. Using the timestamp isn't enough since
        // we have jobs running in parallel
        String jobName = 'Job_' +
            Datetime.now().format('MM-dd-yyyy_HH:mm:ss:SSS') + '_' +
            String.valueOf((Integer)(Math.random()*1000)) + '.csv';

        lettersToSend.addFile(jobName, csvBlob, null);

        String heapLimitString = Util.getHeapLimit('Heap');
        Logger.logLater('QueueAccountBillLetterStreamMailer', 'sendAccountBills', heapLimitString, Logger.FINE);
        List<String> heapLimitParts = heapLimitString.split(' ');
        Decimal used = Decimal.valueOf(heapLimitParts[2]);
        Decimal available = Decimal.valueOf(heapLimitParts[4]);
        Decimal percent = 100 * used/available;
        // A 2 MB doc and 5 100k docs gets us to 61% of heap - we'll exit if there's no heap left
        if (percent > 61) {
            throw new Util.BWException('Too much heap used: ' + heapLimitString);
        }

        // end build package
        Blob letterPackage = lettersToSend.getZipArchive();

        Logger.logLater('QueueAccountBillLetterStreamMailer', 'sendAccountBills', Util.getHeapLimit('After zipping'), Logger.FINE);

        HttpRequest request = lss.buildRequestWithFile(letterPackage, 'filename.zip');
        // One minute timeout is conservative - we hit System.CalloutException: Read timed out at 10 seconds
        request.setTimeout(60000);
        HttpResponse response = new Http().send(request);
        Dom.Document responseXML = response.getBodyDocument();
        String responseXMLString = responseXML.toXmlString();
        String message = 'Request: ' + request.getEndpoint() + '\n' +
                'Response: ' + response.getBody();
        Logger.logLater('QueueAccountBillLetterStreamMailer', 'sendAccountBills', message, Logger.FINE);
        handleResponse(responseXMLString, accountBillIds, lss.csv);

        if (allAccountBills != null && accountBillsAlreadySent != null) {
            queueRemainingAccountBills(accountBills);
        }
    }

    @TestVisible
    private static void handleResponse(String responseXMLString, Set<Id> accountBillIds, String csv) {
        LetterStreamService lss = new LetterStreamService();
        // newJob gets inserted within here
        LetterStreamJob__c newJob = lss.parseLetterStreamResponse(responseXMLString);

        if (newJob == null) {
            String message = 'Job post failed for account bills: (' + String.join(new List<Id>(accountBillIds), ',') + ') + \n';
            message += 'Response: \n' + responseXMLString + '\n';
            message += 'CSV: \n' + csv;
            Logger.logLater('QueueAccountBillLetterStreamMailer', 'execute', message, Logger.ERROR);
        } else {
            Util.updateSObjs(markAccountBillsAsMailed(accountBillIds, newJob.Id));
        }
    }

    private void queueRemainingAccountBills(List<Account_Bill__c> accountBills) {
        Boolean enqueueJobBoolean = false;
        for (Account_Bill__c accountBill : allAccountBills) {
            if (!accountBillsAlreadySent.contains(accountBill.Id)) {
                System.enqueueJob(new AccountBillLetterStreamImpl(allAccountBills, accountBillsAlreadySent));
                enqueueJobBoolean = true;
                break;
            }
        }
        if (!enqueueJobBoolean) {
            String message = 'No need to enqueue another job, ' + accountBillsAlreadySent.size() + ' already sent';
            Logger.logLater('QueueAccountBillLetterStreamMailer', 'sendAccountBills', message, Logger.FINE);
        }
    }

    public static List<Account_Bill__c> markAccountBillsAsMailed(Set<Id> accountBillIds, Id newJobId) {
        List<Account_Bill__c> accountBills = [
            SELECT Id
            FROM Account_Bill__c
            WHERE Id IN : accountBillIds
        ];
        for (Account_Bill__c accountBill : accountBills) {
            accountBill.Ready_For_Paper_Bill_Queue__c = false;
            accountBill.Added_To_Paper_Bill_Queue__c = true;
            accountBill.LetterStreamJob__c = newJobId;
        }
        return accountBills;
    }

    public class Params {
        public Set<Id> accountBills;
        public Set<Id> documentsIds;
        public Boolean makeCallout;
        public List<Account_Bill__c> allAccountBills;
        public Set<Id> accountBillsAlreadySent;
    }
}