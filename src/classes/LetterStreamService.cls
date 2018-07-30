/**
 * Created by mstackhouse on 7/17/2018.
 * Description: This class communicates with the LetterSteam API in order to automatically initiate letter jobs to
 * send paper bills to customers.
 *
 * Test: LetterStreamServiceTest
 */


public with sharing class LetterStreamService {
    public Http http = new Http();

    public String csv = 'UniqueDocId,PDFFileName,RecipientName1,RecipientAddr1,RecipientAddr2,RecipientCity,' +
        'RecipientState, RecipientZip,SenderName1,SenderName2,SenderAddr1,SenderAddr2,SenderCity,SenderState,' +
        'SenderZip,PageCount,MailType (firstclass|certified|postcard|flat),CoverSheet (Y|N),Duplex (Y|N),Ink (B|C),' +
        'Paper (W(hite-default)|Y(ellow)|P(ink)|B(lue))';

    public void sendAccountBills() {
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

        // build Package
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
            String fileName = document.LatestPublishedVersion.Title.replace(' ', '_') + '.pdf';
            lettersToSend.addFile(fileName, document.LatestPublishedVersion.VersionData, null);
        }

        Blob csvBlob = Blob.valueOf(csv);

        lettersToSend.addFile('bw_bills.csv', csvBlob, null);

        // end build package
        Blob letterPackage = lettersToSend.getZipArchive();

        String endpoint = 'https://secure.letterstream.com/apis/';

        HttpRequest request = buildRequestWithFile(letterPackage, 'filename.zip', endpoint);
        HttpResponse response = http.send(request);

        Dom.Document responseXML = response.getBodyDocument();
        XmlStreamReader responseReader = new XmlStreamReader(responseXML.toXmlString());

        String responseCode;
        List<Account_Bill__c> sentAccountBills = new List<Account_Bill__c>();
        while(responseReader.hasNext()) {
//            if (responseReader.getEventType() == XmlTag.START_ELEMENT) {
//                System.debug(responseReader.getLocalName() + ' :' + responseReader.getText());
//                if ('code' == responseReader.getLocalName()) {
//                    responseCode = responseReader.getText();
//                }
//                // handle responseCodes
//                if ('doc' == responseReader.getLocalName()) {
//                    String subXML = responseReader.getText();
//                    XmlStreamReader docReader = new XmlStreamReader(subXML);
//                    while(docReader.hasNext()) {
//                        String accountBillId;
//                        String jobId;
//                        Decimal pieceCost;
//                        // response contains an xml doc
//                        if ('id' == docReader.getLocalName()) {
//                            accountBillId = docReader.getText();
//                        } else if ('job' == docReader.getLocalName()) {
//                            jobId = docReader.getText();
//                        } else if ('cost' == docReader.getLocalName()) {
//                            pieceCost = (Decimal) docReader.getText();
//                        }
//                        Account_Bill__c accountBill = new Account_Bill__c(
//                            Id = accountBillId,
//                            LetterStreamJobId = jobId, // proposed new fields
//                            LetterStreamPieceCost = pieceCost, // proposed new fields
//                            Ready_For_Paper_Bill_Queue__c = false,
//                            Added_To_Paper_Bill_Queue__c = true
//                        );
//                        sentAccountBills.add(accountBill);
//                        docReader.next();
//                    }
//                }
//            }
            responseReader.next();
        }
        if (sentAccountBills.size() > 0) {
            update sentAccountBills;
        }
    }

    public HttpRequest buildRequestWithFile(Blob file_body, String file_name, String endpoint){
        // Repost of code  with fix for file corruption issue
        // Orignal code postings and explanations
        // http://enreeco.blogspot.in/2013/01/salesforce-apex-post-mutipartform-data.html
        // http://salesforce.stackexchange.com/questions/24108/post-multipart-without-base64-encoding-the-body
        // Additional changes commented GW: that fix issue with occasional corruption of files
        String boundary = '----------------------------741e90d31eff';
        Map<String, String> letterStreamHeaders = letterStreamHeaders();

        String header = '--'+boundary+'\nContent-Disposition: form-data; ';
        header += ('name="a"' + '\r\n\r\n' + letterStreamHeaders.get('apiId')+ '\r\n');
        header += '--'+boundary+'\nContent-Disposition: form-data; ';
        header += ('name="t"' + '\r\n\r\n' + letterStreamHeaders.get('uniqueId')+ '\r\n');
        header += '--'+boundary+'\nContent-Disposition: form-data; ';
        header += ('name="h"' + '\r\n\r\n' + letterStreamHeaders.get('hashedId')+ '\r\n');
        header += '--'+boundary+'\nContent-Disposition: form-data; ';
        header += 'name="multi_file"; filename="'+file_name+'";\nContent-Type: application/zip';
        String footer = '--'+boundary+'--';
        String headerEncoded = EncodingUtil.base64Encode(Blob.valueOf(header+'\r\n\r\n'));
        while(headerEncoded.endsWith('=')) {
            header+=' ';
            headerEncoded = EncodingUtil.base64Encode(Blob.valueOf(header+'\r\n\r\n'));
        }
        String bodyEncoded = EncodingUtil.base64Encode(file_body);
        Blob bodyBlob = null;
        String last4Bytes = bodyEncoded.substring(bodyEncoded.length()-4,bodyEncoded.length());
        if(last4Bytes.endsWith('==')) {
            last4Bytes = last4Bytes.substring(0,2) + '0K';
            bodyEncoded = bodyEncoded.substring(0,bodyEncoded.length()-4) + last4Bytes;
            String footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
            bodyBlob = EncodingUtil.base64Decode(headerEncoded+bodyEncoded+footerEncoded);
        } else if(last4Bytes.endsWith('=')) {
            last4Bytes = last4Bytes.substring(0,3) + 'N';
            bodyEncoded = bodyEncoded.substring(0,bodyEncoded.length()-4) + last4Bytes;
            footer = '\n' + footer;
            String footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
            bodyBlob = EncodingUtil.base64Decode(headerEncoded+bodyEncoded+footerEncoded);
        } else {
            footer = '\r\n' + footer;
            String footerEncoded = EncodingUtil.base64Encode(Blob.valueOf(footer));
            bodyBlob = EncodingUtil.base64Decode(headerEncoded+bodyEncoded+footerEncoded);
        }

        HttpRequest request = new HttpRequest();

        request.setHeader('Content-Type','multipart/form-data; boundary=' + boundary);
        request.setMethod('POST');
        request.setEndpoint(endpoint);
        request.setBodyAsBlob(bodyBlob);
        return request;
    }

    public void addLetterToCSV(LetterParameters params) {
        // of the headers is important. ex. API won't know PageCount is in column N even with the correct title.
        // PageCount must be in column Q
        // Will need to do some edge case management to make sure the file is built correctly

        csv += '\n';
        csv += (params.fileId + ','); // UniqueDocId
        csv += (params.fileName + ','); // PDFFileName
        csv += (params.recipientName + ','); // RecipientName1
        csv += (','); // RecipientName2
        csv += (params.recipientStreet + ','); // RecipientAddr1
        csv += (','); // RecipientAddr2
        csv += (params.recipientCity + ','); // RecipientCity
        csv += (params.recipientState + ','); // RecipientState
        csv += (params.recipientPostalCode + ','); //RecipientZip
        csv += blueWaveAddress();
        csv += ('2' + ','); // page count
//        csv += (params.pages + ','); // page count
        csv += 'firstclass,'; // mailType
        csv += 'N,'; // coversheet
        csv += 'N,'; // duplex
        csv += 'C,'; // ink
        csv += 'W,'; // Paper
    }

    public String blueWaveAddress() {
        String bwAddress = '';
        BW_Address__c address = [
            SELECT Id, Address_Line_One__c, Address_Line_Two__c
            FROM BW_Address__c
        ];
        bwAddress += 'BlueWave Solar,'; //SenderName1
        bwAddress += ','; //SenderName2
        bwAddress += (address.Address_Line_One__c + ','); //SenderAddr1 (& SenderAddr2 because comma in text)
        bwAddress += 'Boston,'; // SenderCity
        bwAddress += 'MA,'; //SenderState
        bwAddress += '02116,'; //SenderZip
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
            fileId = document.Id;
//            fileId = accountBill.Id;
            fileName = document.LatestPublishedVersion.Title.replace(' ', '_') + '.pdf';
            recipientName = accountBill.Parent_Account__r.Name;
            recipientStreet = accountBill.Parent_Account__r.BillingStreet ;
            recipientCity = accountBill.Parent_Account__r.BillingCity;
            recipientState = accountBill.Parent_Account__r.BillingState;
            recipientPostalCode = accountBill.Parent_Account__r.BillingPostalCode;
            pages = accountBill.Number_of_Pages_in_Template__c.toPlainString();
        }
    }

    public Map<String, String> letterStreamHeaders() {
        String uniqueId = String.valueOf(DateTime.now().getTime());
        Integer uniqueIdLength = uniqueId.length();
        String apiId = '86fjkb92';
        String apiKey = 'wkpv3417e9r2d3qx';
        // per LetterStreamDocs - String to Hash
        String rawHashedId = uniqueId.substring(uniqueIdLength - 6, uniqueIdLength) + apiKey + uniqueId.substring(0, 6);
        // per LetterSteamDocs - Base64Encode string
        Blob rawHashedIdBlob = Blob.valueOf(rawHashedId);
        rawHashedId = EncodingUtil.base64Encode(rawHashedIdBlob);
        // per LetterStreamDocs - MD5 the base64Encoded String
        Blob md5HashedId = Crypto.generateDigest('MD5', Blob.valueOf(rawHashedId));
        String hashedId = EncodingUtil.convertToHex(md5HashedId);

        Map<String, String> headers = new Map<String, String>();

        headers.put('apiId', apiId);
        headers.put('uniqueId', uniqueId);
        headers.put('rawHashedId', rawHashedId);
        headers.put('hashedId', hashedId);

        return headers;
    }
}