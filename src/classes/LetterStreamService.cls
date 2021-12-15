/**
 * Created by mstackhouse on 7/17/2018.
 * Description: This class communicates with the LetterSteam API in order to automatically initiate letter jobs to
 * send paper bills to customers.
 *
 * Test: LetterStreamServiceTest
 */


public without sharing class LetterStreamService {
    private String csvHeaders = 'UniqueDocId,' +
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

    public Blob getCSV() {
        return Blob.valueOf(csv);
    }

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

    private LetterStreamJob__c parseLetterStreamMessage(XmlStreamReader responseReader) {
        LetterStreamJob__c newJob = new LetterStreamJob__c();
        List<LetterStream_Piece__c> pieces = new List<LetterStream_Piece__c>();
        while (responseReader.hasNext()) {
            if (responseReader.getEventType() == XmlTag.START_ELEMENT &&
                responseReader.getLocalName() == 'doc') {
                responseReader.next();
                pieces.add(parseLetterStreamPiece(responseReader));
            } else if (responseReader.getEventType() == XmlTag.START_ELEMENT) {
                setLetterStreamJobFields(responseReader, newJob);
                responseReader.next();
            } else if (responseReader.getEventType() == XmlTag.END_ELEMENT &&
                responseReader.getLocalName() == 'message') {
                break;
            } else {
                responseReader.next();
            }
        }
        insertJobAndPieces(pieces, newJob);
        return newJob;
    }

    // Since we want to insert Letterstreamjobs independent of user permissions:
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private void insertJobAndPieces(List<LetterStream_Piece__c> pieces, LetterStreamJob__c newJob) {
        if (pieces.isEmpty()) {
            return;
        }
        newJob.Job_Id__c = pieces[0].LetterStream_Job_Id__c;
        insert newJob;
        for (LetterStream_Piece__c piece : pieces) {
            piece.LetterStreamJob__c = newJob.Id;
        }
        insert pieces;
    }

    private void setLetterStreamJobFields(XmlStreamReader responseReader, LetterStreamJob__c newJob) {
        switch on responseReader.getLocalName() {
            when 'details' {
                newJob.Details__c = getNodeText(responseReader);
            } when 'batch' {
                newJob.Batch_Name__c = getNodeText(responseReader);
            } when 'quantity' {
                newJob.Piece_Count__c = Integer.valueOf(getNodeText(responseReader));
            } when 'cost' {
                newJob.Cost__c = Decimal.valueOf(getNodeText(responseReader));
            }
        }
    }

    private String getNodeText(XmlStreamReader xmlReader) {
        xmlReader.next();
        return xmlReader.getText();
    }

    private LetterStream_Piece__c parseLetterStreamPiece(XmlStreamReader docReader) {
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

    public HttpRequest buildRequestWithFile(Blob fileBody, String fileName) {
        List<LetterStream_Settings__c> letterStreamSettings = LetterStream_Settings__c.getall().values();
        String endpoint = letterStreamSettings.get(0).API_Endpoint__c;
        String apiId = letterStreamSettings[0].API_Id__c;
        String apiKey = letterStreamSettings[0].API_Key__c;
        String uniqueId = String.valueOf(Datetime.now().getTime());

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
        header += 'name="multi_file"; filename="'+fileName+'";\nContent-Type: application/zip';
        String footer = '--'+boundary+'--';
        String headerEncoded = EncodingUtil.base64Encode(Blob.valueOf(header+'\r\n\r\n'));
        while(headerEncoded.endsWith('=')) {
            header+=' ';
            headerEncoded = EncodingUtil.base64Encode(Blob.valueOf(header+'\r\n\r\n'));
        }
        String bodyEncoded = EncodingUtil.base64Encode(fileBody);
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
        fileName = fileName.replace('\'', '');
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
        csv += (params.mailType==null?'firstclass':params.mailType) + ',';
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
    @TestVisible
    private String blueWaveAddress() {
        String bwAddress = '';
        BW_Address__c address = [
            SELECT Id, Name, Address_Line_One__c, Address_Line_Two__c, Zip_Code__c, City__c, State__c
            FROM BW_Address__c
        ];
        bwAddress += Util.prepForCSV(address.Name) + ','; //SenderName1
        bwAddress += ','; //SenderName2
        bwAddress += Util.prepForCSV(address.Address_Line_One__c) + ','; //SenderAddr1
        bwAddress += Util.prepForCSV(address.Address_Line_Two__c) + ','; //SenderAddr2
        bwAddress += address.City__c + ','; // SenderCity
        bwAddress += address.State__c + ','; //SenderState
        bwAddress += address.Zip_Code__c + ','; //SenderZip
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
        public String mailType;

        public LetterParameters(ContentMailerService.Param contentMailerParam) {
            this.fileId = contentMailerParam.linkedEntityId;
            this.fileName = contentMailerParam.fileName;
            this.recipientName = contentMailerParam.recipientName;
            this.recipientStreet = contentMailerParam.street;
            this.recipientCity = contentMailerParam.city;
            this.recipientState = contentMailerParam.state;
            this.recipientPostalCode = contentMailerParam.postalCode;
            this.extraInserts = contentMailerParam.extraInserts;
            this.mailType = contentMailerParam.mailType;
        }

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
        @TestVisible
        private String getExtraInserts() {
            if (String.isBlank(extraInserts)) {
                return '';
            } else {
                return extraInserts;
            }
        }
    }

    @TestVisible
    private Map<String, String> letterStreamHeaders(String uniqueId, String apiId, String apiKey) {
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