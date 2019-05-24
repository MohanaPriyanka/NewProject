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
        Test.startTest();
        Database.executeBatch(asyncService);
        Test.stopTest();
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
}