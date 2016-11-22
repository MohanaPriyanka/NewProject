@isTest
private class RecalculateUALCostControllerTest {
    
    @isTest static void test_method_one() {

        Account parentAccount = (Account)TestFactory.createSObject(new Account(), 'TestFactory.AccountDefaults', true);

        Contact con = (Contact)TestFactory.createSObject(new Contact(AccountId = parentAccount.Id, Active_Communities_User__c = true), 'TestFactory.ContactDefaults', true);

        Account propertyAcc = (Account)TestFactory.createSObject(new Account(Parent_Account__c = parentAccount.Id), 'TestFactory.AccountDefaults', true);



        Utility_NMC_Tariff__c nmcRate =  (Utility_NMC_Tariff__c)TestFactory.createSObject(new Utility_NMC_Tariff__c(Value_of_Net_Metering_Credit__c = 1,
                                                                                                                    Name = 'Nation Grid WCMA Class 2 - S/F 2016',
                                                                                                                    Sizing_Rate__c = true,
                                                                                                                    Date__c = Date.today()), true);

        Shared_Solar_System__c sss1 = (Shared_Solar_System__c)TestFactory.createSObject(new Shared_Solar_System__c(Name = 'Oxford Barrett St. P1',
                                                                                                                    Service_Territory__c = 'WCMA',
                                                                                                                    Open__c = true,
                                                                                                                    Reserved_Capacity_kW_DC__c = '1000',
                                                                                                                    Capacity_Committed_kW_DC__c = 1000,
                                                                                                                    Total_System_Size_kWh_DC__c = 1445.86,
                                                                                                                    Total_System_Size_kW_AC__c  = 996,
                                                                                                                    System_Utility__c = 'National Grid',
                                                                                                                    Credit_Score_Requirement__c = 200,
                                                                                                                    Assignment_order__c = '1',
                                                                                                                    Utility_NMC_Tariff__c = nmcRate.Id,
                                                                                                                    Expected_Yield_kWh_kW__c = 1300,
                                                                                                                    Assemblage_Count__c = 1,
                                                                                                                    Maximum_Subscription_Assemblage__c = 25));

        Shared_Solar_System__c sss2 = (Shared_Solar_System__c)TestFactory.createSObject(new Shared_Solar_System__c(Name = 'Oxford Barrett St. P2',
                                                                                                                    Service_Territory__c = 'WCMA',
                                                                                                                    Open__c = false,
                                                                                                                    Schedule_Z_Filed__c = true,
                                                                                                                    Reserved_Capacity_kW_DC__c = '100',
                                                                                                                    Capacity_Committed_kW_DC__c = 100,
                                                                                                                    Total_System_Size_kWh_DC__c = 100,
                                                                                                                    System_Utility__c = 'National Grid',
                                                                                                                    Credit_Score_Requirement__c = 200,
                                                                                                                    Assignment_order__c = '2'));
        Shared_Solar_System__c sss3 = (Shared_Solar_System__c)TestFactory.createSObject(new Shared_Solar_System__c(Name = 'Oxford Barrett St. P3',
                                                                                                                    Service_Territory__c = 'WCMA',
                                                                                                                    Open__c = false,
                                                                                                                    Reserved_Capacity_kW_DC__c = '100',
                                                                                                                    Capacity_Committed_kW_DC__c = 100,
                                                                                                                    Total_System_Size_kWh_DC__c = 100,
                                                                                                                    System_Utility__c = 'National Grid',
                                                                                                                    Credit_Score_Requirement__c = 200,
                                                                                                                    Assignment_order__c = '3'));


        Shared_Solar_System__c sss4 = (Shared_Solar_System__c)TestFactory.createSObject(new Shared_Solar_System__c(Name = 'Oxford Barrett St. P4',
                                                                                                                    Service_Territory__c = 'WCMA',
                                                                                                                    Open__c = false,
                                                                                                                    Schedule_Z_Filed__c = true,
                                                                                                                    Reserved_Capacity_kW_DC__c = '100',
                                                                                                                    Capacity_Committed_kW_DC__c = 100,
                                                                                                                    Total_System_Size_kWh_DC__c = 100,
                                                                                                                    System_Utility__c = 'National Grid',
                                                                                                                    Credit_Score_Requirement__c = 200,
                                                                                                                    Assignment_order__c = '4'));
        insert new List<Shared_Solar_System__c>{sss1, sss2, sss3, sss4};



        Opportunity opp1 = (Opportunity)TestFactory.createSObject(new Opportunity(AccountId = propertyAcc.Id,
                                                                                 Shared_Solar_System__c = sss1.Id), 'TestFactory.OpportunityDefaults');

        Opportunity opp2 = (Opportunity)TestFactory.createSObject(new Opportunity(AccountId = propertyAcc.Id,
                                                                                 Shared_Solar_System__c = sss2.Id), 'TestFactory.OpportunityDefaults');

        Opportunity opp3 = (Opportunity)TestFactory.createSObject(new Opportunity(AccountId = propertyAcc.Id,
                                                                                 Shared_Solar_System__c = sss3.Id), 'TestFactory.OpportunityDefaults');

        Opportunity opp4 = (Opportunity)TestFactory.createSObject(new Opportunity(AccountId = propertyAcc.Id,
                                                                                 Shared_Solar_System__c = sss4.Id), 'TestFactory.OpportunityDefaults');

        insert new List<Opportunity>{opp1, opp2, opp3, opp4};

        Utility_Account_Log__c ual = (Utility_Account_Log__c)TestFactory.createSObject(new Utility_Account_Log__c(Account__c = propertyAcc.Id,
                                                                                                                 Annual_Cost_of_Electricity__c = 100,
                                                                                                                 Name_on_Account__c = 'Joey Chan'));
        insert ual;

        Utility_Account_Subscription__c uas1 = (Utility_Account_Subscription__c)TestFactory.createSObject(new Utility_Account_Subscription__c(
                                                                                                    Utility_Account_Log__c = ual.Id,
                                                                                                    Opportunity__c = opp1.Id,
                                                                                                    Calculated_Annual_Cost_of_Electricity__c = 5000,
                                                                                                    Subscribed_Annual_Cost_of_Electricity__c = 5000));

        Utility_Account_Subscription__c uas2 = (Utility_Account_Subscription__c)TestFactory.createSObject(new Utility_Account_Subscription__c(
                                                                                                    Utility_Account_Log__c = ual.Id,
                                                                                                    Opportunity__c = opp2.Id,
                                                                                                    Calculated_Annual_Cost_of_Electricity__c = 3000,
                                                                                                    Subscribed_Annual_Cost_of_Electricity__c = 3000));

        Utility_Account_Subscription__c uas3 = (Utility_Account_Subscription__c)TestFactory.createSObject(new Utility_Account_Subscription__c(
                                                                                                    Utility_Account_Log__c = ual.Id,
                                                                                                    Opportunity__c = opp3.Id,
                                                                                                    Calculated_Annual_Cost_of_Electricity__c = 2000,
                                                                                                    Subscribed_Annual_Cost_of_Electricity__c = 2000));

        Utility_Account_Subscription__c uas4 = (Utility_Account_Subscription__c)TestFactory.createSObject(new Utility_Account_Subscription__c(
                                                                                                    Utility_Account_Log__c = ual.Id,
                                                                                                    Opportunity__c = opp4.Id,
                                                                                                    Calculated_Annual_Cost_of_Electricity__c = 1000,
                                                                                                    Subscribed_Annual_Cost_of_Electricity__c = 1000));


        insert new List<Utility_Account_Subscription__c>{uas1, uas2, uas3, uas4};

        Test.startTest();

        ApexPages.currentPage().getParameters().put('id', ual.Id);
        ApexPages.currentPage().getParameters().put('adminMode', '1');

        RecalculateUALCostController theController = new RecalculateUALCostController();
        
        theController.deductionMethod = 'Assignment Order';
        theController.setDeductionMethod();

        theController.deductionMethod = 'COD Date';
        theController.setDeductionMethod();

        //Set deduction for closed
        theController.closedUASActionList[0].action = 'Deduct and mark as Open';

        //Set deduction for Schedule Z Filed
        theController.scheduleZFiledUASActionList[0].action = 'Deduct from Schedule Z Filed';

        theController.processDeduction();


        Test.stopTest();

        //Check if UAS has already been deducted
        Utility_Account_Subscription__c verifyuas1 = [Select Id,Calculated_Annual_Cost_of_Electricity__c, Subscribed_Annual_Cost_of_Electricity__c From Utility_Account_Subscription__c Where Id = :uas1.Id];
        System.debug(uas1);
        System.debug(verifyuas1);
        System.assert(uas1.Subscribed_Annual_Cost_of_Electricity__c > verifyuas1.Subscribed_Annual_Cost_of_Electricity__c);

        Utility_Account_Subscription__c verifyuas2 = [Select Id,Calculated_Annual_Cost_of_Electricity__c, Subscribed_Annual_Cost_of_Electricity__c From Utility_Account_Subscription__c Where Id = :uas2.Id];
        System.assert(uas2.Subscribed_Annual_Cost_of_Electricity__c > verifyuas2.Subscribed_Annual_Cost_of_Electricity__c);

        Utility_Account_Subscription__c verifyuas3 = [Select Id,Calculated_Annual_Cost_of_Electricity__c, Subscribed_Annual_Cost_of_Electricity__c From Utility_Account_Subscription__c Where Id = :uas3.Id];
        System.assert(uas2.Subscribed_Annual_Cost_of_Electricity__c > verifyuas2.Subscribed_Annual_Cost_of_Electricity__c);

        Utility_Account_Subscription__c verifyuas4 = [Select Id,Calculated_Annual_Cost_of_Electricity__c, Subscribed_Annual_Cost_of_Electricity__c From Utility_Account_Subscription__c Where Id = :uas4.Id];
        System.assert(uas2.Subscribed_Annual_Cost_of_Electricity__c > verifyuas2.Subscribed_Annual_Cost_of_Electricity__c);

        //Verify that there are still cost not yet 
        Utility_Account_Log__c verifyUAL = [Select Id, Cost_not_yet_Allocated__c From Utility_Account_Log__c Where Id = :ual.Id];
        System.debug(verifyUAL);
        System.assert(verifyUAL.Cost_not_yet_Allocated__c > 0);

    }

