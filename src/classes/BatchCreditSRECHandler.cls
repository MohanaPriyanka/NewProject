/*************************************************************************************
 + * Created By:  Jordan Pentaleri 
 + * - Allows for batch crediting of Chargent Orders (sending $ instead of charging customer)
 + * 
 + * Tested By: RecurringSRECHandlerTest
 + *************************************************************************************/

public without sharing class BatchCreditSRECHandler implements Database.Batchable<sObject>,Database.Stateful { 
    //Database.executeBatch(this, 1);

    public List<ChargentOrders__ChargentOrder__c> updatedChOrders;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        updatedChOrders = new List<ChargentOrders__ChargentOrder__c>();

        String query = 'SELECT Id, Name, SREC_Status__c, ' +
        'ChargentOrders__Credit_Amount__c, ' +
        'ChargentOrders__Bank_Routing_Number__c, ' +
        'ChargentOrders__Bank_Account_Number__c, ' +
        'ChargentOrders__Bank_Account_Type__c, ' +
        'ChargentOrders__Bank_Name__c, ' + 
        'ChargentOrders__Subtotal__c, ' +
        'ChargentOrders__Bank_Account_Name__c ' +
        'FROM ChargentOrders__ChargentOrder__c ' +
        'WHERE SREC_Status__c = \'Ready\'';

        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<ChargentOrders__ChargentOrder__c> scope){
        Boolean isSuccess;
        for (ChargentOrders__ChargentOrder__c chOrder : scope) {
            isSuccess = CreateOrderandPaymentRequest.attemptSRECsend(chOrder);
            if (isSuccess) {
                chOrder.SREC_Status__c = 'Success';
            } else {
                chOrder.SREC_Status__c = 'Failed';
            }
            updatedChOrders.add(chOrder);
        }
    }

    public void finish(Database.BatchableContext bc){
        Logger.flushLogs(); 
        update updatedChOrders;

        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, 
                            JobItemsProcessed,
                            TotalJobItems, CreatedBy.Email
                            FROM AsyncApexJob
                            WHERE Id = :bc.getJobId()];

        String emailBody = 'SREC Send Has Completed - Job Id: '+ job.Id 
                                + '  Errors: ' + job.NumberOfErrors 
                                + '  Total Orders Processed: ' + job.JobItemsProcessed;    

        List<String> postJobEmailAddresses = new List<String>{'product@bluewavesolar.com'};  

        if(!Test.isRunningTest()){
            MessagingService.createAndSendEmail(emailBody, 'product@bluewavesolar.com', 'SREC Send Has Completed', postJobEmailAddresses);
        }
    }  
}