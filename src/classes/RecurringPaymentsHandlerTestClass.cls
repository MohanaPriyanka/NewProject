@isTest
private class RecurringPaymentsHandlerTestClass{

Static testMethod void RecurringPaymentsHandlerTestClass(){

// Create NMC Tariffs

        Utility_NMC_Tariff__c everbillNMC = new Utility_NMC_Tariff__c (
                Name = 'Eversource SEMA Class 2', 
                Utility__c = 'Eversource', 
                Class__c = 'Class 2',
                Value_of_Net_Metering_Credit__c = 0.1848,
                Current_Billing_Rate__c = TRUE
                );
        system.debug(everbillNMC);

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
        
        system.debug(everbillNMC);


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

        Insert everLZU;
        Insert ngridLZU;
        
        system.debug(ngridLZU);

// Create Shared Solar Systems 

        Shared_Solar_System__c sss1 = (Shared_Solar_System__c)TestFactory.createSObject(new Shared_Solar_System__c(Name = 'Oxford Barrett St. P1',
                                                                                                                                Service_Territory__c = 'SEMA',
                                                                                                                                Open__c = true,
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

      //  insert sss1;

        Shared_Solar_System__c sss2 = (Shared_Solar_System__c)TestFactory.createSObject(new Shared_Solar_System__c(Name = 'Oxford Barrett St. P2',
                                                                                                                                Service_Territory__c = 'SEMA',
                                                                                                                                Open__c = true,
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


        insert new List<Shared_Solar_System__c>{sss1, sss2};


// create Parent Accounts

        Account accountA = new Account(name = 'Account A',
            RecordTypeId = '012j00000010Ha3',
            Recurring_Billing__c = True);       
        Insert accountA;      

        system.debug(accountA);

        Account accountB = new Account(name = 'Account B',
            RecordTypeId = '012j00000010Ha3',
            Recurring_Billing__c = True);       
        Insert accountB;      

        system.debug(accountB);

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


 Opportunity opportunityone = (Opportunity)TestFactory.createSObject(new Opportunity(Name = 'Jordan Jordan',
                                                                                AccountId = accountA.Id,
                                                                                Shared_Solar_System__c = sss1.Id,
                                                                                StageName = 'Complete',
                                                                                CS_Capacity_Allocated__c = 25,
                                                                                CloseDate = System.today()));

 Opportunity opportunitytwo = (Opportunity)TestFactory.createSObject(new Opportunity(Name = 'Jordan Jordan',
                                                                                AccountId = accountA.Id,
                                                                                Shared_Solar_System__c = sss2.Id,
                                                                                StageName = 'Complete',
                                                                                CS_Capacity_Allocated__c = 20,
                                                                                CloseDate = System.today())); 

Opportunity opportunitythree = (Opportunity)TestFactory.createSObject(new Opportunity(Name = 'Nick Speyer',
                                                                                AccountId = accountB.Id,
                                                                                Shared_Solar_System__c = sss2.Id,
                                                                                StageName = 'Complete',
                                                                                CS_Capacity_Allocated__c = 12,
                                                                                CloseDate = System.today())); 
                                                                                
 insert opportunityone;
 insert opportunitytwo;
 insert opportunitythree;

 Utility_Account_Subscription__c uasone = (Utility_Account_Subscription__c)TestFactory.createSObject(new Utility_Account_Subscription__c(
                                                                                                    Name = '0000234',
                                                                                                    Utility_Account_Log__c = ualog.Id,
                                                                                                    Opportunity__c = opportunityone.Id,
                                                                                                    Calculated_Annual_Cost_of_Electricity__c = 4000,
                                                                                                    Subscribed_Annual_Cost_of_Electricity__c = 4000));

 Utility_Account_Subscription__c uastwo = (Utility_Account_Subscription__c)TestFactory.createSObject(new Utility_Account_Subscription__c(
                                                                                                    Name = '000-0235',
                                                                                                    Utility_Account_Log__c = ualog.Id,
                                                                                                    Opportunity__c = opportunitytwo.Id,
                                                                                                    Calculated_Annual_Cost_of_Electricity__c = 6000,
                                                                                                    Subscribed_Annual_Cost_of_Electricity__c = 6000));

 Utility_Account_Subscription__c uasthree = (Utility_Account_Subscription__c)TestFactory.createSObject(new Utility_Account_Subscription__c(
                                                                                                    Name = '000-0236',
                                                                                                    Utility_Account_Log__c = ualogtwo.Id,
                                                                                                    Opportunity__c = opportunitythree.Id,
                                                                                                    Calculated_Annual_Cost_of_Electricity__c = 1800,
                                                                                                    Subscribed_Annual_Cost_of_Electricity__c = 1800));
insert uasone;
insert uastwo; 
insert uasthree;

uasone.Customer_Subscription_KW_DC_STATIC__c = 25;
uastwo.Customer_Subscription_KW_DC_STATIC__c = 20;
uasthree.Customer_Subscription_KW_DC_STATIC__c = 20;

update uasone;
update uastwo;
update uasthree;

system.debug(uasone.Customer_Subscription_KW_DC_STATIC__c);

    /*    List <Utility_Account_Subscription__c> uaslist = [SELECT Id, Customer_Subscription_KW_DC_STATIC__c, Subscribed_Annual_Cost_of_Electricity__c, Calculated_Annual_Cost_of_Electricity__c, Shared_Solar_System_Name__c FROM Utility_Account_Subscription__c];

        for(Utility_Account_Subscription__c uas : uaslist){
        system.debug(uas.Customer_Subscription_KW_DC_STATIC__c);
        system.debug(uas.Subscribed_Annual_Cost_of_Electricity__c);
        system.debug(uas.Calculated_Annual_Cost_of_Electricity__c);
        }
    */

// Log Production Update - First Month

        Date myDateJan = Date.newInstance(2016, 1, 1);
        Date myDateFeb = Date.newInstance(2016, 2, 2);
        Date myDateMar = Date.newInstance(2016, 3, 3);
        Date myDateApr = Date.newInstance(2016, 4, 4);

        Energy_Usage_Update__c productionupdateA2 = new Energy_Usage_Update__c (
                Name = 'sssA - February 2016',
                Shared_Solar_System__c = sss1.id,
                Production__c = 120000,
                Date__c = myDateFeb
                );
                
        insert productionupdateA2;

        Energy_Usage_Update__c productionupdateB2 = new Energy_Usage_Update__c (
                Name = 'sssB - February 2016',
                Shared_Solar_System__c = sss2.id,
                Production__c = 14000,
                Date__c = myDateFeb
                );
                
        insert productionupdateB2;           
  
        List <System_Bill__c> systemBillList = [SELECT Id, Name, Waive_Late_Fees__c, Total_Due__c, Due_This_Month__c, Shared_Solar_System__c, Shared_Solar_System_ID__c, Bill_Number__c, Property_Account_ID__c 
                                                FROM System_Bill__c
                                                ORDER BY Bill_NUmber__c DESC];
        system.debug(systemBillList);      

        ChargentBase__Gateway__c chGatewayone  = new ChargentBase__Gateway__c(Name = 'Chargent Gateway One',
                                                                           ChargentBase__Merchant_ID__c = '235986',
                                                                           ChargentBase__Active__c = TRUE,
                                                                           Shared_Solar_System__c = sss1.id);
        insert chGatewayone;

        ChargentBase__Gateway__c chGatewaytwo  = new ChargentBase__Gateway__c(Name = 'Chargent Gateway Two',
                                                                           ChargentBase__Merchant_ID__c = '235116',
                                                                           ChargentBase__Active__c = TRUE,
                                                                           Shared_Solar_System__c = sss2.id);
        insert chGatewaytwo;

                // Query for system bills that were created from the production update
                for(System_Bill__c systemBill : systemBillList){

                    if(systembill.Shared_Solar_System__c == sss1.id){
                        ChargentOrders__ChargentOrder__c orderA1  = new ChargentOrders__ChargentOrder__c(
                                                                                          ChargentOrders__Account__c = systemBill.Property_Account_Id__c,
                                                                                          ChargentOrders__Gateway__c = chGatewayone.Id,
                                                                                          ChargentOrders__Shipping_Name__c = sss1.Id,
                                                                                          ChargentOrders__Billing_First_Name__c = 'Jordan',
                                                                                          ChargentOrders__Billing_Last_Name__c = 'Pentaleri',
                                                                                          ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
                                                                                          ChargentOrders__Billing_Zip_Postal__c = '02467',                                                                                                    
                                                                                          ChargentOrders__Subtotal__c = 603.92,
                                                                                          ChargentOrders__Payment_Method__c = 'Credit Card',
                                                                                          System_Bill__c = systemBill.Id,
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
                        insert orderA1;                        
                    }

                    if(systembill.Shared_Solar_System__c == sss2.id){
                        ChargentOrders__ChargentOrder__c orderA2  = new ChargentOrders__ChargentOrder__c(
                                                                                          ChargentOrders__Account__c = systemBill.Property_Account_Id__c,
                                                                                          ChargentOrders__Gateway__c = chGatewaytwo.Id,
                                                                                          ChargentOrders__Shipping_Name__c = sss2.id,
                                                                                          ChargentOrders__Billing_First_Name__c = 'Cole',
                                                                                          ChargentOrders__Billing_Last_Name__c = 'Swain',
                                                                                          ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
                                                                                          ChargentOrders__Billing_Zip_Postal__c = '02467',                                                                                                    
                                                                                          ChargentOrders__Subtotal__c = 100.22,
                                                                                          ChargentOrders__Payment_Method__c = 'Credit Card',
                                                                                          System_Bill__c = systemBill.Id,
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
                        insert orderA2;

                    }

                }
                

        List <System_Bill__c> updatedsystemBillList = [SELECT Id, Late_Fees__c, Recurring_Payment_ID__c, Late_Payments__c, YTD_Billed__c, YTD_Payments__c, Shared_Solar_System_ID__c, Payment_Plan_Balance_to_Distribute__c, Bill_Number__c, Payment_Plan_Balance__c, Name, Due_This_Month__c, Previous_Month_Overdue_Balance__c, Total_Due__c, Balance_Net_Late_Payments__c, Total_Payments_This_Month__c, Shared_Solar_System__c, Property_Account_ID__c FROM System_Bill__c];
        system.debug(updatedsystemBillList);

   //     for(System_Bill__c sb : updatedsystemBillList){
    //        sb.Recurring_Billing__c = True;
    //    }

    //    update updatedsystemBillList;

        Test.StartTest();

        Energy_Usage_Update__c productionupdateC1 = new Energy_Usage_Update__c (
                Name = 'sssB - February 2016',
                Shared_Solar_System__c = sss2.id,
                Production__c = 24000,
                Date__c = myDateMar
        );

        insert productionupdateC1;

        List <ChargentOrders__ChargentOrder__c> orderlist = [SELECT Id, Unique_ID__c, System_Bill__r.Property_Account_ID__c, ChargentOrders__Payment_Status__c, ChargentOrders__Payment_Stop__c, ChargentOrders__Payment_Frequency__c, ChargentOrders__Charge_Date__c,
                                                                ChargentOrders__Payment_Start_Date__c, System_Bill__r.Bill_Number__c, ChargentOrders__Payment_End_Date__c, ChargentOrders__Next_Transaction_Date__c, ChargentOrders__Charge_Amount__c
                                                            FROM ChargentOrders__ChargentOrder__c];
        system.debug(orderlist);

        Test.StopTest();

        for(ChargentOrders__ChargentOrder__c cho : orderlist){
            // charge date of 25 = sss2 orders
            if(cho.ChargentOrders__Charge_Date__c == '25'){
                system.assert(cho.System_Bill__r.Bill_Number__c == 2);  
            }
            else if(cho.ChargentOrders__Charge_Date__c == '30'){
                system.assert(cho.System_Bill__r.Bill_Number__c == 1);
            }
        }

        List <System_Bill__c> updatedsystemBillList2 = [SELECT Id, Late_Fees__c, Recurring_Payment_ID__c, Late_Payments__c, YTD_Billed__c, YTD_Payments__c, Shared_Solar_System_ID__c, Payment_Plan_Balance_to_Distribute__c, Bill_Number__c, Payment_Plan_Balance__c, Name, Due_This_Month__c, Previous_Month_Overdue_Balance__c, Total_Due__c, Balance_Net_Late_Payments__c, Total_Payments_This_Month__c, Shared_Solar_System__c, Property_Account_ID__c FROM System_Bill__c];
        system.debug(updatedsystemBillList2);

}
}