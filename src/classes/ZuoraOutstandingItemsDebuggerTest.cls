/*************************************************************************************
 * Created By: peteryao on 11/8/19  
 * Description: 
 * Test: 
 *************************************************************************************/
@IsTest
public with sharing class ZuoraOutstandingItemsDebuggerTest {
    @IsTest
    private static void testOutstandingItemsDebugger() {
        List<Error_Log__c> errorLogs = [SELECT Id FROM Error_Log__c];
        System.assertEquals(0, errorLogs.size());

        ZuoraOutstandingItemsDebugger outstandingItemsDebugger = new ZuoraOutstandingItemsDebugger();
        outstandingItemsDebugger.processOutstandingItems(new List<ZuoraOutstandingItemsService.OutstandingItem>(), new ZuoraOutstandingItemsService.ProcessingParameter());

        errorLogs = [SELECT Id FROM Error_Log__c];
        System.assertEquals(2, errorLogs.size());
    }
}