@isTest
public with sharing class CreateOrderandPaymentRequestTest {
    @isTest static void getLink() {

        Account accountA = new Account(name = 'Account Parent');
        insert accountA;  

        Opportunity opportunityone = new Opportunity(Name = 'Jordan Jordan',
                            AccountId = accountA.Id,
                            Email__c = 'test@test.com',
                            StageName = 'Complete',
                            CloseDate = System.today());

        insert opportunityone;

        ChargentOrders__ChargentOrder__c orderEntry = new ChargentOrders__ChargentOrder__c(
                                                ChargentOrders__Bank_Account_Number__c = '123456789102',
                                                ChargentOrders__Bank_Routing_Number__c = '123456789',
                                                ChargentOrders__Bank_Account_Name__c = 'Jordan Test',
                                                ChargentOrders__Bank_Name__c = 'Bank of Bank',             
                                                ChargentOrders__Bank_Account_Type__c = 'Checking');                       

        ChargentBase__Gateway__c chGateway  = 
        new ChargentBase__Gateway__c(   Name = 'SREC',
                                        ChargentBase__Merchant_ID__c = '235986',
                                        ChargentBase__Active__c = True);
        insert chGateway;

        Boolean failedRequest = CreateOrderandPaymentRequest.checkEmailOnOpp(opportunityone.Id, 'bademail@test.com');
        Boolean payRequest = CreateOrderandPaymentRequest.insertRequest(opportunityone.Id, 'test@test.com', orderEntry);

        List<ChargentOrders__ChargentOrder__c> chOrderList = [  SELECT Id, Name, ChargentOrders__Gateway__c
                                                                FROM ChargentOrders__ChargentOrder__c];
        System.assertEquals(false, failedRequest);
        System.assertNotEquals(false, payRequest);
        System.assertEquals(1, chOrderList.size());
    }
}