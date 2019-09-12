/**
 * Created by mstackhouse on 7/17/2018.
 * Description: This class communicates with the LetterSteam API in order to automatically initiate letter jobs to
 * send paper bills to customers.
 *
 * Test: LetterStreamServiceTest
 */


public without sharing class LetterStreamService {
    public String csvHeaders = 'UniqueDocId,' +
        'PDFFileName,' +
        'RecipientName1,' +
        'RecipientName2,' +
        'RecipientAddr1,' +
        'RecipientAddr2,' +
        'RecipientCity,' +
        'RecipientState,' +
        'RecipientZip,' +
        'SenderName1,' +
        'SenderName2,' +
        'SenderAddr1,' +
        'SenderAddr2,' +
        'SenderCity,' +
        'SenderState,' +
        'SenderZip,' +
        'PageCount,' +
        'MailType,' +
        'CoverSheet,' +
        'Duplex,' +
        'Ink,' +
        'Paper,' +
        'Return Envelope,' +
        'Affidavit,' +
        'Extra Inserts';

    public String csv = '';

    public LetterStreamJob__c parseLetterStreamResponse(String responseXML) {
        XmlStreamReader responseReader = new XmlStreamReader(responseXML);

        LetterStreamJob__c newJob;
        while (responseReader.hasNext()) {
            if (responseReader.getEventType() == XmlTag.START_ELEMENT
                && 'message' == responseReader.getLocalName()) {
                responseReader.next();
                newJob = parseLetterStreamMessage(responseReader);
            }
            responseReader.next();
        }
        return newJob;
    }

    public LetterStreamJob__c parseLetterStreamMessage(XmlStreamReader responseReader) {
        String responseCode;
        String details;
        String batchName;
        Integer batchQuantity;
        Decimal batchCost;
        LetterStreamJob__c newJob;
        List<LetterStream_Piece__c> pieces = new List<LetterStream_Piece__c>();
        while (responseReader.hasNext()) {
            if (responseReader.getEventType() == XmlTag.START_ELEMENT
                && 'doc' == responseReader.getLocalName()) {
                responseReader.next();
                pieces.add(parseLetterStreamPiece(responseReader));
            } else if (responseReader.getEventType() == XmlTag.START_ELEMENT) {
                if ('code' == responseReader.getLocalName()) {
                    responseCode = getNodeText(responseReader);
                }
                if ('details' == responseReader.getLocalName()) {
                    details = getNodeText(responseReader);
                }
                if ('batch' == responseReader.getLocalName()) {
                    batchName = getNodeText(responseReader);
                }
                if ('quantity' == responseReader.getLocalName()) {
                    batchQuantity = Integer.valueOf(getNodeText(responseReader));
                }
                if ('cost' == responseReader.getLocalName()) {
                    batchCost = Decimal.valueOf(getNodeText(responseReader));
                }
                responseReader.next();
            } else if (responseReader.getEventType() == XmlTag.END_ELEMENT
                && 'message' == responseReader.getLocalName()) {
                break;
            } else if (responseReader.getEventType() == XmlTag.END_ELEMENT) {
                responseReader.next();
            } else {
                responseReader.next();
            }
        }
        if (responseCode != null
            && details != null
            && batchName != null
            && batchQuantity != null
            && batchCost != null
            && pieces.size() > 0) {
            newJob = new LetterStreamJob__c(
                Batch_Name__c = batchName,
                Cost__c = batchCost,
                Details__c = details,
                Piece_Count__c = batchQuantity,
                Job_Id__c = pieces[0].LetterStream_Job_Id__c
            );
            insert newJob;
            for (LetterStream_Piece__c piece : pieces) {
                piece.LetterStreamJob__c = newJob.Id;
            }
            insert pieces;
        }
        return newJob;
    }

    public String getNodeText(XmlStreamReader xmlReader) {
        xmlReader.next();
        return xmlReader.getText();
    }

    public LetterStream_Piece__c parseLetterStreamPiece(XmlStreamReader docReader) {
        String objectId;
        String jobId;
        Decimal pieceCost;
        while (docReader.hasNext()) {
            if (docReader.getEventType() == XmlTag.START_ELEMENT) {
                if ('id' == docReader.getLocalName()) {
                    objectId = getNodeText(docReader);
                } else if ('job' == docReader.getLocalName()) {
                    jobId = getNodeText(docReader);
                } else if ('cost' == docReader.getLocalName()) {
                    pieceCost = Decimal.valueOf(getNodeText(docReader));
                }
                docReader.next();
                docReader.next();
            }
            if (docReader.getEventType() == XmlTag.END_ELEMENT
                && 'doc' == docReader.getLocalName()) {
                docReader.next();
                break;
            } else if (docReader.getEventType() == XmlTag.END_ELEMENT) {
                docReader.next();
            }
        }
        return new LetterStream_Piece__c(
            Object_Id__c = objectId,
            Piece_Cost__c = pieceCost,
            LetterStream_Job_Id__c = jobId
        );
    }

    public HttpRequest buildRequestWithFile(Blob file_body, String file_name){
        List<LetterStream_Settings__c> letterStreamSettings = LetterStream_Settings__c.getall().values();
        String endpoint = letterStreamSettings.get(0).API_Endpoint__c;
        String apiId = letterStreamSettings[0].API_Id__c;
        String apiKey = letterStreamSettings[0].API_Key__c;
        String uniqueId = String.valueOf(DateTime.now().getTime());

        // Repost of code  with fix for file corruption issue
        // Original code postings and explanations
        // http://enreeco.blogspot.in/2013/01/salesforce-apex-post-mutipartform-data.html
        // http://salesforce.stackexchange.com/questions/24108/post-multipart-without-base64-encoding-the-body
        // Additional changes commented GW: that fix issue with occasional corruption of files
        String boundary = '----------------------------741e90d31eff';

        Map<String, String> letterStreamHeaders = letterStreamHeaders(uniqueId, apiId, apiKey);

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
        // Order of the headers and data is important:
        // ex. API won't know PageCount is in column 6 even with the correct title. PageCount must be in column 16
        if (csv == '') {
            csv += csvHeaders;
        }
        csv += '\n';
        csv += (Util.prepForCSV(params.fileId) + ','); // UniqueDocId
        String fileName = Util.prepForCSV(params.fileName);
        // Can't have ' in file names to letterstream
        filename = fileName.replace('\'', '');
        csv += (fileName + ','); // PDFFileName
        csv += (Util.prepForCSV(params.recipientName) + ','); // RecipientName1
        csv += (','); // RecipientName2
        csv += (Util.prepForCSV(params.recipientStreet) + ','); // RecipientAddr1
        csv += (','); // RecipientAddr2
        csv += (Util.prepForCSV(params.recipientCity) + ','); // RecipientCity
        csv += (Util.prepForCSV(params.recipientState) + ','); // RecipientState
        csv += (Util.prepForCSV(params.recipientPostalCode) + ','); //RecipientZip
        csv += blueWaveAddress();
        csv += (Util.prepForCSV(params.getPages()) + ','); // page count
        csv += 'firstclass,'; // mailType
        csv += 'N,'; // coversheet
        csv += 'Y,'; // duplex
        csv += 'C,'; // ink
        csv += 'W,'; // Paper
        csv += 'N,'; // Return Envelope
        csv += 'N,'; // Affidavit
        csv += Util.prepForCSV(params.getExtraInserts()); // Extra Inserts

    }

    // Selecting BW_Address should be open to all users
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public String blueWaveAddress() {
        String bwAddress = '';
        BW_Address__c address = [
            SELECT Id, Address_Line_One__c, Address_Line_Two__c, Zip_Code__c, City__c, State__c
            FROM BW_Address__c
        ];
        bwAddress += 'BlueWave Solar,'; //SenderName1
        bwAddress += ','; //SenderName2
        bwAddress += (address.Address_Line_One__c + ','); //SenderAddr1
        bwAddress += (address.Address_Line_Two__c + ','); //SenderAddr2
        bwAddress += (address.City__c + ','); // SenderCity
        bwAddress += (address.State__c + ','); //SenderState
        bwAddress += (address.Zip_Code__c + ','); //SenderZip
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
        public String extraInserts;

        // Undocumented LetterStream feature to handle the case where we don't have a page count
        // On Wed, Sep 4, 2019 at 12:53 PM MST, David Patterson <production@letterstream.com> wrote:
        // Hi Peter,
        //
        // Me again. We've decided to give you a "Variable Page Count Identifier" that you can push to us instead of a
        // page count number. You'd simply use a "v" (no quotes) in that field instead of a page count.
        //
        // We'll use this flag value to skip the page count verification.
        public String getPages() {
            if (String.isBlank(pages)) {
                return 'v';
            } else {
                return pages;
            }
        }

        // Undocumented feature:
        // Remembered Items can be called and added to API mailings by using the POST argument "extrainserts".
        // Multiple Remembered Items can be called/included by simply using a pipe delimiter (ie 1297|3294).
        public String getExtraInserts() {
            if (String.isBlank(extraInserts)) {
                return '';
            } else {
                return extraInserts;
            }
        }

        public void generateFromAccountBill(Account_Bill__c accountBill, ContentDocument document) {
            fileId = accountBill.Id;
            fileName = document.LatestPublishedVersion.Title.replace(' ', '_') + '.pdf';
            recipientName = accountBill.Parent_Account__r.Name;
            recipientStreet = accountBill.Parent_Account__r.BillingStreet ;
            recipientCity = accountBill.Parent_Account__r.BillingCity;
            recipientState = accountBill.Parent_Account__r.BillingState;
            recipientPostalCode = accountBill.Parent_Account__r.BillingPostalCode;
            pages = String.valueOf(accountBill.Bill_PDF_Page_Count__c);
        }
    }

    public Map<String, String> letterStreamHeaders(String uniqueId, String apiId, String apiKey) {
        Integer uniqueIdLength = uniqueId.length();
        // per LetterStreamDocs - String to Hash
        String rawHashedId = uniqueId.substring(uniqueIdLength - 6, uniqueIdLength) + apiKey + uniqueId.substring(0, 6);
        // per LetterSteamDocs - Base64Encode string
        Blob rawHashedIdBlob = Blob.valueOf(rawHashedId);
        String encodedHashedId = EncodingUtil.base64Encode(rawHashedIdBlob);
        // per LetterStreamDocs - MD5 the base64Encoded String
        Blob md5HashedId = Crypto.generateDigest('MD5', Blob.valueOf(encodedHashedId));
        String hashedId = EncodingUtil.convertToHex(md5HashedId);

        Map<String, String> headers = new Map<String, String>();

        headers.put('apiId', apiId);
        headers.put('uniqueId', uniqueId);
        headers.put('rawHashedId', rawHashedId);
        headers.put('encodedHashedId', encodedHashedId);
        headers.put('hashedId', hashedId);

        return headers;
    }
}