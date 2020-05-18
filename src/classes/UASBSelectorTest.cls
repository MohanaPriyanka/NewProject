@isTest
public class UASBSelectorTest {
    @testSetup public static void setupTestData() {
        // Disable triggers so that we don't have to populate client account, sss, entity when inserting UASes and UASBs:
        Util.disableTrigger('Disable_Client_Objects_Trigger__c');
        Util.disableTrigger('Disable_UASBTrigger__c');

        String firstName1 = 'Ashley';
        String lastName1 = 'Smith';
        String accountName1 = firstName1 + ' ' + lastname1;

        Account propAccount1 = new Account(
            Name = accountName1);
        insert propAccount1;

        Utility_Account_Log__c ualog1 = new Utility_Account_Log__c(
            Name = '0000234',
            Account__c = propAccount1.Id,
            Annual_Cost_of_Electricity__c = 10000,
            Name_on_Account__c = accountName1);
        insert ualog1;

        Opportunity opportunity1 = new Opportunity(
            Name = accountName1,
            AccountId = propAccount1.Id,
            StageName = 'Complete',
            Customer_Group__c = 'Residential',
            CloseDate = System.today());
        insert opportunity1;

        Utility_Account_Subscription__c uas1 = new Utility_Account_Subscription__c(
            Name = '0000234',
            Utility_Account_Log__c = ualog1.Id,
            Opportunity__c = opportunity1.Id,
            Next_Schedule_Z_Status__c = 'Active Subscription',
            Calculated_Annual_Cost_of_Electricity__c = 1400,
            Subscribed_Annual_Cost_of_Electricity__c = 1400
        );
        insert uas1;
    }

    @isTest public static void testGetUASBsFromExternalIds() {
        List<Utility_Account_Subscription__c> uasList = [
            SELECT Id, Opportunity__r.AccountId
            FROM Utility_Account_Subscription__c
        ];

        UASB__c billOne = new UASB__c(
            Account__c = uasList[0].Opportunity__r.AccountId,
            Zuora_Id__c = 'bbb1230005',
            Utility_Account_Subscription__c = uasList[0].Id
        );
        UASB__c billTwo = new UASB__c(
            Account__c = uasList[0].Opportunity__r.AccountId,
            Zuora_Id__c = 'bbb1230001',
            Utility_Account_Subscription__c = uasList[0].Id
        );
        UASB__c billThree = new UASB__c(
            Account__c = uasList[0].Opportunity__r.AccountId,
            Zuora_Id__c = 'bbb1230001',
            Utility_Account_Subscription__c = uasList[0].Id
        );
        insert new List<UASB__c>{billOne, billTwo, billThree};

        UASBSelector selector = new UASBSelector();
        Map<String,List<UASB__c>> billMap = selector.getUASBMapFromExternalIds(new Set<String>{
            'bbb1230001', 'bbb1230004', 'bbb1230005'
        });
        List<UASB__c> billListOne = billMap.get('bbb1230001');
        List<UASB__c> billListTwo = billMap.get('bbb1230005');

        System.assertEquals(2,billListOne.size());
        System.assertEquals(1,billListTwo.size());
    }

    @isTest public static void testGetUnservicedWithoutProductionDetail(){
        List<Utility_Account_Subscription__c> uasList = [
            SELECT Id, Opportunity__r.AccountId
            FROM Utility_Account_Subscription__c
        ];

        // On insert, Ready_for_Production_Detail__c is set to true if Externally Serviced = true
        Util.enableTrigger('Disable_UASBTrigger__c');

        UASB__c billOne = new UASB__c(
            Account__c = uasList[0].Opportunity__r.AccountId,
            Externally_Serviced__c = true,
            Utility_Account_Subscription__c = uasList[0].Id
        );
        UASB__c billTwo = new UASB__c(
            Account__c = uasList[0].Opportunity__r.AccountId,
            Externally_Serviced__c = true,
            Utility_Account_Subscription__c = uasList[0].Id
        );
        UASB__c billThree = new UASB__c(
            Account__c = uasList[0].Opportunity__r.AccountId,
            Externally_Serviced__c = false,
            Utility_Account_Subscription__c = uasList[0].Id
        );
        insert new List<UASB__c>{billOne, billTwo, billThree};

        billOne.Ready_For_Production_Detail__c = true;
        billTwo.Ready_For_Production_Detail__c = true;
        billThree.Ready_For_Production_Detail__c = true;
        update new List<UASB__c>{billOne, billTwo, billThree};

        UASBSelector selector = new UASBSelector();
        List<UASB__c> uasbList = selector.getUnservicedWithoutProductionDetail(5);

        System.assertEquals(2,uasbList.size());
    }
}