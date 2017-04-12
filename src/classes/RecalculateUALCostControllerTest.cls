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
                                       Total_System_Size_kWh_DC__c = 800,
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
                                       Estimated_COD_Date_Manual__c = System.today() + 10,
                                       Assignment_order__c = '2');
        Shared_Solar_System__c sss3 = 
            new Shared_Solar_System__c(Name = 'Oxford Barrett St. P3',
                                       Service_Territory__c = 'WCMA',
                                       Open__c = true,
                                       Schedule_Z_Filed__c = false,
                                       Reserved_Capacity_kW_DC__c = '100',
                                       Capacity_Committed_kW_DC__c = 100,
                                       Total_System_Size_kWh_DC__c = 800,
                                       System_Utility__c = 'National Grid',
                                       Credit_Score_Requirement__c = 200,
                                       Estimated_COD_Date_Manual__c = System.today() + 10,
                                       Assignment_order__c = '3');
        Shared_Solar_System__c sss4 = 
            new Shared_Solar_System__c(Name = 'Oxford Barrett St. P4',
                                       Service_Territory__c = 'WCMA',
                                       Open__c = true,
                                       Schedule_Z_Filed__c = false,
                                       Reserved_Capacity_kW_DC__c = '100',
                                       Capacity_Committed_kW_DC__c = 100,
                                       Total_System_Size_kWh_DC__c = 1200,
                                       System_Utility__c = 'National Grid',
                                       Credit_Score_Requirement__c = 200,
                                       Estimated_COD_Date_Manual__c = System.today() + 20,
                                       Assignment_order__c = '4');
        Shared_Solar_System__c sss5 = 
            new Shared_Solar_System__c(Name = 'Oxford Barrett St. P5',
                                       Service_Territory__c = 'WCMA',
                                       Open__c = true,
                                       Schedule_Z_Filed__c = false,
                                       Reserved_Capacity_kW_DC__c = '100',
                                       Capacity_Committed_kW_DC__c = 100,
                                       Total_System_Size_kWh_DC__c = 800,
                                       System_Utility__c = 'National Grid',
                                       Credit_Score_Requirement__c = 200,
                                       Assignment_order__c = '5');
        Shared_Solar_System__c sss6 = 
            new Shared_Solar_System__c(Name = 'Closed Schedule Zed P1',
                                       Service_Territory__c = 'WCMA',
                                       Open__c = false,
                                       Schedule_Z_Filed__c = true,
                                       Reserved_Capacity_kW_DC__c = '100',
                                       Capacity_Committed_kW_DC__c = 100,
                                       Total_System_Size_kWh_DC__c = 800,
                                       System_Utility__c = 'National Grid',
                                       Credit_Score_Requirement__c = 200,
                                       Assignment_order__c = '3');
        Shared_Solar_System__c sss7 = 
            new Shared_Solar_System__c(Name = 'Closed Schedule Zed P2',
                                       Service_Territory__c = 'WCMA',
                                       Open__c = false,
                                       Schedule_Z_Filed__c = true,
                                       Reserved_Capacity_kW_DC__c = '100',
                                       Capacity_Committed_kW_DC__c = 100,
                                       Total_System_Size_kWh_DC__c = 800,
                                       System_Utility__c = 'National Grid',
                                       Credit_Score_Requirement__c = 200,
                                       Assignment_order__c = '4');
        Shared_Solar_System__c sss8 = 
            new Shared_Solar_System__c(Name = 'Closed Not Zed P1',
                                       Service_Territory__c = 'WCMA',
                                       Open__c = false,
                                       Schedule_Z_Filed__c = false,
                                       Reserved_Capacity_kW_DC__c = '100',
                                       Capacity_Committed_kW_DC__c = 100,
                                       Total_System_Size_kWh_DC__c = 800,
                                       System_Utility__c = 'National Grid',
                                       Credit_Score_Requirement__c = 200,
                                       Assignment_order__c = '4');
        Shared_Solar_System__c sss9 = 
            new Shared_Solar_System__c(Name = 'Closed Not Zed P2',
                                       Service_Territory__c = 'WCMA',
                                       Open__c = false,
                                       Schedule_Z_Filed__c = false,
                                       Reserved_Capacity_kW_DC__c = '100',
                                       Capacity_Committed_kW_DC__c = 100,
                                       Total_System_Size_kWh_DC__c = 800,
                                       System_Utility__c = 'National Grid',
                                       Credit_Score_Requirement__c = 200,
                                       Utility_NMC_Tariff__c = nmcRate.Id,
                                       Expected_Yield_kWh_kW__c = 1300,
                                       Assemblage_Count__c = 1,
                                       Maximum_Subscription_Assemblage__c = 25,
                                       Assignment_order__c = '5');
        Shared_Solar_System__c sss10 = 
            new Shared_Solar_System__c(Name = 'Closed Not Zed P3',
                                       Service_Territory__c = 'WCMA',
                                       Open__c = false,
                                       Schedule_Z_Filed__c = false,
                                       Reserved_Capacity_kW_DC__c = '100',
                                       Capacity_Committed_kW_DC__c = 100,
                                       Total_System_Size_kWh_DC__c = 800,
                                       System_Utility__c = 'National Grid',
                                       Credit_Score_Requirement__c = 200,
                                       Utility_NMC_Tariff__c = nmcRate.Id,
                                       Expected_Yield_kWh_kW__c = 1300,
                                       Assemblage_Count__c = 1,
                                       Maximum_Subscription_Assemblage__c = 25,
                                       Assignment_order__c = '5');
        insert new List<Shared_Solar_System__c>{sss1, sss2, sss3, sss4, sss5, sss6, sss7, sss8, sss9, sss10};

        Opportunity opp1 = new Opportunity(Name = 'Opp1',
                                           StageName = 'Closed won',
                                           CloseDate = System.today(),
                                           AccountId = propertyAcc.Id,
                                           Product_Line__c = 'Community Solar',
                                           Shared_Solar_System__c = sss1.Id);
        Opportunity opp2 = new Opportunity(Name = 'Opp2',
                                           StageName = 'Closed won',
                                           CloseDate = System.today(),
                                           AccountId = propertyAcc.Id,
                                           Product_Line__c = 'Community Solar',
                                           Shared_Solar_System__c = sss2.Id);
        Opportunity opp3 = new Opportunity(Name = 'Opp3',
                                           StageName = 'Closed won',
                                           CloseDate = System.today(),
                                           AccountId = propertyAcc.Id,
                                           Product_Line__c = 'Community Solar',
                                           Shared_Solar_System__c = sss3.Id);
        Opportunity opp4 = new Opportunity(Name = 'Opp4',
                                           StageName = 'Closed won',
                                           CloseDate = System.today(),
                                           AccountId = propertyAcc.Id,
                                           Product_Line__c = 'Community Solar',
                                           Shared_Solar_System__c = sss4.Id);
        Opportunity opp5 = new Opportunity(Name = 'Opp5',
                                           StageName = 'Closed won',
                                           CloseDate = System.today(),
                                           AccountId = propertyAcc.Id,
                                           Product_Line__c = 'Community Solar',
                                           Shared_Solar_System__c = sss5.Id);
        Opportunity opp6 = new Opportunity(Name = 'Opp6',
                                           StageName = 'Closed won',
                                           CloseDate = System.today(),
                                           AccountId = propertyAcc.Id,
                                           Product_Line__c = 'Community Solar',
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
                                           NMC_Tariff__c = nmcRate.Id,
                                           Product_Line__c = 'Community Solar',
                                           Shared_Solar_System__c = sss9.Id);
        Opportunity opp9 = new Opportunity(Name = 'Opp9',
                                           StageName = 'Closed won',
                                           CloseDate = System.today(),
                                           AccountId = propertyAcc.Id,
                                           NMC_Tariff__c = nmcRate.Id,
                                           Product_Line__c = 'Community Solar',
                                           Shared_Solar_System__c = sss9.Id);
        Opportunity opp10 = new Opportunity(Name = 'Opp10',
                                           StageName = 'Closed won',
                                           CloseDate = System.today(),
                                           AccountId = propertyAcc.Id,
                                           NMC_Tariff__c = nmcRate.Id,
                                           Product_Line__c = 'Community Solar',
                                           Shared_Solar_System__c = sss10.Id);
        insert new List<Opportunity>{opp1, opp2, opp3, opp4, opp5, opp6, opp7, opp8, opp9, opp10};

        Utility_Account_Log__c ual = 
            new Utility_Account_Log__c(Account__c = propertyAcc.Id,
                                       Annual_Cost_of_Electricity__c = 0,
                                       Name_on_Account__c = 'Joey Chan');
        insert ual;

        Utility_Account_Subscription__c uas1 = 
            new Utility_Account_Subscription__c(Utility_Account_Log__c = ual.Id,
                                                Name = 'uas1',
                                                Opportunity__c = opp1.Id,
                                                Subscribed_Annual_Cost_of_Electricity__c = 5000,
                                                Next_Schedule_Z_Status__c = 'Not Enacted: Addition',
                                                Custom_Deduction_Order__c = 1);
        Utility_Account_Subscription__c uas2 = 
            new Utility_Account_Subscription__c(Utility_Account_Log__c = ual.Id,
                                                Name = 'uas2',
                                                Opportunity__c = opp2.Id,
                                                Subscribed_Annual_Cost_of_Electricity__c = 1000,
                                                Next_Schedule_Z_Status__c = 'Enacted: Removed',
                                                Custom_Deduction_Order__c = 2);
        Utility_Account_Subscription__c uas3 = 
            new Utility_Account_Subscription__c(Utility_Account_Log__c = ual.Id,
                                                Name = 'uas3',
                                                Opportunity__c = opp3.Id,
                                                Subscribed_Annual_Cost_of_Electricity__c = 1000,
                                                Next_Schedule_Z_Status__c = 'Enacted',
                                                Custom_Deduction_Order__c = 3);
        Utility_Account_Subscription__c uas4 = 
            new Utility_Account_Subscription__c(Utility_Account_Log__c = ual.Id,
                                                Name = 'uas4',
                                                Opportunity__c = opp4.Id,
                                                Subscribed_Annual_Cost_of_Electricity__c = 1000,
                                                Next_Schedule_Z_Status__c = 'Not Enacted: Addition',
                                                Custom_Deduction_Order__c = 4);
        Utility_Account_Subscription__c uas5 = 
            new Utility_Account_Subscription__c(Utility_Account_Log__c = ual.Id,
                                                Name = 'uas5',
                                                Opportunity__c = opp5.Id,
                                                Subscribed_Annual_Cost_of_Electricity__c = 1000,
                                                Next_Schedule_Z_Status__c = 'Not Enacted: Addition',
                                                Custom_Deduction_Order__c = 5);
        Utility_Account_Subscription__c uas6 = 
            new Utility_Account_Subscription__c(Utility_Account_Log__c = ual.Id,
                                                Name = 'uas6',
                                                Opportunity__c = opp6.Id,
                                                Subscribed_Annual_Cost_of_Electricity__c = 3000,
                                                Next_Schedule_Z_Status__c = 'Not Enacted: Addition',
                                                Custom_Deduction_Order__c = 6);
        Utility_Account_Subscription__c uas7 = 
            new Utility_Account_Subscription__c(Utility_Account_Log__c = ual.Id,
                                                Name = 'uas7',
                                                Opportunity__c = opp7.Id,
                                                Subscribed_Annual_Cost_of_Electricity__c = 1000,
                                                Next_Schedule_Z_Status__c = 'Not Enacted: Addition',
                                                Custom_Deduction_Order__c = 7);
        Utility_Account_Subscription__c uas8 = 
            new Utility_Account_Subscription__c(Utility_Account_Log__c = ual.Id,
                                                Name = 'uas8',
                                                Opportunity__c = opp8.Id,
                                                Subscribed_Annual_Cost_of_Electricity__c = 3000,
                                                Next_Schedule_Z_Status__c = 'Not Enacted: Addition',
                                                // Customer_Subscription_KW_DC__c = 3000 / 1 / 1300 =  2.3077
                                                UAS_Number__c = 2,
                                                Custom_Deduction_Order__c = 8);
        Utility_Account_Subscription__c uas9 = 
            new Utility_Account_Subscription__c(Utility_Account_Log__c = ual.Id,
                                                Name = 'uas9',
                                                Opportunity__c = opp8.Id,
                                                Subscribed_Annual_Cost_of_Electricity__c = 9000,
                                                Next_Schedule_Z_Status__c = 'Enacted: Removed',
                                                // Customer_Subscription_KW_DC__c = 9000 / 1 / 1300 =  6.9230
                                                UAS_Number__c = 3,
                                                Custom_Deduction_Order__c = 9);
        Utility_Account_Subscription__c uas10 = 
            new Utility_Account_Subscription__c(Utility_Account_Log__c = ual.Id,
                                                Name = 'uas10',
                                                Opportunity__c = opp8.Id,
                                                Subscribed_Annual_Cost_of_Electricity__c = 10000,
                                                Next_Schedule_Z_Status__c = 'Enacted',
                                                // Customer_Subscription_KW_DC__c = 10000 / 1 / 1300 =  7.6923
                                                UAS_Number__c = 4,
                                                Custom_Deduction_Order__c = 10);
        Utility_Account_Subscription__c uas11 = 
            new Utility_Account_Subscription__c(Utility_Account_Log__c = ual.Id,
                                                Name = 'uas11',
                                                Opportunity__c = opp9.Id,
                                                Subscribed_Annual_Cost_of_Electricity__c = 10000,
                                                Next_Schedule_Z_Status__c = 'Not Enacted: Addition',
                                                // Customer_Subscription_KW_DC__c = 10000 / 1 / 1300 =  7.6923
                                                UAS_Number__c = 4,
                                                Custom_Deduction_Order__c = 11);
        Utility_Account_Subscription__c uas12 = 
            new Utility_Account_Subscription__c(Utility_Account_Log__c = ual.Id,
                                                Name = 'uas12',
                                                Opportunity__c = opp10.Id,
                                                Subscribed_Annual_Cost_of_Electricity__c = 2000,
                                                Next_Schedule_Z_Status__c = 'Not Enacted: Addition',
                                                // Customer_Subscription_KW_DC__c = 10000 / 1 / 1300 =  7.6923
                                                UAS_Number__c = 4,
                                                Custom_Deduction_Order__c = 11);
        insert new List<Utility_Account_Subscription__c>{uas1, uas2, uas3, uas4, uas5, uas6, uas7, uas8, uas9, uas10, uas11, uas12};
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
            if (uasAction.uas.Name == 'uas1') {
                uas1 = uasAction.uas.clone(true,false,false,false);
                System.assertEquals(uasAction.uas.Custom_Deduction_Order__c, 5);
                System.debug(LoggingLevel.ERROR, 'uas1: ' + uas1.Subscribed_Annual_Cost_of_Electricity__c);
            } else if (uasAction.uas.Name == 'uas2') {
                uas2 = uasAction.uas.clone(true,false,false,false);
                System.assertEquals(uasAction.uas.Custom_Deduction_Order__c, 2);
            } else if (uasAction.uas.Name == 'uas3') {
                uas3 = uasAction.uas.clone(true,false,false,false);
                System.assertEquals(uasAction.uas.Custom_Deduction_Order__c, 3);
            } else if (uasAction.uas.Name == 'uas4') {
                uas4 = uasAction.uas.clone(true,false,false,false);
                System.assertEquals(uasAction.uas.Custom_Deduction_Order__c, 1);
                uasAction.action = 'Deduct and mark as Closed';
                sssToBeClosedId = theController.uasActionList[0].sss.Id;
                sssToBeClosed = [SELECT Id, Open__c
                                 FROM Shared_Solar_System__c
                                 WHERE Id = :sssToBeClosedId];
                System.assertEquals(sssToBeClosed.Open__c, true);
            } else if (uasAction.uas.Name == 'uas5') {
                uas5 = uasAction.uas.clone(true,false,false,false);
                System.assertEquals(uasAction.uas.Custom_Deduction_Order__c, 4);
            } else if (uasAction.uas.Name == 'uas6') {
                uas6 = uasAction.uas.clone(true,false,false,false);
                System.assertEquals(uasAction.uas.Custom_Deduction_Order__c, 12);
                uasAction.action = 'Deduct from Schedule Z Filed';
            } else if (uasAction.uas.Name == 'uas7') {
                uas7 = uasAction.uas.clone(true,false,false,false);
                System.assertEquals(uasAction.uas.Custom_Deduction_Order__c, 11);
            } else if (uasAction.uas.Name == 'uas8') {
                uas8 = uasAction.uas.clone(true,false,false,false);
                System.assertEquals(uasAction.uas.Custom_Deduction_Order__c, 7);

            } else if (uasAction.uas.Name == 'uas9') {
                uas9 = uasAction.uas.clone(true,false,false,false);
                System.assertEquals(uasAction.uas.Custom_Deduction_Order__c, 8);
                uasAction.action = 'Deduct and keep as Closed';
            } else if (uasAction.uas.Name == 'uas10') {
                uas10 = uasAction.uas.clone(true,false,false,false);
                // UAS10 and UAS 11 can switch places
                // System.assertEquals(uasAction.uas.Custom_Deduction_Order__c, 9);
            } else if (uasAction.uas.Name == 'uas11') {
                uas11 = uasAction.uas.clone(true,false,false,false);
                // UAS10 and UAS 11 can switch places
                // System.assertEquals(uasAction.uas.Custom_Deduction_Order__c, 10);
                uasAction.action = 'Deduct and mark as Open';
                sssToBeOpenedId = uasAction.sss.Id;
                sssToBeOpened = [SELECT Id, Open__c
                                 FROM Shared_Solar_System__c
                                 WHERE Id = :sssToBeOpenedId];
                System.assertEquals(sssToBeOpened.Open__c, false);
                System.debug(LoggingLevel.ERROR, 'sssToBeOpened.Open__c: ' + sssToBeOpened.Open__c);
            } else if (uasAction.uas.Name == 'uas12') {
                uas12 = uasAction.uas.clone(true,false,false,false);
                System.assertEquals(uasAction.uas.Custom_Deduction_Order__c, 6);
                uasAction.action = 'Deduct and keep as Closed';
                sssToKeepAsClosedId = uasAction.sss.Id;
                sssToKeepAsClosed = [SELECT Id, Open__c
                                     FROM Shared_Solar_System__c
                                     WHERE Id = :sssToKeepAsClosedId];
                System.assertEquals(sssToKeepAsClosed.Open__c, false);
            }
        }

        for (RecalculateUALCostController.UASAction ua : theController.uasActionList) {
            System.debug(ua);
        }

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
            [SELECT Id, Name, Subscribed_Annual_Cost_of_Electricity__c,
             Custom_Deduction_Order__c
             FROM Utility_Account_Subscription__c
             WHERE Utility_Account_Log__c = :ual.Id
             AND Subscribed_Annual_Cost_of_Electricity__c > 0];
        System.debug(LoggingLevel.ERROR, ualList);
        System.assertEquals(3, ualList.size());
    }

    @isTest static void testCustomDeductionOrder() {
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
        System.assertEquals(-47000, theController.adjustmentAmount);

        // All subscriptions should be available to be ordered
        Utility_Account_Subscription__c uas1, uas2, uas3, uas4, uas5, uas6, uas7, uas8, uas9, uas10, uas11, uas12;
        for (RecalculateUALCostController.UASAction uasAction : theController.uasActionList) {
            if (uasAction.uas.Name == 'uas1') {
                uas1 = uasAction.uas;
            } else if (uasAction.uas.Name == 'uas2') {
                uas2 = uasAction.uas;
            } else if (uasAction.uas.Name == 'uas3') {
                uas3 = uasAction.uas;
            } else if (uasAction.uas.Name == 'uas4') {
                uas4 = uasAction.uas;
            } else if (uasAction.uas.Name == 'uas5') {
                uas5 = uasAction.uas;
            } else if (uasAction.uas.Name == 'uas6') {
                uas6 = uasAction.uas;
            } else if (uasAction.uas.Name == 'uas7') {
                uas7 = uasAction.uas;
            } else if (uasAction.uas.Name == 'uas8') {
                uas8 = uasAction.uas;
            } else if (uasAction.uas.Name == 'uas9') {
                uas9 = uasAction.uas;
            } else if (uasAction.uas.Name == 'uas10') {
                uas10 = uasAction.uas;
            } else if (uasAction.uas.Name == 'uas11') {
                uas11 = uasAction.uas;
            } else if (uasAction.uas.Name == 'uas12') {
                uas12 = uasAction.uas;
            }
        }

        // Set custom order
        for (RecalculateUALCostController.UASAction uasAction : theController.uasActionList) {
            if (uasAction.uas.Subscribed_Annual_Cost_of_Electricity__c == 5000 &&
                uasAction.uas.Custom_Deduction_Order__c == 5) {
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

        uasList = [SELECT Id, Subscribed_Annual_Cost_of_Electricity__c, Custom_Deduction_Order__c
                   FROM Utility_Account_Subscription__c
                   WHERE Opportunity__r.Shared_Solar_System__r.Open__c = true
                   AND Opportunity__r.Shared_Solar_System__r.Schedule_Z_Filed__c = false
                   AND Utility_Account_Log__c = :ual.Id];

        for (Utility_Account_Subscription__c uas : uasList) {
            if (uas.Subscribed_Annual_Cost_of_Electricity__c == 5000) {
                System.assertEquals(8, uas.Custom_Deduction_Order__c);
            } else if (uas.Subscribed_Annual_Cost_of_Electricity__c == 3000) {
                System.assertEquals(2, uas.Custom_Deduction_Order__c);
            } else if (uas.Subscribed_Annual_Cost_of_Electricity__c == 2000) {
                System.assertEquals(3, uas.Custom_Deduction_Order__c);
            } else if (uas.Subscribed_Annual_Cost_of_Electricity__c == 1000) {
                System.assertEquals(4, uas.Custom_Deduction_Order__c);
            }
        }
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
                   AND Name = 'uas12']; 
            System.assertEquals(2000, uas.Subscribed_Annual_Cost_of_Electricity__c);

            uas = [SELECT Id, Subscribed_Annual_Cost_of_Electricity__c, Custom_Deduction_Order__c
                   FROM Utility_Account_Subscription__c
                   WHERE Utility_Account_Log__c = :ual.Id
                   AND Name = 'uas7']; 
            System.assertEquals(1000, uas.Subscribed_Annual_Cost_of_Electricity__c);

            Shared_Solar_System__c sssToBeOpened = [SELECT Id, Open__c
                                                    FROM Shared_Solar_System__c
                                                    WHERE Id = :sssToBeOpenedId];
            System.assertEquals(sssToBeOpened.Open__c, false);
        }
    }
}