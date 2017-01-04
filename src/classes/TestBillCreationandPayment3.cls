@isTest
private class TestBillCreationandPayment3 {

Static testMethod void TestBillCreationandPayment3(){

/// https://cs4.salesforce.com/setup/build/viewApexClass.apexp?id=01pP0000000FrZQ

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
            RecordTypeId = '012j00000010Ha3');       
        Insert accountA;      

        system.debug(accountA);

        List <String> parentaccountIDs = new List<String>{ 
          'accountA.id'
        };      


 Utility_Account_Log__c ualog = (Utility_Account_Log__c)TestFactory.createSObject(new Utility_Account_Log__c(Name = '0000234',
                                                                                                                 Account__c = accountA.Id,
                                                                                                                 Annual_Cost_of_Electricity__c = 10000,
                                                                                                                 Name_on_Account__c = 'jordan jordan'));
 insert ualog;

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
                                                                                
 insert opportunityone;
 insert opportunitytwo;

 Utility_Account_Subscription__c uasone = (Utility_Account_Subscription__c)TestFactory.createSObject(new Utility_Account_Subscription__c(
                                                                                                    Name = '0000234',
                                                                                                    Utility_Account_Log__c = ualog.Id,
                                                                                                    Opportunity__c = opportunityone.Id,
                                                                                                    Calculated_Annual_Cost_of_Electricity__c = 4000,
                                                                                                    Subscribed_Annual_Cost_of_Electricity__c = 4000));

 Utility_Account_Subscription__c uastwo = (Utility_Account_Subscription__c)TestFactory.createSObject(new Utility_Account_Subscription__c(
                                                                                                    Name = '000-0234',
                                                                                                    Utility_Account_Log__c = ualog.Id,
                                                                                                    Opportunity__c = opportunitytwo.Id,
                                                                                                    Calculated_Annual_Cost_of_Electricity__c = 6000,
                                                                                                    Subscribed_Annual_Cost_of_Electricity__c = 6000));

insert uasone;
insert uastwo; 

uasone.Customer_Subscription_KW_DC_STATIC__c = 25;
uastwo.Customer_Subscription_KW_DC_STATIC__c = 20;
update uasone;
update uastwo;
system.debug(uasone.Customer_Subscription_KW_DC_STATIC__c);

        System.debug('Verifying the opportunity:');
        List <Opportunity> oppUpdatePendingList = new List<Opportunity>();       
        List <Opportunity> oppUpdateCompleteList = new List<Opportunity>();
        List <Opportunity> oppList = [SELECT Id, Shared_Solar_System__c, AccountId FROM Opportunity];
        
     /*   for(Opportunity opp : oppList){
            opp.stageName = 'Pending BlueWave Signature';
            oppUpdatePendingList.add(opp);
            system.debug(opp);
        }
        update oppUpdatePendingList;

        for(Opportunity opptwo : oppList){
            opptwo.stageName = 'Complete';
            oppUpdateCompleteList.add(opptwo);  
            system.debug(opptwo);          
            System.debug(opptwo.AccountId);
        }
        update oppUpdateCompleteList;
        */

        List <Utility_Account_Subscription__c> uaslist = [SELECT Id, Customer_Subscription_KW_DC_STATIC__c, Subscribed_Annual_Cost_of_Electricity__c, Calculated_Annual_Cost_of_Electricity__c, Shared_Solar_System_Name__c FROM Utility_Account_Subscription__c];

        for(Utility_Account_Subscription__c uas : uaslist){
        system.debug(uas.Customer_Subscription_KW_DC_STATIC__c);
        system.debug(uas.Subscribed_Annual_Cost_of_Electricity__c);
        system.debug(uas.Calculated_Annual_Cost_of_Electricity__c);
        }

// Log Production Update - First Month

        Date myDateJan = Date.newInstance(2016, 1, 1);
        Date myDateFeb = Date.newInstance(2016, 2, 2);
        Date myDateMar = Date.newInstance(2016, 3, 3);
        Date myDateApr = Date.newInstance(2016, 4, 4);

