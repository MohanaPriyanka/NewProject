/**
 * Created by mstackhouse on 8/1/2018.
 * Description: Queues collection of accountBills with their pdf versions (ContentDocument) for sending to LetterStream.
 * Called from ScheduledAccountBillLetterStreamMailer which batches collections to avoid APEX heap size limits.
 *
 * Test: 
 */


public with sharing class QueueAccountBillLetterStreamMailer Implements Queueable{
    public Map<Id, Account_Bill__c> accountBillsByDocIds;
    public List<ContentDocument> documents;
    public Integer jobNumber;

    public QueueAccountBillLetterStreamMailer(Map<Id, Account_Bill__c> accountBillsByDocIds,List<ContentDocument> documents, Integer jobNumber) {
        this.accountBillsByDocIds = accountBillsByDocIds;
        this.jobNumber = jobNumber;
        this.documents = documents;
        String checkout;
    }

    public void execute(QueueableContext context) {
        LetterStreamService lss = new LetterStreamService();

        Zippex lettersToSend = new Zippex();

        for (ContentDocument document : documents) {
            Account_Bill__c accountBill = accountBillsByDocIds.get(document.Id);
            LetterStreamService.LetterParameters letterParams = new LetterStreamService.LetterParameters();
            letterParams.generateFromAccountBill(accountBill, document);
            lss.addLetterToCSV(letterParams);
            String fileName = letterParams.fileName;
            lettersToSend.addFile(fileName, document.LatestPublishedVersion.VersionData, null);
        }

        Blob csvBlob = Blob.valueOf(lss.csv);

        String jobName = date.today().format() + '_Job_' + jobNumber;

        lettersToSend.addFile('bw_bills.csv', csvBlob, null);

        // end build package
        Blob letterPackage = lettersToSend.getZipArchive();


        HttpRequest request = lss.buildRequestWithFile(letterPackage, 'filename.zip');
        Http http = new Http();
        HttpResponse response = http.send(request);

        String checkpoint;
        // will return null if a job wasn't posted correctly
        Dom.Document responseXML = response.getBodyDocument();
        LetterStreamJob__c newJob = lss.parseLetterStreamResponse(responseXML.toXmlString());

        if (newJob != null) {
            update markAccountBillsAsMailed(accountBillsByDocIds.values(), newJob);
        }
    }

    public List<Account_Bill__c> markAccountBillsAsMailed(List<Account_Bill__c> accountBills, LetterStreamJob__c newJob) {
        for (Account_Bill__c accountBill : accountBills) {
            accountBill.Ready_For_Paper_Bill_Queue__c = false;
            accountBill.Added_To_Paper_Bill_Queue__c = true;
            accountBill.LetterStreamJob__c = newJob.Id;
        }
        return accountBills;
    }
}