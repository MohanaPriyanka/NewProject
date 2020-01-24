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
            /*
                JP July 2019:
                Important that the email address is null when SREC credits are submitted to the gateway.
                If not, a confusing email receipt will be sent from the gateway automatically that makes it appear that
                we charged customers instead of crediting them.
                Linked2Pay has a setting to toggle that email, but we've seen that it still gets sent even when
                that setting is off (bug on their side). Additionally, if all transactions are set to the same
                email (compliance@bw for ex) transactions will mistakenly be assigned to the same Linked2Pay contact
                and the bank account name will get overwritten with the contact name of the Linked2Pay contact with
                compliance@bw as its email.
            */

            ChargentOrders__ChargentOrder__c chargentOrder = new ChargentOrders__ChargentOrder__c(
                                                                Comments__c = 'Created For Payment Request',
                                                                ChargentOrders__Subtotal__c = 0.01,
                                                                ChargentOrders__Billing_Email__c = null,
                                                                ChargentOrders__Charge_Amount__c = 0.01,
                                                                ChargentOrders__Bank_Account_Number__c = chOrder.ChargentOrders__Bank_Account_Number__c,
                                                                ChargentOrders__Bank_Routing_Number__c = chOrder.ChargentOrders__Bank_Routing_Number__c,
                                                                ChargentOrders__Bank_Account_Name__c = chOrder.ChargentOrders__Bank_Account_Name__c,
                                                                ChargentOrders__Bank_Name__c = chOrder.ChargentOrders__Bank_Name__c,             
                                                                ChargentOrders__Bank_Account_Type__c = chOrder.ChargentOrders__Bank_Account_Type__c,
                                                                Loan__c = loanRecord.Id,
                                                                Opportunity__c = oppId);

            try {
                Entity__c srecEntity = [    SELECT Id, Name, Gateway__r.Id
                                            FROM Entity__c
                                            WHERE Name = 'BlueWave Finance Group, LLC'
                                            LIMIT 1];
                chargentOrder.ChargentOrders__Gateway__c = srecEntity.Gateway__r.Id;
                chargentOrder.Entity__c = srecEntity.Id;
                insert chargentOrder;
            } catch (Exception excep) {
                Logger.logNow('CreateOrderandPaymentRequest', 'submitDDInfoWithoutCharge', 'Could not insert Ch Order: ' + String.valueOf(excep));
                return false; // payment info was not stored, show error to user
            }

            try {
                loanRecord.SREC_Direct_Deposit_Order__c = chargentOrder.Id;
                update loanRecord;
            } catch (Exception e) {
                Logger.logNow('CreateOrderandPaymentRequest', 'submitDDInfoWithoutCharge', 'Did not Update Loan: ' + chargentOrder.Id + String.valueOf(e));
            }

            try {
                String htmlValue = MessagingService.getHtml('SREC_Payment_Info_Confirmation').HtmlValue;
                htmlValue = htmlValue.replace(
                    '{!ChargentOrders__ChargentOrder__c.ChargentOrders__Bank_Account_Name__c}',
                    chargentOrder.ChargentOrders__Bank_Account_Name__c
                );
                htmlValue = htmlValue.replace(
                    '{!ChargentOrders__ChargentOrder__c.ChargentOrders__Bank_Name__c}',
                    chargentOrder.ChargentOrders__Bank_Name__c
                );
                htmlValue = htmlValue.replace(
                    '{!ChargentOrders__ChargentOrder__c.ChargentOrders__Bank_Account_Number__c}',
                    '***' + chargentOrder.ChargentOrders__Bank_Account_Number__c.right(4)
                );
                MessagingService.createAndSendEmail(
                    htmlValue,
                    'customercare@bluewavesolar.com',
                    'Receiving SREC Payments Via Automatic Deposit',
                    new List<String>{emailInput},
                    null
                );
            } catch (Exception e){
                Logger.logNow('CreateOrderandPaymentRequest', 'submitDDInfoWithoutCharge', 'Did not send email receipt: ' + chargentOrder.Id + String.valueOf(e));
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

    @TestVisible private enum ChargentTestResult {
        CHARGENT_TEST_RESULT_APPROVED,
        CHARGENT_TEST_RESULT_TIMEOUT
    }
    @TestVisible private static ChargentTestResult testResult = ChargentTestResult.CHARGENT_TEST_RESULT_APPROVED;

    public static Id testAPICall(ChargentOrders__ChargentOrder__c orderTest, Boolean isCredit) {
        ChargentOrders__Transaction__c transA = new ChargentOrders__Transaction__c(
            ChargentOrders__Order__c = orderTest.Id,
            ChargentOrders__Amount__c = orderTest.ChargentOrders__Subtotal__c,
            ChargentOrders__Response_Status__c ='Approved',
            ChargentOrders__Response_Message__c = 'OK',
            ChargentOrders__Type__c = 'Charge',
            Activity_Type__c = 'Payment'
        );
        if (testResult == ChargentTestResult.CHARGENT_TEST_RESULT_TIMEOUT) {
            transA.ChargentOrders__Response_Status__c = 'Error';
            transA.ChargentOrders__Response_Message__c =
                'System.JSONException! Unexpected character (\'S\' (code 83)): expected a valid value (number, String, ' +
                    'array, object, \'true\', \'fal';
            transA.ChargentOrders__Gateway_Response__c = 'System.CalloutException! Read timed out';
        }
        if (isCredit) {
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