public without sharing class CreateOrderandPaymentRequest {
  @AuraEnabled
    public static ChargentOrders__Payment_Request__c insertRequest(String oppId) {
        ChargentBase__Gateway__c srecGateway = [SELECT Id, Name 
                                                FROM ChargentBase__Gateway__c 
                                                WHERE Name = 'SREC' 
                                                LIMIT 1];

        ChargentOrders__ChargentOrder__c chOrder = new ChargentOrders__ChargentOrder__c(
                                                            Comments__c = 'Created For Payment Request',
                                                            ChargentOrders__Subtotal__c = 0.01,
                                                            ChargentOrders__Charge_Amount__c = 0.01,
                                                            ChargentOrders__Gateway__c = srecGateway.Id,
                                                            Opportunity__c = oppId); 
        insert chOrder;
        ChargentOrders__Payment_Request__c payRequest = new ChargentOrders__Payment_Request__c(
                                                            ChargentOrders__ChargentOrder__c = chOrder.Id); 
        insert payRequest;
        return payRequest;
    }
    
    @AuraEnabled
    public static ChargentOrders__Payment_Request__c checkForLink(String payRequestId) {
        ChargentOrders__Payment_Request__c payRequest = [SELECT Id, ChargentOrders__Pay_Link__c, ChargentOrders__ChargentOrder__c
                                                         FROM ChargentOrders__Payment_Request__c 
                                                         WHERE Id = : payRequestId];
        return payRequest;
    }

    @AuraEnabled
    public static Boolean checkEmail(String oppId, String emailInput) {
        Boolean idCheck = false;
        Opportunity loanRecord = [  SELECT Id, Email__c
                                    FROM Opportunity
                                    WHERE Id = : oppID];
        if (loanRecord.Email__c == emailInput){
            idCheck = true;
        }
        return idCheck;
    }
}