/**
 * Created by mstackhouse on 7/17/2018.
 * Description: 
 * Test: 
 */

@isTest
public with sharing class LetterStreamServiceTest {
    @isTest public static void testResponseParser() {
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

        XmlStreamReader response = new XmlStreamReader(exampleResponse);

        LetterStreamService lss = new LetterStreamService();

        lss.parseLetterStreamResponse(response);

        List<LetterStreamJob__c> jobs = [
            SELECT Id, Batch_Name__c, Cost__c, Details__c, Job_Id__c, Piece_Count__c
            FROM LetterStreamJob__c
        ];

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
}