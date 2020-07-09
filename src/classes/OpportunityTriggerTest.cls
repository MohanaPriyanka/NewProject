@isTest
public with sharing class OpportunityTriggerTest {
    @testSetup static void setupData() {
        RecalculateUALCostControllerTest.setupTestData();
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
}