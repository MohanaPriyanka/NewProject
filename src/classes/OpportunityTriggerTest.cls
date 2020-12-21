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
    public static void testCSOpportunityStageUpdates() {
        Opportunity opportunityToTest = new Opportunity(
            Name = 'Test Opp',
            Product_Line__c = 'Community Solar',
            StageName = 'New',
            CloseDate = Date.today()
        );
        insert opportunityToTest;
        dsfs__DocuSign_Status__c docuSignStatus = new dsfs__DocuSign_Status__c(
            dsfs__Opportunity__c = opportunityToTest.Id
        );
        insert docuSignStatus;
        dsfs__DocuSign_Recipient_Status__c docuRecipientOne = new dsfs__DocuSign_Recipient_Status__c(
            dsfs__Parent_Status_Record__c = docuSignStatus.Id,
            dsfs__Recipient_Status__c = 'Completed',
            dsfs__DocuSign_Recipient_Id__c = 'recipient Id',
            dsfs__DocuSign_Routing_Order__c = 1,
            Opportunity__c = opportunityToTest.Id
        );
        dsfs__DocuSign_Recipient_Status__c docuRecipienttwo = new dsfs__DocuSign_Recipient_Status__c(
            dsfs__Parent_Status_Record__c = docuSignStatus.Id,
            dsfs__Recipient_Status__c = 'Sent',
            dsfs__DocuSign_Recipient_Id__c = 'recipient Id',
            dsfs__DocuSign_Routing_Order__c = 1
        );
        dsfs__DocuSign_Recipient_Status__c docuRecipientThree = new dsfs__DocuSign_Recipient_Status__c(
            dsfs__Parent_Status_Record__c = docuSignStatus.Id,
            dsfs__Recipient_Status__c = 'Sent',
            dsfs__DocuSign_Recipient_Id__c = 'recipient Id',
            dsfs__DocuSign_Routing_Order__c = 3,
            Opportunity__c = opportunityToTest.Id
        );
        insert new List<dsfs__DocuSign_Recipient_Status__c>{
            docuRecipientOne,
            docuRecipientTwo,
            docuRecipientThree
        };
        List<Opportunity> opps = [
            SELECT Id, StageName, Contract_Status__c
            FROM Opportunity
            WHERE Id = :opportunityToTest.Id
        ];
        System.assertNotEquals('Sent', opps[0].Contract_Status__c);
        System.assertNotEquals('Contract Pending', opps[0].StageName);
        docuRecipientTwo.Opportunity__c = opps[0].Id;
        Test.startTest();
        update new List<dsfs__DocuSign_Recipient_Status__c>{
            docuRecipientTwo
        };
        Test.stopTest();
        opps = [
            SELECT Id, StageName, Contract_Status__c
            FROM Opportunity
            WHERE Id = :opportunityToTest.Id
        ];
        System.assertEquals('Sent', opps[0].Contract_Status__c);
        System.assertEquals('Contract Pending', opps[0].StageName);
    }
    
    @IsTest
    public static void testEventHandling(){
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
        for (Opportunity opp : oppList){
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
        List<Opportunity> newOppList = new List<Opportunity>{newOpp1, newOpp2, newOpp3};
        Test.startTest();
            Map<Id,Subscription_Change_Event__e> eventMap = new Map<Id,Subscription_Change_Event__e>();
            OpportunityTriggerHandler handler = new OpportunityTriggerHandler();
            eventMap = handler.eventHandling(newOppList, oldOppMap);
        Test.stopTest();
        System.assert(eventMap.containsKey(oppList[0].AccountId));
        System.assert(eventMap.containsKey(oppList[1].AccountId));
        System.assert(eventMap.containsKey(oppList[2].AccountId));
        System.assert(eventMap.containsKey(newAccount.Id));
    }
    @IsTest
    public static void testNMCTariffChange() {
        Map<String, Boolean> featureFlagMap = new Map<String, Boolean>{'Sizing_Method'=>false,'Subscription_Orders'=>true};
        FeatureService featureServiceMock = (FeatureService) Test.createStub(FeatureService.class, new FeatureService.Mock(featureFlagMap));
        SubscriptionManagementService.featureService = featureServiceMock;
        Opportunity opp = [
            SELECT Id, Name
            FROM Opportunity
            WHERE Name = 'RecalcUALOpp8A'
            ORDER BY Name
            LIMIT 1
        ];
        List<Utility_Account_Subscription__c> uasList = [
            SELECT Id, Opportunity__c, Name, Annual_kWh_Subscription_Future_Rollup__c, Future_Customer_Subscription_KWDC_Rollup__c,
                Subscription_Type__c, Annual_kwh_subscription_future__c, Subscribed_Annual_Cost_of_Electricity__c, Subscription_Comment_c__c
            FROM Utility_Account_Subscription__c
            WHERE Opportunity__r.Name = :opp.Name
            ORDER BY Name
        ];
        FeatureService checkFeature = new FeatureService();
        if (!checkFeature.isEnabled('Subscription_Orders')) {
            SubscriptionManagementService subscriptionService = new SubscriptionManagementService();
            subscriptionService.insertSubscriptionOrdersForTests(uasList);
            uasList = [
                SELECT Id, Future_Customer_Subscription_KWDC_Rollup__c
                FROM Utility_Account_Subscription__c
                WHERE Opportunity__r.Name = :opp.Name
            ];
        }

        System.assertEquals(3, uasList.size());
        System.assertEquals(2.3200, uasList[0].Future_Customer_Subscription_KWDC_Rollup__c);
        System.assertEquals(6.9600, uasList[1].Future_Customer_Subscription_KWDC_Rollup__c);
        System.assertEquals(7.6800, uasList[2].Future_Customer_Subscription_KWDC_Rollup__c);
        Set<Id> uasIds = new Set<Id>();
        for (Utility_Account_Subscription__c uas : uasList){
            uasIds.add(uas.Id);
        }
        List<Subscription_Order__c> soList = [
            SELECT Id, Approval_Status__c,
                Approved_Change_in_Subscription__c, Calculated_Change_in_Subscription_KW_DC__c, Name,
                Change_in_Annual_kWh__c, Utility_Account_Subscription__r.Name, Change_in_Annual_Cost__c, Type__c
            FROM Subscription_Order__c
            WHERE Utility_Account_Subscription__c IN :uasIds
        ];
        //Initial Subscription Orders
        System.assertEquals(3, soList.size());
        //Change NMC Tariff for Opportunity to create Resize Subscription Orders
        Utility_NMC_Tariff__c nmcRate = (Utility_NMC_Tariff__c) TestFactory.createSObject(new Utility_NMC_Tariff__c(Value_of_Net_Metering_Credit__c = .1567,
            Name = 'Nation Grid WCMA Class 2 - S/F 2016',
            Sizing_Rate__c = true,
            Date__c = Date.today()));
        insert nmcRate;
        Test.startTest();
        opp.NMC_Tariff__c = nmcRate.Id;
        update opp;
        Test.stopTest();
        List<Subscription_Order__c> resizeSOs = [
            SELECT Id, Utility_NMC_Tariff__c, Approval_Status__c, Approved_Change_in_Subscription__c
            FROM Subscription_Order__c
            WHERE Utility_Account_Subscription__c IN :uasIds
            AND Type__c = 'Resize'
        ];
        System.assertEquals(3, resizeSOs.size());
        for (Subscription_Order__c so : resizeSOs) {
            System.assertEquals(nmcRate.Id, so.Utility_NMC_Tariff__c);
            System.assertEquals('Approved', so.Approval_Status__c);
            System.assertNotEquals(null, so.Approved_Change_in_Subscription__c);
        }
    }

    @IsTest
    public static void testCSRecordTypeUpdates() {
        Opportunity noCustomerGroup = new Opportunity(
            Name = 'Test Opp',
            Product_Line__c = 'Community Solar',
            StageName = 'New',
            CloseDate = Date.today()
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