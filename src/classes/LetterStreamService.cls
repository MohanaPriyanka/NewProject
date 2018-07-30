/**
 * Created by mstackhouse on 7/17/2018.
 * Description: 
 * Test: 
 */


public with sharing class LetterStreamService {
    public Http http = new Http();

    public String csv = 'UniqueDocId,PDFFileName,RecipientName1,RecipientAddr1,RecipientCity,RecipientState,' +
        'RecipientZip,SenderName1,SenderAddr1,SenderCity,SenderState,SenderZip,PageCount,Ink';

    public void downloadZipFiles() {
        // 1. Query for Account bills that need to be sent
        // 2. Collect ContentVersion files (Account_Bill.Bill_Attach_Version)
        // 3. Create batches of ContentVersion.Size where Total Size < 10 Mb
        //
        // for each batch (Map<ContentVersion ID, Account_Bill__c>, List<ContentVersion>):
        // done - 1. Create Zippex file
        // done - 2. Add ContentVersion.VersionData to zippex
        // done - 3. Zippex.addFile(String fileName, Blob fileData, null)
        // done - 4. Build CSV to LetterStream's specs
        // done - 5. Zippex.addFile(String csvName, Blob fileData, null)
        // 6. POST to LetterStream
        //      - If Failed, we need to re-queue / schedule for another time
        //      - If succeeded, record LetterStream job for Bills.

        // add 'https://secure.letterstream.com/apis/index.php' to remote sites
        Account_Bill__c testAccountBill = [
            SELECT Id, Parent_Account__r.Name, Parent_Account__r.BillingStreet,
                Parent_Account__r.BillingCity, Parent_Account__r.BillingState,
                Parent_Account__r.BillingPostalCode, Number_of_Pages_in_Template__c
            FROM Account_Bill__c
            WHERE Id = 'a1n4C0000009JmJQAU'
        ];

        Map<Id, Account_Bill__c> accountBillsByDocIds = new Map<Id, Account_Bill__c>();
        List<ContentDocument> documents = [
            SELECT Id, LatestPublishedVersion.Title, LatestPublishedVersion.VersionData, ContentSize
            FROM ContentDocument
            WHERE Id = '0694C000000PskrQAC'
            OR Id = '0694C000000Psl1QAC'
        ];

        for (ContentDocument doc : documents) {
            accountBillsByDocIds.put(doc.Id, testAccountBill);
        }

        Zippex lettersToSend = new Zippex();

        for (ContentDocument document : documents) {
            Account_Bill__c accountBill = accountBillsByDocIds.get(document.Id);
            LetterParameters letterParams = new LetterParameters();
            letterParams.generateFromAccountBill(accountBill, document);
            addLetterToCSV(letterParams);
            String fileName = document.LatestPublishedVersion.Title + '.pdf';
            lettersToSend.addFile(fileName, document.LatestPublishedVersion.VersionData, null);
        }

        Blob csvBlob = Blob.valueOf(csv);

        lettersToSend.addFile('summary.csv', csvBlob, null);

        Map<String, String> letterStreamHeaders = letterStreamHeaders();
        String endpoint = 'https://secure.letterstream.com/apis/index.php?';
        endpoint += ('a=' + letterStreamHeaders.get('apiId'));
        endpoint += ('&' + 'h=' + letterStreamHeaders.get('hashedId'));
        endpoint += ('&' + 't=' + letterStreamHeaders.get('uniqueId'));

        HttpRequest request = new HttpRequest();
        request.setEndpoint(endpoint);
        request.setMethod('POST');
        request.setBodyAsBlob(lettersToSend.getZipArchive());

        HttpResponse response = http.send(request);
        System.debug(LoggingLevel.ERROR, response.getBody());

//        System.debug(LoggingLevel.ERROR, 'api id: ' + letterStreamHeaders.get('apiId'));
//        System.debug(LoggingLevel.ERROR, 'unique id: ' + letterStreamHeaders.get('uniqueId'));
//        System.debug(LoggingLevel.ERROR, 'MD5 hashed: ' + letterStreamHeaders.get('hashedId'));
//        System.debug(LoggingLevel.ERROR, 'raw hash: ' + letterStreamHeaders.get('rawHashedId'));
//
//        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
//        attachment.fileName = 'letters.zip';
//        attachment.body = lettersToSend.getZipArchive();
//
//        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
//        mail.setSubject('Sending Zip Files!!');
//        mail.setHtmlBody('Wahoo');
//        mail.setFileAttachments(new List<Messaging.EmailFileAttachment>{attachment});
//        mail.setToAddresses(new List<String>{'mstackhouse@bluewavesolar.com'});
//        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
    }

    public void addLetterToCSV(LetterParameters params) {
        csv += '\n';
        csv += (params.fileId + ',');
        csv += (params.fileName + ',');
        csv += (params.recipientName + ',');
        csv += (params.recipientStreet + ',');
        csv += (params.recipientCity + ',');
        csv += (params.recipientState + ',');
        csv += (params.recipientPostalCode + ',');
        csv += blueWaveAddress();
        csv += (params.pages + ',');
        csv += 'c';
    }

    public String blueWaveAddress() {
        String bwAddress = '';
        BW_Address__c address = [
            SELECT Id, Address_Line_One__c, Address_Line_Two__c
            FROM BW_Address__c
        ];

        bwAddress += (address.Address_Line_One__c + ',');
        bwAddress += 'Boston,';
        bwAddress += 'MA,';
        bwAddress += '02116,';
        return bwAddress;
    }

    public class LetterParameters {
        public String fileId;
        public String fileName;
        public String recipientName;
        public String recipientStreet;
        public String recipientCity;
        public String recipientState;
        public String recipientPostalCode;
        public String pages;

        public void generateFromAccountBill(Account_Bill__c accountBill, ContentDocument document) {
            fileId = accountBill.Id;
            fileName = document.LatestPublishedVersion.Title + '.pdf';
            recipientName = accountBill.Parent_Account__r.Name;
            recipientStreet = accountBill.Parent_Account__r.BillingStreet ;
            recipientCity = accountBill.Parent_Account__r.BillingCity;
            recipientState = accountBill.Parent_Account__r.BillingState;
            recipientPostalCode = accountBill.Parent_Account__r.BillingPostalCode;
            pages = accountBill.Number_of_Pages_in_Template__c.toPlainString();
        }
    }

    private Map<String, String> letterStreamHeaders() {
        String uniqueId = String.valueOf(DateTime.now().getTime());
        Integer uniqueIdLength = uniqueId.length();
        String apiId = '86fjkb92';
        String apiKey = 'wkpv3417e9r2d3qx';
        String hashedId;
        String rawHashedId = uniqueId.substring(uniqueIdLength - 6, uniqueIdLength) + apiKey + uniqueId.substring(0, 6);
        Blob md5HashedId = Crypto.generateDigest('MD5', Blob.valueOf(rawHashedId));
        hashedId = EncodingUtil.base64Encode(md5HashedId);

        Map<String, String> headers = new Map<String, String>();

        headers.put('apiId', apiId);
        headers.put('uniqueId', uniqueId);
        headers.put('hashedId', hashedId);
        headers.put('rawHashedId', rawHashedId);

        return headers;
    }
}