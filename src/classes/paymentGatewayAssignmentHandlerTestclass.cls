@isTest
public class paymentGatewayAssignmentHandlerTestclass {
    @isTest static void testPaymentGatewayAssignmentHandler() {
        
        Utility_NMC_Tariff__c nmcRateNgridWcmaSizing =  new Utility_NMC_Tariff__c(
            Value_of_Net_Metering_Credit__c = 0.15,
            Name = 'Nation Grid WCMA Class 2 I',
            Sizing_Rate__c = true,
            Current_Billing_Rate__c = false,
            Date__c = Date.today()
        );

        Utility_NMC_Tariff__c nmcRateNgridWcmaBilling =  new Utility_NMC_Tariff__c(
            Value_of_Net_Metering_Credit__c = 0.15,
            Name = 'National Grid WCMA Class 2',
            Sizing_Rate__c = false,
            Current_Billing_Rate__c = true,
            Date__c = Date.today()
        );



        insert new List<Utility_NMC_Tariff__c>{nmcRateNgridWcmaSizing, nmcRateNgridWcmaBilling};

        ChargentBase__Gateway__c chGatewayOxfordBarretSt  = new ChargentBase__Gateway__c(
            Name = 'Chargent Gateway Oxford Barret St',
            ChargentBase__Merchant_ID__c = '235986',
            ChargentBase__Active__c = TRUE
        );
        insert chGatewayOxfordBarretSt;

        ChargentBase__Gateway__c chGatewayOxfordBarretSt2  = new ChargentBase__Gateway__c(
            Name = 'Chargent Gateway Oxford Barret St',
            ChargentBase__Merchant_ID__c = '235986',
            ChargentBase__Active__c = FALSE
        );
        insert chGatewayOxfordBarretSt2;

        ChargentBase__Gateway__c chGatewayMedfieldCountryWay  = new ChargentBase__Gateway__c(
            Name = 'Chargent Gateway Medfield Country Way',
            ChargentBase__Merchant_ID__c = '123123',
            ChargentBase__Active__c = TRUE
        );
        insert chGatewayMedfieldCountryWay;

        ChargentBase__Gateway__c chGatewayMedfieldCountryWay2  = new ChargentBase__Gateway__c(
            Name = 'Chargent Gateway Medfield Country Way',
            ChargentBase__Merchant_ID__c = '123123',
            ChargentBase__Active__c = TRUE
        );
        insert chGatewayMedfieldCountryWay2;

        ChargentBase__Gateway__c chGatewayFairhavenMillRd  = new ChargentBase__Gateway__c(
            Name = 'Chargent Gateway Fairhaven Mill Rd',
            ChargentBase__Merchant_ID__c = '43543',
            ChargentBase__Active__c = TRUE
        );

        insert chGatewayFairhavenMillRd;

        Entity__c entity1 = new Entity__c (Name = 'Oxford Barret St', Gateway__c = chGatewayOxfordBarretSt.Id);
        Entity__c entity1b = new Entity__c (Name = 'Oxford Barret St 2', Gateway__c = chGatewayOxfordBarretSt.Id);
        Entity__c entity2 = new Entity__c (Name = 'Medfield Country Way', Gateway__c = chGatewayMedfieldCountryWay2.Id);
        Entity__c entity3 = new Entity__c (Name = 'Fairhaven Mill Rd', Gateway__c = chGatewayFairhavenMillRd.Id);

        insert new List <Entity__c>{entity1, entity1b, entity2, entity3};

        Shared_Solar_System__c sharedSolarSystemOxfordBarretSt = new Shared_Solar_System__c(
            Name = 'Oxford Barret St',
            Service_Territories__c = 'WCMA',
            Open__c = true,
            BWC_Project_Entity_Manual__c = entity1.Id,
            Expected_Yield_kWh_kW__c = 1300,
            Credit_Score_Requirement__c = 750,
            Reserved_Capacity_kW_DC__c = '0',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 1445.86,
            Total_System_Size_kW_AC__c  = 996,
            System_Utility__c = 'National Grid',
            Assignment_order__c = '1',
            Utility_NMC_Tariff__c = nmcRateNgridWcmaSizing.Id,
            Assemblage_Count__c = 1,
            Maximum_Subscription_Assemblage__c = 25
        );

        Shared_Solar_System__c sharedSolarSystemOxfordBarretSt2 = new Shared_Solar_System__c(
            Name = 'Oxford Barret St Pt 2',
            Service_Territories__c = 'WCMA',
            Open__c = true,
            BWC_Project_Entity_Manual__c = entity1b.Id,
            Expected_Yield_kWh_kW__c = 1300,
            Credit_Score_Requirement__c = 750,
            Reserved_Capacity_kW_DC__c = '0',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 1445.86,
            Total_System_Size_kW_AC__c  = 996,
            System_Utility__c = 'National Grid',
            Assignment_order__c = '1',
            Utility_NMC_Tariff__c = nmcRateNgridWcmaSizing.Id,
            Assemblage_Count__c = 1,
            Maximum_Subscription_Assemblage__c = 25
        );

        Shared_Solar_System__c sharedSolarSystemMedfieldCountryWay = new Shared_Solar_System__c(
            Name = 'Medfield Country Way',
            Service_Territories__c = 'NEMA',
            Open__c = true,
            BWC_Project_Entity_Manual__c = entity2.Id,
            Expected_Yield_kWh_kW__c = 1300,
            Credit_Score_Requirement__c = 750,
            Reserved_Capacity_kW_DC__c = '0',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 1445.86,
            Total_System_Size_kW_AC__c  = 996,
            System_Utility__c = 'Eversource',
            Assignment_order__c = '1',
            Utility_NMC_Tariff__c = nmcRateNgridWcmaSizing.Id,
            Assemblage_Count__c = 1,
            Maximum_Subscription_Assemblage__c = 25
        );

        Shared_Solar_System__c sharedSolarSystemFairhavenMillRd = new Shared_Solar_System__c(
            Name = 'Fairhaven Mill Rd',
            Service_Territories__c = 'NEMA',
            Open__c = true,
            BWC_Project_Entity_Manual__c = entity3.Id,
            Expected_Yield_kWh_kW__c = 1300,
            Credit_Score_Requirement__c = 750,
            Reserved_Capacity_kW_DC__c = '0',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 1445.86,
            Total_System_Size_kW_AC__c  = 996,
            System_Utility__c = 'Eversource',
            Assignment_order__c = '1',
            Utility_NMC_Tariff__c = nmcRateNgridWcmaSizing.Id,
            Assemblage_Count__c = 1,
            Maximum_Subscription_Assemblage__c = 25
        );
        
        insert new List<Shared_Solar_System__c>{
            sharedSolarSystemOxfordBarretSt,
            sharedSolarSystemOxfordBarretSt2,
            sharedSolarSystemMedfieldCountryWay,
            sharedSolarSystemFairhavenMillRd
        };
        
        Account parentAccountColeSwain = new Account(
            Name = 'Cole Swain',
            Recurring_Billing__c = TRUE
        );

                                                                                                                                                         
        insert parentAccountColeSwain;                                                                                                                                                             


        Account propertyAccountColesCakes = new Account(
            Name = 'Coles Cakes',
            Recurring_Billing__c = TRUE,
            Parent_Account__c = parentAccountColeSwain.Id
        );
                                                                                           
        insert propertyAccountColesCakes;   


        Utility_Account_Log__c ualColesCakes = new Utility_Account_Log__c(
            Name = '000X0A1',
            Account__c = propertyAccountColesCakes.Id,
            Annual_Cost_of_Electricity__c = 6825,
            Name_on_Account__c = 'Coles Cakes'
        );

        insert ualColesCakes;


        Opportunity oppColesCakes = new Opportunity(
            Name = 'Coles Cakes',
            AccountId = propertyAccountColesCakes.Id,
            Shared_Solar_System__c = sharedSolarSystemOxfordBarretSt.Id,
            StageName = 'Complete',
            CloseDate = System.today()
        );

        insert oppColesCakes;

        Opportunity oppColesCupCakes = new Opportunity(
            Name = 'Coles Cup Cakes',
            AccountId = propertyAccountColesCakes.Id,
            Shared_Solar_System__c = sharedSolarSystemOxfordBarretSt2.Id,
            StageName = 'Complete',
            CloseDate = System.today()
        );

        insert oppColesCupCakes;

        Utility_Account_Subscription__c uasColesCakes = new Utility_Account_Subscription__c(
            Name = '000X0A1',
            Utility_Account_Log__c = ualColesCakes.Id,
            Opportunity__c = oppColesCakes.Id,
            Calculated_Annual_Cost_of_Electricity__c = 4875,
            Subscribed_Annual_Cost_of_Electricity__c = 4875
        );
        
        insert uasColesCakes;   
                                                                                                                                                                                                                                                                                    
        Date myDateJan = Date.newInstance(2016, 1, 1);
        Date myDateFeb = Date.newInstance(2016, 2, 2);
        Date myDateMar = Date.newInstance(2016, 3, 3);
        Date myDateApr = Date.newInstance(2016, 4, 4);
        Date myDateMay = Date.newInstance(2016, 5, 5);
        Date myDateJun = Date.newInstance(2016, 6, 6);

        Energy_Usage_Update__c productionUpdateOxfordBarretStJan = new Energy_Usage_Update__c(
            Name = 'sharedSolarSystemOxfordBarretSt - January 2016',
            Shared_Solar_System__c = sharedSolarSystemOxfordBarretSt.id,
            Production__c = 80000,
            Date__c = myDateJan
        );

        insert productionUpdateOxfordBarretStJan;

        Energy_Usage_Update__c productionUpdateOxfordBarretStFeb = new Energy_Usage_Update__c(
            Name = 'sharedSolarSystemOxfordBarretSt - January 2016',
            Shared_Solar_System__c = sharedSolarSystemOxfordBarretSt.id,
            Production__c = 80000,
            Date__c = myDateApr
        );

        insert productionUpdateOxfordBarretStFeb;

        List<ChargentOrders__ChargentOrder__c> chargentOrderRecurringList = new List<ChargentOrders__ChargentOrder__c>();        
        List<ChargentOrders__Transaction__c> chargentTransRecurringList= new List<ChargentOrders__Transaction__c>();
        List<ChargentOrders__ChargentOrder__c> chargentOrderOneTimeList = new List<ChargentOrders__ChargentOrder__c>();        
        List<ChargentOrders__Transaction__c> chargentTransOneTimeList= new List<ChargentOrders__Transaction__c>();

        ChargentOrders__ChargentOrder__c orderColesCakes = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Account__c = oppColesCakes.AccountId,
            Opportunity__c = oppColesCakes.Id,
            Entity__c = sharedSolarSystemOxfordBarretSt.BWC_Project_Entity_Manual__c,
            ChargentOrders__Payment_Method__c = 'Credit Card',
            ChargentOrders__Bank_Name__c = null,
            ChargentOrders__Bank_Routing_Number__c = null,
            ChargentOrders__Bank_Account_Type__c = null,
            ChargentOrders__Bank_Account_Number__c = null,
            ChargentOrders__Bank_Account_Name__c = null,
            ChargentOrders__Card_Type__c = 'VISA',
            ChargentOrders__Card_Number__c = '1234567812345678',
            ChargentOrders__Card_Security_Code__c = '123',
            ChargentOrders__Billing_Last_Name__c = 'CupCake',
            ChargentOrders__Card_Expiration_Month__c = '01',
            ChargentOrders__Card_Expiration_Year__c = '2020');
        insert orderColesCakes;

