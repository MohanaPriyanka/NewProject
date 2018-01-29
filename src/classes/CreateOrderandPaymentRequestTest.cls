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

        ChargentBase__Gateway__c chGateway  = 
        new ChargentBase__Gateway__c(   Name = 'SREC',
                                        ChargentBase__Merchant_ID__c = '235986',
                                        ChargentBase__Active__c = True);
        insert chGateway;

        String failedRequest = CreateOrderandPaymentRequest.insertRequest(opportunityone.Id, 'bademail@test.com');
        String payRequest = CreateOrderandPaymentRequest.insertRequest(opportunityone.Id, 'test@test.com');
        ChargentOrders__Payment_Request__c payRequestUpdated = CreateOrderandPaymentRequest.checkForLink(payRequest);

        List<ChargentOrders__ChargentOrder__c> chOrderList = [  SELECT Id, Name, ChargentOrders__Gateway__c
                                                                FROM ChargentOrders__ChargentOrder__c];
        
        System.assertEquals('emailFailure', failedRequest);
        System.assertNotEquals('emailFailure', payRequest);
        System.assertEquals(1, chOrderList.size());
        System.assertEquals(payRequestUpdated.ChargentOrders__ChargentOrder__c, chOrderList[0].Id);
    }
}