    @testSetup static void setupTestData() {
        Account parentAccount = 
            (Account) TestFactory.createSObject(new Account(), 
                                                'TestFactory.AccountDefaults', 
                                                true);

        Contact con = 
            (Contact) TestFactory.createSObject(new Contact(AccountId = parentAccount.Id, 
                                                            Active_Communities_User__c = true), 
                                                'TestFactory.ContactDefaults', true);

        Account propertyAcc = 
            (Account) TestFactory.createSObject(new Account(Parent_Account__c = parentAccount.Id), 
                                                'TestFactory.AccountDefaults', true);

        Utility_NMC_Tariff__c nmcRate =  
            (Utility_NMC_Tariff__c) TestFactory.createSObject(new Utility_NMC_Tariff__c(Value_of_Net_Metering_Credit__c = 1,
                                                                                        Name = 'Nation Grid WCMA Class 2 - S/F 2016',
                                                                                        Sizing_Rate__c = true,
                                                                                        Date__c = Date.today()), true);

        Shared_Solar_System__c sss1 = 
            (Shared_Solar_System__c)TestFactory.createSObject(new Shared_Solar_System__c(Name = 'Oxford Barrett St. P1',
                                                                                         Service_Territory__c = 'WCMA',
                                                                                         Open__c = true,
                                                                                         Schedule_Z_Filed__c = false,
                                                                                         Reserved_Capacity_kW_DC__c = '100',
                                                                                         Capacity_Committed_kW_DC__c = 100,
                                                                                         Total_System_Size_kWh_DC__c = 1000,
                                                                                         Total_System_Size_kW_AC__c  = 996,
                                                                                         System_Utility__c = 'National Grid',
                                                                                         Credit_Score_Requirement__c = 200,
                                                                                         Assignment_order__c = '1',
                                                                                         Utility_NMC_Tariff__c = nmcRate.Id,
                                                                                         Expected_Yield_kWh_kW__c = 1300,
                                                                                         Assemblage_Count__c = 1,
                                                                                         Maximum_Subscription_Assemblage__c = 25));

        Shared_Solar_System__c sss2 = 
            (Shared_Solar_System__c)TestFactory.createSObject(new Shared_Solar_System__c(Name = 'Oxford Barrett St. P2',
                                                                                         Service_Territory__c = 'WCMA',
                                                                                         Open__c = true,
                                                                                         Schedule_Z_Filed__c = false,
                                                                                         Reserved_Capacity_kW_DC__c = '100',
                                                                                         Capacity_Committed_kW_DC__c = 100,
                                                                                         Total_System_Size_kWh_DC__c = 1000,
                                                                                         System_Utility__c = 'National Grid',
                                                                                         Credit_Score_Requirement__c = 200,
                                                                                         Assignment_order__c = '2'));
        Shared_Solar_System__c sss3 = 
            (Shared_Solar_System__c)TestFactory.createSObject(new Shared_Solar_System__c(Name = 'Oxford Barrett St. P3',
                                                                                         Service_Territory__c = 'WCMA',
                                                                                         Open__c = true,
                                                                                         Schedule_Z_Filed__c = false,
                                                                                         Reserved_Capacity_kW_DC__c = '100',
                                                                                         Capacity_Committed_kW_DC__c = 100,
                                                                                         Total_System_Size_kWh_DC__c = 1000,
                                                                                         System_Utility__c = 'National Grid',
                                                                                         Credit_Score_Requirement__c = 200,
                                                                                         Assignment_order__c = '3'));


        Shared_Solar_System__c sss4 = 
            (Shared_Solar_System__c)TestFactory.createSObject(new Shared_Solar_System__c(Name = 'Oxford Barrett St. P4',
                                                                                         Service_Territory__c = 'WCMA',
                                                                                         Open__c = true,
                                                                                         Schedule_Z_Filed__c = false,
                                                                                         Reserved_Capacity_kW_DC__c = '100',
                                                                                         Capacity_Committed_kW_DC__c = 100,
                                                                                         Total_System_Size_kWh_DC__c = 1000,
                                                                                         System_Utility__c = 'National Grid',
                                                                                         Credit_Score_Requirement__c = 200,
                                                                                         Assignment_order__c = '4'));
        insert new List<Shared_Solar_System__c>{sss1, sss2, sss3, sss4};

        Opportunity opp1 = 
            (Opportunity)TestFactory.createSObject(new Opportunity(AccountId = propertyAcc.Id,
                                                                   Shared_Solar_System__c = sss1.Id), 
                                                   'TestFactory.OpportunityDefaults');

        Opportunity opp2 = 
            (Opportunity)TestFactory.createSObject(new Opportunity(AccountId = propertyAcc.Id,
                                                                   Shared_Solar_System__c = sss2.Id), 
                                                   'TestFactory.OpportunityDefaults');

        Opportunity opp3 = 
            (Opportunity)TestFactory.createSObject(new Opportunity(AccountId = propertyAcc.Id,
                                                                   Shared_Solar_System__c = sss3.Id), 
                                                   'TestFactory.OpportunityDefaults');

        Opportunity opp4 = 
            (Opportunity)TestFactory.createSObject(new Opportunity(AccountId = propertyAcc.Id,
                                                                   Shared_Solar_System__c = sss4.Id), 
                                                   'TestFactory.OpportunityDefaults');

        insert new List<Opportunity>{opp1, opp2, opp3, opp4};

        Utility_Account_Log__c ual = 
            (Utility_Account_Log__c)TestFactory.createSObject(new Utility_Account_Log__c(Account__c = propertyAcc.Id,
                                                                                         Annual_Cost_of_Electricity__c = 100,
                                                                                         Name_on_Account__c = 'Joey Chan'));
        insert ual;

        Utility_Account_Subscription__c uas1 = 
            (Utility_Account_Subscription__c)TestFactory.createSObject(new Utility_Account_Subscription__c(Utility_Account_Log__c = ual.Id,
                                                                                                           Opportunity__c = opp1.Id,
                                                                                                           Calculated_Annual_Cost_of_Electricity__c = 5,
                                                                                                           Subscribed_Annual_Cost_of_Electricity__c = 5,
                                                                                                           Custom_Deduction_Order__c = 1));

        Utility_Account_Subscription__c uas2 = 
            (Utility_Account_Subscription__c)TestFactory.createSObject(new Utility_Account_Subscription__c(Utility_Account_Log__c = ual.Id,
                                                                                                           Opportunity__c = opp2.Id,
                                                                                                           Calculated_Annual_Cost_of_Electricity__c = 3,
                                                                                                           Subscribed_Annual_Cost_of_Electricity__c = 3,
                                                                                                           Custom_Deduction_Order__c = 2));

        Utility_Account_Subscription__c uas3 = 
            (Utility_Account_Subscription__c)TestFactory.createSObject(new Utility_Account_Subscription__c(Utility_Account_Log__c = ual.Id,
                                                                                                           Opportunity__c = opp3.Id,
                                                                                                           Calculated_Annual_Cost_of_Electricity__c = 2,
                                                                                                           Subscribed_Annual_Cost_of_Electricity__c = 2,
                                                                                                           Custom_Deduction_Order__c = 3));

        Utility_Account_Subscription__c uas4 = 
            (Utility_Account_Subscription__c)TestFactory.createSObject(new Utility_Account_Subscription__c(Utility_Account_Log__c = ual.Id,
                                                                                                           Opportunity__c = opp4.Id,
                                                                                                           Calculated_Annual_Cost_of_Electricity__c = 1,
                                                                                                           Subscribed_Annual_Cost_of_Electricity__c = 1,
                                                                                                           Custom_Deduction_Order__c = 4));


        insert new List<Utility_Account_Subscription__c>{uas1, uas2, uas3, uas4};
    }