        ChargentOrders__ChargentOrder__c orderColesCupCakes = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Account__c = oppColesCupCakes.AccountId,
            Opportunity__c = oppColesCupCakes.Id,
            Entity__c = sharedSolarSystemOxfordBarretSt2.BWC_Project_Entity_Manual__c,
            ChargentOrders__Payment_Method__c = 'Credit Card',
            ChargentOrders__Bank_Name__c = null,
            ChargentOrders__Bank_Routing_Number__c = null,
            ChargentOrders__Bank_Account_Type__c = null,
            ChargentOrders__Bank_Account_Number__c = null,
            ChargentOrders__Bank_Account_Name__c = null,
            ChargentOrders__Card_Type__c = 'VISA',
            ChargentOrders__Card_Number__c = '1234567812345678',
            ChargentOrders__Card_Security_Code__c = '123',
            ChargentOrders__Billing_Last_Name__c = 'CupCake',
            ChargentOrders__Card_Expiration_Month__c = '01',
            ChargentOrders__Card_Expiration_Year__c = '2020');
        insert orderColesCupCakes;

        for (System_Bill__c systemBillJan : [SELECT Id, Name, Total_Due__c, Bill_Number__c, Property_Account_ID__c, Recurring_Billing__c, Shared_Solar_System__r.Id FROM System_Bill__c]) {
            if(systemBillJan.Bill_Number__c == 1) {
                ChargentOrders__ChargentOrder__c chOrderRecurring  = new ChargentOrders__ChargentOrder__c(
                    ChargentOrders__Account__c = systemBillJan.Property_Account_Id__c,
                    Entity__c = entity1.Id,
                    ChargentOrders__Billing_First_Name__c = 'Cole',
                    ChargentOrders__Billing_Last_Name__c = 'Swain',
                    ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
                    ChargentOrders__Billing_Zip_Postal__c = '02467',
                    ChargentOrders__Subtotal__c = systemBillJan.Total_Due__c,
                    ChargentOrders__Payment_Status__c = 'Recurring',
                    ChargentOrders__Payment_Method__c = 'Credit Card',
                    System_Bill__c = systemBillJan.Id,
                    ChargentOrders__Card_Type__c = 'Visa',
                    ChargentOrders__Card_Number__c = '411111111111',
                    ChargentOrders__Card_Security_Code__c = '999',
                    ChargentOrders__Card_Expiration_Month__c = '02',
                    ChargentOrders__Card_Expiration_Year__c = '2018',
                    ChargentOrders__Card_Last_4__c = '1111'
                );
                insert chOrderRecurring;
                System.debug('The shipping name is ' + chOrderRecurring.Entity__c);

                ChargentOrders__Transaction__c chTransactionRecurring = new ChargentOrders__Transaction__c(
                    ChargentOrders__Order__c = chOrderRecurring.id,
                    ChargentOrders__Amount__c = 300,
                    ChargentOrders__Response_Status__c ='Approved',
                    ChargentOrders__Gateway_ID__c = chOrderRecurring.ChargentOrders__Gateway__r.Id,
                    ChargentOrders__Gateway__c = chOrderRecurring.ChargentOrders__Gateway__r.Id,
                    Distributed_Among_System_Bills__c = FALSE,
                    ChargentOrders__Response_Message__c = 'OK',
                    ChargentOrders__Type__c = 'Charge',
                    ChargentOrders__Payment_Method__c = 'Credit Card',
                    Activity_Type__c = 'Payment'
                );
                insert chTransactionRecurring;
                chTransactionRecurring.Distributed_Among_System_Bills__c = TRUE;
                update chTransactionRecurring;

                System.debug(chTransactionRecurring);

                chargentOrderRecurringList.add(chOrderRecurring);
                chargentTransRecurringList.add(chTransactionRecurring);                
           }
            else{
                ChargentOrders__ChargentOrder__c chOrderOneTime  = new ChargentOrders__ChargentOrder__c(
                    ChargentOrders__Account__c = systemBillJan.Property_Account_Id__c,
                    Entity__c = entity2.Id,
                    ChargentOrders__Billing_First_Name__c = 'Cole',
                    ChargentOrders__Billing_Last_Name__c = 'Swain',
                    ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
                    ChargentOrders__Billing_Zip_Postal__c = '02468',
                    ChargentOrders__Subtotal__c = systemBillJan.Total_Due__c,
                    ChargentOrders__Payment_Method__c = 'Credit Card',
                    System_Bill__c = systemBillJan.Id,
                    ChargentOrders__Card_Type__c = 'Visa',
                    ChargentOrders__Card_Number__c = '411111111111',
                    ChargentOrders__Card_Security_Code__c = '999',
                    ChargentOrders__Card_Expiration_Month__c = '02',
                    ChargentOrders__Card_Expiration_Year__c = '2018',
                    ChargentOrders__Card_Last_4__c = '1111'
                );
                insert chOrderOneTime;
                System.debug('The shipping name is ' + chOrderOneTime.Entity__c);

                ChargentOrders__Transaction__c chTransactionOneTime = new ChargentOrders__Transaction__c(
                    ChargentOrders__Order__c = chOrderOneTime.id,
                    ChargentOrders__Amount__c = 100,
                    ChargentOrders__Response_Status__c ='Approved',
                    ChargentOrders__Gateway_ID__c = chOrderOneTime.ChargentOrders__Gateway__r.Id,
                    ChargentOrders__Gateway__c = chOrderOneTime.ChargentOrders__Gateway__r.Id,
                    Distributed_Among_System_Bills__c = FALSE,
                    ChargentOrders__Response_Message__c = 'OK',
                    ChargentOrders__Type__c = 'Charge',
                    ChargentOrders__Payment_Method__c = 'Credit Card',
                    Activity_Type__c = 'Payment'
                );
                insert chTransactionOneTime;
                chTransactionOneTime.Distributed_Among_System_Bills__c = TRUE;
                update chTransactionOneTime;

                System.debug(chTransactionOneTime);  

                chargentOrderOneTimeList.add(chOrderOneTime);
                chargentTransOneTimeList.add(chTransactionOneTime);               
            }          
        }

        Test.startTest();

        for (ChargentOrders__ChargentOrder__c chOrderAssert : [
            SELECT Id, Name, ChargentOrders__Gateway__r.Id, System_Bill__r.Bill_Number__c,
                Entity__c, ChargentOrders__Shipping_Name__c, ChargentOrders__Card_Number__c
            FROM ChargentOrders__ChargentOrder__c
        ]) {
            if (chOrderAssert.System_Bill__r.Bill_Number__c == 1) {
                System.assertEquals(chOrderAssert.ChargentOrders__Gateway__r.Id, entity1.Gateway__c);
                System.assertEquals(chOrderAssert.ChargentOrders__Gateway__r.Id, chGatewayOxfordBarretSt.Id );
            } else if (chOrderAssert.ChargentOrders__Card_Number__c == '411111111111') {
                System.assertEquals(chOrderAssert.ChargentOrders__Gateway__r.Id, entity2.Gateway__c);
                System.assertEquals(chOrderAssert.ChargentOrders__Gateway__r.Id, chGatewayMedfieldCountryWay2.Id );
            }
        }

        List<ChargentOrders__ChargentOrder__c> chargentOrdersWithSharedGateways = [
            SELECT Id, ChargentOrders__Gateway__c, Opportunity__r.Shared_Solar_System__c, ChargentOrders__Shipping_Name__c,
                Entity__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE ChargentOrders__Gateway__c = : chGatewayOxfordBarretSt.Id
        ];
        // should have 2 chargent orders using this gateway
        // they should have different shared solar systems
        // they should have different entities
        System.assertEquals(2, chargentOrdersWithSharedGateways.size());
        Id sssId1 = chargentOrdersWithSharedGateways[0].Opportunity__r.Shared_Solar_System__c;
        Id sssId2 = chargentOrdersWithSharedGateways[1].Opportunity__r.Shared_Solar_System__c;
        System.assertNotEquals(sssId1, sssId2);
        Id entityId1 = chargentOrdersWithSharedGateways[0].Entity__c;
        Id entityId2 = chargentOrdersWithSharedGateways[1].Entity__c;
        System.assertNotEquals(entityId1, entityId2);
        System.assertEquals(chGatewayOxfordBarretSt.Id, chargentOrdersWithSharedGateways[0].ChargentOrders__Gateway__c);
        System.assertEquals(chGatewayOxfordBarretSt.Id, chargentOrdersWithSharedGateways[1].ChargentOrders__Gateway__c);

        Test.stopTest();
    }
}