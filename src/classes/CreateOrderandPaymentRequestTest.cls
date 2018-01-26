@isTest
public with sharing class CreateOrderandPaymentRequestTest {
    @isTest static void getLink() {

        Account accountA = new Account(name = 'Account Parent');
        Insert accountA;  

        Opportunity opportunityone = new Opportunity(Name = 'Jordan Jordan',
                            AccountId = accountA.Id,
                            Email__c = 'test@test.com',
                            StageName = 'Complete',
                            CloseDate = System.today());

        Insert opportunityone;

        ChargentBase__Gateway__c chGateway  = 
        new ChargentBase__Gateway__c(   Name = 'SREC',
                                        ChargentBase__Merchant_ID__c = '235986',
                                        ChargentBase__Active__c = True);
        Insert chGateway;

        Boolean emailCheck = CreateOrderandPaymentRequest.checkEmail(opportunityone.Id,'test@test.com');
        ChargentOrders__Payment_Request__c payRequest = CreateOrderandPaymentRequest.insertRequest(opportunityone.Id);
        ChargentOrders__Payment_Request__c payRequestUpdated = CreateOrderandPaymentRequest.checkForLink(payRequest.Id);

        List<ChargentOrders__ChargentOrder__c> chOrderList = [  SELECT Id, Name, ChargentOrders__Gateway__c
                                                                FROM ChargentOrders__ChargentOrder__c];

        System.AssertEquals(true, emailCheck);
        System.AssertEquals(1, chOrderList.size());
        System.AssertEquals(payRequestUpdated.ChargentOrders__ChargentOrder__c, chOrderList[0].Id);
    }
}