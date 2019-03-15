@isTest
public class BillGenerationAndDeliveryServiceTest {
    @testSetup public static void setupTestData(){
        ProductionUpdateSelectorTest.setupTestData();
    }

    @isTest public static void testProdUpdateAndSSSQuery(){
        List<Energy_Usage_Update__c> euuList = BillGenerationConsoleController.getThisMonthsProductionUpdates();
        List<Shared_Solar_System__c> sssList = BillGenerationConsoleController.getSSSWithoutProductionUpdates(euuList);

        System.assertEquals(3,euuList.size());
        System.assertEquals(0, sssList.size());
    }

    @isTest public static void testBillGenerationAndABSummary(){
        List<Account_Bill__c> acctBillToUpdate = new List<Account_Bill__c>();

        Test.startTest();
        BillGenerationConsoleController.runThisMonthsBills();
        Test.stopTest();

        String abSummary = BillGenerationConsoleController.getAccountBillSummary();

        System.assertEquals('Generated Account Bills: 5',abSummary.substring(0,26));
        System.assertEquals('Ready for Email Send: 0 bills (0%)' ,abSummary.substring(29,63));
        System.assertEquals('Ready for Paper Send: 0 bills (0%)',abSummary.substring(66,100));

        for (Account_Bill__c acctBill : [
            SELECT Id, Name, Ready_for_Email_Send__c
            FROM Account_Bill__c]){
                acctBill.Ready_for_Email_Send__c = true;
                acctBillToUpdate.add(acctBill);
        }

        update acctBillToUpdate;

        String newABSummary = BillGenerationConsoleController.getAccountBillSummary();

        System.assertEquals('Generated Account Bills: 5',newABSummary.substring(0,26));
        System.assertEquals('Ready for Email Send: 5 bills (100%)' ,newABSummary.substring(29,65));
        System.assertEquals('Ready for Paper Send: 0 bills (0%)',newABSummary.substring(68,102));
    }

    @isTest public static void testNoBillsInserted(){
        String newABSummary = BillGenerationConsoleController.getAccountBillSummary();
        System.assertEquals('Generated Account Bills: 0',newABSummary.substring(0,26));
    }

    @isTest public static void simulateBatch(){
        Test.startTest();

        List<Schedule_Z_Subscription__c> scheduleZSubs = [
            SELECT Id, Utility_Account_Subscription__c, Utility_Account_Subscription__r.Opportunity__c
            FROM Schedule_Z_Subscription__c
        ];

        List<Schedule_Z_Subscription__c> batch1 = new List<Schedule_Z_Subscription__c>();
        List<Schedule_Z_Subscription__c> batch2 = new List<Schedule_Z_Subscription__c>();

        Integer counter = 1;
        for (Schedule_Z_Subscription__c scheduleZSubscription : scheduleZSubs) {
            if (Math.mod(counter, 2) == 0) {
                batch1.add(scheduleZSubscription);
            } else {
                batch2.add(scheduleZSubscription);
            }
            counter += 1;
        }

        Date todaysDate = Date.today();

        List<Energy_Usage_Update__c> prodList;
        prodList = ProductionUpdateSelector.getProductionUpdatesByMonth(todaysDate.month(),String.valueOf(todaysDate.year()));

        EnergyUsageUpdateTriggerHandler handler = new EnergyUsageUpdateTriggerHandler(prodList);
        handler.createBills(batch1);
        handler.createBills(batch2);

        Test.stopTest();

        List<System_Bill__c> systemBillList = SystemBillsSelector.selectAllSystemBills();
        System.assertEquals(10, systemBillList.size());
    }
}