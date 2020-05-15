@isTest
public class AdjustmentSelectorTest {
    @testSetup public static void setupTestData() {
        // Disable triggers so that we don't have to populate client account, sss, entity when inserting UASes and UASBs:
        Util.disableTrigger('Disable_Client_Objects_Trigger__c');
        Util.disableTrigger('Disable_BillAdjustmentTrigger__c');

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

    @isTest public static void testGetAdjustmentMapFromExternalIds() {
        List<Utility_Account_Subscription__c> uasList = [
            SELECT Id, Opportunity__r.AccountId
            FROM Utility_Account_Subscription__c
        ];

        Bill_Adjustment__c adjustOne = new Bill_Adjustment__c(
            Account__c = uasList[0].Opportunity__r.AccountId,
            Adjustment_Type__c = 'BW Credit',
            Reason_For_Adjustment__c = 'Some Reason',
            Zuora_Id__c = 'aaa1230002',
            Utility_Account_Subscription__c = uasList[0].Id
        );
        Bill_Adjustment__c adjustTwo = new Bill_Adjustment__c(
            Account__c = uasList[0].Opportunity__r.AccountId,
            Adjustment_Type__c = 'BW Credit',
            Reason_For_Adjustment__c = 'Some Reason',
            Zuora_Id__c = 'aaa1230003',
            Utility_Account_Subscription__c = uasList[0].Id
        );
        Bill_Adjustment__c adjustThree = new Bill_Adjustment__c(
            Account__c = uasList[0].Opportunity__r.AccountId,
            Adjustment_Type__c = 'BW Credit',
            Reason_For_Adjustment__c = 'Some Reason',
            Zuora_Id__c = 'aaa1230002',
            Utility_Account_Subscription__c = uasList[0].Id
        );
        insert new List<Bill_Adjustment__c>{adjustOne, adjustTwo, adjustThree};

        AdjustmentSelector selector = new AdjustmentSelector();
        Map<String,List<Bill_Adjustment__c>> billMap = selector.getAdjustmentMapFromExternalIds(new Set<String>{
            'aaa1230002','aaa1230001','aaa1230003'
        });
        List<Bill_Adjustment__c> adjustmentList1 = billMap.get('aaa1230002');
        List<Bill_Adjustment__c> adjustmentList2 = billMap.get('aaa1230003');

        System.assertEquals(2,adjustmentList1.size());
        System.assertEquals(1,adjustmentList2.size());
    }

    @isTest public static void testGetAdjustmentsFromExternalIds(){
        List<Utility_Account_Subscription__c> uasList = [
            SELECT Id, Opportunity__r.AccountId
            FROM Utility_Account_Subscription__c
        ];

        Bill_Adjustment__c adjustOne = new Bill_Adjustment__c(
            Account__c = uasList[0].Opportunity__r.AccountId,
            Adjustment_Type__c = 'BW Credit',
            Zuora_Id__c = 'aaa234',
            Reason_For_Adjustment__c = 'Some Reason',
            Utility_Account_Subscription__c = uasList[0].Id
        );
        Bill_Adjustment__c adjustTwo = new Bill_Adjustment__c(
            Account__c = uasList[0].Opportunity__r.AccountId,
            Adjustment_Type__c = 'BW Credit',
            Zuora_Id__c = 'aaa235',
            Reason_For_Adjustment__c = 'Some Reason',
            Utility_Account_Subscription__c = uasList[0].Id
        );
        Bill_Adjustment__c adjustThree = new Bill_Adjustment__c(
            Account__c = uasList[0].Opportunity__r.AccountId,
            Adjustment_Type__c = 'BW Credit',
            Zuora_Id__c = 'aaa236',
            Reason_For_Adjustment__c = 'Some Reason',
            Utility_Account_Subscription__c = uasList[0].Id
        );
        insert new List<Bill_Adjustment__c>{adjustOne, adjustTwo, adjustThree};

        AdjustmentSelector selector = new AdjustmentSelector();
        List<Bill_Adjustment__c> billList = selector.getAdjustmentsFromExternalIds(new Set<String>{'aaa235','aaa236'});
        System.assertEquals(2,billList.size());
    }

    @isTest public static void testGetUnservicedWithoutProductionDetail(){
        Util.enableTrigger('Disable_BillAdjustmentTrigger__c');
        Account clientAccount = new Account(Name = 'Client');
        insert clientAccount;

        List<Utility_Account_Subscription__c> uasList = [
            SELECT Id, Opportunity__r.AccountId
            FROM Utility_Account_Subscription__c
        ];

        Bill_Adjustment__c adjustOne = new Bill_Adjustment__c(
            Account__c = uasList[0].Opportunity__r.AccountId,
            Client__c = clientAccount.Id,
            Adjustment_Type__c = 'BW Credit',
            Externally_Serviced__c = true,
            Reason_For_Adjustment__c = 'Some Reason',
            Utility_Account_Subscription__c = uasList[0].Id
        );
        Bill_Adjustment__c adjustTwo = new Bill_Adjustment__c(
            Account__c = uasList[0].Opportunity__r.AccountId,
            Client__c = clientAccount.Id,
            Adjustment_Type__c = 'BW Credit',
            Externally_Serviced__c = true,
            Reason_For_Adjustment__c = 'Some Reason',
            Utility_Account_Subscription__c = uasList[0].Id
        );
        Bill_Adjustment__c adjustThree = new Bill_Adjustment__c(
            Account__c = uasList[0].Opportunity__r.AccountId,
            Client__c = clientAccount.Id,
            Adjustment_Type__c = 'BW Credit',
            Externally_Serviced__c = true,
            Reason_For_Adjustment__c = 'Some Reason',
            Utility_Account_Subscription__c = uasList[0].Id
        );
        insert new List<Bill_Adjustment__c>{adjustOne, adjustTwo, adjustThree};

        AdjustmentSelector selector = new AdjustmentSelector();
        List<Bill_Adjustment__c> adjustments = selector.getUnservicedWithoutProductionDetail(2);
        System.assertEquals(2,adjustments.size());
    }
}