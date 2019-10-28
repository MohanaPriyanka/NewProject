@isTest
public class ZuoraGenericBatchOperationTest {
    @IsTest
    public static void testActionUpdate(){
        ZuoraAPI.ActionItems actionItem = new ZuoraAPI.ActionItems();
        actionItem.type = 'Account';
        actionItem.objects = new List<ZuoraAPI.ZuoraAccount>();

        ZuoraAPI.ZuoraAccount accountOne = new ZuoraAPI.ZuoraAccount();
        accountOne.Id = '123XXXXXXXXXXXXXXX';
        accountOne.Notes = 'accountOneNotes';
        actionItem.objects.add(accountOne);

        ZuoraAPI.ZuoraAccount accountTwo = new ZuoraAPI.ZuoraAccount();
        accountTwo.Id = '456XXXXXXXXXXXXXXX';
        accountTwo.Notes = 'accountTwoNotes';
        actionItem.objects.add(accountTwo);

        ZuoraAPI.ZuoraAccount accountThree = new ZuoraAPI.ZuoraAccount();
        accountThree.Id = '789XXXXXXXXXXXXXXX';
        accountThree.Notes = 'accountThreeNotes';
        actionItem.objects.add(accountThree);

        Test.startTest();
            ZuoraGenericBatchOperation batchUpdate = new ZuoraGenericBatchOperation(actionItem, ZuoraAPIHelper.actionDMLOperations.UPDATE_action);
            Database.executeBatch(batchUpdate, 50);
        Test.stopTest();

        List<Error_Log__c> afterLogs = [
            SELECT Id, Message__c
            FROM Error_Log__c
            WHERE Class__c = 'ZuoraGenericBatchOperation'
            AND Method__c = 'finish Results'
        ];

        List<ZuoraAPI.SaveResult> saveResults = (List<ZuoraAPI.SaveResult>) System.JSON.deserialize(afterLogs[0].Message__c, List<ZuoraAPI.SaveResult>.class);
        System.assertEquals(3,saveResults.size());
        System.assert(saveResults[0].Success);
        System.assert(saveResults[1].Success);
        System.assert(saveResults[2].Success);
    }

    @IsTest
    public static void testActionInsert(){
        ZuoraAPI.ActionItems actionItem = new ZuoraAPI.ActionItems();
        actionItem.type = 'Account';
        actionItem.objects = new List<ZuoraAPI.ZuoraAccount>();

        ZuoraAPI.ZuoraAccount accountOne = new ZuoraAPI.ZuoraAccount();
        accountOne.Id = '123XXXXXXXXXXXXXXX';
        accountOne.Notes = 'accountOneNotes';
        actionItem.objects.add(accountOne);

        ZuoraAPI.ZuoraAccount accountTwo = new ZuoraAPI.ZuoraAccount();
        accountTwo.Id = '456XXXXXXXXXXXXXXX';
        accountTwo.Notes = 'accountTwoNotes';
        actionItem.objects.add(accountTwo);

        ZuoraAPI.ZuoraAccount accountThree = new ZuoraAPI.ZuoraAccount();
        accountThree.Id = '789XXXXXXXXXXXXXXX';
        accountThree.Notes = 'accountThreeNotes';
        actionItem.objects.add(accountThree);

        Test.startTest();
            ZuoraGenericBatchOperation batchUpdate = new ZuoraGenericBatchOperation(actionItem, ZuoraAPIHelper.actionDMLOperations.INSERT_action);
            Database.executeBatch(batchUpdate, 50);
        Test.stopTest();

        List<Error_Log__c> afterLogs = [
            SELECT Id, Message__c
            FROM Error_Log__c
            WHERE Class__c = 'ZuoraGenericBatchOperation'
            AND Method__c = 'finish Results'
        ];

        List<ZuoraAPI.SaveResult> saveResults = (List<ZuoraAPI.SaveResult>) System.JSON.deserialize(afterLogs[0].Message__c, List<ZuoraAPI.SaveResult>.class);
        System.assertEquals(3,saveResults.size());
        System.assert(saveResults[0].Success);
        System.assert(saveResults[1].Success);
        System.assert(saveResults[2].Success);
    }

    @IsTest
    public static void testActionDelete(){
        ZuoraAPI.ActionItems actionItem = new ZuoraAPI.ActionItems();
        actionItem.type = 'Account';
        actionItem.objects = new List<Object>();
        actionItem.objects.add('123XXXXXXXXXXXXXXX');

        Test.startTest();
            ZuoraGenericBatchOperation batchUpdate = new ZuoraGenericBatchOperation(actionItem, ZuoraAPIHelper.actionDMLOperations.DELETE_action);
            Database.executeBatch(batchUpdate, 50);
        Test.stopTest();

        List<Error_Log__c> afterLogs = [
            SELECT Id, Message__c
            FROM Error_Log__c
            WHERE Class__c = 'ZuoraGenericBatchOperation'
            AND Method__c = 'finish Results'
        ];

        List<ZuoraAPI.SaveResult> saveResults = (List<ZuoraAPI.SaveResult>) System.JSON.deserialize(afterLogs[0].Message__c, List<ZuoraAPI.SaveResult>.class);
        System.assertEquals(1,saveResults.size());
        System.assert(saveResults[0].Success);
    }
}