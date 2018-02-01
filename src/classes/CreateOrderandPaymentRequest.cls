public without sharing class CreateOrderandPaymentRequest {
    @AuraEnabled
    public static Boolean insertRequest(String oppId, String emailInput, ChargentOrders__ChargentOrder__c chOrder) {
        Boolean emailCheck = checkEmailOnOpp(oppId, emailInput);

        if (!emailCheck) {
            return false;
        } else {
            ChargentBase__Gateway__c srecGateway = [SELECT Id, Name 
                                                    FROM ChargentBase__Gateway__c 
                                                    WHERE Name = 'SREC' 
                                                    LIMIT 1];

            ChargentOrders__ChargentOrder__c chargentOrder = new ChargentOrders__ChargentOrder__c(
                                                                Comments__c = 'Created For Payment Request',
                                                                ChargentOrders__Subtotal__c = 0.01,
                                                                ChargentOrders__Billing_Email__c = emailInput,
                                                                ChargentOrders__Charge_Amount__c = 0.01,
                                                                ChargentOrders__Gateway__c = srecGateway.Id,
                                                                ChargentOrders__Bank_Account_Number__c = chOrder.ChargentOrders__Bank_Account_Number__c,
                                                                ChargentOrders__Bank_Routing_Number__c = chOrder.ChargentOrders__Bank_Routing_Number__c,
                                                                ChargentOrders__Bank_Account_Name__c = chOrder.ChargentOrders__Bank_Account_Name__c,
                                                                ChargentOrders__Bank_Name__c = chOrder.ChargentOrders__Bank_Name__c,             
                                                                ChargentOrders__Bank_Account_Type__c = chOrder.ChargentOrders__Bank_Account_Type__c,
                                                                Opportunity__c = oppId); 
            insert chargentOrder;
            return true;
        }
    }

    @AuraEnabled
    public static Boolean checkEmailOnOpp(String oppId, String emailInput) {
        Opportunity loanRecord = [  SELECT Id, Email__c
                                    FROM Opportunity
                                    WHERE Id = : oppID];

        if (loanRecord.Email__c == emailInput){
            return true;
        } else {
            return false;
        }
    }
}