        Energy_Usage_Update__c productionupdateA1 = new Energy_Usage_Update__c (
                Name = 'sssA - January 2016',
                Shared_Solar_System__c = sss1.id,
                Production__c = 90000,
                Date__c = myDateJan 
                );

        Insert productionupdateA1;
        system.debug(productionupdateA1);

// Production Update Month 2

        Energy_Usage_Update__c productionupdateB2 = new Energy_Usage_Update__c (
                Name = 'sssA - February 2016',
                Shared_Solar_System__c = sss1.id,
                Production__c = 120000,
                Date__c = myDateFeb
                );
                
        insert productionupdateB2;


// Make payment plan balance on 2
        
        List <System_Bill__c> systemBillList = [SELECT Id, Name, Waive_Late_Fees__c, Total_Due__c, Shared_Solar_System__c, Shared_Solar_System_ID__c, Bill_Number__c, Property_Account_ID__c FROM System_Bill__c];
        system.debug(systemBillList);

        ChargentBase__Gateway__c chGateway  = new ChargentBase__Gateway__c(Name = 'Chargent Gateway',
                                                                           ChargentBase__Merchant_ID__c = '235986',
                                                                           ChargentBase__Active__c = TRUE);
        insert chGateway;

                // Query for system bills that were created from the production update
                for(System_Bill__c systemBill : systemBillList){
                        if (systembill.Bill_Number__c == 2){
                                //Pay off balance in month 2
                                ChargentOrders__ChargentOrder__c orderA  = new ChargentOrders__ChargentOrder__c(
                                                                                          ChargentOrders__Account__c = systemBill.Property_Account_Id__c,
                                                                                          ChargentOrders__Gateway__c = chGateway.Id,
                                                                                        //  ChargentOrders__Shipping_Name__c = systemBill.Shared_Solar_System__r.Id,
                                                                                          ChargentOrders__Billing_First_Name__c = 'Cole',
                                                                                          ChargentOrders__Billing_Last_Name__c = 'Swain',
                                                                                          ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
                                                                                          ChargentOrders__Billing_Zip_Postal__c = '02467',                                                                                                    
                                                                                          ChargentOrders__Subtotal__c = 100,
                                                                                          ChargentOrders__Payment_Method__c = 'Credit Card',
                                                                                          System_Bill__c = systemBill.Id,
                                                                                          ChargentOrders__Card_Type__c = 'Visa',
                                                                                          ChargentOrders__Card_Number__c = '411111111111',
                                                                                          ChargentOrders__Card_Security_Code__c = '999',
                                                                                          ChargentOrders__Card_Expiration_Month__c = '02',
                                                                                          ChargentOrders__Card_Expiration_Year__c = '2018',
                                                                                          ChargentOrders__Card_Last_4__c = '1111'); 
                                insert orderA;

                                ChargentOrders__Transaction__c transA = new ChargentOrders__Transaction__c(
                                                    ChargentOrders__Order__c = orderA.id,
                                                    ChargentOrders__Amount__c = 100,
                                                    ChargentOrders__Response_Status__c ='Approved',
                                                    ChargentOrders__Gateway_ID__c = chGateway.id,
                                                    ChargentOrders__Gateway__c = chGateway.id,
                                                    Distributed_Among_System_Bills__c = FALSE,
                                                    ChargentOrders__Response_Message__c = 'OK',
                                                    ChargentOrders__Type__c = 'Charge',
                                                    ChargentOrders__Payment_Method__c = 'Credit Card',                                    
                                                    Activity_Type__c = 'Payment');

                                insert transA;
                                transA.Distributed_Among_System_Bills__c = TRUE;
                                update transA;
                    
                                // Make Payment Plan on Bill 2
                                systembill.Waive_Late_Fees__c = TRUE;
                                systembill.Distribute_This_Balance_As_Payment_Plan__c = TRUE;
                                //systembill.Payment_Plan_Balance_to_Distribute__c = 300;
                                update systembill;
                        }

                }

// insert 8 more months with same property and SSS as other Bills

