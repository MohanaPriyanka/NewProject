@IsTest
public class CSPaymentTest {
    private static Profile profileRecord = [SELECT Id FROM Profile WHERE Name = 'Community Solar Community User'];

    @testSetup public static void csPaymentSetupTestData() {
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
        Test.startTest();
        Test.loadData(Opportunity.SObjectType, 'TestCSOpportunity');
        Test.loadData(Utility_Account_Subscription__c.SObjectType, 'TestCSUtilityAccountSubscription');
        Test.loadData(Schedule_Z__c.SObjectType, 'TestCSScheduleZ');
        Test.loadData(Schedule_Z_Subscription__c.SObjectType, 'TestCSScheduleZSubscription');
        Test.loadData(Bill_Period__c.SObjectType, 'TestCSBillPeriod');
        Test.loadData(Production__c.SObjectType, 'TestCSProduction');
        Test.loadData(Transfer__c.SObjectType, 'TestCSTransfer');
        Test.loadData(Account_Bill__c.SObjectType, 'TestCSAccountBill');
        Test.loadData(System_Bill__c.SObjectType, 'TestCSSystemBill');
        Test.loadData(Utility_Account_Bill__c.SObjectType, 'TestCSUtilityAccountBill');
        Test.stopTest();
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

        for (Account acct : accounts) {
            if (acct.Name == 'ADonut Shop Parent') {
                insertUser(acct, 'CSPaymentTest@bluewavesolar.com');
            } else if (acct.Name == 'Unrelated OtherAccount Parent') {
                insertUser(acct, 'CSPaymentTestB@bluewavesolar.com');
            } else if (acct.Name == 'PaymentTestParentAccountA') {
                insertUser(acct, 'PaymentTestParentAccountA@bluewavesolar.com');
            } else if (acct.Name == 'PaymentTestParentAccountC') {
                insertUser(acct, 'PaymentTestParentAccountC@bluewavesolar.com');
            }
        }
        Util.printCPULimit('1');
        Util.enableAllTriggers();

        List<Account_Bill__c> abs = [
            SELECT Id, Name, Bill_Number__c
            FROM Account_Bill__c
            WHERE Name LIKE '%Donut Shop%'
            OR Name LIKE '%Payment Test%'
            OR Name LIKE '%Account A%'
            OR Name LIKE '%Account B%'
            OR Name LIKE '%Pizza Shop%'
        ];
        for (Account_Bill__c ab : abs) {
            if (!ab.Name.contains('Pizza Shop') || ab.Bill_Number__c != 2) {
                ab.Published__c = true;
            }
        }
        update abs;
    }

    // We get System.UnexpectedException: Salesforce System Error: 900955498-340097 (1185570226) (1185570226)
    // when trying to load users via Test.loadData
    private static void insertUser(Account account, String email) {
        Contact contact = new Contact(FirstName = 'First', LastName = account.Name, AccountId = account.Id);
        insert contact;
        User user = new User(
            FirstName = 'First',
            LastName = account.Name,
            Alias = ((String) account.Id).right(6),
            Email = email,
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profileRecord.Id,
            Country = 'United States',
            IsActive = true,
            ContactId = contact.Id,
            TimeZoneSidKey = 'Pacific/Tongatapu',
            Username = email);
        Util.insertSObj(user);
    }
}