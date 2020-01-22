@isTest
public class ZuoraUsageServiceTest {
    @testSetup public static void testDataSetup() {
        MultipleMonthProductionUpdateTest.multipleMonthTest();
        setBillsToUnPublished();
    }

    public static void setBillsToUnPublished() {
        List <Account_Bill__c> listAccountBills = [
            SELECT Id, Published__c
            FROM Account_Bill__c
            WHERE Published__c = TRUE
        ];
        for (Account_Bill__c acctBill : listAccountBills) {
            acctBill.Published__c = FALSE;
            acctBill.Reason_For_Unpublish__c = 'Test reason for unpublishing this bill';
        }
        update listAccountBills;
    }

    // To avoid SOQL Limits, do this method inside Test.StartTest()
    public static void finishTestSetup(){
        Shared_Solar_System__c sss = [
            SELECT Id, Name, Unique_ID__c, BWC_Project_Entity_Manual__r.Client_Account__r.Account_Number__c
            FROM Shared_Solar_System__c
            WHERE Name = 'Oxford Barrett St. P1'
            LIMIT 1
        ];

        Account clientAccount = [
            SELECT Id, Name, Account_Number__c
            FROM Account
            WHERE Name = 'Test Client'
            LIMIT 1
        ];

        List<Account> propertyAccounts = [
            SELECT Id, Name, Zuora_Id__c
            FROM Account
            WHERE Name = 'Property A'
        ];

        // See ZuoraAPIMock.getOrderByOwnerResponse()
        // If ZuoraId contains CID, mocked subscriptions will be returned for this client/shared solar system pair:
        String accountKey = 'CID' + clientAccount.Account_Number__c + 'SID' + sss.Unique_ID__c + 'END';

        for (Account accts : propertyAccounts){
            accts.Zuora_Id__c = accountKey;
        }
        update propertyAccounts;

        List<UASB__c> uasbList = [
            SELECT Id, Name, Utility_Account_Subscription__r.Id
            FROM UASB__c
            ORDER BY Date__c
            LIMIT 2
        ];

        Bill_Adjustment__c adjustOne = new Bill_Adjustment__c(
            Name = 'UASoneAdjustment',
            Utility_Account_Subscription__c = uasbList[0].Utility_Account_Subscription__r.Id,
            UASB__c = uasbList[0].Id,
            Adjustment_Type__c = 'Production',
            Adjustment_Amount__c = 90,
            Credits_Allocated__c = 100,
            Approval_Status__c = 'Approved',
            Client__c = clientAccount.Id,
            Reason_For_Adjustment__c = 'Needs adjustment');

        Bill_Adjustment__c adjustTwo = new Bill_Adjustment__c(
            Name = 'UASoneAdjustment2',
            Utility_Account_Subscription__c = uasbList[0].Utility_Account_Subscription__r.Id,
            UASB__c = uasbList[0].Id,
            Adjustment_Type__c = 'Production',
            Adjustment_Amount__c = 45,
            Credits_Allocated__c = 50,
            Approval_Status__c = 'Approved',
            Client__c = clientAccount.Id,
            Reason_For_Adjustment__c = 'Needs adjustment');

        Bill_Adjustment__c adjustThree = new Bill_Adjustment__c(
            Name = 'UASoneAdjustment2',
            Utility_Account_Subscription__c = uasbList[1].Utility_Account_Subscription__r.Id,
            UASB__c = uasbList[1].Id,
            Adjustment_Type__c = 'BW Credit',
            Adjustment_Amount__c = 15,
            Approval_Status__c = 'Approved',
            Client__c = clientAccount.Id,
            Reason_For_Adjustment__c = 'Needs adjustment');

        insert new List<Bill_Adjustment__c>{adjustOne, adjustTwo, adjustThree};
    }

    @IsTest
    private static void testQueries() {
        Test.startTest();
        finishTestSetup();
        Database.QueryLocator queryLocator = UASBSelector.uasbsNotYetInZuora();
        Database.QueryLocatorIterator iterator = queryLocator.iterator();
        Integer i = 0;
        while (iterator.hasNext()) {
            iterator.next();
            i++;
        }
        System.assertEquals(12, i);

        queryLocator = AdjustmentSelector.getAdjustmentsNotYetInZuora(true, ZuoraCreditMemoBatchSend.AdjustmentType.PostNextBill);
        iterator = queryLocator.iterator();
        i = 0;
        while (iterator.hasNext()) {
            iterator.next();
            i++;
        }
        System.assertEquals(2, i);
        Test.stopTest();
    }

