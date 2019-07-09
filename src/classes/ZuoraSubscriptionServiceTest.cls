/*************************************************************************************
 * Created By: peteryao on 2019-05-15  
 * Description:
 * Test:
 *************************************************************************************/
@IsTest
public with sharing class ZuoraSubscriptionServiceTest {
    @TestSetup
    public static void testSetup() {
        Test.startTest();
        Util.disableAllTriggers();

        TestFactory.insertBWAddress();
        Test.loadData(Utility__c.SObjectType, 'TestCSUtility');
        Test.loadData(Utility_NMC_Tariff__c.SObjectType, 'TestCSUtilityNMCTariff');
        Test.loadData(Load_U__c.SObjectType, 'TestCSLoadU');
        Test.loadData(ChargentBase__Gateway__c.SObjectType, 'TestCSGateway');
        Test.loadData(Contact.SObjectType, 'TestCSContact');
        Test.loadData(Account.SObjectType, 'TestCSAccount');
        Test.loadData(Entity__c.SObjectType, 'TestCSEntity');
        Test.loadData(Shared_Solar_System__c.SObjectType, 'TestCSSharedSolarSystem');
        Test.loadData(Utility_Account_Log__c.SObjectType, 'TestCSUtilityAccountLog');
        Test.loadData(Opportunity.SObjectType, 'TestCSOpportunity');
        Test.stopTest();
        Test.loadData(Utility_Account_Subscription__c.SObjectType, 'TestCSUtilityAccountSubscription');
        Test.loadData(Schedule_Z__c.SObjectType, 'TestCSScheduleZ');
        Test.loadData(Schedule_Z_Subscription__c.SObjectType, 'TestCSScheduleZSubscription');
        Test.loadData(Energy_Usage_Update__c.SObjectType, 'TestCSProdUpdate');
        Test.loadData(Account_Bill__c.SObjectType, 'TestCSAccountBill');
        Test.loadData(System_Bill__c.SObjectType, 'TestCSSystemBill');
        Test.loadData(Utility_Account_Bill__c.SObjectType, 'TestCSUtilityAccountBill');
        Test.loadData(UASB__c.SObjectType, 'TestCSUASB');
        Test.loadData(ChargentOrders__ChargentOrder__c.SObjectType, 'TestCSChargentOrder');

        TestFactory.setCSBillSettings();

        // Because there's no way to populate self lookups:
        // https://salesforce.stackexchange.com/questions/54527/test-loaddata-undocumented-but-useful-behavior-loading-relationships
        // We put the parent account's name in AccountNumber and use that to update the accounts.
        Map<String, Account> accountNameMap = new Map<String, Account>();
        List<Account> accounts = [SELECT Id, Name, AccountNumber FROM Account];
        for (Account acct : accounts) {
            accountNameMap.put(acct.Name, acct);
        }
        for (Account acct : accounts) {
            if (accountNameMap.get(acct.AccountNumber) != null) {
                acct.Parent_Account__c = accountNameMap.get(acct.AccountNumber).Id;
            }
        }
        update accounts;
        Util.enableAllTriggers();

        zqu__ZProduct__c zProduct = new zqu__ZProduct__c(
            Name = 'Community Solar'
        );
        insert zProduct;

        zqu__ProductRatePlan__c productRatePlan = new zqu__ProductRatePlan__c(
            Name = 'Community Solar Subscriptions',
            zqu__ZuoraId__c = '2c92c0f86ab120de016ab427c7d8234d',
            zqu__ZProduct__c = zProduct.Id
        );
        insert productRatePlan;
        zqu__ProductRatePlanCharge__c productRatePlanCharge = new zqu__ProductRatePlanCharge__c(
            Name = 'Utility Credit',
            zqu__ZuoraId__c = '2c92c0f86ab120de016ab427c97b2368',
            zqu__ProductRatePlan__c = productRatePlan.Id
        );
        insert productRatePlanCharge;
    }

    @IsTest
    public static void testCreateSubscription() {
        ZuoraSubscriptionService.OrderActionParam param = new ZuoraSubscriptionService.OrderActionParam();
        param.accountNumber = 'BW-00000076';
        param.orderDate = Date.newInstance(2019,5,20);
        param.contractEffectiveDate = Date.newInstance(2019,5,20);
        param.productRatePlanId = '2c92c0f869c8e5c50169caec86e07095';
        param.productRatePlanChargeId = '2c92c0f969c8f15e0169caed586a1909';
        param.clientName = 'AES Distributed Energy';
        param.projectName = 'Albany Post Road Solar Farm';

        Set<ZuoraSubscriptionService.ClientProject> clientProjects = new Set<ZuoraSubscriptionService.ClientProject>();
        ZuoraSubscriptionService.ClientProject norton = new ZuoraSubscriptionService.ClientProject('Norton Solar Development', 'Norton Solar Farm');
        clientProjects.add(norton);
        ZuoraSubscriptionService.ClientProject dudley = new ZuoraSubscriptionService.ClientProject('AMP', 'Dudley #3');
        clientProjects.add(dudley);

        ZuoraSubscriptionService.SubscriptionParam subscriptionParam = new ZuoraSubscriptionService.SubscriptionParam(param, clientProjects);
        List<String> subscriptions = ZuoraSubscriptionService.createSubscriptions(new List<ZuoraSubscriptionService.SubscriptionParam>{subscriptionParam});
        System.assertEquals('A-S00000090', subscriptions[0]);
    }

    @IsTest
    public static void testDataLoad() {
        ZuoraSubscriptionAsyncService asyncService = new ZuoraSubscriptionAsyncService();
        asyncService.initForDataLoad();
        // There should be enough subscriptions to require queueable invocation
        System.assert(asyncService.allSubscriptionsToCreate.size() > 5);
        Integer allSubscriptionsToCreateStartingSize = asyncService.allSubscriptionsToCreate.size();
        List<Error_Log__c> errorLogs = [SELECT Id FROM Error_Log__c WHERE Class__c = 'ZuoraAPIHelper'];
        System.assertEquals(0, errorLogs.size());
        Test.startTest();
        Database.executeBatch(asyncService);
        Test.stopTest();

        ZuoraSubscriptionAsyncService nextAsyncService = ZuoraSubscriptionAsyncService.nextAsyncService;
        System.assert(nextAsyncService.allSubscriptionsToCreate.size() > 0);
        System.assert(ZuoraSubscriptionAsyncService.batchedSubscriptionsToCreate.size() == 0);
        System.debug(LoggingLevel.ERROR, nextAsyncService.allSubscriptionsToCreate.size());
        System.debug(LoggingLevel.ERROR, ZuoraSubscriptionAsyncService.subscriptionsCreated.size());
        System.debug(LoggingLevel.ERROR, allSubscriptionsToCreateStartingSize);
        System.assert(nextAsyncService.allSubscriptionsToCreate.size() + ZuoraSubscriptionAsyncService.subscriptionsCreated.size() == allSubscriptionsToCreateStartingSize);
        errorLogs = [SELECT Id FROM Error_Log__c WHERE Class__c = 'ZuoraAPIHelper'];
        System.assertEquals(1, errorLogs.size());
    }

    @IsTest
    public static void testTimeout() {
        ZuoraSubscriptionAsyncService asyncService = new ZuoraSubscriptionAsyncService();
        asyncService.initForDataLoad();
        // There should be enough subscriptions to require queueable invocation
        System.assert(asyncService.allSubscriptionsToCreate.size() > 5);
        Integer allSubscriptionsToCreateStartingSize = asyncService.allSubscriptionsToCreate.size();
        List<Error_Log__c> errorLogs = [SELECT Id FROM Error_Log__c WHERE Class__c = 'ZuoraAPIHelper'];
        System.assertEquals(0, errorLogs.size());
        Test.startTest();
        // Simulate 119 seconds of 120 seconds used, so no subscriptions would be created
        ZuoraAPIHelper.calloutMillis = 119000;
        Database.executeBatch(asyncService);
        Test.stopTest();

        ZuoraSubscriptionAsyncService nextAsyncService = ZuoraSubscriptionAsyncService.nextAsyncService;
        // We expect to try everything again
        System.assertEquals(allSubscriptionsToCreateStartingSize, nextAsyncService.allSubscriptionsToCreate.size());
        // And ZuoraAPIHelper wouldn't log anything since it would have thrown an exception, caught and logged by the
        // ZuoraSubscriptionService
        errorLogs = [SELECT Id FROM Error_Log__c WHERE Class__c = 'ZuoraSubscriptionService'];
        System.assertEquals(1, errorLogs.size());
    }

    @IsTest
    public static void testClientProjectSets() {
        Set<ZuoraSubscriptionService.ClientProject> clientProjectSet = new Set<ZuoraSubscriptionService.ClientProject>();

        ZuoraSubscriptionService.ClientProject clientProjectA = new ZuoraSubscriptionService.ClientProject('foo', 'bar');
        clientProjectSet.add(clientProjectA);
        ZuoraSubscriptionService.ClientProject clientProjectB = new ZuoraSubscriptionService.ClientProject('foo', 'bar');
        clientProjectSet.add(clientProjectB);
        System.assertEquals(1, clientProjectSet.size());
        ZuoraSubscriptionService.ClientProject clientProjectC = new ZuoraSubscriptionService.ClientProject('fo', 'obar');
        clientProjectSet.add(clientProjectC);
        System.assertEquals(2, clientProjectSet.size());
    }

    @IsTest
    public static void testSRPCListForDataload() {
        Map<String, ZuoraSubscriptionService.SubscriptionParam> accountNumberToSubscriptionMap =
            new Map<String, ZuoraSubscriptionService.SubscriptionParam>();
        ZuoraSubscriptionService.OrderActionParam orderActionParam;
        orderActionParam = new ZuoraSubscriptionService.OrderActionParam();
        orderActionParam.accountNumber = '1234';
        orderActionParam.clientName = 'AMP';
        orderActionParam.projectName = 'Westport';

        ZuoraSubscriptionAsyncService.addOrderActionToMap(accountNumberToSubscriptionMap, orderActionParam);
        System.assertEquals(1, accountNumberToSubscriptionMap.size());

        orderActionParam = new ZuoraSubscriptionService.OrderActionParam();
        orderActionParam.accountNumber = 'ABCD';
        orderActionParam.clientName = 'AMP';
        orderActionParam.projectName = 'Westport Blossom Rd A';

        ZuoraSubscriptionAsyncService.addOrderActionToMap(accountNumberToSubscriptionMap, orderActionParam);
        System.assertEquals(2, accountNumberToSubscriptionMap.size());
        // There shouldn't be additional client projects - the client/project combination is on the original param
        System.assertEquals(0, accountNumberToSubscriptionMap.get('ABCD').additionalClientProjects.size());

        orderActionParam = new ZuoraSubscriptionService.OrderActionParam();
        orderActionParam.accountNumber = 'ABCD';
        orderActionParam.clientName = 'AMP';
        orderActionParam.projectName = 'Westport Blossom Rd A';

        ZuoraSubscriptionAsyncService.addOrderActionToMap(accountNumberToSubscriptionMap, orderActionParam);
        // Even when we add another one, there shouldn't be any additional client projects
        System.assertEquals(0, accountNumberToSubscriptionMap.get('ABCD').additionalClientProjects.size());

        orderActionParam = new ZuoraSubscriptionService.OrderActionParam();
        orderActionParam.accountNumber = 'ABCD';
        orderActionParam.clientName = 'AMP';
        orderActionParam.projectName = 'Westport Blossom Rd B';

        ZuoraSubscriptionAsyncService.addOrderActionToMap(accountNumberToSubscriptionMap, orderActionParam);
        // This should have gotten added to ABCD's additional client projects, not as another account
        System.assertEquals(2, accountNumberToSubscriptionMap.size());
        System.assertEquals(1, accountNumberToSubscriptionMap.get('ABCD').additionalClientProjects.size());

        orderActionParam = new ZuoraSubscriptionService.OrderActionParam();
        orderActionParam.accountNumber = 'ABCD';
        orderActionParam.clientName = 'AMP';
        orderActionParam.projectName = 'Westport Blossom Rd B';

        ZuoraSubscriptionAsyncService.addOrderActionToMap(accountNumberToSubscriptionMap, orderActionParam);
        // But if we add another Westport Blossom Rd B, we shouldn't add another additional client project
        System.assertEquals(2, accountNumberToSubscriptionMap.size());
        System.assertEquals(1, accountNumberToSubscriptionMap.get('ABCD').additionalClientProjects.size());

        orderActionParam = new ZuoraSubscriptionService.OrderActionParam();
        orderActionParam.accountNumber = 'ABCD';
        orderActionParam.clientName = 'Goldman';
        orderActionParam.projectName = 'Westport Blossom Rd B';

        ZuoraSubscriptionAsyncService.addOrderActionToMap(accountNumberToSubscriptionMap, orderActionParam);
        // But if add another client/project combination, we should add the additional client project
        System.assertEquals(2, accountNumberToSubscriptionMap.get('ABCD').additionalClientProjects.size());
    }

    @IsTest
    public static void testExistingSubscriptionWithDifferentSRPC() {
        ZuoraSubscriptionService.OrderActionParam orderActionParam = new ZuoraSubscriptionService.OrderActionParam();
        orderActionParam.accountNumber = 'ExistingAccount';
        orderActionParam.productRatePlanId = '2c92c0f86ab120de016ab427c7d8234d';
        orderActionParam.productRatePlanChargeId = '2c92c0f86ab120de016ab427c97b2368';
        orderActionParam.clientName = 'AMP';
        orderActionParam.projectName = 'Dudley';
        ZuoraSubscriptionService.ClientProject clientProject = new ZuoraSubscriptionService.ClientProject('Goldman', 'Barrett');
        // ExistingAccount should have Goldman/Dudley and Goldman/Barrett, but not AMP/Dudley. So we should expect to see one
        // AddProduct call to add AMP/Dudley to subscription A-S00002141
        ZuoraSubscriptionService.createSubscription(orderActionParam, new Set<ZuoraSubscriptionService.ClientProject>{clientProject});

        // Expect one error log for ZuoraAPIHelper, callJSONEndpoint, Fine
        System.assertEquals(1, Logger.logs.values().size());
        // Expect two messages, one for the subscriptionOwner query, and the other for the addProduct call
        System.assertEquals(2, Logger.logs.values()[0].size());
        System.assert(Logger.logs.values()[0][0].message.contains('/v1/orders/subscriptionOwner'));
        System.assert(Logger.logs.values()[0][1].message.contains('AddProduct'));
        System.assert(Logger.logs.values()[0][1].message.contains('"customFields":{"Project__c":"Dudley","ClientOwner__c":"AMP"}'));
    }

    @IsTest
    public static void testExistingSubscriptionWithSameSRPC() {
        ZuoraSubscriptionService.OrderActionParam orderActionParam = new ZuoraSubscriptionService.OrderActionParam();
        orderActionParam.accountNumber = 'ExistingAccount';
        orderActionParam.productRatePlanId = '2c92c0f86ab120de016ab427c7d8234d';
        orderActionParam.productRatePlanChargeId = '2c92c0f86ab120de016ab427c97b2368';
        orderActionParam.clientName = 'Goldman';
        orderActionParam.projectName = 'Dudley';
        // This should get overridden, since the existing Contract Effective Date is 2017-01-01
        orderActionParam.orderDate = Date.newInstance(2000,1,1);
        ZuoraSubscriptionService.ClientProject clientProject = new ZuoraSubscriptionService.ClientProject('AMP', 'Dudley');
        // ExistingAccount should have Goldman/Dudley and Goldman/Barrett, but not AMP/Dudley. So we should expect to see one
        // AddProduct call to add AMP/Dudley to subscription A-S00002141
        ZuoraSubscriptionService.createSubscription(orderActionParam, new Set<ZuoraSubscriptionService.ClientProject>{clientProject});

        // Expect one error log for ZuoraAPIHelper, callJSONEndpoint, Fine
        System.assertEquals(1, Logger.logs.values().size());
        // Expect two messages, one for the subscriptionOwner query, and the other for the addProduct call
        System.assertEquals(2, Logger.logs.values()[0].size());
        System.assert(Logger.logs.values()[0][0].message.contains('/v1/orders/subscriptionOwner'));
        System.assert(Logger.logs.values()[0][1].message.contains('AddProduct'));
        System.assert(Logger.logs.values()[0][1].message.contains('"orderDate":"2017-01-01"'));
        System.assert(Logger.logs.values()[0][1].message.contains('"customFields":{"Project__c":"Dudley","ClientOwner__c":"AMP"}'));
    }

    @IsTest
    public static void testExistingSubscription() {
        ZuoraSubscriptionService.OrderActionParam orderActionParam = new ZuoraSubscriptionService.OrderActionParam();
        orderActionParam.accountNumber = 'ExistingAccount';
        orderActionParam.productRatePlanId = '2c92c0f86ab120de016ab427c7d8234d';
        orderActionParam.productRatePlanChargeId = '2c92c0f86ab120de016ab427c97b2368';
        orderActionParam.clientName = 'Goldman';
        orderActionParam.projectName = 'Dudley';
        ZuoraSubscriptionService.ClientProject clientProject = new ZuoraSubscriptionService.ClientProject('Goldman', 'Barrett');
        // ExistingAccount should have Goldman/Dudley and Goldman/Barrett. So we should expect to see just one query, but no
        // other calls
        ZuoraSubscriptionService.createSubscription(orderActionParam, new Set<ZuoraSubscriptionService.ClientProject>{clientProject});

        // Expect one error log for ZuoraAPIHelper, callJSONEndpoint, Fine
        System.assertEquals(1, Logger.logs.values().size());
        // Expect one messages, for for the subscriptionOwner query
        System.assertEquals(1, Logger.logs.values()[0].size());
        System.assert(Logger.logs.values()[0][0].message.contains('/v1/orders/subscriptionOwner'));
    }

    @IsTest
    public static void testOrdersBySubscriptionOwnerCache() {
        List<Error_Log__c> errorLogs = [
            SELECT Id
            FROM Error_Log__c
            WHERE Class__c = 'ZuoraAPIHelper'
        ];
        System.assertEquals(0, errorLogs.size());

        ZuoraSubscriptionService.getOrderBySubscriptionOwner('12345');
        Logger.flushLogs();
        errorLogs = [
            SELECT Id
            FROM Error_Log__c
            WHERE Class__c = 'ZuoraAPIHelper'
        ];
        // There should be one error log since we did the callout
        System.assertEquals(1, errorLogs.size());
        System.assertEquals(1, ZuoraSubscriptionService.ordersBySubscriptionOwnerCache.size());

        ZuoraSubscriptionService.getOrderBySubscriptionOwner('12345');
        Logger.flushLogs();
        errorLogs = [
            SELECT Id
            FROM Error_Log__c
            WHERE Class__c = 'ZuoraAPIHelper'
        ];
        // Since we cache the result, there should still only be one error log
        System.assertEquals(1, errorLogs.size());
        System.assertEquals(1, ZuoraSubscriptionService.ordersBySubscriptionOwnerCache.size());

        ZuoraSubscriptionService.getOrderBySubscriptionOwner('67890');
        Logger.flushLogs();
        errorLogs = [
            SELECT Id
            FROM Error_Log__c
            WHERE Class__c = 'ZuoraAPIHelper'
        ];
        // But if we query a different account number, we should have logged another error log
        System.assertEquals(2, errorLogs.size());
        System.assertEquals(2, ZuoraSubscriptionService.ordersBySubscriptionOwnerCache.size());
    }

    @IsTest
    public static void testGetOrderBySubscriptionOwnerPages() {
        ZuoraAPI.Order order = new ZuoraAPI.Order('12345', System.today());
        List<ZuoraAPI.Order> existingOrders = new List<ZuoraAPI.Order>{order};
        ZuoraAPI.OrderBySubscriptionOwner obso =
            ZuoraSubscriptionService.getOrderBySubscriptionOwnerPage('/v1/orders/subscriptionOwner/ExistingAccountPage?page=2', existingOrders);
        System.assertEquals(3, obso.orders.size());
        Boolean foundExistingAccount = false;
        Boolean found12345 = false;
        for (ZuoraAPI.Order orderFromQuery : obso.orders) {
            if (orderFromQuery.existingAccountNumber == 'ExistingAccount') {
                foundExistingAccount = true;
            } else if (orderFromQuery.existingAccountNumber == '12345') {
                found12345 = true;
            }
        }
        System.assert(foundExistingAccount);
        System.assert(found12345);

        obso =
            ZuoraSubscriptionService.getOrderBySubscriptionOwnerPage('/v1/orders/subscriptionOwner/ExistingAccountPage', null);
        System.assertEquals(4, obso.orders.size());
    }
}