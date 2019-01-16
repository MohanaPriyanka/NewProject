/**
 * Created by mstackhouse on 8/1/2018.
 * Description: Queues collection of accountBills with their pdf versions (ContentDocument) for sending to LetterStream.
 * Called from ScheduledAccountBillLetterStreamMailer which batches collections to avoid APEX heap size limits.
 *
 * Test: LetterStreamServiceTests
 */


public without sharing class QueueAccountBillLetterStreamMailer implements Queueable, Database.AllowsCallouts {
    public Set<Id> accountBills;
    public Set<Id> documentsIds;
    public Boolean makeCallout;
    public Integer jobNumber;

    public QueueAccountBillLetterStreamMailer(Set<Id> accountBills, Set<Id> documentsIds, Boolean makeCallout, Integer jobNumber) {
        this.accountBills = accountBills;
        this.documentsIds = documentsIds;
        this.makeCallout = makeCallout;
        this.jobNumber = jobNumber;
    }

    public void execute(QueueableContext context) {
        if (makeCallout) {
            sendAccountBills();
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

        Zippex lettersToSend = new Zippex();

        for (ContentDocument document : documents) {
            Account_Bill__c accountBill = accountBillsByDocIds.get(document.Id);
            LetterStreamService.LetterParameters letterParams = new LetterStreamService.LetterParameters();
            letterParams.generateFromAccountBill(accountBill, document);
            lss.addLetterToCSV(letterParams);
            String fileName = Util.prepForCSV(letterParams.fileName);
            // Can't have ' in file names to letterstream
            filename = fileName.replace('\'', '');
            lettersToSend.addFile(fileName, document.LatestPublishedVersion.VersionData, null);
        }

        Blob csvBlob = Blob.valueOf(lss.csv);

        String jobName = 'Job_' +  + '_' + DateTime.now().format('MM-dd-yyyy_HH:mm:ss:SSS') + '_' + jobNumber + '.csv';

        lettersToSend.addFile(jobName, csvBlob, null);

        // end build package
        Blob letterPackage = lettersToSend.getZipArchive();


        HttpRequest request = lss.buildRequestWithFile(letterPackage, 'filename.zip');
        Http http = new Http();
        HttpResponse response;
        response = http.send(request);
        Dom.Document responseXML = response.getBodyDocument();
        String responseXMLString = responseXML.toXmlString();
        System.enqueueJob(
            new QueueAccountBillLetterStreamMailer.QueueHandleResponse(responseXMLString, accountBillIds, lss.csv, accountBillsByDocIds, makeCallout)
        );
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

    public class QueueHandleResponse implements Queueable {
        public String responseXMLString;
        public Set<Id> accountBillIds;
        public String csv;
        public Map<Id, Account_Bill__c> accountBillsByDocIds;
        public Boolean makeCallout;

        public QueueHandleResponse(String responseXMLString, Set<Id> accountBillIds, String csv, Map<Id, Account_Bill__c> accountBillsByDocIds, Boolean makeCallout) {
            this.responseXMLString = responseXMLString;
            this.accountBillIds = accountBillIds;
            this.csv = csv;
            this.accountBillsByDocIds = accountBillsByDocIds;
            this.makeCallout = makeCallout;
        }

        public void execute(QueueableContext contact) {
            handleResponse();
        }

        public void handleResponse() {
            LetterStreamService lss = new LetterStreamService();
            // newJob gets inserted within here
            LetterStreamJob__c newJob = lss.parseLetterStreamResponse(responseXMLString);

            if (newJob == null && accountBillIds.size() > 1) {
                retryJobs();
            } else if (newJob == null) {
                Logger.logNow('QueueAccountBillLetterStreamMailer', 'execute', 'Job post failed - response xml: ' + responseXMLString + '\n CSV: ' + csv);
            } else {
                update markAccountBillsAsMailed(accountBillIds, newJob.Id);

                ContentVersion file = new ContentVersion();
                file.VersionData = Blob.valueOf(responseXMLString);
                file.Title = 'response.xml';
                file.FirstPublishLocationId = newJob.Id;
                file.pathOnClient = '/response.xml';
                insert file;
            }
        }

        public void retryJobs() {
            Integer jobNumber = 1;
            for (Id documentId : accountBillsByDocIds.keySet()) {
                Id accountId = accountBillsByDocIds.get(documentId).Id;
                Set<Id> accountIds = new Set<Id>{accountId};
                Set<Id> documentIds = new Set<Id>{documentId};
                System.enqueueJob(new QueueAccountBillLetterStreamMailer(accountIds, documentIds, makeCallout, jobNumber));
            }
        }
    }
}