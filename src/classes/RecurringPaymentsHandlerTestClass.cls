@isTest
private class RecurringPaymentsHandlerTestClass{

Static testMethod void RecurringPaymentsHandlerTestClass(){

// Create NMC Tariffs

        Date myDateJan = Date.newInstance(2016, 1, 1);
        Date myDateFeb = Date.newInstance(2016, 2, 2);
        Date myDateMar = Date.newInstance(2016, 3, 3);
        Date myDateApr = Date.newInstance(2016, 4, 4);


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

        insert new List<Utility_NMC_Tariff__c>{everbillNMC, eversizeNMC, ngridsizeNMC, ngridbillNMC};


// Create Load Zones and Service Territories

        Load_U__c everLZU = new Load_U__c ( 
                Name = '02633', 
                Load_zone__c = 'SEMA Eversource', 
                LZ__c = 'SEMA', 
                Utility__C = 'Eversource', 
                Town__c= 'Medfield');

        Load_U__c ngridLZU = new Load_U__c ( 
                Name = '01570', 
                Load_zone__c= 'WCMA National Grid', 
                LZ__c = 'WCMA', 
                Utility__C = 'National Grid', 
                Town__c= 'Westtown');

        insert new List<Load_U__c>{everLZU, ngridLZU};
        
        Entity__c entity1 = new Entity__c(Name = 'Entityone');

        Entity__c entity2 = new Entity__c(Name = 'Entitytwo');
        
        insert new List<Entity__c>{entity1, entity2};


// Create Shared Solar Systems 

        Shared_Solar_System__c sss1 = (Shared_Solar_System__c)TestFactory.createSObject(new Shared_Solar_System__c(Name = 'Oxford Barrett St. P1',
                                                                                                                                Service_Territory__c = 'SEMA',
                                                                                                                                Open__c = true,
                                                                                                                                BWC_Project_Entity_Manual__c = entity1.Id,
                                                                                                                                Reserved_Capacity_kW_DC__c = '0',
                                                                                                                                Capacity_Committed_kW_DC__c = 0,
                                                                                                                                Total_System_Size_kWh_DC__c = 1445.86,
                                                                                                                                Total_System_Size_kW_AC__c  = 996,
                                                                                                                                System_Utility__c = 'Eversource',
                                                                                                                                Credit_Score_Requirement__c = 200,
                                                                                                                                Assignment_order__c = '1',
                                                                                                                                Utility_NMC_Tariff__c = eversizeNMC.Id,
                                                                                                                                Expected_Yield_kWh_kW__c = 1300,
                                                                                                                                Assemblage_Count__c = 1,
                                                                                                                                Sales_Partners__c = 'All',
                                                                                                                                Maximum_Subscription_Assemblage__c = 25));

        Shared_Solar_System__c sss2 = (Shared_Solar_System__c)TestFactory.createSObject(new Shared_Solar_System__c(Name = 'Oxford Barrett St. P2',
                                                                                                                                Service_Territory__c = 'SEMA',
                                                                                                                                Open__c = true,
                                                                                                                                BWC_Project_Entity_Manual__c = entity1.Id,
                                                                                                                                Reserved_Capacity_kW_DC__c = '0',
                                                                                                                                Capacity_Committed_kW_DC__c = 0,
                                                                                                                                Total_System_Size_kWh_DC__c = 1445.86,
                                                                                                                                Total_System_Size_kW_AC__c  = 996,
                                                                                                                                System_Utility__c = 'Eversource',
                                                                                                                                Credit_Score_Requirement__c = 200,
                                                                                                                                Assignment_order__c = '2',
                                                                                                                                Utility_NMC_Tariff__c = eversizeNMC.Id,
                                                                                                                                Expected_Yield_kWh_kW__c = 1300,
                                                                                                                                Assemblage_Count__c = 1,
                                                                                                                                Sales_Partners__c = 'All',
                                                                                                                                Maximum_Subscription_Assemblage__c = 25));

        Shared_Solar_System__c sss3 = (Shared_Solar_System__c)TestFactory.createSObject(new Shared_Solar_System__c(Name = 'Fairhaven',
                                                                                                                                Service_Territory__c = 'SEMA',
                                                                                                                                Open__c = true,
                                                                                                                                BWC_Project_Entity_Manual__c = entity2.Id,
                                                                                                                                Reserved_Capacity_kW_DC__c = '0',
                                                                                                                                Capacity_Committed_kW_DC__c = 0,
                                                                                                                                Total_System_Size_kWh_DC__c = 1335.86,
                                                                                                                                Total_System_Size_kW_AC__c  = 996,
                                                                                                                                System_Utility__c = 'Eversource',
                                                                                                                                Credit_Score_Requirement__c = 200,
                                                                                                                                Assignment_order__c = '2',
                                                                                                                                Utility_NMC_Tariff__c = eversizeNMC.Id,
                                                                                                                                Expected_Yield_kWh_kW__c = 1300,
                                                                                                                                Assemblage_Count__c = 1,
                                                                                                                                Sales_Partners__c = 'All',
                                                                                                                                Maximum_Subscription_Assemblage__c = 25));
        insert new List<Shared_Solar_System__c>{sss1, sss2, sss3};


// create Parent Accounts

        Account accountA = new Account(name = 'Account A',
            RecordTypeId = '012j00000010Ha3',
            Recurring_Billing__c = True); 

        Insert accountA;      

        Account accountB = new Account(name = 'Account B',
            RecordTypeId = '012j00000010Ha3',
            Recurring_Billing__c = True);    

        Insert accountB;      


        Utility_Account_Log__c ualog = (Utility_Account_Log__c)TestFactory.createSObject(new Utility_Account_Log__c(Name = '0000234',
                                                                                                                 Account__c = accountA.Id,
                                                                                                                 Annual_Cost_of_Electricity__c = 10000,
                                                                                                                 Name_on_Account__c = 'jordan pentaleri'));
        insert ualog;

        Utility_Account_Log__c ualogtwo = (Utility_Account_Log__c)TestFactory.createSObject(new Utility_Account_Log__c(Name = '0000256',
                                                                                                                 Account__c = accountB.Id,
                                                                                                                 Annual_Cost_of_Electricity__c = 15000,
                                                                                                                 Name_on_Account__c = 'nick speyer'));
        insert ualogtwo;


        Opportunity opportunityone = new Opportunity(Name = 'Jordan Jordan',
                                                            AccountId = accountA.Id,
                                                            Shared_Solar_System__c = sss1.Id,
                                                            StageName = 'Complete',
                                                            CS_Capacity_Allocated__c = 25,
                                                            CloseDate = System.today());

        Opportunity opportunitytwo = new Opportunity(Name = 'Jordan Jordan',
                                                            AccountId = accountA.Id,
                                                            Shared_Solar_System__c = sss2.Id,
                                                            StageName = 'Complete',
                                                            CS_Capacity_Allocated__c = 20,
                                                            CloseDate = System.today()); 

        Opportunity opportunitythree = new Opportunity(Name = 'Nick Speyer',
                                                            AccountId = accountB.Id,
                                                            Shared_Solar_System__c = sss2.Id,
                                                            StageName = 'Complete',
                                                            CS_Capacity_Allocated__c = 12,
                                                            CloseDate = System.today()); 

        Opportunity opportunityfour = new Opportunity(Name = 'Nick Speyer',
                                                            AccountId = accountB.Id,
                                                            Shared_Solar_System__c = sss3.Id,
                                                            StageName = 'Complete',
                                                            CS_Capacity_Allocated__c = 9,
                                                            CloseDate = System.today()); 
                                                                                
        insert new List<Opportunity>{opportunityone, opportunitytwo, opportunitythree, opportunityfour};

        Utility_Account_Subscription__c uasone = new Utility_Account_Subscription__c(Name = '0000234',
                                                                                    Utility_Account_Log__c = ualog.Id,
                                                                                    Opportunity__c = opportunityone.Id,
                                                                                    Calculated_Annual_Cost_of_Electricity__c = 4000,
                                                                                    Subscribed_Annual_Cost_of_Electricity__c = 4000);

        Utility_Account_Subscription__c uastwo = new Utility_Account_Subscription__c(Name = '0000234',
                                                                                    Utility_Account_Log__c = ualog.Id,
                                                                                    Opportunity__c = opportunitytwo.Id,
                                                                                    Calculated_Annual_Cost_of_Electricity__c = 5000,
                                                                                    Subscribed_Annual_Cost_of_Electricity__c = 5000);

        Utility_Account_Subscription__c uasthree = new Utility_Account_Subscription__c(Name = '0000256',
                                                                                    Utility_Account_Log__c = ualogtwo.Id,
                                                                                    Opportunity__c = opportunitythree.Id,
                                                                                    Calculated_Annual_Cost_of_Electricity__c = 6000,
                                                                                    Subscribed_Annual_Cost_of_Electricity__c = 6000);

        Utility_Account_Subscription__c uasfour = new Utility_Account_Subscription__c(Name = '0000256',
                                                                                    Utility_Account_Log__c = ualogtwo.Id,
                                                                                    Opportunity__c = opportunityfour.Id,
                                                                                    Calculated_Annual_Cost_of_Electricity__c = 7000,
                                                                                    Subscribed_Annual_Cost_of_Electricity__c = 7000);



        insert new List<Utility_Account_Subscription__c>{uasone, uastwo, uasthree, uasfour};

        uasone.Customer_Subscription_KW_DC_STATIC__c = 25;
        uastwo.Customer_Subscription_KW_DC_STATIC__c = 20;
        uasthree.Customer_Subscription_KW_DC_STATIC__c = 20;
        uasfour.Customer_Subscription_KW_DC_STATIC__c = 20;

        update new List<Utility_Account_Subscription__c>{uasone, uastwo, uasthree, uasfour};

// Log Production Update - First Month

        ChargentBase__Gateway__c chGatewayone  = new ChargentBase__Gateway__c(Name = 'Chargent Gateway One',
                                                                           ChargentBase__Merchant_ID__c = '235986',
                                                                           ChargentBase__Active__c = TRUE,
                                                                           Shared_Solar_System__c = sss1.id,
                                                                           Entity__c = entity1.Id);
        insert chGatewayone;

        ChargentBase__Gateway__c chGatewaytwo  = new ChargentBase__Gateway__c(Name = 'Chargent Gateway Two',
                                                                           ChargentBase__Merchant_ID__c = '235116',
                                                                           ChargentBase__Active__c = TRUE,
                                                                           Shared_Solar_System__c = sss3.id,
                                                                           Entity__c = entity2.Id);
        insert chGatewaytwo;



        Account_Bill__c abone = new Account_Bill__c (   Name = 'Jordan Jordan March 2016',
                                                        Bill_Number__c = 1,
                                                        Autopay__c = True,
                                                        Parent_Account__c = AccountA.Id);

        Account_Bill__c abtwo = new Account_Bill__c (   Name = 'Nick Speyer March 2016',
                                                        Bill_Number__c = 1,
                                                        Autopay__c = True,
                                                        Parent_Account__c = AccountB.Id);

        insert new List <Account_Bill__c>{abone, abtwo};

        System_Bill__c sbone = new System_Bill__c ( Name = 'Jordan Oxford Barrett St. P1 March 2016', 
                                                    Bill_Number__c = 1,
                                                    Account_Bill__c = abone.Id,
                                                    Refund_this_Balance__c = True,
                                                    Amount_To_Add__c = -100,
                                                    Unique_ID__c = '000000001',
                                                    Shared_Solar_System__c = sss1.Id, 
                                                    Property_Account__c = AccountA.Id );

        System_Bill__c sbtwo = new System_Bill__c ( Name = 'Jordan Oxford Barrett St. P2 March 2016', 
                                                    Bill_Number__c = 1,
                                                    Account_Bill__c = abone.Id,
                                                    Refund_this_Balance__c  = True,
                                                    Amount_To_Add__c = -100,
                                                    Unique_ID__c = '000000001',
                                                    Shared_Solar_System__c = sss2.Id, 
                                                    Property_Account__c = AccountA.Id );

        System_Bill__c sbthree = new System_Bill__c ( Name = 'Nick Speyer Oxford Barrett St. P2 March 2016', 
                                                    Bill_Number__c = 1,
                                                    Account_Bill__c = abtwo.Id,
                                                    Refund_this_Balance__c = True,
                                                    Amount_To_Add__c = -100,
                                                    Unique_ID__c = '000000001',
                                                    Shared_Solar_System__c = sss2.Id, 
                                                    Property_Account__c = AccountB.Id );

        System_Bill__c sbfour = new System_Bill__c ( Name = 'Nick Speyer Fairhaven March 2016', 
                                                    Bill_Number__c = 1,
                                                    Account_Bill__c = abtwo.Id,
                                                    Refund_this_Balance__c = True,
                                                    Amount_To_Add__c = -100,
                                                    Unique_ID__c = '000000001',
                                                    Shared_Solar_System__c = sss3.Id, 
                                                    Property_Account__c = AccountB.Id );

        insert new List <System_Bill__c>{sbone, sbtwo, sbthree, sbfour};

        List <ChargentOrders__ChargentOrder__c> neworderlist = new list <ChargentOrders__ChargentOrder__c> ();

        List <System_Bill__c> systemBillList = [SELECT Id, Name, Waive_Late_Fees__c, Total_Due__c, Due_This_Month__c, Shared_Solar_System__c, Shared_Solar_System_ID__c, Bill_Number__c, Property_Account_ID__c 
                                                FROM System_Bill__c
                                                ORDER BY Bill_NUmber__c DESC];
        system.debug(systemBillList);   
        
        List <Account_Bill__c> accountbilllist = [  SELECT Id, Name, Property_Account_Id__c
                                                    FROM Account_Bill__c
                                                    ORDER BY Bill_NUmber__c DESC];
        system.debug(accountbilllist);   

                for(Account_Bill__c accountbill : accountbillList){

                    if(accountbill.Property_Account_Id__c == AccountA.Id){
                        ChargentOrders__ChargentOrder__c orderA  = new ChargentOrders__ChargentOrder__c(
                                                                                          ChargentOrders__Account__c = accountbill.Property_Account_Id__c,
                                                                                          ChargentOrders__Gateway__c = chGatewayone.Id,
                                                                                          ChargentOrders__Shipping_Name__c = entity1.Id,
                                                                                          ChargentOrders__Billing_First_Name__c = 'Jordan',
                                                                                          ChargentOrders__Billing_Last_Name__c = 'Pentaleri',
                                                                                          ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
                                                                                          ChargentOrders__Billing_Zip_Postal__c = '02467',                                                                                                    
                                                                                          ChargentOrders__Subtotal__c = 603.92,
                                                                                          ChargentOrders__Payment_Method__c = 'Credit Card',
                                                                                          Account_Bill__c = accountbill.Id,
                                                                                          ChargentOrders__Card_Type__c = 'Visa',
                                                                                          ChargentOrders__Card_Number__c = '411111111111',
                                                                                          ChargentOrders__Card_Security_Code__c = '999',
                                                                                          ChargentOrders__Card_Expiration_Month__c = '02',
                                                                                          ChargentOrders__Card_Expiration_Year__c = '2018',
                                                                                          ChargentOrders__Card_Last_4__c = '1111',
                                                                                          ChargentOrders__Payment_Status__c = 'Recurring',
                                                                                          ChargentOrders__Payment_Frequency__c = 'Monthly',
                                                                                          ChargentOrders__Payment_Start_Date__c = system.today(),
                                                                                          ChargentOrders__Charge_Date__c = '30'); 
                        neworderlist.add(orderA);
                    }

                    if(accountbill.Property_Account_Id__c == AccountB.Id ){
                        ChargentOrders__ChargentOrder__c orderB1  = new ChargentOrders__ChargentOrder__c(
                                                                                          ChargentOrders__Account__c = accountbill.Property_Account_Id__c,
                                                                                          ChargentOrders__Gateway__c = chGatewaytwo.Id,
                                                                                          ChargentOrders__Shipping_Name__c = entity1.Id,
                                                                                          ChargentOrders__Billing_First_Name__c = 'Cole',
                                                                                          ChargentOrders__Billing_Last_Name__c = 'Swain',
                                                                                          ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
                                                                                          ChargentOrders__Billing_Zip_Postal__c = '02467',                                                                                                    
                                                                                          ChargentOrders__Subtotal__c = 100.22,
                                                                                          ChargentOrders__Payment_Method__c = 'Credit Card',
                                                                                          Account_Bill__c = accountbill.Id,
                                                                                          ChargentOrders__Card_Type__c = 'Visa',
                                                                                          ChargentOrders__Card_Number__c = '411111111111',
                                                                                          ChargentOrders__Card_Security_Code__c = '999',
                                                                                          ChargentOrders__Card_Expiration_Month__c = '02',
                                                                                          ChargentOrders__Card_Expiration_Year__c = '2018',
                                                                                          ChargentOrders__Card_Last_4__c = '1111',
                                                                                          ChargentOrders__Payment_Status__c = 'Recurring',
                                                                                          ChargentOrders__Payment_Frequency__c = 'Monthly',
                                                                                          ChargentOrders__Payment_Start_Date__c = system.today(),
                                                                                          ChargentOrders__Charge_Date__c = '25'); 
                        neworderlist.add(orderB1);    

                        ChargentOrders__ChargentOrder__c orderB2  = new ChargentOrders__ChargentOrder__c(
                                                                                          ChargentOrders__Account__c = accountbill.Property_Account_Id__c,
                                                                                          ChargentOrders__Gateway__c = chGatewaytwo.Id,
                                                                                          ChargentOrders__Shipping_Name__c = entity2.Id,
                                                                                          ChargentOrders__Billing_First_Name__c = 'Cole',
                                                                                          ChargentOrders__Billing_Last_Name__c = 'Swain',
                                                                                          ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
                                                                                          ChargentOrders__Billing_Zip_Postal__c = '02467',                                                                                                    
                                                                                          ChargentOrders__Subtotal__c = 100.22,
                                                                                          ChargentOrders__Payment_Method__c = 'Credit Card',
                                                                                          Account_Bill__c = accountbill.Id,
                                                                                          ChargentOrders__Card_Type__c = 'Visa',
                                                                                          ChargentOrders__Card_Number__c = '411111111111',
                                                                                          ChargentOrders__Card_Security_Code__c = '999',
                                                                                          ChargentOrders__Card_Expiration_Month__c = '02',
                                                                                          ChargentOrders__Card_Expiration_Year__c = '2018',
                                                                                          ChargentOrders__Card_Last_4__c = '1111',
                                                                                          ChargentOrders__Payment_Status__c = 'Recurring',
                                                                                          ChargentOrders__Payment_Frequency__c = 'Monthly',
                                                                                          ChargentOrders__Payment_Start_Date__c = system.today(),
                                                                                          ChargentOrders__Charge_Date__c = '20'); 
                        neworderlist.add(orderB2);
                    }

                }

Test.StartTest();

        insert neworderlist;

        Energy_Usage_Update__c productionupdateC1 = new Energy_Usage_Update__c (
                Name = 'sssB - February 2016',
                Shared_Solar_System__c = sss2.id,
                Production__c = 24000,
                Date__c = myDateMar
        );

        Energy_Usage_Update__c productionupdateC2 = new Energy_Usage_Update__c (
                Name = 'sssC - February 2016',
                Shared_Solar_System__c = sss3.id,
                Production__c = 14000,
                Date__c = myDateMar
        );
        
        insert productionupdateC2;
        insert productionupdateC1;

Test.StopTest();

    List <UASB__c> uasb1 = [SELECT Id
                            FROM UASB__c];

    Update uasb1;

        List <System_Bill__c> systemBillListtwo = [SELECT Id, Name, Account_Bill__c, Waive_Late_Fees__c, Total_Due__c, Due_This_Month__c, Shared_Solar_System__c, Shared_Solar_System_ID__c, Bill_Number__c, Property_Account_ID__c 
                                                FROM System_Bill__c
                                                ORDER BY Bill_Number__c DESC];
        system.debug(systemBillListtwo);      


        List <ChargentOrders__ChargentOrder__c> orderlist = [SELECT Id, Unique_ID__c, System_Bill__r.Property_Account_ID__c, ChargentOrders__Payment_Status__c, ChargentOrders__Payment_Stop__c, ChargentOrders__Payment_Frequency__c, ChargentOrders__Charge_Date__c,
                                                                ChargentOrders__Payment_Start_Date__c, Account_Bill__r.Bill_Number__c, ChargentOrders__Payment_End_Date__c, ChargentOrders__Next_Transaction_Date__c, ChargentOrders__Charge_Amount__c
                                                            FROM ChargentOrders__ChargentOrder__c];
        system.debug(orderlist);

        for(ChargentOrders__ChargentOrder__c cho : orderlist){
            // charge date of 25(sss2)/20(sss3) = accountB (nick) orders, charge date 30 = accountA (jordan) orders
            if(cho.ChargentOrders__Charge_Date__c == '20'){
                system.assertEquals(cho.Account_Bill__r.Bill_Number__c, 2);  
                system.debug(cho.ChargentOrders__Charge_Amount__c == 34.86); 
                system.debug(cho.ChargentOrders__Charge_Amount__c); 
            }
            if(cho.ChargentOrders__Charge_Date__c == '25'){
                system.assertEquals(cho.Account_Bill__r.Bill_Number__c, 2);  
                system.debug(cho.ChargentOrders__Charge_Amount__c == 55.22); 
                system.debug(cho.ChargentOrders__Charge_Amount__c); 
            }
            else if(cho.ChargentOrders__Charge_Date__c == '30'){
                system.assertEquals(cho.Account_Bill__r.Bill_Number__c, 2);
                system.debug(cho.ChargentOrders__Charge_Amount__c);
            }
        }
}
}