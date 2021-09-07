@IsTest
public with sharing class OpportunityTriggerTest {

    @TestSetup
    public static void setupData() {
        Profile bfgStandardUser = [SELECT Id FROM Profile WHERE Name = 'BFG Standard User'];
        User bfgUser = new User (ProfileId = bfgStandardUser.Id,
            FirstName = 'Test',
            LastName = 'BFG_User',
            Username = 'bfguser@test.com',
            Email = 'bfguser@test.com',
            Alias = 'bfg_usr',
            CommunityNickname = 'bfg_usr',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'ISO-8859-1',
            LanguageLocaleKey = 'en_US');
        insert bfgUser;
        Test.loadData(Utility__c.SObjectType, 'TestCSUtility');
        Test.loadData(Utility_NMC_Tariff__c.SObjectType, 'TestCSUtilityNMCTariff');
        Test.loadData(Product2.SObjectType, 'RecalcUALTestProduct');
        Test.loadData(Shared_Solar_System__c.SObjectType, 'RecalcUALTestSharedSolarSystem');
        Test.loadData(Account.SObjectType, 'RecalcUALTestAccount');
        Test.loadData(Utility_Account_Log__c.SObjectType, 'RecalcUALTestUtilityAccountLog');
        Test.startTest();
        Test.loadData(Opportunity.SObjectType, 'RecalcUALTestOpportunity');
        Test.stopTest();
        Test.loadData(Utility_Account_Subscription__c.SObjectType, 'RecalcUALTestUtilityAccountSubscription');
        Test.loadData(Schedule_Z__c.SObjectType, 'RecalcUALTestScheduleZ');

        // Because there's no way to populate self lookups:
        // https://salesforce.stackexchange.com/questions/54527/test-loaddata-undocumented-but-useful-behavior-loading-relationships
        // We put the parent account's name in AccountNumber and use that to update the accounts.
        Map<String, Account> accountNameMap = new Map<String, Account>();
        List<Account> accounts = [SELECT Id, Name, AccountNumber FROM Account];
        Account byCostAccount;
        Account bykWhAccount;

        for (Account acct : accounts) {
            accountNameMap.put(acct.Name, acct);
            if (acct.Name == 'TestRecalcPropA') {
                byCostAccount = acct;
            } else if (acct.Name == 'TestRecalcPropB') {
                bykWhAccount = acct;
            }
        }
        for (Account acct : accounts) {
            if (accountNameMap.get(acct.AccountNumber) != null) {
                acct.Parent_Account__c = accountNameMap.get(acct.AccountNumber).Id;
            }
        }
        update accounts;
    }


    @IsTest
    public static void testEventHandling() {
        Account newAccount = new Account(
            Name = 'newAccount'
        );
        insert newAccount;
        List<Opportunity> oppList = [
            SELECT Id, AccountId, StageName, Shared_Solar_System__c
            FROM Opportunity
            WHERE StageName != 'Cancelled'
        ];
        Map<Id, Opportunity> oldOppMap = new Map<Id, Opportunity>();
        for (Opportunity opp : oppList) {
            oldOppMap.put(opp.Id, opp);
        }
        Opportunity newOpp1 = new Opportunity(
            Id = oppList[0].Id,
            Shared_Solar_System__c = oppList[0].Shared_Solar_System__c,
            AccountId = oppList[0].AccountId,
            StageName = 'Cancelled'
        );
        Opportunity newOpp2 = new Opportunity(
            Id = oppList[1].Id,
            Shared_Solar_System__c = oppList[1].Shared_Solar_System__c,
            AccountId = oppList[1].AccountId,
            StageName = 'Cancelled'
        );
        Opportunity newOpp3 = new Opportunity(
            Id = oppList[2].Id,
            Shared_Solar_System__c = oppList[2].Shared_Solar_System__c,
            StageName = oppList[2].StageName,
            AccountId = newAccount.Id
        );
        Map<Id, Opportunity> newOppMap = new Map<Id, Opportunity>();
        newOppMap.put(newOpp1.Id, newOpp1);
        newOppMap.put(newOpp2.Id, newOpp2);
        newOppMap.put(newOpp3.Id, newOpp3);
        Test.startTest();
        Map<Id, Subscription_Change_Event__e> eventMap = new Map<Id, Subscription_Change_Event__e>();
        OpportunityTriggerHandler handler = new OpportunityTriggerHandler(newOppMap.values(), newOppMap, oldOppMap);
        eventMap = handler.eventHandling();
        Test.stopTest();
        System.assert(eventMap.containsKey(oppList[0].AccountId));
        System.assert(eventMap.containsKey(oppList[1].AccountId));
        System.assert(eventMap.containsKey(oppList[2].AccountId));
        System.assert(eventMap.containsKey(newAccount.Id));
    }

    @IsTest
    public static void testCSRecordTypeUpdates() {
        List<Shared_Solar_System__c> sssID = [SELECT Id FROM Shared_Solar_System__c LIMIT 1];
        Opportunity noCustomerGroup = new Opportunity(
            Name = 'Test Opp',
            Product_Line__c = 'Community Solar',
            StageName = 'New',
            CloseDate = Date.today(),
            Shared_Solar_System__c = sssID[0].Id
        );

        insert noCustomerGroup;
        noCustomerGroup = [SELECT RecordType.Name FROM Opportunity WHERE Id = :noCustomerGroup.Id];
        System.assertEquals('Community Solar', noCustomerGroup.RecordType.Name,
            'The default record type for an opportunity with Product Line of Community Solar should be Community Solar');

    }

    @IsTest
    public static void testServicingOnBehalfOf() {
        List<Opportunity> opportunities = [
            SELECT Id, Servicing_on_Behalf_oftest__c, Servicing_on_behalf_of__c, Shared_Solar_System__c
            FROM Opportunity
            WHERE Product_Line__c = 'Community Solar'
        ];
        Set<Id> sharedSolarSystemIds = new Set<Id>();
        for (Opportunity opportunity : opportunities) {
            System.assertEquals(null, opportunity.Servicing_on_Behalf_oftest__c, 'Test setup should not set Servicing on behalf of');
            sharedSolarSystemIds.add(opportunity.Shared_Solar_System__c);
        }
        List<Shared_Solar_System__c> sharedSolarSystems = new List<Shared_Solar_System__c>();
        for (Id sssId : sharedSolarSystemIds) {
            sharedSolarSystems.add(new Shared_Solar_System__c(
                Id = sssId,
                Picklist__c = 'BlueWave'
            ));
        }
        update sharedSolarSystems;
        update opportunities;
        opportunities = [
            SELECT Id, Servicing_on_Behalf_oftest__c, Servicing_on_behalf_of__c, Shared_Solar_System__r.Picklist__c
            FROM Opportunity
            WHERE Product_Line__c = 'Community Solar'
        ];
        for (Opportunity opportunity : opportunities) {
            System.assertEquals(opportunity.Shared_Solar_System__r.Picklist__c, opportunity.Servicing_on_Behalf_oftest__c,
                'Servicing on Behalf Of should be set to the SSS Picklist value');
        }
    }
}