    @IsTest
    private static void testRadianGenQueries() {
        Test.startTest();
        finishTestSetup();

        UASB__c uasb = [
            SELECT Id, Date__c, NMC_Rate__c, NMC_Discount__c, Utility_Account_Subscription__r.Id, Opportunity__r.Id,
                System_Bill__r.Id, Shared_Solar_System__r.Id, Total_System_Size_kW_DC__c, CS_Billing_Log__r.Id
            FROM UASB__c
            LIMIT 1
        ];

        UASB__c uasbAnchor = new UASB__c(
            Customer_Subscription_KW_DC__c = 25,
            CS_Billing_Log__c = uasb.CS_Billing_Log__r.Id,
            Date__c = uasb.Date__c,
            NMC_Discount__c	= uasb.NMC_Discount__c,
            Share_of_System__c = 2.5,
            Total_System_Production_kWh__c = 150000,
            Total_System_NMCs__c = 18000,
            Utility_Account_Subscription__c = uasb.Utility_Account_Subscription__r.Id,
            Opportunity__c = uasb.Opportunity__r.Id,
            System_Bill__c = uasb.System_Bill__r.Id,
            Shared_Solar_System__c = uasb.Shared_Solar_System__r.Id,
            Total_System_Size_kw_DC__c = uasb.Total_System_Size_kw_DC__c,
            NMC_Rate__c = uasb.NMC_Rate__c,
            Credits_Allocated__c = 450,
            Subscription_Production_kWh_Static__c = 3750,
            Unique_ID__c = 'Anchor UASB',
            Externally_Serviced__c = true
        );
        insert uasbAnchor;

        Database.QueryLocator queryLocator = UASBSelector.uasbsNotYetInZuora();
        Database.QueryLocatorIterator iterator = queryLocator.iterator();
        Integer i = 0;
        while (iterator.hasNext()) {
            iterator.next();
            i++;
        }
        //Only 12 UASBs returned even though there is an additional "Externally Serviced" UASB
        System.assertEquals(12, i);

        Test.stopTest();
    }

    @IsTest
    private static void testAPIUASBCallsWithMock() {
        // disableTrigger just sets a system property checkbox to true
        Util.disableTrigger('Update_Usage_Records_With_ZuoraId__c');
        Test.startTest();
        finishTestSetup();
        ZuoraUsageBatchSend zSend = new ZuoraUsageBatchSend(ZuoraUsageBatchSend.UsageType.UASBS, System.today());
        zSend.executeBatch();
        Test.stopTest();

        // API Mock returns 14 rows, 3 errors, 11 successes:
        System.assertEquals(true, Util.getSystemPropertyCheckbox('Update_Usage_Records_With_ZuoraId__c'));
        List<UASB__c> uasbList = [
            SELECT Id, Name, Zuora_Id__c, Client_Account_Number__c
            FROM UASB__c
            WHERE Zuora_Id__c != null
        ];
        System.debug(uasbList);
        System.assertEquals(10, uasbList.size());

        List<Error_Log__c> errors = [
            SELECT Id, Message__c
            FROM Error_Log__c
            WHERE Class__c = 'ZuoraUsageService'
        ];
        System.assertEquals(1, errors.size());

        Database.QueryLocator queryLocator = UASBSelector.uasbsNotYetInZuora();
        Database.QueryLocatorIterator iterator = queryLocator.iterator();
        List<UASB__c> failedUASB = new List<UASB__c>();
        while (iterator.hasNext()) {
            failedUASB.add((UASB__c) iterator.next());
        }
        System.assert(errors[0].Message__c.contains(failedUASB[0].Id));
        System.assert(errors[0].Message__c.contains(failedUASB[1].Id));
    }

