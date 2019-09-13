@isTest
public class RecalculateUALCostControllerTest {
    @testSetup public static void setupTestData() {
        Profile bfgStandardUser = 
            [SELECT Id from Profile WHERE Name = 'BFG Standard User'];
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
        Account byCostAccount, bykWhAccount;
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

    @isTest static void testMethodOne() {
        Utility_Account_Log__c ual = [SELECT Id
                                      FROM Utility_Account_Log__c
                                      WHERE Name_on_Account__c = 'Joey Chan'];
        List<Utility_Account_Subscription__c> uasList;

        Test.startTest();
        PageReference recalculateUALCost = Page.RecalculateUALCost;
        Test.setCurrentPage(recalculateUALCost);
        ApexPages.currentPage().getParameters().put('id', ual.Id);
        ApexPages.currentPage().getParameters().put('adminMode', '1');

        RecalculateUALCostController theController = new RecalculateUALCostController();
      

        Utility_Account_Subscription__c uas1, uas2, uas3, uas4, uas5, uas6, uas7, uas8, uas9, uas10, uas11, uas12;
        Id sssToBeOpenedId, sssToKeepAsClosedId, sssToBeClosedId;
        Shared_Solar_System__c sssToBeOpened, sssToKeepAsClosed, sssToBeClosed;
        System.assertEquals(theController.uasActionList.size(), 12);
        for (RecalculateUALCostController.UASAction uasAction : theController.uasActionList) {
            if (uasAction.uas.Name == 'uas01A') {
                uas1 = uasAction.uas.clone(true,false,false,false);
            } else if (uasAction.uas.Name == 'uas02A') {
                uas2 = uasAction.uas.clone(true,false,false,false);
            } else if (uasAction.uas.Name == 'uas03A') {
                uas3 = uasAction.uas.clone(true,false,false,false);
            } else if (uasAction.uas.Name == 'uas04A') {
                uas4 = uasAction.uas.clone(true,false,false,false);
                uasAction.action = 'Deduct and mark as Closed';
                sssToBeClosedId = theController.uasActionList[0].sss.Id;
                sssToBeClosed = [SELECT Id, Open__c
                                 FROM Shared_Solar_System__c
                                 WHERE Id = :sssToBeClosedId];
                System.assertEquals(sssToBeClosed.Open__c, true);
            } else if (uasAction.uas.Name == 'uas05A') {
                uas5 = uasAction.uas.clone(true,false,false,false);
            } else if (uasAction.uas.Name == 'uas06A') {
                uas6 = uasAction.uas.clone(true,false,false,false);
                uasAction.action = 'Deduct from Schedule Z Filed';
            } else if (uasAction.uas.Name == 'uas07A') {
                uas7 = uasAction.uas.clone(true,false,false,false);
                //System.assertEquals(uasAction.uas.Custom_Deduction_Order__c, 6);
            } else if (uasAction.uas.Name == 'uas08A') {
                uas8 = uasAction.uas.clone(true,false,false,false);
            } else if (uasAction.uas.Name == 'uas09A') {
                uas9 = uasAction.uas.clone(true,false,false,false);
                uasAction.action = 'Deduct and keep as Closed';
            } else if (uasAction.uas.Name == 'uas10A') {
                uas10 = uasAction.uas.clone(true,false,false,false);
                // UAS10 and UAS 11 can switch places
                // System.assertEquals(uasAction.uas.Custom_Deduction_Order__c, 9);
            } else if (uasAction.uas.Name == 'uas11A') {
                uas11 = uasAction.uas.clone(true,false,false,false);
                // UAS10 and UAS 11 can switch places
                // System.assertEquals(uasAction.uas.Custom_Deduction_Order__c, 10);
                uasAction.action = 'Deduct and mark as Open';
                sssToBeOpenedId = uasAction.sss.Id;
                sssToBeOpened = [SELECT Id, Open__c
                                 FROM Shared_Solar_System__c
                                 WHERE Id = :sssToBeOpenedId];
                System.assertEquals(sssToBeOpened.Open__c, false);
            } else if (uasAction.uas.Name == 'uas12A') {
                uas12 = uasAction.uas.clone(true,false,false,false);
                uasAction.action = 'Deduct and keep as Closed';
                sssToKeepAsClosedId = uasAction.sss.Id;
                sssToKeepAsClosed = [SELECT Id, Open__c
                                     FROM Shared_Solar_System__c
                                     WHERE Id = :sssToKeepAsClosedId];
                System.assertEquals(sssToKeepAsClosed.Open__c, false);
            }
        }
        System.assertEquals(uas1.Custom_Deduction_Order__c, 5);
        System.assertEquals(uas2.Custom_Deduction_Order__c, 2);
        System.assertEquals(uas3.Custom_Deduction_Order__c, 3);
        System.assertEquals(uas4.Custom_Deduction_Order__c, 1);
        System.assertEquals(uas5.Custom_Deduction_Order__c, 4);
        System.assertEquals(uas6.Custom_Deduction_Order__c, 12);
        System.assertEquals(uas7.Custom_Deduction_Order__c, 11);
        System.assertEquals(uas8.Custom_Deduction_Order__c, 7);
        System.assertEquals(uas9.Custom_Deduction_Order__c, 8);
        System.assertEquals(uas12.Custom_Deduction_Order__c, 6);


        theController.processDeduction();

        Test.stopTest();

        //Check if UAS has already been deducted
        Utility_Account_Subscription__c verifyuas1 = 
            [SELECT Id, Subscribed_Annual_Cost_of_Electricity__c 
             FROM Utility_Account_Subscription__c 
             WHERE Id = :uas1.Id];
        System.assert(uas1.Subscribed_Annual_Cost_of_Electricity__c > 
                      verifyuas1.Subscribed_Annual_Cost_of_Electricity__c);

        Utility_Account_Subscription__c verifyuas2 = 
            [SELECT Id, Subscribed_Annual_Cost_of_Electricity__c 
             FROM Utility_Account_Subscription__c 
             WHERE Id = :uas2.Id];
        System.assert(uas2.Subscribed_Annual_Cost_of_Electricity__c > 
                      verifyuas2.Subscribed_Annual_Cost_of_Electricity__c);

        Utility_Account_Subscription__c verifyuas3 = 
            [SELECT Id, Subscribed_Annual_Cost_of_Electricity__c 
             FROM Utility_Account_Subscription__c 
             WHERE Id = :uas3.Id];
        System.assert(uas2.Subscribed_Annual_Cost_of_Electricity__c > 
                      verifyuas2.Subscribed_Annual_Cost_of_Electricity__c);

        Utility_Account_Subscription__c verifyuas4 = 
            [SELECT Id, Subscribed_Annual_Cost_of_Electricity__c 
             FROM Utility_Account_Subscription__c 
             WHERE Id = :uas4.Id];
        System.assert(uas2.Subscribed_Annual_Cost_of_Electricity__c > 
                      verifyuas2.Subscribed_Annual_Cost_of_Electricity__c);

        //Verify that there are still cost not yet 
        Utility_Account_Log__c verifyUAL = 
            [SELECT Id, Cost_not_yet_Allocated__c 
             FROM Utility_Account_Log__c 
             WHERE Id = :ual.Id];
        System.assert(verifyUAL.Cost_not_yet_Allocated__c < 0);

        // Check that Deduct and mark as Open/Closed works
        sssToBeOpened = [SELECT Id, Open__c
                         FROM Shared_Solar_System__c
                         WHERE Id = :sssToBeOpenedId];
        System.assertEquals(true, sssToBeOpened.Open__c);
        sssToBeClosed = [SELECT Id, Open__c
                         FROM Shared_Solar_System__c
                         WHERE Id = :sssToBeClosedId];
        System.assertEquals(false, sssToBeClosed.Open__c);
        sssToKeepAsClosed = [SELECT Id, Open__c
                             FROM Shared_Solar_System__c
                             WHERE Id = :sssToKeepAsClosedId];
        System.assertEquals(false, sssToKeepAsClosed.Open__c);

        // Check that Subscription Annual Cost is updated for everything
        // except the one Schedule Z Filed subscription for which we 
        // didn't update the action
        List<Utility_Account_Subscription__c> ualList = 
            [SELECT Id, Name, Subscribed_Annual_Cost_of_Electricity__c,
             Custom_Deduction_Order__c
             FROM Utility_Account_Subscription__c
             WHERE Utility_Account_Log__c = :ual.Id
             AND Subscribed_Annual_Cost_of_Electricity__c > 0];
    }

    @isTest static void testCustomDeductionOrderByCost() {
        Utility_Account_Log__c ual = [SELECT Id
                                      FROM Utility_Account_Log__c
                                      WHERE Name_on_Account__c = 'Joey Chan'];

        Test.startTest();

        PageReference recalculateUALCost = Page.RecalculateUALCost;
        Test.setCurrentPage(recalculateUALCost);
        ApexPages.currentPage().getParameters().put('id', ual.Id);
        ApexPages.currentPage().getParameters().put('adminMode', '1');

        RecalculateUALCostController theController = new RecalculateUALCostController();
        // Adjustment amount should be total of all subscriptions
        // ual.Annual_Cost_of_Electricity = 0
        // adjustmentAmount = Annual_Cost_of_Electricity - total subscriptions
        System.assertEquals(-47000, theController.adjustmentAmount);


        // Set custom order
        for (RecalculateUALCostController.UASAction uasAction : theController.uasActionList) {
            if (uasAction.uas.Name == 'uas01A') {
                uasAction.uas.Custom_Deduction_Order__c = 8;
                theController.uasId = uasAction.uas.Id;
            } else if (uasAction.uas.Name == 'uas13A') {
                uasAction.uas.Custom_Deduction_Order__c = 1;
            }
        }

        // should set custom order
        theController.updateCustomDeductionOrder();
        List<Utility_Account_Subscription__c> uasList = 
            [SELECT Id, Subscribed_Annual_Cost_of_Electricity__c, Custom_Deduction_Order__c, Name
             FROM Utility_Account_Subscription__c
             WHERE Utility_Account_Log__c = :ual.Id];


        // All subscriptions should be available to be ordered
        Utility_Account_Subscription__c uas1, uas2, uas3, uas4, uas5;

        for (Utility_Account_Subscription__c uas : uasList) {
            if (uas.Name == 'uas01A') {
                uas1 = uas;
            }
        }
        System.assertEquals(8, uas1.Custom_Deduction_Order__c);

        theController.processDeduction();

        Test.stopTest();

        uasList = [
            SELECT Id, Subscribed_Annual_Cost_of_Electricity__c, Custom_Deduction_Order__c,
                Opportunity__r.Name, Name
            FROM Utility_Account_Subscription__c
            WHERE Opportunity__r.Shared_Solar_System__r.Open__c = true
            AND Opportunity__r.Shared_Solar_System__r.ScheduleZ_Filed__c = false
            AND Utility_Account_Log__c = :ual.Id
        ];

        for (Utility_Account_Subscription__c uas : uasList) {
            if (uas.Name == 'uas01A') {
                uas1 = uas;
            } else if (uas.Name == 'uas02A') {
                uas2 = uas;
            } else if (uas.Name == 'uas03A') {
                uas3 = uas;
            } else if (uas.Name == 'uas04A') {
                uas4 = uas;
            } else if (uas.Name == 'uas05A') {
                uas5 = uas;
            }
        }
        System.assertEquals(8, uas1.Custom_Deduction_Order__c);
        System.assertEquals(0, uas1.Subscribed_Annual_Cost_of_Electricity__c);
        System.assertEquals(2, uas2.Custom_Deduction_Order__c);
        System.assertEquals(0, uas2.Subscribed_Annual_Cost_of_Electricity__c);
        System.assertEquals(3, uas3.Custom_Deduction_Order__c);
        System.assertEquals(0, uas3.Subscribed_Annual_Cost_of_Electricity__c);
        System.assertEquals(4, uas4.Custom_Deduction_Order__c);
        System.assertEquals(0, uas4.Subscribed_Annual_Cost_of_Electricity__c);
        System.assertEquals(5, uas5.Custom_Deduction_Order__c);
        System.assertEquals(0, uas5.Subscribed_Annual_Cost_of_Electricity__c);
    }

    @isTest static void testCustomIncreaseOrderByCost() {
        Utility_Account_Log__c ual = [SELECT Id
                                      FROM Utility_Account_Log__c
                                      WHERE Name_on_Account__c = 'Joey Chan'];

        ual.Annual_Cost_of_Electricity__c = 48000;
        update ual;

        Test.startTest();

        PageReference recalculateUALCost = Page.RecalculateUALCost;
        Test.setCurrentPage(recalculateUALCost);
        ApexPages.currentPage().getParameters().put('id', ual.Id);
        ApexPages.currentPage().getParameters().put('adminMode', '1');

        RecalculateUALCostController theController = new RecalculateUALCostController();
        // Adjustment amount should be total of all subscriptions
        // ual.Annual_Cost_of_Electricity = 0
        // adjustmentAmount = Annual_Cost_of_Electricity - total subscriptions
        System.assertEquals(1000, theController.adjustmentAmount);

        // All subscriptions should be available to be ordered
        Utility_Account_Subscription__c uas1, uas2, uas3, uas4, uas5, uas6, uas7, uas8, uas9, uas10, uas11, uas12;

        // Set custom order
        for (RecalculateUALCostController.UASAction uasAction : theController.uasActionList) {
            if (uasAction.uas.Name == 'uas01A') {
                uasAction.uas.Custom_Deduction_Order__c = 8;
                theController.uasId = uasAction.uas.Id;
            }
        }

        // should set custom order
        theController.updateCustomDeductionOrder();
        List<Utility_Account_Subscription__c> uasList =
            [SELECT Id, Subscribed_Annual_Cost_of_Electricity__c, Custom_Deduction_Order__c
             FROM Utility_Account_Subscription__c
             WHERE Utility_Account_Log__c = :ual.Id];

        for (Utility_Account_Subscription__c uas : uasList) {
            if (uas.Subscribed_Annual_Cost_of_Electricity__c == 5000) {
                System.assertEquals(8, uas.Custom_Deduction_Order__c);
            }
        }

        theController.processDeduction();

        Test.stopTest();

        uasList = [
            SELECT Id, Subscribed_Annual_Cost_of_Electricity__c, Custom_Deduction_Order__c,
                Opportunity__r.Name, Name
            FROM Utility_Account_Subscription__c
            WHERE Opportunity__r.Shared_Solar_System__r.Open__c = true
            AND Opportunity__r.Shared_Solar_System__r.ScheduleZ_Filed__c = false
            AND Utility_Account_Log__c = :ual.Id
        ];

        for (Utility_Account_Subscription__c uas : uasList) {
            if (uas.Name == 'uas01A') {
                uas1 = uas;
            } else if (uas.Name == 'uas02A') {
                uas2 = uas;
            } else if (uas.Name == 'uas03A') {
                uas3 = uas;
            } else if (uas.Name == 'uas04A') {
                uas4 = uas;
            } else if (uas.Name == 'uas05A') {
                uas5 = uas;
            }
        }
        System.assertEquals(8, uas1.Custom_Deduction_Order__c);
        System.assertEquals(5000, uas1.Subscribed_Annual_Cost_of_Electricity__c);
        System.assertEquals(2, uas2.Custom_Deduction_Order__c);
        System.assertEquals(2000, uas2.Subscribed_Annual_Cost_of_Electricity__c);
        System.assertEquals(3, uas3.Custom_Deduction_Order__c);
        System.assertEquals(1000, uas3.Subscribed_Annual_Cost_of_Electricity__c);
        System.assertEquals(4, uas4.Custom_Deduction_Order__c);
        System.assertEquals(1000, uas4.Subscribed_Annual_Cost_of_Electricity__c);
        System.assertEquals(5, uas5.Custom_Deduction_Order__c);
        System.assertEquals(1000, uas5.Subscribed_Annual_Cost_of_Electricity__c);

    }

    @isTest static void testCustomDeductionOrderBykWH() {
        Utility_Account_Log__c ual = [
            SELECT Id, Subscribed_Annual_kWhs__c, Proposed_kWh__c
            FROM Utility_Account_Log__c
            WHERE Name_on_Account__c = 'Johnny Bravo'
        ];

        System.assertEquals(283000.00, ual.Subscribed_Annual_kWhs__c);
        System.assertEquals(00, ual.Proposed_kWh__c);

        Test.startTest();

        PageReference recalculateUALCost = Page.RecalculateUALCost;
        Test.setCurrentPage(recalculateUALCost);
        ApexPages.currentPage().getParameters().put('id', ual.Id);
        ApexPages.currentPage().getParameters().put('adminMode', '1');

        RecalculateUALCostController theController = new RecalculateUALCostController();
        // Adjustment amount should be total of all subscriptions
        // ual.Annual_Cost_of_Electricity = 0
        // adjustmentAmount = Annual_Cost_of_Electricity - total subscriptions
        System.assertEquals(-283000, theController.adjustmentAmount);


        // Set custom order
        for (RecalculateUALCostController.UASAction uasAction : theController.uasActionList) {
            if (uasAction.uas.Name == 'uas01B') {
                uasAction.uas.Custom_Deduction_Order__c = 8;
                theController.uasId = uasAction.uas.Id;
            }
        }

        // should set custom order
        theController.updateCustomDeductionOrder();
        List<Utility_Account_Subscription__c> uasList =
        [SELECT Id, Subscribed_Annual_Cost_of_Electricity__c, Custom_Deduction_Order__c, Name
        FROM Utility_Account_Subscription__c
        WHERE Utility_Account_Log__c = :ual.Id];


        // All subscriptions should be available to be ordered
        Utility_Account_Subscription__c uas1, uas2, uas3, uas4, uas5;

        for (Utility_Account_Subscription__c uas : uasList) {
            if (uas.Name == 'uas01B') {
                uas1 = uas;
            }
        }
        System.assertEquals(8, uas1.Custom_Deduction_Order__c);

        theController.processDeduction();

        Test.stopTest();

        uasList = [
            SELECT Id, Annual_kwh_subscription_future__c, Custom_Deduction_Order__c,
                Opportunity__r.Name, Name
            FROM Utility_Account_Subscription__c
            WHERE Opportunity__r.Shared_Solar_System__r.Open__c = true
            AND Opportunity__r.Shared_Solar_System__r.ScheduleZ_Filed__c = false
            AND Utility_Account_Log__c = :ual.Id
        ];

        for (Utility_Account_Subscription__c uas : uasList) {
            if (uas.Name == 'uas01B') {
                uas1 = uas;
            } else if (uas.Name == 'uas02B') {
                uas2 = uas;
            } else if (uas.Name == 'uas03B') {
                uas3 = uas;
            } else if (uas.Name == 'uas04B') {
                uas4 = uas;
            } else if (uas.Name == 'uas05B') {
                uas5 = uas;
            }
        }
        System.assertEquals(8, uas1.Custom_Deduction_Order__c);
        System.assertEquals(0, uas1.Annual_kwh_subscription_future__c);
        System.assertEquals(2, uas2.Custom_Deduction_Order__c);
        System.assertEquals(0, uas2.Annual_kwh_subscription_future__c);
        System.assertEquals(3, uas3.Custom_Deduction_Order__c);
        System.assertEquals(0, uas3.Annual_kwh_subscription_future__c);
        System.assertEquals(4, uas4.Custom_Deduction_Order__c);
        System.assertEquals(0, uas4.Annual_kwh_subscription_future__c);
        System.assertEquals(5, uas5.Custom_Deduction_Order__c);
        System.assertEquals(0, uas5.Annual_kwh_subscription_future__c);
    }

    @isTest static void testCustomIncreaseOrderBykWh() {
        Utility_Account_Log__c ual = [SELECT Id, Subscribed_Annual_kWhs__c
                                      FROM Utility_Account_Log__c
                                      WHERE Name_on_Account__c = 'Johnny Bravo'];

        System.assertEquals(283000.00, ual.Subscribed_Annual_kWhs__c);
        ual.Proposed_kWh__c = 320000; // 320000 - 283000 = 37000
        update ual;

        Test.startTest();

        PageReference recalculateUALCost = Page.RecalculateUALCost;
        Test.setCurrentPage(recalculateUALCost);
        ApexPages.currentPage().getParameters().put('id', ual.Id);
        ApexPages.currentPage().getParameters().put('adminMode', '1');

        RecalculateUALCostController theController = new RecalculateUALCostController();
        // Adjustment amount should be total of all subscriptions
        // ual.Annual_Cost_of_Electricity = 0
        // adjustmentAmount = Annual_Cost_of_Electricity - total subscriptions
        System.assertEquals(37000, theController.adjustmentAmount);

        // All subscriptions should be available to be ordered
        Utility_Account_Subscription__c uas1, uas2, uas3, uas4, uas5, uas6, uas7, uas8, uas9, uas10, uas11, uas12;

        // Set custom order
        for (RecalculateUALCostController.UASAction uasAction : theController.uasActionList) {
            if (uasAction.uas.Name == 'uas01B') {
                uasAction.uas.Custom_Deduction_Order__c = 8;
                theController.uasId = uasAction.uas.Id;
            }
        }

        // should set custom order
        theController.updateCustomDeductionOrder();
        List<Utility_Account_Subscription__c> uasList =
            [SELECT Id, Subscribed_Annual_Cost_of_Electricity__c, Custom_Deduction_Order__c, Name
             FROM Utility_Account_Subscription__c
             WHERE Utility_Account_Log__c = :ual.Id];

        for (Utility_Account_Subscription__c uas : uasList) {
            if (uas.Name == 'uas1B' ) {
                System.assertEquals(8, uas.Custom_Deduction_Order__c);
            }
        }

        theController.processDeduction();

        Test.stopTest();

        uasList = [
            SELECT Id, Annual_kwh_subscription_future__c, Custom_Deduction_Order__c,
                Opportunity__r.Name, Name
            FROM Utility_Account_Subscription__c
            WHERE Opportunity__r.Shared_Solar_System__r.Open__c = true
            AND Opportunity__r.Shared_Solar_System__r.ScheduleZ_Filed__c = false
            AND Utility_Account_Log__c = :ual.Id
        ];

        for (Utility_Account_Subscription__c uas : uasList) {
            if (uas.Name == 'uas01B') {
                uas1 = uas;
            } else if (uas.Name == 'uas02B') {
                uas2 = uas;
            } else if (uas.Name == 'uas03B') {
                uas3 = uas;
            } else if (uas.Name == 'uas04B') {
                uas4 = uas;
            } else if (uas.Name == 'uas05B') {
                uas5 = uas;
            }
        }
        System.assertEquals(8, uas1.Custom_Deduction_Order__c);
        System.assertEquals(27000, uas1.Annual_kwh_subscription_future__c);
        System.assertEquals(2, uas2.Custom_Deduction_Order__c);
        // max out one subscription
        System.assertEquals(32500, uas2.Annual_kwh_subscription_future__c);
        System.assertEquals(3, uas3.Custom_Deduction_Order__c);
        // add remainder of adjustment to next subscription
        System.assertEquals(15300, uas3.Annual_kwh_subscription_future__c);
        System.assertEquals(4, uas4.Custom_Deduction_Order__c);
        System.assertEquals(5400, uas4.Annual_kwh_subscription_future__c);
        System.assertEquals(5, uas5.Custom_Deduction_Order__c);
        System.assertEquals(5400, uas5.Annual_kwh_subscription_future__c);

    }

    @isTest static void testSubscriptionErrors() {
        // get a UAL that doesn't have a product
        Utility_Account_Log__c ual = [SELECT Id, Subscribed_Annual_kWhs__c
                                      FROM Utility_Account_Log__c
                                      WHERE Name_on_Account__c = 'Anchor UAL'];

        Test.startTest();

        PageReference recalculateUALCost = Page.RecalculateUALCost;
        Test.setCurrentPage(recalculateUALCost);
        ApexPages.currentPage().getParameters().put('id', ual.Id);
        ApexPages.currentPage().getParameters().put('adminMode', '1');

        try {
            RecalculateUALCostController theController = new RecalculateUALCostController();
        } catch (Util.BWException e) {
            String expectedError = 'There is no customer subcription type for this Subscription. Subscriptions cannot be sized with this tool';
            System.assertEquals(expectedError, e.getMessage());
        }


        ual = [
            SELECT Id, Subscribed_Annual_kWhs__c,
                (SELECT Id, Opportunity__r.Product__c
                FROM Utility_Account_Subscriptions__r
                ORDER BY Opportunity__r.Name ASC)
            FROM Utility_Account_Log__c
            WHERE Name_on_Account__c = 'Johnny Bravo'
        ];

        Product2 costProduct = [
            SELECT Id
            FROM Product2
            WHERE Name = 'Cost Product'
        ];

        ual.Utility_Account_Subscriptions__r[0].Opportunity__r.Product__c = costProduct.Id;
        update ual.Utility_Account_Subscriptions__r[0].Opportunity__r;

        Test.setCurrentPage(recalculateUALCost);
        ApexPages.currentPage().getParameters().put('id', ual.Id);
        ApexPages.currentPage().getParameters().put('adminMode', '1');

        try {
            RecalculateUALCostController theController = new RecalculateUALCostController();
        } catch (Util.BWException e) {
            String expectedError = 'Not all subscriptions have the same sizing method. Please review Opportunities and their Products';
            System.assertEquals(expectedError, e.getMessage());
        }
        Test.stopTest();
    }

    @isTest static void testNonAdmin() {
        Utility_Account_Log__c ual = [SELECT Id
                                      FROM Utility_Account_Log__c
                                      WHERE Name_on_Account__c = 'Joey Chan'];
        List<Utility_Account_Subscription__c> uasList; 
        uasList = [SELECT Id, Subscribed_Annual_Cost_of_Electricity__c,
                   Custom_Deduction_Order__c
                   FROM Utility_Account_Subscription__c
                   WHERE Utility_Account_Log__c = :ual.Id];

        User bfguser = [SELECT Id from User where Username = 'bfguser@test.com'];
        System.runAs(bfguser) {
            Test.startTest();
            PageReference recalculateUALCost = Page.RecalculateUALCost;
            Test.setCurrentPage(recalculateUALCost);
            ApexPages.currentPage().getParameters().put('id', ual.Id);

            RecalculateUALCostController theController = new RecalculateUALCostController();

            System.debug(LoggingLevel.ERROR, theController.uasActionList);
        
            //Set deduction for closed, deduction order 6
            System.assertEquals(6, theController.uasActionList[5].uas.Custom_Deduction_Order__c);
            theController.uasActionList[5].action = 'Deduct and mark as Open';
            Id sssToBeOpenedId = theController.uasActionList[5].sss.Id;


            //Set deduction for Schedule Z Filed, deduction order 11
            System.assertEquals(11, theController.uasActionList[10].uas.Custom_Deduction_Order__c);
            theController.uasActionList[10].action = 'Deduct from Schedule Z Filed';

            //Set deduction for open, deduction order 1
            System.assertEquals(1, theController.uasActionList[0].uas.Custom_Deduction_Order__c);
            theController.uasActionList[0].action = 'Deduct and mark as Closed';
            Id sssToBeClosedId = theController.uasActionList[0].sss.Id;

            theController.processDeduction();

            Test.stopTest();

            // The open SSS should have been processed
            Utility_Account_Subscription__c uas;
            uas = [SELECT Id, Subscribed_Annual_Cost_of_Electricity__c, Custom_Deduction_Order__c
                   FROM Utility_Account_Subscription__c
                   WHERE Utility_Account_Log__c = :ual.Id
                   AND Custom_Deduction_Order__c = 1]; 
            System.assertEquals(0, uas.Subscribed_Annual_Cost_of_Electricity__c);

            Shared_Solar_System__c sssToBeClosed = [SELECT Id, Open__c
                                                    FROM Shared_Solar_System__c
                                                    WHERE Id = :sssToBeClosedId];
            System.assertEquals(sssToBeClosed.Open__c, false);

            // Non-open ones shouldn't be updated
            uas = [SELECT Id, Subscribed_Annual_Cost_of_Electricity__c, Custom_Deduction_Order__c
                   FROM Utility_Account_Subscription__c
                   WHERE Utility_Account_Log__c = :ual.Id
                   AND Name = 'uas12A'];
            System.assertEquals(2000, uas.Subscribed_Annual_Cost_of_Electricity__c);

            uas = [SELECT Id, Subscribed_Annual_Cost_of_Electricity__c, Custom_Deduction_Order__c
                   FROM Utility_Account_Subscription__c
                   WHERE Utility_Account_Log__c = :ual.Id
                   AND Name = 'uas07A'];
            System.assertEquals(1000, uas.Subscribed_Annual_Cost_of_Electricity__c);

            Shared_Solar_System__c sssToBeOpened = [SELECT Id, Open__c
                                                    FROM Shared_Solar_System__c
                                                    WHERE Id = :sssToBeOpenedId];
            System.assertEquals(sssToBeOpened.Open__c, false);
        }
    }
}