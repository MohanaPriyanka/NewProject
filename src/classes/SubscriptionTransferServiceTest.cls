/**
 * Created by PeterYao on 3/29/2021.
 */
@IsTest
public with sharing class SubscriptionTransferServiceTest {
    @TestSetup public static void setupData() {
        Test.startTest();
        Utility__c eversource = new Utility__c(
            Name = 'Eversource',
            Number_of_Decimal_Places__c = 2
        );
        Utility__c nationalGrid = new Utility__c(
            Name = 'National Grid',
            Number_of_Decimal_Places__c = 2
        );
        insert new List<Utility__c>{
            eversource, nationalGrid
        };

        Utility_NMC_Tariff__c everbillNMC = new Utility_NMC_Tariff__c(Name = 'Eversource SEMA Class 2',
            Utility__c = 'Eversource',
            Class__c = 'Class 2',
            Value_of_Net_Metering_Credit__c = 0.1848,
            Size_Ratio__c = .9,
            Current_Billing_Rate__c = true);
        Utility_NMC_Tariff__c eversizeNMC = new Utility_NMC_Tariff__c(Name = 'Eversource SEMA Class 2',
            Utility__c = 'Eversource',
            Class__c = 'Class 2',
            Value_of_Net_Metering_Credit__c = 0.1848,
            Size_Ratio__c = .9,
            Sizing_Rate__c = true);
        insert new List<Utility_NMC_Tariff__c>{
            everbillNMC, eversizeNMC
        };

        Shared_Solar_System__c sss1 =
            new Shared_Solar_System__c(Name = 'SSS1',
                Service_Territory__c = 'SEMA',
                Service_Territories__c = 'SEMA',
                Open__c = true,
                Reserved_Capacity_kW_DC__c = '0',
                Capacity_Committed_kW_DC__c = 0,
                Total_System_Size_kWh_DC__c = 1445.86,
                Total_System_Size_kW_AC__c = 996,
                Utility__c = eversource.Id,
                Credit_Score_Requirement__c = 200,
                Assignment_Order__c = '1',
                Utility_NMC_Tariff__c = eversizeNMC.Id,
                Expected_Yield_kWh_kW__c = 1300,
                Assemblage_Count__c = 1,
                Maximum_Subscription_Capacity_kWDC__c = 25,
                Billing_Method__c = 'NMC');
        Shared_Solar_System__c sss2 =
            new Shared_Solar_System__c(Name = 'SSS2',
                Service_Territory__c = 'SEMA',
                Service_Territories__c = 'SEMA',
                Open__c = true,
                Reserved_Capacity_kW_DC__c = '0',
                Capacity_Committed_kW_DC__c = 0,
                Total_System_Size_kWh_DC__c = 1225.86,
                Total_System_Size_kW_AC__c = 800,
                Utility__c = eversource.Id,
                Credit_Score_Requirement__c = 200,
                Assignment_Order__c = '1',
                Utility_NMC_Tariff__c = eversizeNMC.Id,
                Expected_Yield_kWh_kW__c = 1300,
                Assemblage_Count__c = 1,
                Maximum_Subscription_Capacity_kWDC__c = 25,
                Billing_Method__c = 'NMC');
        insert new List<Shared_Solar_System__c>{sss1, sss2};

        Account accountParent1 = new Account(Name = 'Parent Account 1');
        insert accountParent1;

        Account propAcct1 = new Account(Name = 'Prop Account 1',
            Parent_Account__c = accountParent1.Id,
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Property').getRecordTypeId()
        );
        insert propAcct1;

        Utility_Account_Log__c ualog1 = new Utility_Account_Log__c(
            Name = '0000234',
            Account__c = propAcct1.Id,
            Annual_Cost_of_Electricity__c = 10000,
            Name_on_Account__c = 'Name one');

        Utility_Account_Log__c ualog2 = new Utility_Account_Log__c(
            Name = '0000236',
            Account__c = propAcct1.Id,
            Annual_Cost_of_Electricity__c = 10000,
            Name_on_Account__c = 'Name two');

        Utility_Account_Log__c ualog3 = new Utility_Account_Log__c(
            Name = '0000238',
            Account__c = propAcct1.Id,
            Annual_Cost_of_Electricity__c = 10000,
            Name_on_Account__c = 'Name three');
        insert new List<Utility_Account_Log__c>{
            ualog1, ualog2, ualog3
        };

        Product2 normalCSProduct = new Product2(Name = 'BlueWave Community Solar',
            Family = 'Community Solar',
            Product_Type__c = 'Community Solar',
            Customer_Subscription_Type__c = 'kWh',
            State__c = 'MA',
            ProductCode = 'CS - BlueWave - 10%',
            IsActive = true,
            Lender_of_Record__c = 'BlueWave',
            NMC_Discount__c = 10,
            Annual_kWh_Maximum__c = 100000000,
            NM_Rate_Floor__c = 0,
            Days_in_Bill_Period__c = 20,
            Monthly_Late_Fee__c = 1,
            Cancellation_Paragraph_Two__c = 'Your cancellation will take up to 6 months',
            Cancellation_Paragraph_Three__c = 'There is a termination fee');
        insert normalCSProduct;

        Opportunity opportunityOne =
            new Opportunity(Name = 'Jordan Jordan 0000234',
                AccountId = propAcct1.Id,
                Shared_Solar_System__c = sss1.Id,
                StageName = 'Complete',
                Product__c = normalCSProduct.Id,
                NMC_Tariff__c = everbillNMC.Id,
                Product_Line__c = 'Community Solar',
                CloseDate = System.today());
        Opportunity opportunityThree =
            new Opportunity(Name = 'Jordan Jordan 0000238',
                AccountId = propAcct1.Id,
                Shared_Solar_System__c = sss1.Id,
                StageName = 'Complete',
                Product__c = normalCSProduct.Id,
                NMC_Tariff__c = everbillNMC.Id,
                Product_Line__c = 'Community Solar',
                CloseDate = System.today());
        insert new List<Opportunity>{opportunityOne, opportunityThree};

        Utility_Account_Subscription__c uasOne =
            new Utility_Account_Subscription__c(Name = '0000234',
                Utility_Account_Log__c = ualog1.Id,
                Opportunity__c = opportunityOne.Id,
                Sizing_Method__c = everbillNMC.Id,
                Next_Schedule_Z_Status__c = 'Active Subscription',
                Annual_kwh_subscription_future__c = 4000,
                calculated_annual_cost_of_electricity__c = 4000,
                Subscribed_Annual_Cost_of_Electricity__c = 4000);
        // Future_Customer_Subscription_KWDC_Rollup__c = 2.747134
        Utility_Account_Subscription__c uasTwo =
            new Utility_Account_Subscription__c(Name = '0000236',
                Utility_Account_Log__c = ualog2.Id,
                Opportunity__c = opportunityOne.Id,
                Sizing_Method__c = everbillNMC.Id,
                Next_Schedule_Z_Status__c = 'Active Subscription',
                Annual_kwh_subscription_future__c = 8000,
                calculated_annual_cost_of_electricity__c = 8000,
                Subscribed_Annual_Cost_of_Electricity__c = 8000);
        Utility_Account_Subscription__c uasThree =
            new Utility_Account_Subscription__c(Name = '0000238',
                Utility_Account_Log__c = ualog3.Id,
                Opportunity__c = opportunityThree.Id,
                Sizing_Method__c = everbillNMC.Id,
                Next_Schedule_Z_Status__c = 'Active Subscription',
                Annual_kwh_subscription_future__c = 0,
                calculated_annual_cost_of_electricity__c = 0,
                Subscribed_Annual_Cost_of_Electricity__c = 0);
        insert new List<Utility_Account_Subscription__c>{
            uasOne, uasTwo, uasThree
        };
    }

    @IsTest
    static void testChangeOpportunitySSS() {
        Opportunity opp = [
            SELECT Id, Shared_Solar_System__c,
            (SELECT Id, Shared_Solar_System__c FROM Utility_Account_Subscriptions__r)
            FROM Opportunity
            WHERE Name = 'Jordan Jordan 0000234'
        ];
        List<Shared_Solar_System__c> sharedSolarSystems = [
            SELECT Id, Name
            FROM Shared_Solar_System__c
        ];
        Map<Object, SObject> sssMap = CollectionUtil.mapByField(sharedSolarSystems, Shared_Solar_System__c.Name);
        System.assertEquals(sssMap.get('SSS1').Id, opp.Shared_Solar_System__c,
            'The opportunity should start with SSS1 and get moved to SSS2'
        );
        System.assertEquals(2, opp.Utility_Account_Subscriptions__r.size(),
            'The opportunity should start with two active subscriptions'
        );

        Test.startTest();
        InvocableOpportunitySystemUpdater.Request request = new InvocableOpportunitySystemUpdater.Request();
        request.opportunityId = opp.Id;
        request.sssId = sssMap.get('SSS2').Id;
        InvocableOpportunitySystemUpdater.changeSystem(new List<InvocableOpportunitySystemUpdater.Request>{request});
        Test.stopTest();

        opp = [
            SELECT Id, Shared_Solar_System__c,
            (SELECT Id, Shared_Solar_System__c, Next_Schedule_Z_Status__c, Annual_kWh_Subscription_Future_Rollup__c FROM Utility_Account_Subscriptions__r)
            FROM Opportunity
            WHERE Name = 'Jordan Jordan 0000234'
        ];
        System.assertEquals(sssMap.get('SSS2').Id, opp.Shared_Solar_System__c,
            'changeOpportunitySSS should have changed the SSS on the opp'
        );
        System.assertEquals(4, opp.Utility_Account_Subscriptions__r.size(),
            'There should be the 2 old, inactive subscriptions on SSS1, and 2 new subscriptions on SSS2'
        );
        for (Utility_Account_Subscription__c uas : opp.Utility_Account_Subscriptions__r) {
            if (uas.Next_Schedule_Z_Status__c == 'Inactive Subscription') {
                System.assertEquals(sssMap.get('SSS1').Id, uas.Shared_Solar_System__c,
                    'Inactive subscriptions should be for SSS1'
                );
                System.assertEquals(0, uas.Annual_kWh_Subscription_Future_Rollup__c,
                    'Inactive subscriptions should roll up to 0 Annual kWh'
                );
            } else {
                System.assertEquals(sssMap.get('SSS2').Id, uas.Shared_Solar_System__c,
                    'Active subscriptions should be for SSS1'
                );
            }
        }
        List<Subscription_Order__c> subscriptionOrders = [
            SELECT Id, Approved_Change_in_Subscription__c
            FROM Subscription_Order__c
            WHERE Utility_Account_Subscription__r.Next_Schedule_Z_Status__c = 'Inactive Subscription'
            AND Approved_Change_in_Subscription__c < 0
        ];
        System.assertEquals(2, subscriptionOrders.size(),
            'Should be a negative SO to zero out the inactive UAS for each UAS'
        );
        List<Subscription_Order__c> transferSubscriptionOrders = [
            SELECT Id, Approved_Change_in_Subscription__c, New_Annual_kWh__c, Utility_Account_Subscription__r.Name
            FROM Subscription_Order__c
            WHERE Utility_Account_Subscription__r.Next_Schedule_Z_Status__c = 'Active Subscription'
            AND Utility_Account_Subscription__r.Shared_Solar_System__r.Name = 'SSS2'
            AND Type__c = 'Transfer'
            ORDER BY Utility_Account_Subscription__r.Name
        ];
        System.assertEquals(2, transferSubscriptionOrders.size(),
            'Should a Transfer subscription order for each of the two UASes'
        );
        System.assertEquals('0000234', transferSubscriptionOrders[0].Utility_Account_Subscription__r.Name,
            'UAS 00000234 should have a transfer SO'
        );
        System.assertEquals(3895.51, transferSubscriptionOrders[0].New_Annual_kWh__c,
            'Expected New Annual kWh should get to an Approved Change in Subscription close to the previous UAS of 2.747134');
        System.assertEquals(2.696892, transferSubscriptionOrders[0].Approved_Change_in_Subscription__c,
            'Expected Approved Change in Subscription is as close to the previous UAS of 2.747134 as possible, maybe formulas ' +
                'changed without changing the SubscriptionTransferCalculator which backs into the New Annual kWh amount?');

        List<Subscription_Order__c> resizeSubscriptionOrders = [
            SELECT Id, New_Annual_kWh__c, Utility_Account_Subscription__r.Name
            FROM Subscription_Order__c
            WHERE Utility_Account_Subscription__r.Next_Schedule_Z_Status__c = 'Active Subscription'
            AND Utility_Account_Subscription__r.Shared_Solar_System__r.Name = 'SSS2'
            AND Type__c = 'Resize'
            ORDER BY Utility_Account_Subscription__r.Name
        ];
        System.assertEquals(2, resizeSubscriptionOrders.size(),
            'Should a Resize subscription order for each of the two UASes'
        );
        System.assertEquals('0000234', resizeSubscriptionOrders[0].Utility_Account_Subscription__r.Name,
            'UAS 00000234 should have a resize SO'
        );
        System.assertEquals(4000, resizeSubscriptionOrders[0].New_Annual_kWh__c,
            'Expected a resize SO to get back to the original UASes Annual kWh amount');
    }

    @IsTest
    private static void oppsWithNoSizeShouldBeAbleToMoveSystems() {
        List<Utility_Account_Subscription__c> utilityAccountSubscriptions = [
            SELECT Id, Future_Customer_Subscription_KWDC_Rollup__c, Opportunity__c, Opportunity__r.Shared_Solar_System__c, (
                SELECT Id FROM Subscription_Orders__r
            )
            FROM Utility_Account_Subscription__c
            WHERE Name = '0000238'
        ];
        System.assert(utilityAccountSubscriptions.size() == 1 &&
            utilityAccountSubscriptions[0].Future_Customer_Subscription_KWDC_Rollup__c == 0 &&
            utilityAccountSubscriptions[0].Subscription_Orders__r.size() == 1,
            'Expected one UAS with 0 Future Customer Subscription kWDC Rollup with a single SO, like UAS a1d5b0000084OjPAAU,' +
                ' but got ' + JSON.serialize(utilityAccountSubscriptions));
        List<Shared_Solar_System__c> sharedSolarSystems = [
            SELECT Id, Name
            FROM Shared_Solar_System__c
        ];

        Map<Object, SObject> sssMap = CollectionUtil.mapByField(sharedSolarSystems, Shared_Solar_System__c.Name);
        System.assertEquals(sssMap.get('SSS1').Id, utilityAccountSubscriptions[0].Opportunity__r.Shared_Solar_System__c,
            'The opportunity should start with SSS1 and get moved to SSS2'
        );

        Test.startTest();
        InvocableOpportunitySystemUpdater.Request request = new InvocableOpportunitySystemUpdater.Request();
        request.opportunityId = utilityAccountSubscriptions[0].Opportunity__c;
        request.sssId = sssMap.get('SSS2').Id;
        InvocableOpportunitySystemUpdater.changeSystem(new List<InvocableOpportunitySystemUpdater.Request>{request});
        Test.stopTest();

        utilityAccountSubscriptions = [
            SELECT Id, Future_Customer_Subscription_KWDC_Rollup__c, Opportunity__c, Opportunity__r.Shared_Solar_System__c, (
                SELECT Id FROM Subscription_Orders__r
            )
            FROM Utility_Account_Subscription__c
            WHERE Name = '0000238'
            ORDER BY CreatedDate
        ];
        System.assert(utilityAccountSubscriptions.size() == 2 &&
            utilityAccountSubscriptions[0].Opportunity__c == utilityAccountSubscriptions[1].Opportunity__c &&
            utilityAccountSubscriptions[1].Opportunity__r.Shared_Solar_System__c == request.sssId,
            'Expected 2 UASes, both to the same Opportunity, which has an updated SSSId, but got \n' +
                JSON.serialize(utilityAccountSubscriptions)
        );
    }

    @IsTest
    static void testTransferToUAS() {
        // Simulating transfer from a1d5b000004jPF6AAM to a1d5b000004jPFuAAM
        sfab_FabricatedSObject fabbedUtility = new sfab_FabricatedSObject(Utility__c.class);
        fabbedUtility.setField(Utility__c.Number_of_Decimal_Places__c, 2);
        sfab_FabricatedSObject fabbedSSS = new sfab_FabricatedSObject(Shared_Solar_System__c.class);
        fabbedSSS.setField(Shared_Solar_System__c.Expected_Yield_kWh_kW__c, 1266);
        fabbedSSS.setField(Shared_Solar_System__c.Total_System_Size_kWh_DC__c, 1445);
        fabbedSSS.setParent('Utility__r', fabbedUtility);
        Shared_Solar_System__c sss = (Shared_Solar_System__c) fabbedSSS.toSObject();
        SubscriptionTransferService.sssSelector =
            (SharedSolarSystemsSelector) Test.createStub(SharedSolarSystemsSelector.class, new MockedSSSSelector(sss));

        sfab_FabricatedSObject fabbedSizingMethod = new sfab_FabricatedSObject(Utility_NMC_Tariff__c.class);
        fabbedSizingMethod.setField(Utility_NMC_Tariff__c.Name, 'National Grid SEMA - Class 2 2018');
        fabbedSizingMethod.setField(Utility_NMC_Tariff__c.Value_of_NMC__c, .186300);

        sfab_FabricatedSObject fabbedOldUAS = new sfab_FabricatedSObject(Utility_Account_Subscription__c.class);
        Id oldUASId = Util.getFakeId(Utility_Account_Subscription__c.SObjectType);
        fabbedOldUAS.setField(Utility_Account_Subscription__c.Id, oldUASId);
        fabbedOldUAS.setField(Utility_Account_Subscription__c.Subscription_Type__c, 'Electricity Cost ($)');
        fabbedOldUAS.setParent('Sizing_Method__r', fabbedSizingMethod);
        fabbedOldUAS.setField(Utility_Account_Subscription__c.Future_Customer_Subscription_KWDC_Rollup__c, 2.023000);

        sfab_FabricatedSObject fabbedNewUAS = new sfab_FabricatedSObject(Utility_Account_Subscription__c.class);
        Id newUASId = Util.incrementFakeId(oldUASId);
        fabbedNewUAS.setField(Utility_Account_Subscription__c.Id, newUASId);
        fabbedNewUAS.setField(Utility_Account_Subscription__c.Subscription_Type__c, 'Electricity Cost ($)');
        fabbedNewUAS.setField(Utility_Account_Subscription__c.Annual_Cost_Future_Rollup__c, 3619.71);
        fabbedNewUAS.setField(Utility_Account_Subscription__c.Shared_Solar_System__c, Util.getFakeId(Shared_Solar_System__c.SObjectType));
        fabbedNewUAS.setField(Utility_Account_Subscription__c.Future_Customer_Subscription_KWDC_Rollup__c, 0);

        List<Utility_Account_Subscription__c> mockedUASes =
            new List<Utility_Account_Subscription__c>{
                (Utility_Account_Subscription__c) fabbedOldUAS.toSObject(),
                (Utility_Account_Subscription__c) fabbedNewUAS.toSObject()
            };

        UASSelector.mockedUASes = mockedUASes;

        SubscriptionTransferService.uowForTransferSO = new fflib_SObjectUnitOfWork(
            new List<SObjectType>{
                Opportunity.SObjectType,
                Subscription_Transfer__c.SObjectType,
                Utility_Account_Subscription__c.SObjectType,
                Subscription_Order__c.SObjectType
            },
            new FFLibHelperTest.MockDML()
        );

        SubscriptionTransferService.uowForResizeSO = new fflib_SObjectUnitOfWork(
            new List<SObjectType>{
                Subscription_Order__c.SObjectType
            },
            new FFLibHelperTest.MockDML()
        );

        Test.startTest();
        InvocableSubscriptionTransferer.Request request = new InvocableSubscriptionTransferer.Request();
        request.oldUASId = oldUASId;
        request.newUASId = newUASId;
        request.amount = 5896.40;
        InvocableSubscriptionTransferer.transferSubscription(new List<InvocableSubscriptionTransferer.Request>{request});
        Test.stopTest();
        List<Subscription_Order__c> transferAndZeroSubscriptionOrders =
            FFLibHelperTest.getRegisterNewListFromUnitOfWork(SubscriptionTransferService.uowForTransferSO, 'Subscription_Order__c');
        System.assertEquals(2, transferAndZeroSubscriptionOrders.size(),
            'Expected one SO to zero out the old UAS, and a transfer SO to transfer the old UAS to the new');
        for (Subscription_Order__c so : transferAndZeroSubscriptionOrders) {
            if (so.New_Annual_Cost__c == 0) {
                System.assertEquals('Subscription Order was created to zero out UAS', so.Comments__c);
            } else {
                System.assertEquals(477.14, so.New_Annual_Cost__c.setScale(2),
                    'Per production SO a9W5b0000004whDEAQ, New annual Cost should be 477.15 to get an Approved Change of 2.023');
            }
        }
        List<Subscription_Order__c> resizeSubscriptionOrders =
            FFLibHelperTest.getRegisterNewListFromUnitOfWork(SubscriptionTransferService.uowForResizeSO, 'Subscription_Order__c');
        System.assertEquals(1, resizeSubscriptionOrders.size(),
            'Expected a resize SO for the new UAS');
        System.assertEquals(5896.40, resizeSubscriptionOrders[0].New_Annual_Cost__c,
            'Since the Invocable Request\'s amount is 5896.40, we should see the resize SO have that amount');
    }

    @IsTest
    static void testTransferCancelledUAS() {
        // Simulating transfer from a1d0a000001npxZAAQ to something else
        sfab_FabricatedSObject fabbedUtility = new sfab_FabricatedSObject(Utility__c.class);
        fabbedUtility.setField(Utility__c.Number_of_Decimal_Places__c, 2);
        sfab_FabricatedSObject fabbedSSS = new sfab_FabricatedSObject(Shared_Solar_System__c.class);
        fabbedSSS.setField(Shared_Solar_System__c.Expected_Yield_kWh_kW__c, 1266);
        fabbedSSS.setField(Shared_Solar_System__c.Total_System_Size_kWh_DC__c, 1445);
        fabbedSSS.setParent('Utility__r', fabbedUtility);
        Shared_Solar_System__c sss = (Shared_Solar_System__c) fabbedSSS.toSObject();
        SubscriptionTransferService.sssSelector =
            (SharedSolarSystemsSelector) Test.createStub(SharedSolarSystemsSelector.class, new MockedSSSSelector(sss));

        sfab_FabricatedSObject fabbedSizingMethod = new sfab_FabricatedSObject(Utility_NMC_Tariff__c.class);
        fabbedSizingMethod.setField(Utility_NMC_Tariff__c.Name, 'National Grid SEMA - Class 2 2018');
        fabbedSizingMethod.setField(Utility_NMC_Tariff__c.Value_of_NMC__c, .186300);

        sfab_FabricatedSObject fabbedOldUAS = new sfab_FabricatedSObject(Utility_Account_Subscription__c.class);
        Id oldUASId = Util.getFakeId(Utility_Account_Subscription__c.SObjectType);
        fabbedOldUAS.setField(Utility_Account_Subscription__c.Id, oldUASId);
        fabbedOldUAS.setField(Utility_Account_Subscription__c.Subscription_Type__c, 'Electricity Cost ($)');
        fabbedOldUAS.setParent('Sizing_Method__r', fabbedSizingMethod);
        fabbedOldUAS.setField(Utility_Account_Subscription__c.Future_Customer_Subscription_KWDC_Rollup__c, 0);

        sfab_FabricatedSObject fabbedCancellationSO = new sfab_FabricatedSObject(Subscription_Order__c.class);
        fabbedCancellationSO.setField(Subscription_Order__c.Type__c, 'Cancellation');
        fabbedCancellationSO.setField(Subscription_Order__c.Previous_kw_DC_Subscription__c, 2.023000);
        fabbedOldUAS.setChildren('Subscription_Orders__r', new List<sfab_FabricatedSObject>{fabbedCancellationSO});

        sfab_FabricatedSObject fabbedNewUAS = new sfab_FabricatedSObject(Utility_Account_Subscription__c.class);
        Id newUASId = Util.incrementFakeId(oldUASId);
        fabbedNewUAS.setField(Utility_Account_Subscription__c.Id, newUASId);
        fabbedNewUAS.setField(Utility_Account_Subscription__c.Subscription_Type__c, 'Electricity Cost ($)');
        fabbedNewUAS.setField(Utility_Account_Subscription__c.Annual_Cost_Future_Rollup__c, 3619.71);
        fabbedNewUAS.setField(Utility_Account_Subscription__c.Shared_Solar_System__c, Util.getFakeId(Shared_Solar_System__c.SObjectType));
        fabbedNewUAS.setField(Utility_Account_Subscription__c.Future_Customer_Subscription_KWDC_Rollup__c, 0);

        List<Utility_Account_Subscription__c> mockedUASes =
            new List<Utility_Account_Subscription__c>{
                (Utility_Account_Subscription__c) fabbedOldUAS.toSObject(),
                (Utility_Account_Subscription__c) fabbedNewUAS.toSObject()
            };

        UASSelector.mockedUASes = mockedUASes;

        SubscriptionTransferService.uowForTransferSO = new fflib_SObjectUnitOfWork(
            new List<SObjectType>{
                Opportunity.SObjectType,
                Subscription_Transfer__c.SObjectType,
                Utility_Account_Subscription__c.SObjectType,
                Subscription_Order__c.SObjectType
            },
            new FFLibHelperTest.MockDML()
        );

        SubscriptionTransferService.uowForResizeSO = new fflib_SObjectUnitOfWork(
            new List<SObjectType>{
                Subscription_Order__c.SObjectType
            },
            new FFLibHelperTest.MockDML()
        );

        Test.startTest();
        InvocableSubscriptionTransferer.Request request = new InvocableSubscriptionTransferer.Request();
        request.oldUASId = oldUASId;
        request.newUASId = newUASId;
        request.amount = 5896.40;
        InvocableSubscriptionTransferer.transferSubscription(new List<InvocableSubscriptionTransferer.Request>{request});
        Test.stopTest();
        List<Subscription_Order__c> transferAndZeroSubscriptionOrders =
            FFLibHelperTest.getRegisterNewListFromUnitOfWork(SubscriptionTransferService.uowForTransferSO, 'Subscription_Order__c');
        System.assertEquals(1, transferAndZeroSubscriptionOrders.size(),
            'Expected a transfer SO to transfer the old UAS to the new, but no SO to zero the old UAS because it is already 0');
        System.assertEquals(477.14, transferAndZeroSubscriptionOrders[0].New_Annual_Cost__c.setScale(2),
            'Per production SO a9W5b0000004whDEAQ, New annual Cost should be 477.15 to get an Approved Change of 2.023');

        List<Subscription_Order__c> resizeSubscriptionOrders =
            FFLibHelperTest.getRegisterNewListFromUnitOfWork(SubscriptionTransferService.uowForResizeSO, 'Subscription_Order__c');
        System.assertEquals(1, resizeSubscriptionOrders.size(),
            'Expected a resize SO for the new UAS');
        System.assertEquals(5896.40, resizeSubscriptionOrders[0].New_Annual_Cost__c,
            'Since the Invocable Request\'s amount is 5896.40, we should see the resize SO have that amount');
    }

    @IsTest
    private static void oppWithUASWithActiveALSShouldNotBeTransferred() {
        SubscriptionTransferService transferService = new SubscriptionTransferService();
        Opportunity unassignedOpp = getMockedOpp(false, null);
        Shared_Solar_System__c sssWithDifferentContractAssignmentEntity =
            getMockedSSSForDifferentContractAssignmentEntity(unassignedOpp.Shared_Solar_System__r.Contract_Assignment_Entity__c);

        Schedule_Z_Subscription__c activeALSS = new Schedule_Z_Subscription__c(
            Id = Util.getFakeId(Schedule_Z_Subscription__c.SObjectType)
        );
        SubscriptionTransferService.alssSelector =
            (ScheduleZSubscriptionSelector) Test.createStub(ScheduleZSubscriptionSelector.class, new MockedALSSSelector(new List<Schedule_Z_Subscription__c>{
                activeALSS
            }));
        try {
            transferService.validateNewSSSForOpp(unassignedOpp, sssWithDifferentContractAssignmentEntity);
            System.assert(false, 'Expected to not validate this SSS change because there are active ALSSes for this opp');
        } catch (Util.BWException bwe) {
            System.assert(bwe.getMessage().contains(SubscriptionTransferService.OPP_ON_ACTIVE_ALS),
                'Expected ' + SubscriptionTransferService.OPP_ON_ACTIVE_ALS + ' but got: ' + bwe.getMessage());
        }
    }

    @IsTest
    private static void oppWithoutAssignmentAgreementOrALSCanBeTransferred() {
        SubscriptionTransferService transferService = new SubscriptionTransferService();
        Opportunity unassignedOpp = getMockedOpp(false, null);
        Shared_Solar_System__c sssWithDifferentContractAssignmentEntity =
            getMockedSSSForDifferentContractAssignmentEntity(unassignedOpp.Shared_Solar_System__r.Contract_Assignment_Entity__c);

        SubscriptionTransferService.alssSelector =
            (ScheduleZSubscriptionSelector) Test.createStub(ScheduleZSubscriptionSelector.class, new MockedALSSSelector(new List<Schedule_Z_Subscription__c>()));
        System.assertEquals(null, unassignedOpp.Contract.Assignment_Agreement__c, 'The mocked opp\'s contract should not have an Assignment Agreement');
        try {
            transferService.validateNewSSSForOpp(unassignedOpp, sssWithDifferentContractAssignmentEntity);
        } catch (Util.BWException bwe) {
            System.assert(false, 'Expected be able to transfer to a SSS with a different Contract Assignment Entity if not yet assigned, but got this: ' + bwe.getMessage());
        }
    }

    @IsTest
    private static void oppWithRejectedAssignmentAgreementCanBeTransferred() {
        SubscriptionTransferService transferService = new SubscriptionTransferService();
        Opportunity oppWithRejectedAA = getMockedOpp(true, 'Rejected');
        Shared_Solar_System__c sssWithDifferentContractAssignmentEntity =
            getMockedSSSForDifferentContractAssignmentEntity(oppWithRejectedAA.Shared_Solar_System__r.Contract_Assignment_Entity__c);

        System.assertEquals('Rejected', oppWithRejectedAA.Contract.Assignment_Agreement__r.Status, 'The mocked opp\'s contract should have a rejected Assignment Agreement');
        try {
            transferService.validateNewSSSForOpp(oppWithRejectedAA, sssWithDifferentContractAssignmentEntity);
        } catch (Util.BWException bwe) {
            System.assert(false, 'Expected be able to transfer to a SSS with a different Contract Assignment Entity if the assignment was rejected, but got this: ' + bwe.getMessage());
        }

        SubscriptionTransferService.entitySelector = (EntitySelector) Test.createStub(EntitySelector.class, new MockedEntitySelector(null));
    }

    @IsTest
    private static void oppWithAssignmentAgreementCanBeTransferredToSSSWithSameCAE() {
        SubscriptionTransferService transferService = new SubscriptionTransferService();
        Opportunity oppWithDraftAA = getMockedOpp(true, 'Draft');
        Shared_Solar_System__c sssWithDifferentContractAssignmentEntity =
            getMockedSSSForDifferentContractAssignmentEntity(oppWithDraftAA.Shared_Solar_System__r.Contract_Assignment_Entity__c);
        System.debug(LoggingLevel.ERROR, sssWithDifferentContractAssignmentEntity.Id);
        System.assertNotEquals(
            oppWithDraftAA.Shared_Solar_System__r.Contract_Assignment_Entity__c,
            sssWithDifferentContractAssignmentEntity.Contract_Assignment_Entity__c,
            'The Opp\'s SSS and the transfer SSS should have different Contract Assignment Entities'
        );

        // The transferService selects all of the systems for the current opp's system's CAE, and checks to see if the
        // new SSS is in that list.
        SubscriptionTransferService.entitySelector = (EntitySelector) Test.createStub(EntitySelector.class, new MockedEntitySelector(new List<Shared_Solar_System__c>{
            oppWithDraftAA.Shared_Solar_System__r
        }));
        try {
            transferService.validateNewSSSForOpp(oppWithDraftAA, sssWithDifferentContractAssignmentEntity);
            System.assert(false, 'Expected to not be able to transfer an Opp with a non-rejected AA to a SSS with a different Contract Assignment Entity');
        } catch (Util.BWException bwe) {
            System.assert(bwe.getMessage().contains(SubscriptionTransferService.INVALID_CONTRACT_ASSIGNMENT_ENTITY),
                'Expected ' + SubscriptionTransferService.INVALID_CONTRACT_ASSIGNMENT_ENTITY + ', but got this: ' + bwe.getMessage());
        }

        SubscriptionTransferService.entitySelector = (EntitySelector) Test.createStub(EntitySelector.class, new MockedEntitySelector(new List<Shared_Solar_System__c>{
            oppWithDraftAA.Shared_Solar_System__r
        }));
        try {
            transferService.validateNewSSSForOpp(oppWithDraftAA, oppWithDraftAA.Shared_Solar_System__r);
        } catch (Util.BWException bwe) {
            System.assert(false, 'Transferring to a SSS that has the same Contract Assignment Entity should not throw an exception');
        }
    }


    private static Shared_Solar_System__c getMockedSSSForDifferentContractAssignmentEntity(Id contractAssignmentEntity) {
        sfab_FabricatedSObject fabbedContractAssignmentEntity2 = new sfab_FabricatedSObject(Entity__c.class);
        fabbedContractAssignmentEntity2.setField(Entity__c.Id, Util.incrementFakeId(contractAssignmentEntity));
        sfab_FabricatedSObject fabbedSSS2 = new sfab_FabricatedSObject(Shared_Solar_System__c.class);
        fabbedSSS2.setField(Shared_Solar_System__c.Id, Util.incrementFakeId(Util.getFakeId(Shared_Solar_System__c.SObjectType)));
        fabbedSSS2.setParent('Contract_Assignment_Entity__r', fabbedContractAssignmentEntity2);
        Shared_Solar_System__c sss = (Shared_Solar_System__c) fabbedSSS2.toSObject();
        return sss;
    }

    private static Opportunity getMockedOpp(Boolean addAssignmentAgreement, String assignmentAgreementStatus) {
        sfab_FabricatedSObject fabbedSSS = new sfab_FabricatedSObject(Shared_Solar_System__c.class);
        fabbedSSS.setField(Shared_Solar_System__c.Id, Util.getFakeId(Shared_Solar_System__c.SObjectType));
        fabbedSSS.setField(Shared_Solar_System__c.Contract_Assignment_Entity__c, Util.getFakeId(Entity__c.SObjectType));
        sfab_FabricatedSObject fabbedOpp = new sfab_FabricatedSObject(Opportunity.class);
        fabbedOpp.setField(Opportunity.Id, Util.getFakeId(Opportunity.SObjectType));
        fabbedOpp.setField(Opportunity.Shared_Solar_System__c, Util.getFakeId(Shared_Solar_System__c.SObjectType));
        fabbedOpp.setParent('Shared_Solar_System__r', fabbedSSS);

        if (addAssignmentAgreement) {
            sfab_FabricatedSObject fabbedAssignmentAgreement = new sfab_FabricatedSObject(Contract.class);
            fabbedAssignmentAgreement.setField(Contract.Id, Util.getFakeId(Contract.SObjectType));
            fabbedAssignmentAgreement.setField(Contract.Status, assignmentAgreementStatus);

            sfab_FabricatedSObject fabbedCustomerContract = new sfab_FabricatedSObject(Contract.class);
            fabbedCustomerContract.setField(Contract.Id, Util.getFakeId(Contract.SObjectType));
            fabbedCustomerContract.setField(Contract.Assignment_Agreement__c, Util.getFakeId(Contract.SObjectType));
            fabbedCustomerContract.setParent('Assignment_Agreement__r', fabbedAssignmentAgreement);

            fabbedOpp.setParent('Contract', fabbedCustomerContract);
        }

        Opportunity opp = (Opportunity) fabbedOpp.toSObject();
        return opp;
    }

    public class MockedALSSSelector extends MockProvider {
        public List<Schedule_Z_Subscription__c> alssesToReturn;
        public MockedALSSSelector(List<Schedule_Z_Subscription__c> alssesToReturn) {
            this.alssesToReturn = alssesToReturn;
        }
        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'getActiveALSSesForOpportunities' {
                    return alssesToReturn;
                }
            }
            return null;
        }
    }

    public class MockedEntitySelector extends MockProvider {
        public List<Shared_Solar_System__c> sharedSolarSystems;
        public MockedEntitySelector(List<Shared_Solar_System__c> sharedSolarSystems) {
            this.sharedSolarSystems = sharedSolarSystems;
        }

        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'getSystemsForContractAssignmentEntity' {
                    return sharedSolarSystems;
                }
            }
            return null;
        }
    }

    public class MockedSSSSelector extends MockProvider {
        private Shared_Solar_System__c sss;
        public MockedSSSSelector(Shared_Solar_System__c sss) {
            this.sss = sss;
        }
        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'selectOne' {
                    return sss;
                }
            }
            return null;
        }
    }


}