    @IsTest
    private static void testAPIAdjustmentCallsWithMock() {
        // disableTrigger just sets a system property checkbox to true
        Util.disableTrigger('Update_Usage_Records_With_ZuoraId__c');

        Test.startTest();
        finishTestSetup();
        ZuoraUsageBatchSend zSend = new ZuoraUsageBatchSend(ZuoraUsageBatchSend.UsageType.ADJUSTMENTS, System.today());
        zSend.executeBatch();
        Test.stopTest();

        // API Mock returns 14 rows, 3 errors, 11 successes:
        System.assertEquals(true, Util.getSystemPropertyCheckbox('Update_Usage_Records_With_ZuoraId__c'));
        List<Bill_Adjustment__c> adjustList = [
            SELECT Id, Name, Zuora_Id__c
            FROM Bill_Adjustment__c
            WHERE Zuora_Id__c != NULL
        ];
        System.assertEquals(1, adjustList.size());

        List<Error_Log__c> errors = [
            SELECT Id, Message__c
            FROM Error_Log__c
            WHERE Class__c = 'ZuoraUsageService'
        ];
        System.assertEquals(1, errors.size());

        Database.QueryLocator queryLocator = AdjustmentSelector.getAdjustmentsNotYetInZuora(true, ZuoraCreditMemoBatchSend.AdjustmentType.PostNextBill);
        Database.QueryLocatorIterator iterator = queryLocator.iterator();
        List<Bill_Adjustment__c> failedAdjust = new List<Bill_Adjustment__c>();
        while (iterator.hasNext()) {
            failedAdjust.add((Bill_Adjustment__c) iterator.next());
        }
        System.assert(errors[0].Message__c.contains(failedAdjust[0].Id));
    }

    @IsTest
    private static void testCallWithoutUpdatingUASBs() {
        Test.startTest();
        finishTestSetup();
        ZuoraUsageBatchSend zSend = new ZuoraUsageBatchSend(ZuoraUsageBatchSend.UsageType.UASBS, null);
        zSend.executeBatch();
        Test.stopTest();

        // This should be unchecked by default
        System.assertEquals(false, Util.getSystemPropertyCheckbox('Update_Usage_Records_With_ZuoraId__c'));

        // API Mock returns 14 rows, 3 errors, 11 successes, but since we're not updating usage records, uasbs and
        // bill adjustments shouldn't be updated
        List<UASB__c> uasbList = [
            SELECT Id, Name, Zuora_Id__c
            FROM UASB__c
            WHERE Zuora_Id__c != NULL
        ];
        System.assertEquals(0, uasbList.size());

        List<Bill_Adjustment__c> adjustList = [
            SELECT Id, Name, Zuora_Id__c
            FROM Bill_Adjustment__c
            WHERE Zuora_Id__c != NULL
        ];
        System.assertEquals(0, adjustList.size());
    }

    @IsTest
    private static void testIndividualAccountLoad() {
        Test.startTest();
        finishTestSetup();
        ZuoraUsageBatchSend zSend = new ZuoraUsageBatchSend(ZuoraUsageBatchSend.UsageType.UASBS, null);
        String query =
            'SELECT Id, Name, Date__c, System_Bill__c,' +
                '    Net_Metering_Credits_Allocated__c, Savings__c,' +
                '    Discounted_Bill__c, Shared_Solar_System__r.Name,' +
                '    Shared_Solar_System__r.System_Utility__c,' +
                '    Utility_Account_Subscription__r.Name,' +
                '    Shared_Solar_System__r.Utility__r.Name,' +
                '    Utility_Account_Subscription__r.Utility_Account_Log__r.Name,' +
                '    Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Client_Account__r.Account_Number__c,' +
                '    Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Unique_ID__c,' +
                '    Utility_Account_Subscription__r.Opportunity__r.Account.Zuora_Id__c,' +
                '    System_Bill__r.Account_Bill__c,' +
                '    Client_Account_Number__c ' +
                'FROM UASB__c ' +
                'ORDER BY Utility_Account_Subscription__r.Opportunity__r.AccountId, Date__c';
        zSend.queryString = query;
        zSend.executeBatch();
        Test.stopTest();

        System.assertEquals(2, ZuoraAPIHelper.endpointsCalled.size());
        System.assert(ZuoraAPIHelper.endpointsCalled[0].endpoint.contains('subscriptionOwner'));
        System.assert(ZuoraAPIHelper.endpointsCalled[1].endpoint.contains('action/create'));
    }
}
