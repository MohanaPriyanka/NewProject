@isTest
public class paymentGatewayAssignmentHandlerTestclass {
    @isTest static void testPaymentGatewayAssignmentHandler() {
        //List<Energy_Usage_Update__c> productionUpdateJanList = new List<Energy_Usage_Update__c>(CommunitySolarTestRecordWarehouse.getCommunitySolarRecordsForBillCreation('1'));
        //insert productionUpdateJanList;
        //System.debug(productionUpdateJanList);  
        
        Utility_NMC_Tariff__c nmcRateNgridWcmaSizing =  (Utility_NMC_Tariff__c)TestFactory.createSObject(new Utility_NMC_Tariff__c(Value_of_Net_Metering_Credit__c = 0.15,
                                                                                                                    Name = 'Nation Grid WCMA Class 2 I',
                                                                                                                    Sizing_Rate__c = true,
                                                                                                                    Current_Billing_Rate__c = false,
                                                                                                                    Date__c = Date.today()));   

        Utility_NMC_Tariff__c nmcRateNgridWcmaBilling =  (Utility_NMC_Tariff__c)TestFactory.createSObject(new Utility_NMC_Tariff__c(Value_of_Net_Metering_Credit__c = 0.15,
                                                                                                                    Name = 'National Grid WCMA Class 2',
                                                                                                                    Sizing_Rate__c = false,
                                                                                                                    Current_Billing_Rate__c = true,
                                                                                                                    Date__c = Date.today()));



        insert new List<Utility_NMC_Tariff__c>{nmcRateNgridWcmaSizing, nmcRateNgridWcmaBilling};   


        Shared_Solar_System__c sharedSolarSystemOxfordBarretSt = (Shared_Solar_System__c)TestFactory.createSObject(new Shared_Solar_System__c(Name = 'Oxford Barret St',
                                                                                                                                Service_Territory__c = 'WCMA',
                                                                                                                                Open__c = true,
                                                                                                                                Schedule_Z_Filed__c = FALSE,
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
                                                                                                                                Maximum_Subscription_Assemblage__c = 25));
        Shared_Solar_System__c sharedSolarSystemMedfieldCountryWay = (Shared_Solar_System__c)TestFactory.createSObject(new Shared_Solar_System__c(Name = 'Medfield Country Way',
                                                                                                                                Service_Territory__c = 'NEMA',
                                                                                                                                Open__c = true,
                                                                                                                                Expected_Yield_kWh_kW__c = 1300,
                                                                                                                                Schedule_Z_Filed__c = FALSE,
                                                                                                                                Credit_Score_Requirement__c = 750,
                                                                                                                                Reserved_Capacity_kW_DC__c = '0',
                                                                                                                                Capacity_Committed_kW_DC__c = 0,
                                                                                                                                Total_System_Size_kWh_DC__c = 1445.86,
                                                                                                                                Total_System_Size_kW_AC__c  = 996,
                                                                                                                                System_Utility__c = 'Eversource',
                                                                                                                                Assignment_order__c = '1',
                                                                                                                                Utility_NMC_Tariff__c = nmcRateNgridWcmaSizing.Id,
                                                                                                                                Assemblage_Count__c = 1,
                                                                                                                                Maximum_Subscription_Assemblage__c = 25));

        Shared_Solar_System__c sharedSolarSystemFairhavenMillRd = (Shared_Solar_System__c)TestFactory.createSObject(new Shared_Solar_System__c(Name = 'Fairhaven Mill Rd',
                                                                                                                                Service_Territory__c = 'NEMA',
                                                                                                                                Open__c = true,
                                                                                                                                Expected_Yield_kWh_kW__c = 1300,
                                                                                                                                Schedule_Z_Filed__c = FALSE,
                                                                                                                                Credit_Score_Requirement__c = 750,
                                                                                                                                Reserved_Capacity_kW_DC__c = '0',
                                                                                                                                Capacity_Committed_kW_DC__c = 0,
                                                                                                                                Total_System_Size_kWh_DC__c = 1445.86,
                                                                                                                                Total_System_Size_kW_AC__c  = 996,
                                                                                                                                System_Utility__c = 'Eversource',
                                                                                                                                Assignment_order__c = '1',
                                                                                                                                Utility_NMC_Tariff__c = nmcRateNgridWcmaSizing.Id,
                                                                                                                                Assemblage_Count__c = 1,
                                                                                                                                Maximum_Subscription_Assemblage__c = 25));
        
        insert new List<Shared_Solar_System__c>{sharedSolarSystemOxfordBarretSt, sharedSolarSystemMedfieldCountryWay, sharedSolarSystemFairhavenMillRd};          
        
        Account parentAccountColeSwain = (Account)TestFactory.createSObject(new Account(Name = 'Cole Swain', Recurring_Billing__c = TRUE));

                                                                                                                                                         
        insert parentAccountColeSwain;                                                                                                                                                             


        Account propertyAccountColesCakes = (Account)TestFactory.createSObject(new Account(Name = 'Coles Cakes',
                                                                                Recurring_Billing__c = TRUE,
                                                                                Parent_Account__c = parentAccountColeSwain.Id));
                                                                                           
        insert propertyAccountColesCakes;   


        Utility_Account_Log__c ualColesCakes = (Utility_Account_Log__c)TestFactory.createSObject(new Utility_Account_Log__c(Name = '000X0A1',
                                                                                                                 Account__c = propertyAccountColesCakes.Id,
                                                                                                                 Annual_Cost_of_Electricity__c = 6825,
                                                                                                                 Name_on_Account__c = 'Coles Cakes'));

        insert ualColesCakes;   
        

        Opportunity oppColesCakes = (Opportunity)TestFactory.createSObject(new Opportunity(Name = 'Coles Cakes',
                                                                                AccountId = propertyAccountColesCakes.Id,
                                                                                Shared_Solar_System__c = sharedSolarSystemOxfordBarretSt.Id,
                                                                                StageName = 'Complete',
                                                                                Cs_Capacity_Allocated__c = 25,
                                                                                CloseDate = System.today()));

        insert oppColesCakes;   
      


        Utility_Account_Subscription__c uasColesCakes = (Utility_Account_Subscription__c)TestFactory.createSObject(new Utility_Account_Subscription__c(
                                                                                                    Name = '000X0A1',
                                                                                                    Utility_Account_Log__c = ualColesCakes.Id,
                                                                                                    Opportunity__c = oppColesCakes.Id,
                                                                                                    Calculated_Annual_Cost_of_Electricity__c = 4875,
                                                                                                    Subscribed_Annual_Cost_of_Electricity__c = 4875));
        
        insert uasColesCakes;   
                                                                                                                                                                                                                                                                                    
        Date myDateJan = Date.newInstance(2016, 1, 1);
        Date myDateFeb = Date.newInstance(2016, 2, 2);
        Date myDateMar = Date.newInstance(2016, 3, 3);
        Date myDateApr = Date.newInstance(2016, 4, 4);
        Date myDateMay = Date.newInstance(2016, 5, 5);
        Date myDateJun = Date.newInstance(2016, 6, 6);

        Energy_Usage_Update__c productionUpdateOxfordBarretStJan = (Energy_Usage_Update__c)TestFactory.createSObject(new Energy_Usage_Update__c(
                                                                                                    Name = 'sharedSolarSystemOxfordBarretSt - January 2016',
                                                                                                    Shared_Solar_System__c = sharedSolarSystemOxfordBarretSt.id,
                                                                                                    Production__c = 80000,
                                                                                                    Date__c = myDateJan )); 
        insert productionUpdateOxfordBarretStJan;


        Energy_Usage_Update__c productionUpdateOxfordBarretStFeb = (Energy_Usage_Update__c)TestFactory.createSObject(new Energy_Usage_Update__c(
                                                                                                    Name = 'sharedSolarSystemOxfordBarretSt - January 2016',
                                                                                                    Shared_Solar_System__c = sharedSolarSystemOxfordBarretSt.id,
                                                                                                    Production__c = 80000,
                                                                                                    Date__c = myDateApr ));                                                                                                     

 
        List<ChargentOrders__ChargentOrder__c> chargentOrderRecurringList = new List<ChargentOrders__ChargentOrder__c>();        
        List<ChargentOrders__Transaction__c> chargentTransRecurringList= new List<ChargentOrders__Transaction__c>();
        List<ChargentOrders__ChargentOrder__c> chargentOrderOneTimeList = new List<ChargentOrders__ChargentOrder__c>();        
        List<ChargentOrders__Transaction__c> chargentTransOneTimeList= new List<ChargentOrders__Transaction__c>();  
  

        ChargentBase__Gateway__c chGatewayOxfordBarretSt  = (ChargentBase__Gateway__c)TestFactory.createSObject(new ChargentBase__Gateway__c(
                                                                                                    Name = 'Chargent Gateway Oxford Barret St',
                                                                                                    Shared_Solar_System__c = sharedSolarSystemOxfordBarretSt.Id, 
                                                                                                    ChargentBase__Merchant_ID__c = '235986',
                                                                                                    ChargentBase__Active__c = TRUE));
        insert chGatewayOxfordBarretSt;  

        ChargentBase__Gateway__c chGatewayMedfieldCountryWay  = (ChargentBase__Gateway__c)TestFactory.createSObject(new ChargentBase__Gateway__c(
                                                                                                    Name = 'Chargent Gateway Medfield Country Way',
                                                                                                    Shared_Solar_System__c = sharedSolarSystemMedfieldCountryWay.Id, 
                                                                                                    ChargentBase__Merchant_ID__c = '123123',
                                                                                                    ChargentBase__Active__c = TRUE));
        insert chGatewayMedfieldCountryWay; 

        ChargentBase__Gateway__c chGatewayFairhavenMillRd  = (ChargentBase__Gateway__c)TestFactory.createSObject(new ChargentBase__Gateway__c(
                                                                                                    Name = 'Chargent Gateway Fairhaven Mill Rd',
                                                                                                    Shared_Solar_System__c = sharedSolarSystemFairhavenMillRd.Id, 
                                                                                                    ChargentBase__Merchant_ID__c = '43543',
                                                                                                    ChargentBase__Active__c = TRUE));
        insert chGatewayFairhavenMillRd;                   

        for (System_Bill__c systemBillJan : [SELECT Id, Name, Total_Due__c, Property_Account_ID__c, Recurring_Billing__c, Shared_Solar_System__r.Id FROM System_Bill__c]){
            if(systemBillJan.Recurring_Billing__c == TRUE){
                ChargentOrders__ChargentOrder__c chOrderRecurring  = (ChargentOrders__ChargentOrder__c)TestFactory.createSObject(new ChargentOrders__ChargentOrder__c(
                                                                                                    ChargentOrders__Account__c = systemBillJan.Property_Account_Id__c,
                                                                                                    ChargentOrders__Gateway__c = chGatewayMedfieldCountryWay.Id,
                                                                                                    ChargentOrders__Shipping_Name__c = sharedSolarSystemOxfordBarretSt.Id,
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
                                                                                                    ChargentOrders__Card_Last_4__c = '1111'));  
                insert chOrderRecurring;
                System.debug('The shipping name is ' + chOrderRecurring.ChargentOrders__Shipping_Name__c);

                ChargentOrders__Transaction__c chTransactionRecurring = new ChargentOrders__Transaction__c(
                                    ChargentOrders__Order__c = chOrderRecurring.id,
                                    ChargentOrders__Amount__c = 200,
                                    ChargentOrders__Response_Status__c ='Approved',
                                    ChargentOrders__Gateway_ID__c = chOrderRecurring.ChargentOrders__Gateway__r.Id,
                                    ChargentOrders__Gateway__c = chOrderRecurring.ChargentOrders__Gateway__r.Id,
                                    Distributed_Among_System_Bills__c = FALSE,
                                    ChargentOrders__Response_Message__c = 'OK',
                                    ChargentOrders__Type__c = 'Charge',
                                    ChargentOrders__Payment_Method__c = 'Credit Card',                                    
                                    Activity_Type__c = 'Payment');
                insert chTransactionRecurring;
                chTransactionRecurring.Distributed_Among_System_Bills__c = TRUE;
                update chTransactionRecurring;

                System.debug(chTransactionRecurring);

                chargentOrderRecurringList.add(chOrderRecurring);
                chargentTransRecurringList.add(chTransactionRecurring);                
            }
            else{
                ChargentOrders__ChargentOrder__c chOrderOneTime  = (ChargentOrders__ChargentOrder__c)TestFactory.createSObject(new ChargentOrders__ChargentOrder__c(
                                                                                                    ChargentOrders__Account__c = systemBillJan.Property_Account_Id__c,
                                                                                                    ChargentOrders__Gateway__c = chGatewayMedfieldCountryWay.Id,
                                                                                                    ChargentOrders__Shipping_Name__c = sharedSolarSystemOxfordBarretSt.Id,
                                                                                                    ChargentOrders__Billing_First_Name__c = 'Cole',
                                                                                                    ChargentOrders__Billing_Last_Name__c = 'Swain',
                                                                                                    ChargentOrders__Billing_Address__c = '108 Ridgeland Drive',
                                                                                                    ChargentOrders__Billing_Zip_Postal__c = '02467',                                                                                                    
                                                                                                    ChargentOrders__Subtotal__c = systemBillJan.Total_Due__c,
                                                                                                    ChargentOrders__Payment_Method__c = 'Credit Card',
                                                                                                    System_Bill__c = systemBillJan.Id,
                                                                                                    ChargentOrders__Card_Type__c = 'Visa',
                                                                                                    ChargentOrders__Card_Number__c = '411111111111',
                                                                                                    ChargentOrders__Card_Security_Code__c = '999',
                                                                                                    ChargentOrders__Card_Expiration_Month__c = '02',
                                                                                                    ChargentOrders__Card_Expiration_Year__c = '2018',
                                                                                                    ChargentOrders__Card_Last_4__c = '1111')); 
                insert chOrderOneTime;
                System.debug('The shipping name is ' + chOrderOneTime.ChargentOrders__Shipping_Name__c);       

                ChargentOrders__Transaction__c chTransactionOneTime = new ChargentOrders__Transaction__c(
                                    ChargentOrders__Order__c = chOrderOneTime.id,
                                    ChargentOrders__Amount__c = 200,
                                    ChargentOrders__Response_Status__c ='Approved',
                                    ChargentOrders__Gateway_ID__c = chOrderOneTime.ChargentOrders__Gateway__r.Id,
                                    ChargentOrders__Gateway__c = chOrderOneTime.ChargentOrders__Gateway__r.Id,
                                    Distributed_Among_System_Bills__c = FALSE,
                                    ChargentOrders__Response_Message__c = 'OK',
                                    ChargentOrders__Type__c = 'Charge',
                                    ChargentOrders__Payment_Method__c = 'Credit Card',                                    
                                    Activity_Type__c = 'Payment');
                insert chTransactionOneTime;
                chTransactionOneTime.Distributed_Among_System_Bills__c = TRUE;
                update chTransactionOneTime;

                System.debug(chTransactionOneTime);  

                chargentOrderOneTimeList.add(chOrderOneTime);
                chargentTransOneTimeList.add(chTransactionOneTime);               
            }          
        }

        Test.startTest();
        //Map<Id,ChargentBase__Gateway__c> gatewayMap = new Map<Id,ChargentBase__Gateway__c>();
        //for (ChargentBase__Gateway__c chGatewayAssert : [SELECT Id, Name, Shared_solar_system__r.Id FROM ChargentBase__Gateway__c]){
        //  gatewayMap.put(chGatewayAssert.Shared_solar_system__r.Id, chGatewayAssert);
        //}
        for (ChargentOrders__ChargentOrder__c chOrderAssert : [SELECT Id, Name, ChargentOrders__Gateway__r.Shared_solar_system__r.Id, ChargentOrders__Shipping_Name__c, System_Bill__r.Shared_Solar_System__r.Id 
                                                        FROM ChargentOrders__ChargentOrder__c]){
            System.debug('Gateway is ' + chOrderAssert.ChargentOrders__Gateway__r.Shared_solar_system__c);
            System.debug('Shipping Name is ' + chOrderAssert.ChargentOrders__Shipping_Name__c);
            System.assert(chOrderAssert.ChargentOrders__Gateway__r.Shared_solar_system__r.Id == chOrderAssert.System_Bill__r.Shared_Solar_System__r.Id);
        }

        //Map<String,System_Bill__c> systemBillMapFeb = new Map<String,System_Bill__c>();
        //Map<String,System_Bill__c> systemBillMapJan = new Map<String,System_Bill__c>();        
        //Map<Id,ChargentOrders__ChargentOrder__c> chOrderMap = new Map<Id,ChargentOrders__ChargentOrder__c>();
        //List<Id> systemBillListIdJan = new List<Id>();
        //String identifier;
        //String chargentIdentifier;
        ////List<Energy_Usage_Update__c> productionUpdateFebList = new List<Energy_Usage_Update__c>(CommunitySolarTestRecordWarehouse.getCommunitySolarRecordsForBillCreation('2'));
        ////System.debug(productionUpdateFebList);   

        //for (System_Bill__c systemBill : [SELECT Id, Name, Opportunity__r.Id, Shared_Solar_System__r.Name ,Bill_Number__c, Recurring_Billing__c FROM System_Bill__c]){ 
        //    System.debug('System Bill ID is ' + systemBill.Id);             
        //    identifier = systemBill.Shared_Solar_System__r.Name + systemBill.Opportunity__r.Id;
        //    systemBillMapJan.put(identifier, systemBill);
        //    systemBillListIdJan.add(systemBill.Id);
        //    System.debug('systemBillMapJan' + systemBillMapJan);                
        //}

        ////insert productionUpdateFebList;
        ////insert new List<Energy_Usage_Update__c>{productionUpdateOxfordBarretStFeb, productionUpdateMedfieldCountryWayFeb, productionUpdateFairhavenMillRdFeb};                          
        //insert productionUpdateOxfordBarretStFeb;
        //insert productionUpdateMedfieldCountryWayFeb;
        //insert productionUpdateFairhavenMillRdFeb;

        //for (System_Bill__c systemBill : [SELECT Id, Name, Opportunity__r.Id, Shared_Solar_System__r.Name ,Bill_Number__c, Recurring_Billing__c FROM System_Bill__c WHERE ID NOT IN : systemBillListIdJan]){
        //    System.debug('System Bill ID is ' + systemBill.Id); 
        //    identifier = systemBill.Shared_Solar_System__r.Name + systemBill.Opportunity__r.Id;
        //    systemBillMapFeb.put(identifier, systemBill);
        //    System.debug('systemBillMapFeb' + systemBillMapFeb);                
        //}

        //for (ChargentOrders__ChargentOrder__c chargentOrderAssertion : [SELECT Id, Name, System_Bill__r.Id, System_Bill__r.Opportunity__r.Id,
        //                                                                    System_Bill__r.Shared_Solar_System__r.Name, ChargentOrders__Payment_Status__c, 
        //                                                                    System_Bill__r.Property_Account__r.Id, System_Bill__r.Name
        //                                                                 FROM ChargentOrders__ChargentOrder__c]){
        //    chargentIdentifier = chargentOrderAssertion.System_Bill__r.Shared_Solar_System__r.Name + chargentOrderAssertion.System_Bill__r.Opportunity__r.Id;
        //    System.debug('The Chargent Identifier is ' + chargentIdentifier);
        //    if(chargentOrderAssertion.ChargentOrders__Payment_Status__c == 'Recurring'){
        //        System.debug('The System bill is is ' + chargentOrderAssertion.System_Bill__r.Id);
        //        System.debug('Recurring Chargent Order System Bill ID Check ' + chargentOrderAssertion.Name + ' ' + chargentOrderAssertion.System_Bill__r.Name + ' ' + systemBillMapFeb.get(chargentIdentifier).Name);
        //        System.assert(chargentOrderAssertion.System_Bill__r.Id == systemBillMapFeb.get(chargentIdentifier).Id);
        //    }
        //    else{                           //Coles Cakes Medfield Country Way February 2016 = Coles Cakes2 Fairhaven Mill Rd March 2016
        //        System.debug('One Time Chargent Order System Bill ID Check ' + chargentOrderAssertion.Name + ' ' + chargentOrderAssertion.System_Bill__r.Name + ' ' + systemBillMapJan.get(chargentIdentifier).Name);
        //        System.assert(chargentOrderAssertion.System_Bill__r.Id == systemBillMapJan.get(chargentIdentifier).Id);                
        //    }
        //}
        Test.stopTest();
    }
}