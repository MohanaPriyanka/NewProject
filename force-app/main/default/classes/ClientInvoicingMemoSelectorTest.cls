@IsTest
public with sharing class ClientInvoicingMemoSelectorTest {
    @testSetup public static void setupTestData(){
        Util.disableAllTriggers();
        Shared_Solar_System__c sssOne = new Shared_Solar_System__c(Name = 'Test SSS One');
        Shared_Solar_System__c sssTwo = new Shared_Solar_System__c(Name = 'Test SSS Two');
        insert new List<Shared_Solar_System__c>{sssOne,sssTwo};

        Utility_Account_Log__c ualOne = new Utility_Account_Log__c(Name = '000124');
        insert ualOne;

        Utility_Account_Subscription__c uasOne = new Utility_Account_Subscription__c(
            Name = '000123',
            Shared_Solar_System__c = sssOne.Id,
            Utility_Account_Log__c = ualOne.Id
        );
        Utility_Account_Subscription__c uasTwo = new Utility_Account_Subscription__c(
            Name = '000123',
            Shared_Solar_System__c = sssTwo.Id,
            Utility_Account_Log__c = ualOne.Id
        );
        insert new List<Utility_Account_Subscription__c>{uasOne,uasTwo};

        Subscription_Order__c orderOne = new Subscription_Order__c(
            Utility_Account_Subscription__c = uasOne.Id,
            Approved_Change_in_Subscription__c = 10
        );
        Subscription_Order__c orderTwo = new Subscription_Order__c(
            Utility_Account_Subscription__c = uasOne.Id,
            Approved_Change_in_Subscription__c = 10
        );
        Subscription_Order__c orderThree = new Subscription_Order__c(
            Utility_Account_Subscription__c = uasTwo.Id,
            Approved_Change_in_Subscription__c = 10
        );
        Subscription_Order__c orderFour = new Subscription_Order__c(
            Utility_Account_Subscription__c = uasTwo.Id,
            Approved_Change_in_Subscription__c = 10
        );
        List<Subscription_Order__c> ordersToInsert = new List<Subscription_Order__c>{
            orderOne, orderTwo, orderThree, orderFour
        };
        insert ordersToInsert;

        List<Client_Invoicing_Memo__c> memosToInsert = new List<Client_Invoicing_Memo__c>();
        for (Subscription_Order__c order : ordersToInsert){
            Client_Invoicing_Memo__c memo = new Client_Invoicing_Memo__c(
                Subscription_Order__c = order.Id,
                Effective_Date__c = System.today(),
                Amount__c = -10,
                Type__c = 'Waived Acquisition / Reacquisition Fee'
            );
            memosToInsert.add(memo);
        }
        insert memosToInsert;
        Util.enableAllTriggers();
    }

    @IsTest
    public static void testGetWaivedFeesBySSS() {
        List<Shared_Solar_System__c> sssList = [
            SELECT Id
            FROM Shared_Solar_System__c
            ORDER BY Name
        ];
        Set<Id> sssIdSet = new Set<Id>();
        for (Shared_Solar_System__c sss : sssList){
            sssIdSet.add(sss.Id);
        }
        System.assert(sssIdSet.size() > 0, 'Expected at least two SSSes in this test but got ' + sssIdSet.size());

        ClientInvoicingMemoSelector selector = new ClientInvoicingMemoSelector();
        MultiMap kwMap = selector.getWaivedFeesBySSS(sssIdSet);

        System.assertEquals(2,kwMap.getValues(sssList[0].Id).size(), 'Expected test setup to create two fee waive CIMs for Test SSS One');
        System.assertEquals(2,kwMap.getValues(sssList[1].Id).size(), 'Expected test setup to create two fee waive CIMs for Test SSS Two');
    }
}