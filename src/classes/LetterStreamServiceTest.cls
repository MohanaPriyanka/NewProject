/**
 * Created by mstackhouse on 7/17/2018.
 * Description: Used to test LetterStreamService Methods
 */

@IsTest
public with sharing class LetterStreamServiceTest {
    @IsTest
    public static void testResponseParser() {
        String exampleResponse = '<?xml version="1.0" encoding="UTF-8"?>' +
            '<messages id="86fjkb92">' +
            '<message type="info">' +
            '<code>-100</code>' +
            '<details>Success</details>' +
            '<batch>bw_bills</batch>' +
            '<quantity>2</quantity>' +
            '<cost>2.82</cost>' +
            '<doc><id>0694C000000PskrQAC</id><job>1646754</job><cost>1.41</cost></doc>' +
            '<doc><id>0694C000000Psl1QAC</id><job>1646754</job><cost>1.41</cost></doc>' +
            '<doc><id>0694C000000Psm1QAC</id><job>1646754</job><cost>1.41</cost></doc>' +
            '<doc><id>0694C000000Psx1QAC</id><job>1646754</job><cost>1.41</cost></doc>' +
            '</message>' +
            '</messages>';

        LetterStreamService lss = new LetterStreamService();

        LetterStreamJob__c newJob = lss.parseLetterStreamResponse(exampleResponse);

        List<LetterStreamJob__c> jobs = [
            SELECT Id, Batch_Name__c, Cost__c, Details__c, Job_Id__c, Piece_Count__c
            FROM LetterStreamJob__c
        ];

        System.assertEquals(newJob.Id, jobs[0].Id);
        System.assertEquals(1, jobs.size());
        System.assertEquals('Success', jobs[0].Details__c);
        System.assertEquals('bw_bills', jobs[0].Batch_Name__c);
        System.assertEquals(2, jobs[0].Piece_Count__c);
        System.assertEquals(2.82, jobs[0].Cost__c);
        System.assertEquals('1646754', jobs[0].Job_Id__c);

        List<LetterStream_Piece__c> pieces = [
            SELECT Id, LetterStreamJob__c, Object_Id__c, Piece_Cost__c
            FROM LetterStream_Piece__c
        ];

        System.assertEquals(4, pieces.size());
        System.assertEquals('0694C000000PskrQAC', pieces[0].Object_Id__c);
        for (LetterStream_Piece__c piece : pieces) {
            System.assertEquals(jobs[0].Id, piece.LetterStreamJob__c);
            System.assertEquals(1.41, piece.Piece_Cost__c);

        }
    }

    @IsTest
    public static void testResponseParserMixedOrder() {
        String exampleResponse = '<?xml version="1.0" encoding="UTF-8"?>' +
            '<messages id="86fjkb92">' +
            '<message type="info">' +
            '<details>Success</details>' +
            '<code>-100</code>' +
            '<doc><id>0694C000000PskrQAC</id><job>1646754</job><cost>1.41</cost></doc>' +
            '<batch>bw_bills</batch>' +
            '<quantity>2</quantity>' +
            '<doc><id>0694C000000Psl1QAC</id><job>1646754</job><cost>1.41</cost></doc>' +
            '<doc><id>0694C000000Psm1QAC</id><job>1646754</job><cost>1.41</cost></doc>' +
            '<doc><id>0694C000000Psx1QAC</id><job>1646754</job><cost>1.41</cost></doc>' +
            '<cost>2.82</cost>' +
            '</message>' +
            '</messages>';

        LetterStreamService lss = new LetterStreamService();

        LetterStreamJob__c newJob = lss.parseLetterStreamResponse(exampleResponse);

        List<LetterStreamJob__c> jobs = [
            SELECT Id, Batch_Name__c, Cost__c, Details__c, Job_Id__c, Piece_Count__c
            FROM LetterStreamJob__c
        ];

        System.assertEquals(newJob.Id, jobs[0].Id);
        System.assertEquals(1, jobs.size());
        System.assertEquals('Success', jobs[0].Details__c);
        System.assertEquals('bw_bills', jobs[0].Batch_Name__c);
        System.assertEquals(2, jobs[0].Piece_Count__c);
        System.assertEquals(2.82, jobs[0].Cost__c);
        System.assertEquals('1646754', jobs[0].Job_Id__c);

        List<LetterStream_Piece__c> pieces = [
            SELECT Id, LetterStreamJob__c, Object_Id__c, Piece_Cost__c
            FROM LetterStream_Piece__c
        ];

        System.assertEquals(4, pieces.size());
        System.assertEquals('0694C000000PskrQAC', pieces[0].Object_Id__c);
        for (LetterStream_Piece__c piece : pieces) {
            System.assertEquals(jobs[0].Id, piece.LetterStreamJob__c);
            System.assertEquals(1.41, piece.Piece_Cost__c);

        }
    }

    @IsTest
    public static void testFailedResponseParser() {
        String exampleResponse = '<?xml version="1.0" encoding="UTF-8"?>' +
            '<messages id="86fjkb92">' +
            '<message type="info">' +
            '<code>-900</code>' +
            '<details>Failed: Job name must be 8 to 20 characters (a-zA-Z0-9_-)</details>' +
            '</message>' +
            '</messages>';

        LetterStreamService lss = new LetterStreamService();

        LetterStreamJob__c newJob = lss.parseLetterStreamResponse(exampleResponse);

        System.assertEquals(null, newJob);
    }

    @IsTest
    public static void testBWAddress() {
        TestFactory.insertBWAddress();
        // BW Address info
        String bwAddress = 'BlueWave Solar,'; // SenderName1
        bwAddress += ','; //SenderName2 - blank
        bwAddress += '137 Newbury Street,'; //SenderAddr1
        bwAddress += '4th Floor,'; //SenderAddr2
        bwAddress += 'Boston,'; //SenderCity
        bwAddress += 'MA,'; //SenderState
        bwAddress += '02116,'; //SenderZip

        LetterStreamService lss = new LetterStreamService();

        String bwAddressUnderTest = lss.blueWaveAddress();

        System.assertEquals(bwAddress, bwAddressUnderTest);
    }

    @IsTest
    public static void testLetterStreamHeaders() {
        // Per LetterStream docs for authorization
        String uniqueId = '1234567890987654321';
        String apiId = 'BlueWave';
        String apiKey = 'BlueWaveAPIKEY';

        LetterStreamService lss = new LetterStreamService();
        Map<String, String> headers = lss.letterStreamHeaders(uniqueId, apiId, apiKey);


        // Per LetterStream docs for authorization
        // build string format: last 6 of uniqueId + apiKey + first 6 of uniqueId
        String expectedRawHashedId = '654321BlueWaveAPIKEY123456';
        // base64 encode string
        String expectedEncodedHashedId = EncodingUtil.base64Encode(Blob.valueOf(expectedRawHashedId));
        // MD5 encrypt base64 string and convertToHex (php format)
        String expectedHashedId = EncodingUtil.convertToHex(Crypto.generateDigest('MD5', Blob.valueOf(expectedEncodedHashedId)));

        System.assertEquals(apiId, headers.get('apiId'));
        System.assertEquals(uniqueId, headers.get('uniqueId'));
        System.assertEquals(expectedRawHashedId, headers.get('rawHashedId'));
        System.assertEquals(expectedEncodedHashedId, headers.get('encodedHashedId'));
        System.assertEquals(expectedHashedId, headers.get('hashedId'));
    }

    @IsTest
    public static void testLetterStreamRequest() {
        LetterStream_Settings__c ls = new LetterStream_Settings__c(
            Name = 'Global',
            API_Endpoint__c = 'https://secure.letterstream.com/apis/',
            API_Id__c = 'bluewave',
            API_Key__c = 'bluewaveAPIKey'
        );
        insert ls;

        LetterStreamService lss = new LetterStreamService();
        Blob testFile = Blob.valueOf('test file');

        HttpRequest testRequest = lss.buildRequestWithFile(testFile, 'test_file.zip');

        System.assertEquals('https://secure.letterstream.com/apis/', testRequest.getEndpoint());

        String contentType = 'multipart/form-data; boundary=----------------------------741e90d31eff';
        System.assertEquals(contentType, testRequest.getHeader('Content-Type'));
        System.assertEquals('POST', testRequest.getMethod());
    }

    @IsTest
    public static void testGetPages() {
        LetterStreamService.LetterParameters parameters = new LetterStreamService.LetterParameters();
        System.assertEquals('v', parameters.getPages());
        parameters.pages = '2';
        System.assertEquals('2', parameters.getPages());
    }

    @IsTest
    public static void testExtraInserts() {
        LetterStreamService.LetterParameters parameters = new LetterStreamService.LetterParameters();
        System.assertEquals('', parameters.getExtraInserts());
        parameters.extraInserts = '23423|12345';
        System.assertEquals('23423|12345', parameters.getExtraInserts());
    }
}