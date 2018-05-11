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

        if (loanRecord.Email__c == emailInput) {
            return true;
        } else {
            return false;
        }
    }

    @AuraEnabled
    public static List<String> getStates() {
        return BlueWaveParent.getUSStates(true);
    }

    @AuraEnabled
    public static List<ChargentOrders__ChargentOrder__c> setChargeAmountAndInsert(List<SObject> chargeAmounts, ChargentOrders__ChargentOrder__c orderInput) {        
        List<ChargentOrders__ChargentOrder__c> ordersToInsert = new List<ChargentOrders__ChargentOrder__c>();
        try {
            for (SObject chargeAmount : chargeAmounts) {
                ChargentOrders__ChargentOrder__c orderA = orderInput.clone(false,true,true,false);
                orderA.ChargentOrders__Shipping_Name__c = (String) chargeAmount.get('ChargentOrders__Shipping_Name__c');
                orderA.ChargentOrders__Subtotal__c = (Decimal) chargeAmount.get('ChargentOrders__Subtotal__c');              
                orderA.Account_Bill__c = (String) chargeAmount.get('Account_Bill__c');
                orderA.Comments__c = 'Created from Lightning';
                ordersToInsert.add(orderA);
            } 
            insert ordersToInsert;
        } catch (Exception excep) {
            Logger.logNow('CreateOrderandPaymentRequest', 'setChargeAmountandInsert', 'No Order Made - Hit Exception: ' + String.valueOf(excep));
        }
        return ordersToInsert;
    }

    // Chargent API will only allow the "Charge" functionality for one order passed at a time

    @AuraEnabled
    public static String chargeOrder(ChargentOrders__ChargentOrder__c chOrder) {
        String response = 'error, An error has occurred. We have been notified and will contact you with further instructions';
        Id transactionId;

        try {
            // Need to mock the Chargent API call for testing:
            if (Test.isRunningTest()) {
                transactionId = testAPICall(chOrder);
            } else {
                ChargentOrders.TChargentOperations.TChargentResult result = ChargentOrders.TChargentOperations.ChargeOrder_Click(chOrder.Id);               
                if (result.TransactID != null) {
                    transactionId = result.TransactID;
                } else {
                    // Error: No Transaction created. This is caused by some kind of internal error
                    Logger.logLater('CreateOrderandPaymentRequest', 'chargeOrder', 'No Transaction Made - Chargent Error: ' + String.valueOf(result.Message));
                }
            }

            ChargentOrders__Transaction__c newTransaction = [SELECT Id, Name, ChargentOrders__Response_Status__c, 
                                                        ChargentOrders__Response_Message__c
                                                        FROM ChargentOrders__Transaction__c 
                                                        WHERE Id = : transactionId];

            if (newTransaction.ChargentOrders__Response_Status__c == 'Approved') {
                response = newTransaction.Id + ',Approved';
            } else if (responseMap.containsKey(newTransaction.ChargentOrders__Response_Message__c)) {
                response = newTransaction.Id + ','+ responseMap.get(newTransaction.ChargentOrders__Response_Message__c);
            } else {
                response = newTransaction.Id + ','+ newTransaction.ChargentOrders__Response_Message__c;
            }
            
        } catch (Exception excep) {
            // Error: No Transaction created. This is caused by some kind of internal error
            Logger.logLater('CreateOrderandPaymentRequest', 'chargeOrder', 'No Transaction Made - Hit Exception: ' + String.valueOf(excep));
        }
        Logger.flushLogs(); 
        return response;
    }

    @AuraEnabled
    public static Boolean processingPostSubmit(List<Id> transactionIdList, Boolean autopay) {
        List<ChargentOrders__ChargentOrder__c> ordersToUpdateList = new List<ChargentOrders__ChargentOrder__c>();

        List<ChargentOrders__Transaction__c> transactionList = [ SELECT Id, Name, ChargentOrders__Response_Status__c, 
                                                                Distributed_Among_System_Bills__c,
                                                                ChargentOrders__Response_Message__c,
                                                                ChargentOrders__Order__r.Id,
                                                                ChargentOrders__Order__r.ChargentOrders__Payment_Frequency__c, 
                                                                ChargentOrders__Order__r.ChargentOrders__Payment_Status__c, 
                                                                ChargentOrders__Order__r.ChargentOrders__Payment_Stop__c, 
                                                                ChargentOrders__Order__r.ChargentOrders__Charge_Date__c, 
                                                                ChargentOrders__Order__r.ChargentOrders__Payment_Start_Date__c
                                                                FROM ChargentOrders__Transaction__c 
                                                                WHERE Id IN : transactionIdList];
        if (transactionList.size() == 0) {
            return false;
        }

        for ( ChargentOrders__Transaction__c transactionToCheck : transactionList) {
            transactionToCheck.Distributed_Among_System_Bills__c = true;
            if (autopay) {
                ChargentOrders__ChargentOrder__c recurringOrder = new ChargentOrders__ChargentOrder__c();
                recurringOrder.Id = transactionToCheck.ChargentOrders__Order__r.Id;
                recurringOrder.ChargentOrders__Payment_Frequency__c = 'Monthly';
                recurringOrder.ChargentOrders__Payment_Status__c = 'Recurring';
                recurringOrder.ChargentOrders__Payment_Stop__c = 'Unending';
                recurringOrder.ChargentOrders__Charge_Date__c = '01';
                recurringOrder.ChargentOrders__Payment_Start_Date__c = Date.today().addDays(1);
                ordersToUpdateList.add(recurringOrder);
            }
        }

        try {
            Database.SaveResult[] orderSRs = Database.update(ordersToUpdateList, false);
            Database.SaveResult[] transactionSRs = Database.update(transactionList, false);
            processDatabaseSaveResult(orderSRs, 'Could not set to Recurring: ');
            processDatabaseSaveResult(transactionSRs,  'Could not Distribute Among Bills: ');
        } catch (Exception excep) {
            Logger.logNow('CreateOrderandPaymentRequest', 'processingPostSubmit', 'Other Error: ' + String.valueOf(excep));
        }
        return true;
    }

    public static Map<String,String> responseMap = new Map<String,String>{
        'Invalid Route' => 'Invalid Routing Number. Please check that Bank Account Number and Routing Number are not reversed.'
    };

    public static void processDatabaseSaveResult(List<Database.SaveResult> saveResult, String specificMessage) {
        for (Database.SaveResult orderSR : saveResult) {
            if (!orderSR.isSuccess()) {
                for (Database.Error orderError : orderSR.getErrors()) {
                    Logger.logNow('CreateOrderandPaymentRequest', 'processingPostSubmit', specificMessage + orderSR.getId() + ' : ' + orderError.getStatusCode() + ' - ' + orderError.getMessage());
                }
            }
        }
    }

    public static Id testAPICall(ChargentOrders__ChargentOrder__c orderTest) {
        ChargentOrders__Transaction__c transA = 
            new ChargentOrders__Transaction__c(ChargentOrders__Order__c = orderTest.Id,
                                                ChargentOrders__Amount__c = orderTest.ChargentOrders__Subtotal__c,
                                                ChargentOrders__Response_Status__c ='Approved',
                                                ChargentOrders__Response_Message__c = 'OK',
                                                ChargentOrders__Type__c = 'Charge',                            
                                                Activity_Type__c = 'Payment');
        insert transA;
        return transA.Id;
    }
}