    @isTest static void testCustomDeductionOrder() {
        Utility_Account_Log__c ual = [SELECT Id 
                                      FROM Utility_Account_Log__c
                                      WHERE Name_on_Account__c = 'Joey Chan'];

        System.debug('test ualid: ' + ual.Id);
       
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

        System.assertNotEquals(2, uasList.size());

        for (Utility_Account_Subscription__c uas : uasList) {
            if (uas.Calculated_Annual_Cost_of_Electricity__c == 5) {
                System.assertEquals(1, uas.Custom_Deduction_Order__c);
            } else if (uas.Calculated_Annual_Cost_of_Electricity__c == 3) {
                System.assertEquals(2, uas.Custom_Deduction_Order__c);
            } else if (uas.Calculated_Annual_Cost_of_Electricity__c == 2) {
                System.assertEquals(3, uas.Custom_Deduction_Order__c);
            } else if (uas.Calculated_Annual_Cost_of_Electricity__c == 1) {
                System.assertEquals(4, uas.Custom_Deduction_Order__c);
            }
        }

        Test.startTest();

        PageReference recalculateUALCost = Page.RecalculateUALCost;
        Test.setCurrentPage(recalculateUALCost);
        ApexPages.currentPage().getParameters().put('id', ual.Id);
        ApexPages.currentPage().getParameters().put('adminMode', '1');

        RecalculateUALCostController theController = new RecalculateUALCostController();
        theController.deductionMethod = 'Custom Deduction Order';
        theController.setDeductionMethod();
        System.assertEquals(4, theController.openUASActionList.size());
        // Set custom order
        for (RecalculateUALCostController.UASAction uasAction : theController.openUASActionList) {
            if (uasAction.uas.Calculated_Annual_Cost_of_Electricity__c == 5) {
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
            if (uas.Calculated_Annual_Cost_of_Electricity__c == 5) {
                System.assertEquals(8, uas.Custom_Deduction_Order__c);
            }
        }

        theController.processDeduction();

        Test.stopTest();

        uasList = [SELECT Id, Calculated_Annual_Cost_of_Electricity__c, Custom_Deduction_Order__c
                   FROM Utility_Account_Subscription__c
                   WHERE Utility_Account_Log__c = :ual.Id];

        for (Utility_Account_Subscription__c uas : uasList) {
            if (uas.Calculated_Annual_Cost_of_Electricity__c == 5) {
                System.assertEquals(8, uas.Custom_Deduction_Order__c);
            } else if (uas.Calculated_Annual_Cost_of_Electricity__c == 3) {
                System.assertEquals(2, uas.Custom_Deduction_Order__c);
            } else if (uas.Calculated_Annual_Cost_of_Electricity__c == 2) {
                System.assertEquals(3, uas.Custom_Deduction_Order__c);
            } else if (uas.Calculated_Annual_Cost_of_Electricity__c == 1) {
                System.assertEquals(4, uas.Custom_Deduction_Order__c);
            }
        }
    }
}