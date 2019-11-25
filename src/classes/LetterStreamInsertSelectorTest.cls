/**
 * Created by PeterYao on 11/19/2019.
 */
@IsTest
public with sharing class LetterStreamInsertSelectorTest {
    @IsTest
    private static void testGetInsertMap() {
        List<LetterStream_Insert__c> letterStreamInserts = new List<LetterStream_Insert__c>();
        letterStreamInserts.add(new LetterStream_Insert__c(
            Utility__c = null,
            Anchor__c = false,
            Client_Brand_Key__c = 'AmpRed',
            Product_Program__c = null,
            Active__c = true
        ));
        letterStreamInserts.add(new LetterStream_Insert__c(
            Utility__c = null,
            Anchor__c = true,
            Client_Brand_Key__c = 'AmpRed',
            Product_Program__c = null,
            Active__c = true
        ));
        letterStreamInserts.add(new LetterStream_Insert__c(
            Utility__c = null,
            Anchor__c = true,
            Client_Brand_Key__c = 'AmpRed',
            Product_Program__c = null,
            Active__c = false
        ));
        insert letterStreamInserts;

        LetterStreamInsertSelector letterStreamInsertSelector = new LetterStreamInsertSelector();

        Map<String, LetterStream_Insert__c> insertMap = letterStreamInsertSelector.getInsertMap();
        System.assertEquals(2, insertMap.values().size());
        System.assertEquals(null, Logger.logs);
        LetterStream_Insert__c letterStreamInsert = new LetterStream_Insert__c(
            Utility__c = null,
            Anchor__c = true,
            Client_Brand_Key__c = 'AmpRed',
            Product_Program__c = null,
            Active__c = true
        );
        insert letterStreamInsert;
        insertMap = letterStreamInsertSelector.getInsertMap();
        System.assertEquals(2, insertMap.values().size());
        System.assertEquals(1, Logger.logs.size());
        System.assert(Logger.logs.values()[0][0].message.contains('Duplicate inserts found'));



    }
}