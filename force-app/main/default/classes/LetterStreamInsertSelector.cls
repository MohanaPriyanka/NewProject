/**
 * Created by PeterYao on 11/19/2019.
 * Tested by: LetterStreamInsertSelectorTest
 */

public with sharing class LetterStreamInsertSelector {
    public Map<String, LetterStream_Insert__c> getInsertMap() {
        Map<String, LetterStream_Insert__c> insertMap = new Map<String, LetterStream_Insert__c>();
        for (LetterStream_Insert__c letterStreamInsert : getAll()) {
            String insertKey = LetterStreamInsertSelector.getInsertKey(letterStreamInsert);
            if (insertMap.containsKey(insertKey)) {
                Logger.logLater(
                    'LetterStreamInsertSelector',
                    'getInsertMap',
                    'Duplicate inserts found for insert: ' + letterStreamInsert + '\n' + JSON.serialize(insertMap),
                    Logger.ERROR);
            } else {
                insertMap.put(insertKey, letterStreamInsert);
            }
        }
        return insertMap;
    }

    public List<LetterStream_Insert__c> getAll() {
        return [
            SELECT Id, Anchor__c, Client_Brand_Key__c, Product_Program__c, Utility__c, Active__c
            FROM LetterStream_Insert__c
            WHERE Active__c = TRUE
        ];
    }

    public static String getInvoiceKey(ZuoraInvoiceAsyncService.DecoratedInvoice decoratedInvoice) {
        return decoratedInvoice.anchor + '~' +
            decoratedInvoice.clientBrandKey + '~' +
            decoratedInvoice.program + '~' +
            decoratedInvoice.utilityId;
    }

    public static String getInsertKey(LetterStream_Insert__c letterStreamInsert) {
        return letterStreamInsert.Anchor__c + '~' +
            letterStreamInsert.Client_Brand_Key__c + '~' +
            letterStreamInsert.Product_Program__c + '~' +
            letterStreamInsert.Utility__c;
    }
}