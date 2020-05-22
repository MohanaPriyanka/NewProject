@isTest
public class ZuoraUsageServiceTest {
    @testSetup public static void testDataSetup() {
        MultipleMonthProductionUpdateTest.multipleMonthTest();
    }

    // To avoid SOQL Limits, do this method inside Test.StartTest()
    public static void finishTestSetup(){
        Shared_Solar_System__c sss = [
            SELECT Id, Name, Unique_ID__c, BWC_Project_Entity_Manual__r.Client_Account__r.Account_Number__c
            FROM Shared_Solar_System__c
            WHERE Name = 'Oxford Barrett St. P1'
            LIMIT 1
        ];

        Transfer__c transfer = [
            SELECT Id
            FROM Transfer__c
            WHERE Name = 'Main Transfer - sssA October'
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
            SELECT Id, Name, Utility_Account_Subscription__r.Id, Utility_Account_Subscription__r.Opportunity__r.AccountId
            FROM UASB__c
            ORDER BY Date__c
            LIMIT 2
        ];

        Bill_Adjustment__c adjustOne = new Bill_Adjustment__c(
            Name = 'UASoneAdjustment',
            Utility_Account_Subscription__c = uasbList[0].Utility_Account_Subscription__r.Id,
            Account__c = uasbList[0].Utility_Account_Subscription__r.Opportunity__r.AccountId,
            UASB__c = uasbList[0].Id,
            Adjustment_Type__c = 'Production',
            Transfer__c = transfer.Id,
            Adjustment_Amount__c = 90,
            Credits_Allocated__c = 100,
            Approval_Status__c = 'Approved',
            Client__c = clientAccount.Id,
            Reason_For_Adjustment__c = 'Needs adjustment');

        Bill_Adjustment__c adjustTwo = new Bill_Adjustment__c(
            Name = 'UASoneAdjustment2',
            Utility_Account_Subscription__c = uasbList[0].Utility_Account_Subscription__r.Id,
            Account__c = uasbList[0].Utility_Account_Subscription__r.Opportunity__r.AccountId,
            UASB__c = uasbList[0].Id,
            Adjustment_Type__c = 'Production',
            Transfer__c = transfer.Id,
            Adjustment_Amount__c = 45,
            Credits_Allocated__c = 50,
            Approval_Status__c = 'Approved',
            Client__c = clientAccount.Id,
            Reason_For_Adjustment__c = 'Needs adjustment');

        Bill_Adjustment__c adjustThree = new Bill_Adjustment__c(
            Name = 'UASoneAdjustment2',
            Utility_Account_Subscription__c = uasbList[1].Utility_Account_Subscription__r.Id,
            Account__c = uasbList[1].Utility_Account_Subscription__r.Opportunity__r.AccountId,
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
        Database.QueryLocator queryLocator = UASBSelector.uasbsNotYetInZuora(Date.newInstance(2050,01,01));
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
                System_Bill__r.Id, Shared_Solar_System__r.Id, Total_System_Size_kW_DC__c, CS_Billing_Log__r.Id,
                Opportunity__r.AccountId
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
            Account__c = uasb.Opportunity__r.AccountId,
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

        Database.QueryLocator queryLocator = UASBSelector.uasbsNotYetInZuora(Date.newInstance(2050,01,01));
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
        ZuoraUsageService.featureService = (FeatureService) Test.createStub(FeatureService.class, new FeatureService.Mock(false));
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
        System.assertEquals(10, uasbList.size());

        List<Error_Log__c> errors = [
            SELECT Id, Message__c
            FROM Error_Log__c
            WHERE Class__c = 'ZuoraUsageService'
        ];
        System.assertEquals(1, errors.size());

        Database.QueryLocator queryLocator = UASBSelector.uasbsNotYetInZuora(Date.newInstance(2050,01,01));
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
        ZuoraUsageService.featureService = (FeatureService) Test.createStub(FeatureService.class, new FeatureService.Mock(false));
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
        ZuoraUsageBatchSend zSend = new ZuoraUsageBatchSend(ZuoraUsageBatchSend.UsageType.UASBS, Date.newInstance(2018,04,20));
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
        ZuoraUsageService.featureService = (FeatureService) Test.createStub(FeatureService.class, new FeatureService.Mock(false));
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

    @IsTest
    private static void testUasbUploadWithMultipleSubscriptions() {
        ZuoraUsageService.featureService = (FeatureService) Test.createStub(FeatureService.class, new FeatureService.Mock(true));
        String uasbJSON = '{"Id":"a1i3I000000AurPQAS","Name":"UASB-0030956","Date__c":"2020-03-02",' +
            '"Net_Metering_Credits_Allocated__c":100.00000,"Savings__c":10.00,"Discounted_Bill__c":90.00,' +
            '"Shared_Solar_System__c":"a1J3I0000003QoOUAU","Utility_Account_Subscription__c":"a1d3I000000HP94QAG","Client_Account_Number__c":"BW-0021776",' +
            '"Shared_Solar_System__r":{"Id":"a1J3I0000003QoOUAU","Name":"Project E Dog St","Utility__c":"a1M3I0000009HazUAE",' +
            '"Utility__r":{"Id":"a1M3I0000009HazUAE","Name":"National Grid"}},' +
            '"Utility_Account_Subscription__r":{"Id":"a1d3I000000HP94QAG","Name":"0002340","Utility_Account_Log__c":"a1b3I000000Hk6dQAC","Opportunity__c":"0063I000002Y9OsQAK",' +
            '"Utility_Account_Log__r":{"Id":"a1b3I000000Hk6dQAC","Name":"0000234"},' +
            '"Opportunity__r":{"Id":"0063I000002Y9OsQAK","Shared_Solar_System__c":"a1J3I0000003QoOUAU","AccountId":"0013I00000I77l7QAB",' +
            '"Shared_Solar_System__r":{"Id":"a1J3I0000003QoOUAU","BWC_Project_Entity_Manual__c":"a1I3I000000NPYbUAO","Unique_ID__c":"SSS-000009",' +
            '"BWC_Project_Entity_Manual__r":{"Id":"a1I3I000000NPYbUAO","Client_Account__c":"0013I00000Lk8VZQAZ",' +
            '"Client_Account__r":{"Id":"0013I00000Lk8VZQAZ","Account_Number__c":"BW-0021776"}}},' +
            '"Account":{"Id":"0013I00000I77l7QAB","Zuora_Id__c":"2c92c0f871bae3ce0171bc5bc5634378"}}}}';
        UASB__c uasb = (UASB__c) JSON.deserialize(uasbJSON, UASB__c.class);
        ZuoraUsageService.ZuoraUsage zuoraUsage = ZuoraUsageService.convertUASBToUsage(uasb);
        System.assertEquals('A-S00029335', zuoraUsage.SubscriptionNumber);
        System.assertEquals('C-00048346', zuoraUsage.ChargeNumber);
    }

    @IsTest
    private static void testAdjustmentUploadWithMultipleSubscriptions() {
        ZuoraUsageService.featureService = (FeatureService) Test.createStub(FeatureService.class, new FeatureService.Mock(true));
        String adjustmentJSON = '{"Id":"a0p3I000002ziVXQAY","Name":"Production Test Project D",' +
            '"Utility_Account_Subscription__c":"a1d3I000000HP95QAG","Client__c":"0013I00000I77klQAB","Adjustment_Amount__c":120.00,' +
            '"Adjustment_Type__c":"Production","Discount__c":-20.00,"Credits_Allocated__c":100.00,' +
            '"Utility_Account_Subscription__r":{"Id":"a1d3I000000HP95QAG","Opportunity__c":"0063I000002Y9OtQAK","Utility_Account_Log__c":"a1b3I000000Hk6eQAC",' +
            '"Opportunity__r":{"Id":"0063I000002Y9OtQAK","Shared_Solar_System__c":"a1J3I0000003QoNUAU","AccountId":"0013I00000I77l7QAB",' +
            '"Shared_Solar_System__r":{"Id":"a1J3I0000003QoNUAU","Utility__c":"a1M3I0000009HazUAE","Name":"Project D Dee St","Unique_ID__c":"SSS-000009",' +
            '"Utility__r":{"Id":"a1M3I0000009HazUAE","Name":"National Grid"}},"Account":{"Id":"0013I00000I77l7QAB","Zuora_Id__c":"2c92c0f871bae3ce0171bc5bc5634378"}},' +
            '"Utility_Account_Log__r":{"Id":"a1b3I000000Hk6eQAC","Name":"0000235"}},"Client__r":{"Id":"0013I00000I77klQAB","Account_Number__c":"BW-0021776"}}';
        Bill_Adjustment__c billAdjustment = (Bill_Adjustment__c) JSON.deserialize(adjustmentJSON, Bill_Adjustment__c.class);
        ZuoraUsageService.ZuoraUsage zuoraUsage = ZuoraUsageService.convertAdjustToUsage(billAdjustment, System.today());
        System.assertEquals('A-S00029335', zuoraUsage.SubscriptionNumber);
        System.assertEquals('C-00048346', zuoraUsage.ChargeNumber);
    }
}