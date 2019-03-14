@isTest
private class CreditCardFeeUpdateHandlerTest{

Static testMethod void ccFeeUpdateTest(){
        Utility__c eversource = new Utility__c(
            Name = 'Eversource',
            Number_of_Decimal_Places__c = 2
        );

        Utility__c nationalGrid = new Utility__c(
            Name = 'National Grid',
            Number_of_Decimal_Places__c = 2
        );

        insert new List<Utility__c>{eversource, nationalGrid};

// Create NMC Tariffs


        Utility_NMC_Tariff__c everbillNMC = new Utility_NMC_Tariff__c (
                Name = 'Eversource SEMA Class 2', 
                Utility__c = 'Eversource', 
                Class__c = 'Class 2',
                Value_of_Net_Metering_Credit__c = 0.1848,
                Current_Billing_Rate__c = TRUE
                );

        Utility_NMC_Tariff__c eversizeNMC = new Utility_NMC_Tariff__c (
                Name = 'Eversource SEMA Class 2', 
                Utility__c = 'Eversource', 
                Class__c = 'Class 2',
                Value_of_Net_Metering_Credit__c = 0.1848,
                Sizing_Rate__c = TRUE
                );

        Utility_NMC_Tariff__c ngridbillNMC = new Utility_NMC_Tariff__c (
                Name = 'National Grid WCMA Class 2', 
                Utility__c = 'National Grid', 
                Class__c = 'Class 2',
                Value_of_Net_Metering_Credit__c = 0.1848,
                Current_Billing_Rate__c = TRUE
                );

        Utility_NMC_Tariff__c ngridsizeNMC = new Utility_NMC_Tariff__c (
                Name = 'National Grid WCMA Class 2', 
                Utility__c = 'National Grid', 
                Class__c = 'Class 2',
                Value_of_Net_Metering_Credit__c = 0.1848,
                Sizing_Rate__c = TRUE
                );

        Insert everbillNMC;
        Insert eversizeNMC;
        Insert ngridsizeNMC;
        Insert ngridbillNMC;

// Create Load Zones and Service Territories

        Load_U__c everLZU = new Load_U__c ( 
                Name = '02633', 
                LZ__c = 'SEMA',
                Town__c= 'Medfield');

        Load_U__c ngridLZU = new Load_U__c ( 
                Name = '01570', 
                LZ__c = 'WCMA',
                Town__c= 'Westtown');

        Insert everLZU;
        Insert ngridLZU;

    ZipCode_Utility_Junction__c junction = new ZipCode_Utility_Junction__c(
        Load_Zone_Utility__c = everLZU.Id,
        Utility__c = eversource.Id
    );

    ZipCode_Utility_Junction__c junctionTwo = new ZipCode_Utility_Junction__c(
        Load_Zone_Utility__c = ngridLZU.Id,
        Utility__c = nationalGrid.Id
    );
    insert new List<ZipCode_Utility_Junction__c>{junction, junctionTwo};

    ChargentBase__Gateway__c chGateway  = new ChargentBase__Gateway__c(Name = 'Chargent Gateway',
        ChargentBase__Merchant_ID__c = '235986',
        ChargentBase__Available_Payment_Methods__c = 'eCheck',
        ChargentBase__Default_Payment_Method_for_PC__c = 'eCheck',
        ChargentBase__Default_Payment_Method_for_PR__c = 'eCheck',
        ChargentBase__Active__c = TRUE);
    insert chGateway;
        
        Entity__c entity1 = new Entity__c (Name = 'Entityone', Gateway__c = chGateway.Id);
        Entity__c entity2 = new Entity__c (Name = 'Entitytwo');
        Entity__c entity3 = new Entity__c (Name = 'Entitythree');

        Insert new list <Entity__c>{entity1, entity2, entity3};
// Create Shared Solar Systems 

        Shared_Solar_System__c sss1 = (Shared_Solar_System__c)TestFactory.createSObject(new Shared_Solar_System__c(Name = 'Oxford Barrett St. P1',
                                                                                                                                Service_Territories__c = 'SEMA',
                                                                                                                                Open__c = true,
                                                                                                                                BWC_Project_Entity_Manual__c = entity1.Id,
                                                                                                                                Reserved_Capacity_kW_DC__c = '0',
                                                                                                                                Capacity_Committed_kW_DC__c = 0,
                                                                                                                                Total_System_Size_kWh_DC__c = 1445.86,
                                                                                                                                Total_System_Size_kW_AC__c  = 996,
                                                                                                                                Utility__c = eversource.Id,
                                                                                                                                Credit_Score_Requirement__c = 200,
                                                                                                                                Assignment_order__c = '1',
                                                                                                                                Utility_NMC_Tariff__c = eversizeNMC.Id,
                                                                                                                                Expected_Yield_kWh_kW__c = 1300,
                                                                                                                                Assemblage_Count__c = 1,
                                                                                                                                Sales_Partners__c = 'All',
                                                                                                                                Maximum_Subscription_Assemblage__c = 25));

      //  insert sss1;

        Shared_Solar_System__c sss2 = (Shared_Solar_System__c)TestFactory.createSObject(new Shared_Solar_System__c(Name = 'Oxford Barrett St. P2',
                                                                                                                                Service_Territories__c = 'SEMA',
                                                                                                                                Open__c = true,
                                                                                                                                BWC_Project_Entity_Manual__c = entity2.Id,
                                                                                                                                Reserved_Capacity_kW_DC__c = '0',
                                                                                                                                Capacity_Committed_kW_DC__c = 0,
                                                                                                                                Total_System_Size_kWh_DC__c = 1445.86,
                                                                                                                                Total_System_Size_kW_AC__c  = 996,
                                                                                                                                Utility__c = eversource.Id,
                                                                                                                                Credit_Score_Requirement__c = 200,
                                                                                                                                Assignment_order__c = '2',
                                                                                                                                Utility_NMC_Tariff__c = eversizeNMC.Id,
                                                                                                                                Expected_Yield_kWh_kW__c = 1300,
                                                                                                                                Assemblage_Count__c = 1,
                                                                                                                                Sales_Partners__c = 'All',
                                                                                                                                Maximum_Subscription_Assemblage__c = 25));


        insert new List<Shared_Solar_System__c>{sss1, sss2};

        TestFactory.insertBWAddress();
        TestFactory.setCSBillSettings();

// create Parent Accounts

        Account accountA = new Account(name = 'Account A',
            RecordTypeId = '012j00000010Ha3');       
        Insert accountA;      

        List <String> parentaccountIDs = new List<String>{ 
          'accountA.id'
        };      


 Utility_Account_Log__c ualog = (Utility_Account_Log__c)TestFactory.createSObject(new Utility_Account_Log__c(Name = '0000234',
                                                                                                                 Account__c = accountA.Id,
                                                                                                                 Annual_Cost_of_Electricity__c = 10000,
                                                                                                                 Name_on_Account__c = 'jordan jordan'));
 insert ualog;

 Product2 normalCSProduct = new Product2( Name = 'BlueWave Community Solar',
                     Family = 'Community Solar',
                     Product_Type__c = 'Community Solar',
                     State__c = 'MA',
                     ProductCode = 'CS - BlueWave - 10%',
                     IsActive = True,
                     Lender_of_Record__c = 'BlueWave', 
                     NMC_Discount__c = 10,
                     Annual_kWh_Maximum__c = 100000000,
                     NM_Rate_Floor__c = 0,
                     Days_In_Bill_Period__c = 20,
                     Monthly_Late_Fee__c = 1);
 insert normalCSProduct;

 Opportunity opportunityone = (Opportunity)TestFactory.createSObject(new Opportunity(Name = 'Jordan Jordan',
                                                                                AccountId = accountA.Id,
                                                                                Shared_Solar_System__c = sss1.Id,
                                                                                StageName = 'Complete',
                                                                                Product__c = normalCSProduct.Id,
                                                                                CloseDate = System.today()));

 Opportunity opportunitytwo = (Opportunity)TestFactory.createSObject(new Opportunity(Name = 'Jordan Jordan',
                                                                                AccountId = accountA.Id,
                                                                                Shared_Solar_System__c = sss2.Id,
                                                                                StageName = 'Complete',
                                                                                Product__c = normalCSProduct.Id,
                                                                                CloseDate = System.today())); 
                                                                                
 insert opportunityone;
 insert opportunitytwo;

 Utility_Account_Subscription__c uasone = (Utility_Account_Subscription__c)TestFactory.createSObject(new Utility_Account_Subscription__c(
                                                                                                    Name = '0000234',
                                                                                                    Utility_Account_Log__c = ualog.Id,
                                                                                                    Next_Schedule_Z_Status__c = 'Active Subscription',
                                                                                                    Opportunity__c = opportunityone.Id,
                                                                                                    Annual_kwh_subscription_future__c = 4000,
                                                                                                    Calculated_Annual_Cost_of_Electricity__c = 4000,
                                                                                                    Subscribed_Annual_Cost_of_Electricity__c = 4000));

 Utility_Account_Subscription__c uastwo = (Utility_Account_Subscription__c)TestFactory.createSObject(new Utility_Account_Subscription__c(
                                                                                                    Name = '000-0234',
                                                                                                    Utility_Account_Log__c = ualog.Id,
                                                                                                    Opportunity__c = opportunitytwo.Id,
                                                                                                    Next_Schedule_Z_Status__c = 'Active Subscription',
                                                                                                    Annual_kwh_subscription_future__c = 6000,
                                                                                                    Calculated_Annual_Cost_of_Electricity__c = 6000,
                                                                                                    Subscribed_Annual_Cost_of_Electricity__c = 6000));

insert uasone;
insert uastwo; 

uasone.Customer_Subscription_KW_DC_STATIC__c = 25;
uastwo.Customer_Subscription_KW_DC_STATIC__c = 20;
update uasone;
update uastwo;

        List <Utility_Account_Subscription__c> uaslist = [SELECT Id, Customer_Subscription_KW_DC_STATIC__c, Subscribed_Annual_Cost_of_Electricity__c, Calculated_Annual_Cost_of_Electricity__c, Shared_Solar_System_Name__c FROM Utility_Account_Subscription__c];

// Log Production Update - First Month

        Date myDateJan = Date.newInstance(2016, 1, 1);
        Date myDateFeb = Date.newInstance(2016, 2, 2);
        Date myDateMar = Date.newInstance(2016, 3, 3);
        Date myDateApr = Date.newInstance(2016, 4, 4);

    Schedule_Z__c scheduleZ1 = new Schedule_Z__c(
        Name = '18-0515 Oxford Barrett St. P1',
        Shared_Solar_System__c = sss1.Id,
        Status__c = 'Billing'
    );

    insert scheduleZ1;

    Energy_Usage_Update__c productionupdateB2 = new Energy_Usage_Update__c (
                Name = 'sssA - February 2016',
                Shared_Solar_System__c = sss1.id,
                Schedule_Z__c = scheduleZ1.id,
                Production__c = 120000,
                Date__c = myDateFeb,
                Net_Metering_Rate_Applied__c = 0.1125,
                Billing_Period_End_Date__c = myDateFeb,
                Total_System_NMCs__c = 45000);
        
        Test.StartTest();
        insert productionupdateB2;

        TestBillCreationandPayment.runProductionUpdate(new List<Id>{productionupdateB2.Id});

        Test.StopTest();
               
        Account_Bill__c accbilltwo = new Account_Bill__c (
                        Bill_Number__c = 2,
                        Parent_Account__c = accountA.Id,
                        Name = 'First Last April 2016',
                        Unique_ID__c = '000111000111000111FAk');

        insert accbilltwo;

        System_Bill__c billthree = new System_Bill__c (
                        Shared_Solar_System__c = sss2.id,
                        Shared_Solar_System_ID2__c = sss2.id,
                        Bill_Number__c = 2,
                        Account_Bill__c = accbilltwo.id,
                        Property_Account__c = accountA.Id,
                        Name = 'First Last April 2016',
                        Unique_ID__c = '000111000111000111FAJ');

        insert billthree;    



        List<Account_Bill__c> accountbilllist = [SELECT Id, Name, Total_Due__c, Due_This_Month__c, Bill_Number__c, Property_Account_ID__c 
                                                FROM Account_Bill__c
                                                ORDER BY Bill_NUmber__c DESC];
        for(Account_Bill__c accountbill : accountbillList){
            if(accountbill.Bill_Number__c == 2){
                ChargentOrders__ChargentOrder__c orderA1  = new ChargentOrders__ChargentOrder__c(
                    ChargentOrders__Gateway__c = chGateway.Id,
                    Entity__c = entity1.Id,
                    ChargentOrders__Billing_First_Name__c = 'Cole',
                    ChargentOrders__Billing_Last_Name__c = 'Swain',
                    ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
                    ChargentOrders__Billing_Zip_Postal__c = '02467',
                    ChargentOrders__Subtotal__c = 603.92,
                    ChargentOrders__Payment_Method__c = 'Credit Card',
                    Account_Bill__c = accountbill.Id,
                    ChargentOrders__Card_Type__c = 'Visa',
                    ChargentOrders__Card_Number__c = '411111111111',
                    ChargentOrders__Card_Expiration_Month__c = '02',
                    ChargentOrders__Card_Expiration_Year__c = '2018',
                    ChargentOrders__Card_Last_4__c = '1111'
                );
                insert orderA1;
                orderA1.ChargentOrders__Payment_Status__c = 'Recurring';
                orderA1.ChargentOrders__Payment_Frequency__c = 'Monthly';
                orderA1.ChargentOrders__Payment_Start_Date__c = system.today();
                orderA1.ChargentOrders__Charge_Date__c = '30';
                update orderA1;
            }

            if(accountbill.Bill_Number__c == 1){
                ChargentOrders__ChargentOrder__c orderA  = new ChargentOrders__ChargentOrder__c(
                    Entity__c = entity2.Id,
                    ChargentOrders__Billing_First_Name__c = 'Cole',
                    ChargentOrders__Billing_Last_Name__c = 'Swain',
                    ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
                    ChargentOrders__Billing_Zip_Postal__c = '02467',
                    ChargentOrders__Subtotal__c = 603.92,
                    ChargentOrders__Payment_Method__c = 'Credit Card',
                    Account_Bill__c = accountbill.Id,
                    ChargentOrders__Card_Type__c = 'Visa',
                    ChargentOrders__Card_Number__c = '411111111111',
                    ChargentOrders__Card_Expiration_Month__c = '02',
                    ChargentOrders__Card_Expiration_Year__c = '2018',
                    ChargentOrders__Card_Last_4__c = '1111'
                );
                insert orderA;
                orderA.ChargentOrders__Payment_Status__c = 'Recurring';
                orderA.ChargentOrders__Payment_Frequency__c = 'Monthly';
                orderA.ChargentOrders__Payment_Start_Date__c = system.today();
                orderA.ChargentOrders__Charge_Date__c = '25';
                update orderA;

                // SECONDARY CREDIT CARD ORDER (CREATED BY FORM ASSEMBLY)
                ChargentOrders__ChargentOrder__c orderB  = new ChargentOrders__ChargentOrder__c(
                    Entity__c = entity3.Id,
                    ChargentOrders__Billing_First_Name__c = 'Cole',
                    ChargentOrders__Billing_Last_Name__c = 'Swain',
                    ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
                    ChargentOrders__Billing_Zip_Postal__c = '02467',
                    ChargentOrders__Subtotal__c = 18.09,
                    ChargentOrders__Payment_Method__c = 'Credit Card',
                    ChargentOrders__Card_Type__c = 'Visa',
                    ChargentOrders__Card_Number__c = '411111111111',
                    ChargentOrders__Card_Expiration_Month__c = '02',
                    ChargentOrders__Card_Expiration_Year__c = '2018',
                    ChargentOrders__Card_Last_4__c = '1111'
                );
                insert orderB;

                orderB.Order_Type__c = 'Credit Card Fee (3%)';
                orderB.Parent_Order__c = OrderA.Id;
                orderB.ChargentOrders__Payment_Status__c = 'Recurring';
                orderB.ChargentOrders__Payment_Frequency__c = 'Monthly';
                orderB.ChargentOrders__Payment_Start_Date__c = system.today();
                orderB.ChargentOrders__Charge_Date__c = '20';
                update orderB;
            }
        }

        List <System_Bill__c> updatedsystemBillList = [ SELECT Id, Late_Fees__c, Late_Payments__c, YTD_Billed__c, 
                                                        YTD_Payments__c, Shared_Solar_System_ID__c, Payment_Plan_Balance_to_Distribute__c,
                                                        Bill_Number__c, Payment_Plan_Balance__c, 
                                                        Name, Due_This_Month__c, Previous_Month_Overdue_Balance__c, 
                                                        Total_Due__c, Balance_Net_Late_Payments__c, Total_Payments_This_Month__c, 
                                                        Shared_Solar_System__c, Property_Account_ID__c 
                                                        FROM System_Bill__c];

        List <ChargentOrders__ChargentOrder__c> orderlist = [SELECT Id, Order_Type__c, Create_Duplicate_CC_Fees_on_Insert__c ,
                                                            System_Bill__r.Property_Account_ID__c, ChargentOrders__Payment_Status__c, 
                                                            ChargentOrders__Payment_Stop__c, ChargentOrders__Payment_Frequency__c, 
                                                            ChargentOrders__Charge_Date__c, ChargentOrders__Payment_Start_Date__c, Parent_Order__c,
                                                            ChargentOrders__Payment_End_Date__c, ChargentOrders__Next_Transaction_Date__c,
                                                            ChargentOrders__Charge_Amount__c
                                                            FROM ChargentOrders__ChargentOrder__c];

        // test that the update of the parent account also updated the CC order:
        for(ChargentOrders__ChargentOrder__c o: orderlist){    
            if(o.ChargentOrders__Charge_Date__c == '20'){
                o.Create_Duplicate_CC_Fees_on_Insert__c = TRUE;
                update o;
            }
        } 
        
        List <ChargentOrders__ChargentOrder__c> orderlistupdated = [SELECT Id, Order_Type__c, Create_Duplicate_CC_Fees_on_Insert__c , 
                                                                    System_Bill__r.Property_Account_ID__c, ChargentOrders__Payment_Status__c, 
                                                                    ChargentOrders__Payment_Stop__c, ChargentOrders__Payment_Frequency__c, 
                                                                    ChargentOrders__Charge_Date__c,
                                                                    ChargentOrders__Payment_Start_Date__c, 
                                                                    Parent_Order__c, ChargentOrders__Payment_End_Date__c, 
                                                                    ChargentOrders__Next_Transaction_Date__c, ChargentOrders__Charge_Amount__c
                                                                    FROM ChargentOrders__ChargentOrder__c];
        
        system.assertEquals(4, orderlistupdated.size());

        for(ChargentOrders__ChargentOrder__c upd: orderlistupdated){    
            if(upd.ChargentOrders__Charge_Date__c == '25' 
                && upd.Order_Type__c != 'Credit Card Fee (3%)'){
                    upd.ChargentOrders__Charge_Date__c = '17';
                    update upd;
            }
        } 

        List <ChargentOrders__ChargentOrder__c> orderlistupdatedagain = [SELECT Id, Order_Type__c, Create_Duplicate_CC_Fees_on_Insert__c , 
                                                                        System_Bill__r.Property_Account_ID__c, ChargentOrders__Payment_Status__c, 
                                                                        ChargentOrders__Payment_Stop__c, ChargentOrders__Payment_Frequency__c, 
                                                                        ChargentOrders__Charge_Date__c, ChargentOrders__Payment_Start_Date__c, 
                                                                        Parent_Order__c, ChargentOrders__Payment_End_Date__c, 
                                                                        ChargentOrders__Next_Transaction_Date__c, ChargentOrders__Charge_Amount__c
                                                                        FROM ChargentOrders__ChargentOrder__c];

        for(ChargentOrders__ChargentOrder__c again: orderlistupdated){    
            if(again.Order_Type__c != 'Credit Card Fee (3%)' 
                && again.Create_Duplicate_CC_Fees_on_Insert__c == TRUE){
                    system.assertEquals('17', again.ChargentOrders__Charge_Date__c);
                    system.assertEquals(3, again.ChargentOrders__Charge_Amount__c);  
            }
        } 
}
}