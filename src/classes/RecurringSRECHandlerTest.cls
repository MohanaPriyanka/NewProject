@isTest
private class RecurringSRECHandlerTest{
    @testSetup public static void setupData() {
        ChargentBase__Gateway__c chGateway  = 
        new ChargentBase__Gateway__c(   Name = 'SREC',
                                        ChargentBase__Merchant_ID__c = '235986',
                                        ChargentBase__Active__c = True);
        insert chGateway;

        /* Only one Chargent Order to avoid error: No more than one executeBatch can be called from within a test method. 
        Please make sure the iterable returned from your start method matches the batch size, resulting in one executeBatch invocation */

        ChargentOrders__ChargentOrder__c orderEntry = new ChargentOrders__ChargentOrder__c(
                                                        ChargentOrders__Bank_Account_Number__c = '00000000000',
                                                        ChargentOrders__Bank_Routing_Number__c = '123456789',
                                                        ChargentOrders__Bank_Account_Name__c = 'Jordan Test',
                                                        ChargentOrders__Bank_Name__c = 'Bank of Bank',             
                                                        ChargentOrders__Bank_Account_Type__c = 'Checking',
                                                        ChargentOrders__Payment_Method__c = 'Check',
                                                        ChargentOrders__Gateway__c = chGateway.Id,
                                                        ChargentOrders__Credit_Amount__c = 0.03,
                                                        SREC_Status__c = 'Ready');
        insert orderEntry;
    }

    static testMethod void runBatch() {
        Test.startTest();
        BatchCreditSRECHandler m = new BatchCreditSRECHandler();
        Database.executeBatch(m, 1);
        Test.stopTest();

        ChargentOrders__ChargentOrder__c updatedCho = [ SELECT Id, Name, 
                                                    SREC_Status__c, 
                                                    ChargentOrders__Credit_Amount__c, 
                                                    ChargentOrders__Bank_Routing_Number__c, 
                                                    ChargentOrders__Bank_Account_Number__c, 
                                                    ChargentOrders__Bank_Account_Type__c, 
                                                    ChargentOrders__Bank_Name__c,  
                                                    ChargentOrders__Subtotal__c, 
                                                    ChargentOrders__Bank_Account_Name__c 
                                                    FROM ChargentOrders__ChargentOrder__c];

        System.assertEquals('Success', updatedCho.SREC_Status__c);
    }
}
