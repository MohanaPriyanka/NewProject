/*************************************************************************************
 + * Created By:  Jordan Pentaleri 
 + * - Used for Chargent API Actions in SREC Direct Deposit form, CS Portal Payments,
 + *   and recurring SREC payments
 + *
 + * Tested By: TestBillCreationandPayment, CreateOrderandPaymentRequestTest, RecurringSRECHandlerTest
 + *************************************************************************************/

public without sharing class CreateOrderandPaymentRequest {
    @AuraEnabled
    public static Boolean submitDDInfoWithoutCharge(String oppId, String emailInput, ChargentOrders__ChargentOrder__c chOrder) {
        Loan__c loanRecord = getLoanAndCheckEmail(oppId, emailInput);

        if (loanRecord == null) {
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
                                                                Loan__c = loanRecord.Id,
                                                                Opportunity__c = oppId); 
            insert chargentOrder;
            loanRecord.SREC_Direct_Deposit_Order__c = chargentOrder.Id;
            try {
                update loanRecord;
            } catch (Exception excep) {
                Logger.logNow('CreateOrderandPaymentRequest', 'submitDDInfoWithoutCharge', 'Did not Update Loan: ' + chargentOrder.Id + String.valueOf(excep));
            }
            return true;
        }
    }

    @AuraEnabled
    public static Loan__c getLoanAndCheckEmail(String oppId, String emailInput) {
        try {
            Loan__c loanRecord = [ SELECT Id, Name, SREC_Direct_Deposit_Order__c, 
                                    Opportunity__r.Id, Opportunity__r.Email__c
                                    FROM Loan__c
                                    WHERE Opportunity__r.Id = : oppID
                                    LIMIT 1];
            if (loanRecord.Opportunity__r.Email__c == emailInput) {
                return loanRecord;
            } else {
                throw new AuraHandledException('Invalid Email');
            }
        } catch (QueryException excep) {
            Logger.logNow('CreateOrderandPaymentRequest', 'getLoanAndCheckEmail', 'No Loan Found - Hit Exception: ' + String.valueOf(excep));
            throw new AuraHandledException('No Loan Found');
        }
    }

    @AuraEnabled
    public static List<String> getStates() {
        return BlueWaveParent.getUSStates(true);
    }

    @AuraEnabled
    public static List<ChargentOrders__ChargentOrder__c> setChargeAmountAndInsert(List<SObject> chargeAmounts, ChargentOrders__ChargentOrder__c orderInput, Boolean autopay) {
        List<ChargentOrders__ChargentOrder__c> ordersToInsert = new List<ChargentOrders__ChargentOrder__c>();
        try {
            Set<Id> accountBillIdSet = new Set<Id>();
            Set<Id> entityIdSet = new Set<Id>();
            for (SObject chargeAmount : chargeAmounts) {
                ChargentOrders__ChargentOrder__c orderA = orderInput.clone(false,true,true,false);
                orderA.Entity__c = (String) chargeAmount.get('Entity__c');
                orderA.ChargentOrders__Subtotal__c = (Decimal) chargeAmount.get('ChargentOrders__Subtotal__c');              
                orderA.Account_Bill__c = (String) chargeAmount.get('Account_Bill__c');
                orderA.Comments__c = 'Created from Lightning';

                if(autopay){
                    orderA.ChargentOrders__Payment_Frequency__c = 'Monthly';
                    orderA.ChargentOrders__Payment_Status__c = 'Recurring';
                    orderA.ChargentOrders__Payment_Stop__c = 'Unending';
                    orderA.ChargentOrders__Charge_Date__c = '01';
                    orderA.ChargentOrders__Payment_Start_Date__c = Date.today().addDays(1);
                }


                if(orderA.ChargentOrders__Subtotal__c < 0 ){
                    orderA.ChargentOrders__Subtotal__c = 0;
                }
                accountBillIdSet.add(orderA.Account_Bill__c);
                entityIdSet.add(orderA.Entity__c);
                ordersToInsert.add(orderA);
            }
            insert ordersToInsert;
            Set<Id> accountSet = new Set<Id>();
            for (Account_Bill__c accountBill : [SELECT Id, Name, Parent_Account__r.Id
                                                FROM Account_Bill__c
                                                WHERE Id IN : accountBillIdSet]){
                accountSet.add(accountBill.Parent_Account__r.Id);
            }

            //Find all of the old chargent orders that are marked Recurring and set it to Stopped
            List<ChargentOrders__ChargentOrder__c> chargentOrderList = [
                SELECT Id, ChargentOrders__Payment_Status__c, Reason_for_Recurring_Stop__c
                FROM ChargentOrders__ChargentOrder__c
                WHERE ( Id NOT IN :ordersToInsert)
                AND ChargentOrders__Payment_Status__c = 'Recurring'
                AND Account_Bill__r.Parent_Account__r.Id IN : accountSet
                AND Entity__r.Id IN : entityIdSet
            ];
            if(chargentOrderList.size() > 0){
                for(ChargentOrders__ChargentOrder__c co : chargentOrderList){
                    co.ChargentOrders__Payment_Status__c = 'Stopped';
                    co.Reason_for_Recurring_Stop__c = 'Replaced with New Payment Info From Portal';
                }
                update chargentOrderList;
            }
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
            // Chargent says: 
            // When testing the callouts that Chargent makes, you can't use the HttpCalloutMock class in Salesforce 
            // because it has to be done from within the Chargent managed package/namespace. 
            // https://www.appfrontier.com/developers.html
            if (Test.isRunningTest()) {
                transactionId = testAPICall(chOrder, false);
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
    public static Boolean processingPostSubmit(List<Id> transactionIdList) {
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
        }

        try {
            Database.SaveResult[] transactionSRs = Database.update(transactionList, false);
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

    public static Id testAPICall(ChargentOrders__ChargentOrder__c orderTest, Boolean isCredit) {
        ChargentOrders__Transaction__c transA = 
            new ChargentOrders__Transaction__c(ChargentOrders__Order__c = orderTest.Id,
                                                ChargentOrders__Amount__c = orderTest.ChargentOrders__Subtotal__c,
                                                ChargentOrders__Response_Status__c ='Approved',
                                                ChargentOrders__Response_Message__c = 'OK',
                                                ChargentOrders__Type__c = 'Charge',                            
                                                Activity_Type__c = 'Payment');
        if (isCredit){
            transA.ChargentOrders__Amount__c = -1 * orderTest.ChargentOrders__Credit_Amount__c;
        }
        insert transA;
        return transA.Id;
    } 

    @AuraEnabled
    public static Boolean attemptSRECsend(ChargentOrders__ChargentOrder__c orderToCredit) { 
        Boolean response = false;
        try {
            if (Test.isRunningTest()) {
                ChargentOrder chargentOrder = new ChargentOrder(orderToCredit);
                testAPICall(orderToCredit, true);
                response = true;
            } else {
                ChargentOrder chargentOrder = new ChargentOrder(orderToCredit);
                ChargentOrders.TChargentOperations.TChargentResult result = ChargentOrders.TChargentOperations.ChargeOrder_ClickJSON(chargentOrder.toJSON());  

                if (result.TransactID != null) {
                    ChargentOrders__Transaction__c insertedTransaction = [ SELECT Id, Name, ChargentOrders__Response_Status__c, 
                                                                            ChargentOrders__Response_Message__c,
                                                                            ChargentOrders__Order__r.Related_SREC__c
                                                                            FROM ChargentOrders__Transaction__c 
                                                                            WHERE Id = : result.TransactID];
                    if (insertedTransaction.ChargentOrders__Response_Status__c == 'Approved'){
                        response = true;
                    }
                } else {
                    // Error: No Transaction created. This is caused by some kind of internal error
                    Logger.logLater('CreateOrderandPaymentRequest', 'attemptSRECsend', 'No Transaction Made - Chargent Error: ' + String.valueOf(result.Message));
                }
            }            
        } catch (Exception excep) {
            // Error: No Transaction created. This is caused by some kind of internal error
            Logger.logLater('CreateOrderandPaymentRequest', 'attemptSRECsend', 'No Transaction Made - Hit Exception: ' + String.valueOf(excep));
        }
        Logger.flushLogs(); 
        return response;
    }

    public class ChargentOrder{      
        String ObjectId;
        String ChargeAmount;
        String BankRoutingNumber;
        String BankAccountNumber;
        String BankAccountType;
        String BankName ;
        String BankAccountName;
        String CustomTransactionType;

        public ChargentOrder(ChargentOrders__ChargentOrder__c orderToCredit){
            Decimal creditAmount = orderToCredit.ChargentOrders__Credit_Amount__c.setScale(2, roundingMode.HALF_UP);

            ObjectId = orderToCredit.Id;
            ChargeAmount = String.valueOf(creditAmount);
            BankRoutingNumber = orderToCredit.ChargentOrders__Bank_Routing_Number__c;
            BankAccountNumber = orderToCredit.ChargentOrders__Bank_Account_Number__c;
            BankAccountType = orderToCredit.ChargentOrders__Bank_Account_Type__c;
            BankName = orderToCredit.ChargentOrders__Bank_Name__c;
            BankAccountName = orderToCredit.ChargentOrders__Bank_Account_Name__c;
            CustomTransactionType = 'ACH_Credit';
        }

        public String toJSON(){
            String json = System.JSON.serializePretty(this);
            return json;
        }
    }
}