/**
 * Created by mstackhouse on 8/1/2018.
 * Description: Queues collection of accountBills with their pdf versions (ContentDocument) for sending to LetterStream.
 * Called from ScheduledAccountBillLetterStreamMailer which batches collections to avoid APEX heap size limits.
 *
 * Test: 
 */


public class QueueAccountBillLetterStreamMailer implements Queueable {
    public Set<Id> accountBills;
    public Set<Id> documentsIds;

    public QueueAccountBillLetterStreamMailer(Set<Id> accountBills, Set<Id> documentsIds) {
        this.accountBills = accountBills;
        this.documentsIds = documentsIds;
    }

    public void execute(QueueableContext context) {
        sendAccountBills();
    }

    public void sendAccountBills() {
        Map<Id, Account_Bill__c> accountBillsByDocIds = new Map<Id, Account_Bill__c>();
        List<Account_Bill__c> accountBills = [
            SELECT Id, Parent_Account__r.Name, Parent_Account__r.BillingStreet, Parent_Account__r.BillingCity,
                Parent_Account__r.BillingState, Parent_Account__r.BillingPostalCode, Number_of_Pages_in_Template__c,
                Calendar_Month__c, Year__c, Bill_Attach_Document__c
            FROM Account_Bill__c
            WHERE Id IN : accountBills
        ];

        if (accountBills.isEmpty()) {
            return ;
        }

        for (Account_Bill__c accountBill : accountBills) {
            accountBillsByDocIds.put(accountBill.Bill_Attach_Document__c, accountBill);
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
            String fileName = letterParams.fileName;
            lettersToSend.addFile(fileName, document.LatestPublishedVersion.VersionData, null);
        }

        Blob csvBlob = Blob.valueOf(lss.csv);

        String jobName = 'Job_' + DateTime.now().format('MM-dd-yyyy_HH:mm:ss') + '.csv';

        lettersToSend.addFile(jobName, csvBlob, null);

        // end build package
        Blob letterPackage = lettersToSend.getZipArchive();


        HttpRequest request = lss.buildRequestWithFile(letterPackage, 'filename.zip');
        Http http = new Http();
        HttpResponse response;
        String responseXMLString;
        response = http.send(request);
        Dom.Document responseXML = response.getBodyDocument();
        responseXMLString = responseXML.toXmlString();
        // will return null if a job wasn't posted correctly
        LetterStreamJob__c newJob = lss.parseLetterStreamResponse(responseXMLString);

        if (newJob == null) {
            Logger.logNow('QueueAccountBillLetterStreamMailer', 'execute', 'Job post failed - response xml: ' + responseXMLString);
        } else {
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