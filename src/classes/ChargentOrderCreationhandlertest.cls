@isTest
private class ChargentOrderCreationhandlertest {

    Static testMethod void ChargentOrderCreationhandlertest (){

        Utility_NMC_Tariff__c eversizeNMC = new Utility_NMC_Tariff__c ( Name = 'Eversource SEMA Class 2', 
                                                                        Utility__c = 'Eversource', 
                                                                        Class__c = 'Class 2',
                                                                        Value_of_Net_Metering_Credit__c = 0.1848,
                                                                        Sizing_Rate__c = TRUE);
        insert eversizeNMC;

        ChargentBase__Gateway__c chGateway  = new ChargentBase__Gateway__c(Name = 'BW Community Solar Payments Account Gateway',
            ChargentBase__Merchant_ID__c = '235986',
            ChargentBase__Available_Payment_Methods__c = 'eCheck',
            ChargentBase__Default_Payment_Method_for_PC__c = 'eCheck',
            ChargentBase__Default_Payment_Method_for_PR__c = 'eCheck',
            ChargentBase__Active__c = TRUE);
        insert chGateway;

        Entity__c entityOne = new Entity__c (
            Name = 'BWC Holdings, LLC',
            Gateway__c = chGateway.Id
        );

        insert entityOne;
        
        Shared_Solar_System__c sss1 = new Shared_Solar_System__c(   Name = 'Oxford Barrett St. P1',
                                                                    Service_Territories__c = 'SEMA',
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
        insert accountA;  


        
        Opportunity oppone = new Opportunity(
            Name = 'Jordan Jordan',
            AccountId = accountA.Id,
            Shared_Solar_System__c = sss1.Id,
            StageName = 'Complete',
            Product_Line__c = 'Community Solar',
            CloseDate = System.today());
        insert oppone;
        
        oppone.ACH_Account_Number__c = '123456790';
        oppone.ACH_Account_Type__c = 'Checking';
        oppone.ACH_Bank_Name__c = 'Bank of America';
        oppone.ACH_Bank_Routing_Number__c = '129383578';
        oppone.ACH_Name_on_Account__c = 'Jordan Pentaleri';

        update oppone;

        Opportunity opptwo = new Opportunity(
            Name = 'Jordan Testcase',
            AccountId = accountA.Id,
            Shared_Solar_System__c = sss1.Id,
            StageName = 'Complete',
            Product_Line__c = 'Community Solar',
            CloseDate = System.today());
        insert opptwo;
        
        opptwo.CC_Account_Number__c = '1112223334545';
        opptwo.CC_CardHolder_Name__c = 'Jordan Testcase';
        opptwo.CC_Card_Type__c = 'MasterCard';
        opptwo.CC_CVV__c = '123';
        opptwo.CC_Expiration_Month__c = '02';
        opptwo.CC_Expiration_Year__c = '2020';

        update opptwo;

        Test.StartTest();
        List<ChargentOrders__ChargentOrder__c > orderlist = [  SELECT Id, ChargentOrders__Bank_Name__c,
                                                                ChargentOrders__Bank_Routing_Number__c, 
                                                                ChargentOrders__Bank_Account_Type__c,
                                                                ChargentOrders__Bank_Account_Number__c, 
                                                                ChargentOrders__Bank_Account_Name__c,
                                                                ChargentOrders__Gateway__c,
                                                                ChargentOrders__Card_Number__c,
                                                                ChargentOrders__Card_Expiration_Month__c,
                                                                ChargentOrders__Card_Expiration_Year__c
                                                                FROM ChargentOrders__ChargentOrder__c];
            System.assertEquals(2, orderList.size());
            System.assertEquals('Bank of America', orderlist[0].ChargentOrders__Bank_Name__c);
            System.assertEquals('129383578', orderlist[0].ChargentOrders__Bank_Routing_Number__c);
            System.assertEquals('Checking', orderlist[0].ChargentOrders__Bank_Account_Type__c);
            System.assertEquals('123456790', orderlist[0].ChargentOrders__Bank_Account_Number__c);
            System.assertEquals('Jordan Pentaleri', orderlist[0].ChargentOrders__Bank_Account_Name__c);
            System.assertEquals(chGateway.Id, orderlist[0].ChargentOrders__Gateway__c);

            System.assertEquals('1112223334545', orderlist[1].ChargentOrders__Card_Number__c);
            System.assertEquals('02', orderlist[1].ChargentOrders__Card_Expiration_Month__c);
            System.assertEquals('2020', orderlist[1].ChargentOrders__Card_Expiration_Year__c);
            System.assertEquals(chGateway.Id, orderlist[1].ChargentOrders__Gateway__c);
        Test.StopTest();
        
}
}