        for(System_Bill__c systemBill : systemBillList){

            if (systembill.Bill_Number__c == 1){

                integer j;
                list <System_Bill__c> sbstoupdate = new list <System_Bill__c>();                     

                for(j = 3; j < 10 ; j++){
                    boolean refund = FALSE;
                    boolean latefee = FALSE;
                    decimal addamount = 0; 

                    if(j==4){
                        refund = TRUE;
                        addamount = 20;
                    }

                    if(j==5){
                        latefee = TRUE;
                        refund = TRUE;
                        addamount = 20;
                    }


                    Account_Bill__c accbillthree = new Account_Bill__c (
                        Bill_Number__c = j,
                        Parent_Account__c = systemBill.Property_Account_Id__c,
                        Name = 'First Last Month 2016' + j,
                        Unique_ID__c = '000111000111000111FAS' + j 
                        );

                    system.debug(accbillthree);
                    insert accbillthree;

                    System_Bill__c billthree = new System_Bill__c (
                        Shared_Solar_System__c = systembill.Shared_Solar_System_Id__c,
                        Shared_Solar_System_ID2__c = systembill.Shared_Solar_System_Id__c,
                        Bill_Number__c = j,
                        Account_Bill__c = accbillthree.id,
                        Property_Account__c = systemBill.Property_Account_Id__c,
                        Refund_This_Balance__c = refund,
                        Amount_to_Add__c = addamount,
                        Waive_Late_Fees__c = latefee,
                        Name = 'First Last March 2016' + j,
                        Unique_ID__c = '000111000111000111FAS' + j
                        );

                    sbstoupdate.add(billthree);

                    //insert billthree; 
                }

                insert sbstoupdate;
            }
        }

        List <System_Bill__c> updatedsystemBillList = [SELECT Id, Late_Fees__c, Late_Payments__c, YTD_Billed__c, YTD_Payments__c, Shared_Solar_System_ID__c, Payment_Plan_Balance_to_Distribute__c, Bill_Number__c, Payment_Plan_Balance__c, Name, Due_This_Month__c, Previous_Month_Overdue_Balance__c, Total_Due__c, Balance_Net_Late_Payments__c, Total_Payments_This_Month__c, Shared_Solar_System__c, Property_Account_ID__c FROM System_Bill__c];
        system.debug(updatedsystemBillList);


        Test.StartTest();
        for(System_Bill__c sbs : updatedsystemBillList){
            system.debug(sbs.YTD_Payments__c);
            system.debug(sbs.YTD_Billed__c);
            // First bill does not have a payment, so no payments that month
            if(sbs.Bill_Number__c == 1){
                system.debug(sbs.Total_Payments_This_Month__c);
                System.assert(sbs.Total_Due__c > 0);
                System.assert(sbs.Late_Payments__c > 0);
                System.assert(sbs.Total_Payments_This_Month__c == 0);
            }

            // Second bill has a payment, so balance should be zero and Late Fees should be waived
            if(sbs.Bill_Number__c == 2){
                system.debug(sbs.Balance_Net_Late_Payments__c);
                System.assert(sbs.Total_Due__c > 0);
                System.assert(sbs.Late_Fees__c == 0);
                System.assert(sbs.Late_Payments__c == 0);
                System.assert(sbs.Total_Payments_This_Month__c > 0);
            }

            // Month 2 Payment Plan should run for bill number 3 through 8 and there should be an Adjustment on bill 4
            if(sbs.Bill_Number__c == 3){
                system.debug(sbs.Payment_Plan_Balance__c);
                System.assert(sbs.Payment_Plan_Balance__c > 0);
                System.assert(sbs.Total_Due__c > 0);
            }

            if(sbs.Bill_Number__c == 4){
                system.debug(sbs.Total_Due__c);
                System.assert(sbs.Total_Due__c > sbs.Payment_Plan_Balance__c);
            }

            if(sbs.Bill_Number__c == 8){
                system.debug(sbs.Payment_Plan_Balance__c);
                System.assert(sbs.Payment_Plan_Balance__c > 0);
            }

            if(sbs.Bill_Number__c == 9){
                system.debug(sbs.Payment_Plan_Balance__c);
                System.assert(sbs.Payment_Plan_Balance__c == 0);
            }
        }

        Test.StopTest();

}
}