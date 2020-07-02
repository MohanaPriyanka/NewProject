@IsTest
public with sharing class ClientInvoicingMemoSelectorTest {
    @testSetup public static void setupTestData(){
        UASSelectorTest.testSetup();

        List<Subscription_Order__c> subOrders = [
            SELECT Id, Utility_Account_Subscription__c
            FROM Subscription_Order__c
            ORDER BY Utility_Account_Subscription__r.Name
        ];

        List<Client_Invoicing_Memo__c> memosToInsert = new List<Client_Invoicing_Memo__c>();

        for (Subscription_Order__c order : subOrders){
            Client_Invoicing_Memo__c memo = new Client_Invoicing_Memo__c(
                Subscription_Order__c = order.Id,
                Effective_Date__c = System.today(),
                Amount__c = 10
            );
            memosToInsert.add(memo);
        }

        insert memosToInsert;
    }

    @IsTest
    public static void testGetWaivedFeesBySSS() {
        List<Subscription_Order__c> subOrders = [
            SELECT Id, Utility_Account_Subscription__c, Utility_Account_Subscription__r.Shared_Solar_System__c, Approved_Change_in_Subscription__c
            FROM Subscription_Order__c
            WHERE Utility_Account_Subscription__r.Shared_Solar_System__c != null
        ];
        System.assert(subOrders.size() > 0);

        Set<Id> sssIdSet = new Set<Id>();

        for (Subscription_Order__c order : subOrders){
            sssIdSet.add(order.Utility_Account_Subscription__r.Shared_Solar_System__c);
        }
        System.assert(sssIdSet.size() > 0);

        List<Id> sssList = new List<Id>(sssIdSet);

        ClientInvoicingMemoSelector selector = new ClientInvoicingMemoSelector();
        Map<Id,Decimal> kwMap = selector.getWaivedFeesBySSS(sssIdSet);

        System.assert(kwMap.get(sssList[0]) > 0);
        System.assert(kwMap.get(sssList[1]) > 0);
        System.assert(kwMap.get(sssList[2]) > 0);
        System.assert(kwMap.get(sssList[3]) > 0);
    }
}