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

        Account parentAccount = new Account(Name = 'Test Account');
        insert parentAccount;

        Contact con = new Contact(FirstName = 'First',
                                  LastName = 'Last',
                                  AccountId = parentAccount.Id, 
                                  Active_Communities_User__c = true);
        insert con;

        Account propertyAcc = new Account(Name = 'Property Account',
                                          Parent_Account__c = parentAccount.Id);
        insert propertyAcc;

        Utility_NMC_Tariff__c nmcRate = 
            new Utility_NMC_Tariff__c(Value_of_Net_Metering_Credit__c = 1,
                                      Name = 'Nation Grid WCMA Class 2 - S/F 2016',
                                      Sizing_Rate__c = true,
                                      Date__c = Date.today());
        insert nmcRate;

        Shared_Solar_System__c sss1 = 
            new Shared_Solar_System__c(Name = 'Oxford Barrett St. P1',
                                       Service_Territory__c = 'WCMA',
                                       Open__c = true,
                                       Schedule_Z_Filed__c = false,
                                       Reserved_Capacity_kW_DC__c = '100',
                                       Capacity_Committed_kW_DC__c = 100,
                                       Total_System_Size_kWh_DC__c = 1000,
                                       Total_System_Size_kW_AC__c = 996,
                                       System_Utility__c = 'National Grid',
                                       Credit_Score_Requirement__c = 200,
                                       Assignment_order__c = '1',
                                       Utility_NMC_Tariff__c = nmcRate.Id,
                                       Expected_Yield_kWh_kW__c = 1300,
                                       Assemblage_Count__c = 1,
                                       Maximum_Subscription_Assemblage__c = 25);
        Shared_Solar_System__c sss2 = 
            new Shared_Solar_System__c(Name = 'Oxford Barrett St. P2',
                                       Service_Territory__c = 'WCMA',
                                       Open__c = true,
                                       Schedule_Z_Filed__c = false,
                                       Reserved_Capacity_kW_DC__c = '100',
                                       Capacity_Committed_kW_DC__c = 100,
                                       Total_System_Size_kWh_DC__c = 1000,
                                       System_Utility__c = 'National Grid',
                                       Credit_Score_Requirement__c = 200,
                                       Assignment_order__c = '2');
        Shared_Solar_System__c sss3 = 
            new Shared_Solar_System__c(Name = 'Oxford Barrett St. P3',
                                       Service_Territory__c = 'WCMA',
                                       Open__c = true,
                                       Schedule_Z_Filed__c = false,
                                       Reserved_Capacity_kW_DC__c = '100',
                                       Capacity_Committed_kW_DC__c = 100,
                                       Total_System_Size_kWh_DC__c = 1000,
                                       System_Utility__c = 'National Grid',
                                       Credit_Score_Requirement__c = 200,
                                       Assignment_order__c = '3');
        Shared_Solar_System__c sss4 = 
            new Shared_Solar_System__c(Name = 'Oxford Barrett St. P4',
                                       Service_Territory__c = 'WCMA',
                                       Open__c = true,
                                       Schedule_Z_Filed__c = false,
                                       Reserved_Capacity_kW_DC__c = '100',
                                       Capacity_Committed_kW_DC__c = 100,
                                       Total_System_Size_kWh_DC__c = 1000,
                                       System_Utility__c = 'National Grid',
                                       Credit_Score_Requirement__c = 200,
                                       Assignment_order__c = '4');
        Shared_Solar_System__c sss5 = 
            new Shared_Solar_System__c(Name = 'Closed Schedule Zed P1',
                                       Service_Territory__c = 'WCMA',
                                       Open__c = false,
                                       Schedule_Z_Filed__c = true,
                                       Reserved_Capacity_kW_DC__c = '100',
                                       Capacity_Committed_kW_DC__c = 100,
                                       Total_System_Size_kWh_DC__c = 1000,
                                       System_Utility__c = 'National Grid',
                                       Credit_Score_Requirement__c = 200,
                                       Assignment_order__c = '3');
        Shared_Solar_System__c sss6 = 
            new Shared_Solar_System__c(Name = 'Closed Schedule Zed P2',
                                       Service_Territory__c = 'WCMA',
                                       Open__c = false,
                                       Schedule_Z_Filed__c = true,
                                       Reserved_Capacity_kW_DC__c = '100',
                                       Capacity_Committed_kW_DC__c = 100,
                                       Total_System_Size_kWh_DC__c = 1000,
                                       System_Utility__c = 'National Grid',
                                       Credit_Score_Requirement__c = 200,
                                       Assignment_order__c = '4');
        Shared_Solar_System__c sss7 = 
            new Shared_Solar_System__c(Name = 'Closed Not Zed P1',
                                       Service_Territory__c = 'WCMA',
                                       Open__c = false,
                                       Schedule_Z_Filed__c = false,
                                       Reserved_Capacity_kW_DC__c = '100',
                                       Capacity_Committed_kW_DC__c = 100,
                                       Total_System_Size_kWh_DC__c = 1000,
                                       System_Utility__c = 'National Grid',
                                       Credit_Score_Requirement__c = 200,
                                       Assignment_order__c = '4');
        Shared_Solar_System__c sss8 = 
            new Shared_Solar_System__c(Name = 'Closed Not Zed P2',
                                       Service_Territory__c = 'WCMA',
                                       Open__c = false,
                                       Schedule_Z_Filed__c = false,
                                       Reserved_Capacity_kW_DC__c = '100',
                                       Capacity_Committed_kW_DC__c = 100,
                                       Total_System_Size_kWh_DC__c = 1000,
                                       System_Utility__c = 'National Grid',
                                       Credit_Score_Requirement__c = 200,
                                       Assignment_order__c = '5');
        insert new List<Shared_Solar_System__c>{sss1, sss2, sss3, sss4, sss5, sss6, sss7, sss8};

        Opportunity opp1 = new Opportunity(Name = 'Opp1',
                                           StageName = 'Closed won',
                                           CloseDate = System.today(),
                                           AccountId = propertyAcc.Id,
                                           Shared_Solar_System__c = sss1.Id);
        Opportunity opp2 = new Opportunity(Name = 'Opp2',
                                           StageName = 'Closed won',
                                           CloseDate = System.today(),
                                           AccountId = propertyAcc.Id,
                                           Shared_Solar_System__c = sss2.Id);
        Opportunity opp3 = new Opportunity(Name = 'Opp3',
                                           StageName = 'Closed won',
                                           CloseDate = System.today(),
                                           AccountId = propertyAcc.Id,
                                           Shared_Solar_System__c = sss3.Id);
        Opportunity opp4 = new Opportunity(Name = 'Opp4',
                                           StageName = 'Closed won',
                                           CloseDate = System.today(),
                                           AccountId = propertyAcc.Id,
                                           Shared_Solar_System__c = sss4.Id);
        Opportunity opp5 = new Opportunity(Name = 'Opp5',
                                           StageName = 'Closed won',
                                           CloseDate = System.today(),
                                           AccountId = propertyAcc.Id,
                                           Shared_Solar_System__c = sss5.Id);
        Opportunity opp6 = new Opportunity(Name = 'Opp6',
                                           StageName = 'Closed won',
                                           CloseDate = System.today(),
                                           AccountId = propertyAcc.Id,
                                           Shared_Solar_System__c = sss6.Id);
        Opportunity opp7 = new Opportunity(Name = 'Opp7',
                                           StageName = 'Closed won',
                                           CloseDate = System.today(),
                                           AccountId = propertyAcc.Id,
                                           Shared_Solar_System__c = sss7.Id);
        Opportunity opp8 = new Opportunity(Name = 'Opp8',
                                           StageName = 'Closed won',
                                           CloseDate = System.today(),
                                           AccountId = propertyAcc.Id,
                                           Shared_Solar_System__c = sss8.Id);
        Opportunity opp9 = new Opportunity(Name = 'Opp9',
                                           StageName = 'Closed won',
                                           CloseDate = System.today(),
                                           AccountId = propertyAcc.Id,
                                           Shared_Solar_System__c = sss8.Id);
        insert new List<Opportunity>{opp1, opp2, opp3, opp4, opp5, opp6, opp7, opp8, opp9};

        Utility_Account_Log__c ual = 
            new Utility_Account_Log__c(Account__c = propertyAcc.Id,
                                       Annual_Cost_of_Electricity__c = 0,
                                       Name_on_Account__c = 'Joey Chan');
        insert ual;

        Utility_Account_Subscription__c uas1 = 
            new Utility_Account_Subscription__c(Utility_Account_Log__c = ual.Id,
                                                Opportunity__c = opp1.Id,
                                                Calculated_Annual_Cost_of_Electricity__c = 5000,
                                                Subscribed_Annual_Cost_of_Electricity__c = 5000,
                                                Custom_Deduction_Order__c = 1);
        Utility_Account_Subscription__c uas2 = 
            new Utility_Account_Subscription__c(Utility_Account_Log__c = ual.Id,
                                                Opportunity__c = opp2.Id,
                                                Calculated_Annual_Cost_of_Electricity__c = 3000,
                                                Subscribed_Annual_Cost_of_Electricity__c = 3000,
                                                Custom_Deduction_Order__c = 2);
        Utility_Account_Subscription__c uas3 = 
            new Utility_Account_Subscription__c(Utility_Account_Log__c = ual.Id,
                                                Opportunity__c = opp3.Id,
                                                Calculated_Annual_Cost_of_Electricity__c = 2000,
                                                Subscribed_Annual_Cost_of_Electricity__c = 2000,
                                                Custom_Deduction_Order__c = 3);
        Utility_Account_Subscription__c uas4 = 
            new Utility_Account_Subscription__c(Utility_Account_Log__c = ual.Id,
                                                Opportunity__c = opp4.Id,
                                                Calculated_Annual_Cost_of_Electricity__c = 1000,
                                                Subscribed_Annual_Cost_of_Electricity__c = 1000,
                                                Custom_Deduction_Order__c = 4);
        Utility_Account_Subscription__c uas5 = 
            new Utility_Account_Subscription__c(Utility_Account_Log__c = ual.Id,
                                                Opportunity__c = opp5.Id,
                                                Calculated_Annual_Cost_of_Electricity__c = 3000,
                                                Subscribed_Annual_Cost_of_Electricity__c = 3000,
                                                Custom_Deduction_Order__c = 5);
        Utility_Account_Subscription__c uas6 = 
            new Utility_Account_Subscription__c(Utility_Account_Log__c = ual.Id,
                                                Opportunity__c = opp6.Id,
                                                Calculated_Annual_Cost_of_Electricity__c = 1000,
                                                Subscribed_Annual_Cost_of_Electricity__c = 1000,
                                                Custom_Deduction_Order__c = 6);
        Utility_Account_Subscription__c uas7 = 
            new Utility_Account_Subscription__c(Utility_Account_Log__c = ual.Id,
                                                Opportunity__c = opp7.Id,
                                                Calculated_Annual_Cost_of_Electricity__c = 2000,
                                                Subscribed_Annual_Cost_of_Electricity__c = 2000,
                                                Custom_Deduction_Order__c = 7);
        Utility_Account_Subscription__c uas8 = 
            new Utility_Account_Subscription__c(Utility_Account_Log__c = ual.Id,
                                                Opportunity__c = opp8.Id,
                                                Calculated_Annual_Cost_of_Electricity__c = 3000,
                                                Subscribed_Annual_Cost_of_Electricity__c = 3000,
                                                Custom_Deduction_Order__c = 8);
        Utility_Account_Subscription__c uas9 = 
            new Utility_Account_Subscription__c(Utility_Account_Log__c = ual.Id,
                                                Opportunity__c = opp9.Id,
                                                Calculated_Annual_Cost_of_Electricity__c = 3000,
                                                Subscribed_Annual_Cost_of_Electricity__c = 3000,
                                                Custom_Deduction_Order__c = 9);
        insert new List<Utility_Account_Subscription__c>{uas1, uas2, uas3, uas4, uas5, uas6, uas7, uas8, uas9};
    }

    @isTest static void testMethodOne() {
        Utility_Account_Log__c ual = [SELECT Id
                                      FROM Utility_Account_Log__c
                                      WHERE Name_on_Account__c = 'Joey Chan'];
        List<Utility_Account_Subscription__c> uasList; 
        uasList = [SELECT Id, Calculated_Annual_Cost_of_Electricity__c, Subscribed_Annual_Cost_of_Electricity__c,
                   Custom_Deduction_Order__c
                   FROM Utility_Account_Subscription__c
                   WHERE Utility_Account_Log__c = :ual.Id];
        Utility_Account_Subscription__c uas1, uas2, uas3, uas4;
        for (Utility_Account_Subscription__c uas : uasList) {
            if (uas.Custom_Deduction_Order__c == 1) {
                uas1 = uas;
            } else if (uas.Custom_Deduction_Order__c == 2) {
                uas2 = uas;
            } else if (uas.Custom_Deduction_Order__c == 3) {
                uas3 = uas;
            } else if (uas.Custom_Deduction_Order__c == 4) {
                uas4 = uas;
            }
        }

        Test.startTest();
        PageReference recalculateUALCost = Page.RecalculateUALCost;
        Test.setCurrentPage(recalculateUALCost);
        ApexPages.currentPage().getParameters().put('id', ual.Id);
        ApexPages.currentPage().getParameters().put('adminMode', '1');

        RecalculateUALCostController theController = new RecalculateUALCostController();
        
        //Set deduction for closed
        theController.closedUASActionList[0].action = 'Deduct and mark as Open';
        Id sssToBeOpenedId = theController.closedUASActionList[0].sss.Id;
        Shared_Solar_System__c sssToBeOpened = [SELECT Id, Open__c
                                                FROM Shared_Solar_System__c
                                                WHERE Id = :sssToBeOpenedId];
        System.assertEquals(sssToBeOpened.Open__c, false);

        theController.closedUASActionList[1].action = 'Deduct and keep as Closed';
        Id sssToKeepAsClosedId = theController.closedUASActionList[1].sss.Id;
        Shared_Solar_System__c sssToKeepAsClosed = [SELECT Id, Open__c
                                                    FROM Shared_Solar_System__c
                                                    WHERE Id = :sssToKeepAsClosedId];
        System.assertEquals(sssToKeepAsClosed.Open__c, false);

        //Set deduction for Schedule Z Filed
        theController.scheduleZFiledUASActionList[0].action = 'Deduct from Schedule Z Filed';

        //Set deduction for open
        theController.openUASActionList[0].action = 'Deduct and mark as Closed';
        Id sssToBeClosedId = theController.openUASActionList[0].sss.Id;
        Shared_Solar_System__c sssToBeClosed = [SELECT Id, Open__c
                                                FROM Shared_Solar_System__c
                                                WHERE Id = :sssToBeClosedId];
        System.assertEquals(sssToBeClosed.Open__c, true);

        theController.processDeduction();

        Test.stopTest();

        //Check if UAS has already been deducted
        Utility_Account_Subscription__c verifyuas1 = 
            [SELECT Id,Calculated_Annual_Cost_of_Electricity__c, Subscribed_Annual_Cost_of_Electricity__c 
             FROM Utility_Account_Subscription__c 
             WHERE Id = :uas1.Id];
        System.debug(uas1);
        System.debug(verifyuas1);
        System.assert(uas1.Subscribed_Annual_Cost_of_Electricity__c > 
                      verifyuas1.Subscribed_Annual_Cost_of_Electricity__c);

        Utility_Account_Subscription__c verifyuas2 = 
            [SELECT Id,Calculated_Annual_Cost_of_Electricity__c, Subscribed_Annual_Cost_of_Electricity__c 
             FROM Utility_Account_Subscription__c 
             WHERE Id = :uas2.Id];
        System.assert(uas2.Subscribed_Annual_Cost_of_Electricity__c > 
                      verifyuas2.Subscribed_Annual_Cost_of_Electricity__c);

        Utility_Account_Subscription__c verifyuas3 = 
            [SELECT Id,Calculated_Annual_Cost_of_Electricity__c, Subscribed_Annual_Cost_of_Electricity__c 
             FROM Utility_Account_Subscription__c 
             WHERE Id = :uas3.Id];
        System.assert(uas2.Subscribed_Annual_Cost_of_Electricity__c > 
                      verifyuas2.Subscribed_Annual_Cost_of_Electricity__c);

        Utility_Account_Subscription__c verifyuas4 = 
            [SELECT Id,Calculated_Annual_Cost_of_Electricity__c, Subscribed_Annual_Cost_of_Electricity__c 
             FROM Utility_Account_Subscription__c 
             WHERE Id = :uas4.Id];
        System.assert(uas2.Subscribed_Annual_Cost_of_Electricity__c > 
                      verifyuas2.Subscribed_Annual_Cost_of_Electricity__c);

        //Verify that there are still cost not yet 
        Utility_Account_Log__c verifyUAL = 
            [SELECT Id, Cost_not_yet_Allocated__c 
             FROM Utility_Account_Log__c 
             WHERE Id = :ual.Id];
        System.debug(verifyUAL);
        System.assert(verifyUAL.Cost_not_yet_Allocated__c > 0);

        // Check that Deduct and mark as Open/Closed works
        sssToBeOpened = [SELECT Id, Open__c
                         FROM Shared_Solar_System__c
                         WHERE Id = :sssToBeOpenedId];
        System.assertEquals(sssToBeOpened.Open__c, true);
        sssToBeClosed = [SELECT Id, Open__c
                         FROM Shared_Solar_System__c
                         WHERE Id = :sssToBeClosedId];
        System.assertEquals(sssToBeClosed.Open__c, false);
        sssToKeepAsClosed = [SELECT Id, Open__c
                             FROM Shared_Solar_System__c
                             WHERE Id = :sssToKeepAsClosedId];
        System.assertEquals(sssToKeepAsClosed.Open__c, false);

        // Check that Subscription Annual Cost is updated for everything
        // except the one Schedule Z Filed subscription for which we 
        // didn't update the action
        List<Utility_Account_Subscription__c> ualList = 
            [SELECT Id, Subscribed_Annual_Cost_of_Electricity__c,
             Custom_Deduction_Order__c
             FROM Utility_Account_Subscription__c
             WHERE Utility_Account_Log__c = :ual.Id
             AND Subscribed_Annual_Cost_of_Electricity__c > 0];
        System.assertEquals(2, ualList.size());
        System.assertEquals(6, ualList[0].Custom_Deduction_Order__c);
    }

    @isTest static void testCustomDeductionOrder() {
        Utility_Account_Log__c ual = [SELECT Id 
                                      FROM Utility_Account_Log__c
                                      WHERE Name_on_Account__c = 'Joey Chan'];

        List<Utility_Account_Subscription__c> uasList; 
        uasList = [SELECT Id, Calculated_Annual_Cost_of_Electricity__c, Custom_Deduction_Order__c,
                   Opportunity__c, 
                   Opportunity__r.Shared_Solar_System__r.Open__c, 
                   Opportunity__r.Shared_Solar_System__r.Schedule_Z_Filed__c,
                   Opportunity__r.Shared_Solar_System__r.Capacity_Available_to_be_Reserved__c,
                   Opportunity__r.Shared_Solar_System__r.Total_CS_Capacity_kW_DC_Formula__c,
                   Opportunity__r.Shared_Solar_System__r.Total_Capacity_Committed_Reserved__c
                   FROM Utility_Account_Subscription__c
                   WHERE Opportunity__r.Shared_Solar_System__r.Open__c = true
                   AND Opportunity__r.Shared_Solar_System__r.Schedule_Z_Filed__c = false
                   AND Utility_Account_Log__c = :ual.Id];
        System.assertEquals(4, uasList.size());

        for (Utility_Account_Subscription__c uas : uasList) {
            if (uas.Calculated_Annual_Cost_of_Electricity__c == 5000) {
                System.assertEquals(1, uas.Custom_Deduction_Order__c);
            } else if (uas.Calculated_Annual_Cost_of_Electricity__c == 3000) {
                System.assertEquals(2, uas.Custom_Deduction_Order__c);
            } else if (uas.Calculated_Annual_Cost_of_Electricity__c == 2000) {
                System.assertEquals(3, uas.Custom_Deduction_Order__c);
            } else if (uas.Calculated_Annual_Cost_of_Electricity__c == 1000) {
                System.assertEquals(4, uas.Custom_Deduction_Order__c);
            }
        }

        Test.startTest();

        PageReference recalculateUALCost = Page.RecalculateUALCost;
        Test.setCurrentPage(recalculateUALCost);
        ApexPages.currentPage().getParameters().put('id', ual.Id);
        ApexPages.currentPage().getParameters().put('adminMode', '1');

        RecalculateUALCostController theController = new RecalculateUALCostController();
        // Adjustment amount should be total of all subscriptions
        System.assertEquals(-23000, theController.adjustmentAmount);

        // All subscriptions should be available to be ordered
        System.assertEquals(4, theController.openUASActionList.size());

        // Set custom order
        for (RecalculateUALCostController.UASAction uasAction : theController.openUASActionList) {
            if (uasAction.uas.Calculated_Annual_Cost_of_Electricity__c == 5000 &&
                uasAction.uas.Custom_Deduction_Order__c == 1) {
                uasAction.uas.Custom_Deduction_Order__c = 8;
                theController.uasId = uasAction.uas.Id;
            }
        }

        // should set custom order
        theController.customDeductionOrder();
        uasList = [SELECT Id, Calculated_Annual_Cost_of_Electricity__c, Custom_Deduction_Order__c
                   FROM Utility_Account_Subscription__c
                   WHERE Utility_Account_Log__c = :ual.Id];

        for (Utility_Account_Subscription__c uas : uasList) {
            if (uas.Calculated_Annual_Cost_of_Electricity__c == 5000) {
                System.assertEquals(8, uas.Custom_Deduction_Order__c);
            }
        }

        theController.processDeduction();

        Test.stopTest();

        uasList = [SELECT Id, Calculated_Annual_Cost_of_Electricity__c, Custom_Deduction_Order__c
                   FROM Utility_Account_Subscription__c
                   WHERE Opportunity__r.Shared_Solar_System__r.Open__c = true
                   AND Opportunity__r.Shared_Solar_System__r.Schedule_Z_Filed__c = false
                   AND Utility_Account_Log__c = :ual.Id];

        for (Utility_Account_Subscription__c uas : uasList) {
            if (uas.Calculated_Annual_Cost_of_Electricity__c == 5000) {
                System.assertEquals(8, uas.Custom_Deduction_Order__c);
            } else if (uas.Calculated_Annual_Cost_of_Electricity__c == 3000) {
                System.assertEquals(2, uas.Custom_Deduction_Order__c);
            } else if (uas.Calculated_Annual_Cost_of_Electricity__c == 2000) {
                System.assertEquals(3, uas.Custom_Deduction_Order__c);
            } else if (uas.Calculated_Annual_Cost_of_Electricity__c == 1000) {
                System.assertEquals(4, uas.Custom_Deduction_Order__c);
            }
        }
    }

    @isTest static void testNonAdmin() {
        Utility_Account_Log__c ual = [SELECT Id
                                      FROM Utility_Account_Log__c
                                      WHERE Name_on_Account__c = 'Joey Chan'];
        List<Utility_Account_Subscription__c> uasList; 
        uasList = [SELECT Id, Calculated_Annual_Cost_of_Electricity__c, Subscribed_Annual_Cost_of_Electricity__c,
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
        
            //Set deduction for closed, deduction order 7
            System.assertEquals(7, theController.closedUASActionList[0].uas.Custom_Deduction_Order__c);
            theController.closedUASActionList[0].action = 'Deduct and mark as Open';
            Id sssToBeOpenedId = theController.closedUASActionList[0].sss.Id;


            //Set deduction for Schedule Z Filed, deduction order 5
            System.assertEquals(5, theController.scheduleZFiledUASActionList[0].uas.Custom_Deduction_Order__c);
            theController.scheduleZFiledUASActionList[0].action = 'Deduct from Schedule Z Filed';

            //Set deduction for open, deduction order 1
            System.assertEquals(1, theController.openUASActionList[0].uas.Custom_Deduction_Order__c);
            theController.openUASActionList[0].action = 'Deduct and mark as Closed';
            Id sssToBeClosedId = theController.openUASActionList[0].sss.Id;

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
                   AND Custom_Deduction_Order__c = 7]; 
            System.assertEquals(2000, uas.Subscribed_Annual_Cost_of_Electricity__c);

            uas = [SELECT Id, Subscribed_Annual_Cost_of_Electricity__c, Custom_Deduction_Order__c
                   FROM Utility_Account_Subscription__c
                   WHERE Utility_Account_Log__c = :ual.Id
                   AND Custom_Deduction_Order__c = 5]; 
            System.assertEquals(3000, uas.Subscribed_Annual_Cost_of_Electricity__c);

            Shared_Solar_System__c sssToBeOpened = [SELECT Id, Open__c
                                                    FROM Shared_Solar_System__c
                                                    WHERE Id = :sssToBeOpenedId];
            System.assertEquals(sssToBeOpened.Open__c, false);
        }
    }
}