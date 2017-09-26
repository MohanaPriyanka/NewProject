@isTest
private class ChargentOrderCreationhandlertest {

Static testMethod void ChargentOrderCreationhandlertest (){

        Utility_NMC_Tariff__c eversizeNMC = new Utility_NMC_Tariff__c ( Name = 'Eversource SEMA Class 2', 
                                                                        Utility__c = 'Eversource', 
                                                                        Class__c = 'Class 2',
                                                                        Value_of_Net_Metering_Credit__c = 0.1848,
                                                                        Sizing_Rate__c = TRUE);
        Insert eversizeNMC;

        Entity__c entityOne = new Entity__c ( Name = 'BlueWave ProjectCo');
        Insert entityOne;
        
        Shared_Solar_System__c sss1 = new Shared_Solar_System__c(   Name = 'Oxford Barrett St. P1',
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
                                                                    Maximum_Subscription_Assemblage__c = 25);
        insert sss1;

        Account accountA = new Account(name = 'Account A',
            RecordTypeId = '012j00000010Ha3');       
        Insert accountA;  

        ChargentBase__Gateway__c chGateway  = new ChargentBase__Gateway__c(Name = 'BW Community Solar Payments Account Gateway',
                                                                           ChargentBase__Merchant_ID__c = '235986',
                                                                           ChargentBase__Active__c = TRUE,
                                                                           Entity__c = entityOne.Id,
                                                                           Shared_Solar_System__c = sss1.Id);
        insert chGateway;
        
        Opportunity oppone = new Opportunity(Name = 'Jordan Jordan',
                                             AccountId = accountA.Id,
                                             Shared_Solar_System__c = sss1.Id,
                                             StageName = 'Complete',
                                             CS_Capacity_Allocated__c = 25,
                                             CloseDate = System.today());
        insert oppone;
        
        oppone.ACH_Account_Number__c = '123456790';
        oppone.ACH_Account_Type__c = 'Checking';
        oppone.ACH_Bank_Name__c = 'Bank of America';
        oppone.ACH_Bank_Routing_Number__c = '129383578';
        oppone.ACH_Name_on_Account__c = 'Jordan Pentaleri';

        update oppone;

        List <ChargentOrders__ChargentOrder__c > orderlist = [  SELECT Id, ChargentOrders__Bank_Name__c,
                                                                ChargentOrders__Bank_Routing_Number__c, 
                                                                ChargentOrders__Bank_Account_Type__c,
                                                                ChargentOrders__Bank_Account_Number__c, 
                                                                ChargentOrders__Bank_Account_Name__c,
                                                                ChargentOrders__Gateway__c 
                                                                FROM ChargentOrders__ChargentOrder__c];

        Test.StartTest();
        
        for (ChargentOrders__ChargentOrder__c choOrder : orderList) {
            System.assertEquals(choOrder.ChargentOrders__Bank_Name__c,'Bank of America');
            System.assertEquals(choOrder.ChargentOrders__Bank_Routing_Number__c,'129383578');
            System.assertEquals(choOrder.ChargentOrders__Bank_Account_Type__c,'Checking');
            System.assertEquals(choOrder.ChargentOrders__Bank_Account_Number__c,'123456790');
            System.assertEquals(choOrder.ChargentOrders__Bank_Account_Name__c,'Jordan Pentaleri');
            System.assertEquals(choOrder.ChargentOrders__Gateway__c,chGateway.Id);
        }

        Test.StopTest();
        
}
}