/*************************************************************************************
 + * Created By:  Jordan Pentaleri 
 + * - Allows for batch crediting of Chargent Orders (sending $ instead of charging customer)
 + * 
 + * Tested By: RecurringSRECHandlerTest
 + *************************************************************************************/

global class BatchCreditSRECHandler implements Database.Batchable<sObject>,Database.AllowsCallouts,Database.Stateful {
    webService static String executeBatch (String type) {
        // As of Feb 2019, we want to explicitly restrict users that can send SREC payments via this class. We can't
        // use apex class permissions, because users that have Author Apex get permission to run all classes. Instead,
        // we'll see if permission is also assigned through a permission set.
        if (!PermissionService.userHasPermissionSetForClass(UserInfo.getUserId(), 'BatchCreditSRECHandler')) {
            return 'You do not have permission to start this job. Log a case if you should.';
        }
        BatchCreditSRECHandler batchJob = new BatchCreditSRECHandler();
        batchJob.srecType = type;
        Id batchId = Database.executeBatch(batchJob, 1);
        return 'Started batch ' + batchId + ' to send SREC payments';
    }
    public List<ChargentOrders__ChargentOrder__c> updatedChOrders;
    public List<Id> successSRECList = new List<Id>();
    public List<Id> successInvoiceList = new List<Id>();
    public String srecType;

    public Database.QueryLocator start(Database.BatchableContext bc) {
        updatedChOrders = new List<ChargentOrders__ChargentOrder__c>();

        String query = 'SELECT Id, Name, ' +
        'Related_SREC__r.Id, SREC_Status__c, ' +
        'SREC_Invoice__r.Id, ' +
        'ChargentOrders__Credit_Amount__c, ' +
        'ChargentOrders__Bank_Routing_Number__c, ' +
        'ChargentOrders__Bank_Account_Number__c, ' +
        'ChargentOrders__Bank_Account_Type__c, ' +
        'ChargentOrders__Bank_Name__c, ' + 
        'ChargentOrders__Subtotal__c, ' +
        'ChargentOrders__Bank_Account_Name__c ' +
        'FROM ChargentOrders__ChargentOrder__c ' +
        'WHERE SREC_Status__c = \'Ready\'';
        if (srecType == 'quarterly') {
            // SREC__c objects used for quarterly payments
            query += ' AND Related_SREC__c != NULL';
        } else if (srecType == 'monthly') {
            // SREC_Invoice__c uses for monthly payments
            query += ' AND SREC_Invoice__c != NULL';
        }

        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext bc, List<ChargentOrders__ChargentOrder__c> scope){
        Boolean isSuccess;
        for (ChargentOrders__ChargentOrder__c chOrder : scope) {
            isSuccess = CreateOrderandPaymentRequest.attemptSRECsend(chOrder);
            if (isSuccess) {
                chOrder.SREC_Status__c = 'Success';
                if (chOrder.Related_SREC__r.Id != null){
                    successSRECList.add(chOrder.Related_SREC__r.Id);
                } else if (chOrder.SREC_Invoice__r.Id != null){
                    successInvoiceList.add(chOrder.SREC_Invoice__r.Id);
                }
            } else {
                chOrder.SREC_Status__c = 'Failed';
            }
            updatedChOrders.add(chOrder);
        }
    }

    public void finish(Database.BatchableContext bc){
        Logger.flushLogs(); 
        update updatedChOrders;

        Date todaysDate = date.newinstance(system.today().year(), system.today().month(), system.today().day());

        if (successSRECList.size() > 0){
            List<SREC__c> srecsToUpdateList = new List<SREC__c>();
            for (SREC__c srecToUpdate : [SELECT Id, Name, Date_Distributed_to_Customer__c
                                        FROM SREC__c
                                        WHERE Id IN : successSRECList]){
                srecToUpdate.Date_Distributed_to_Customer__c = todaysDate;
                srecsToUpdateList.add(srecToUpdate);
            }
            update srecsToUpdateList;
        }

        if (successInvoiceList.size() > 0){
            List<SREC_Invoice__c> invoicesToUpdateList = new List<SREC_Invoice__c>();
            for (SREC_Invoice__c invoiceToUpdate : [SELECT Id, Name, Date_Paid__c
                                                    FROM SREC_Invoice__c
                                                    WHERE Id IN : successInvoiceList]){
                invoiceToUpdate.Date_Paid__c = todaysDate;
                invoicesToUpdateList.add(invoiceToUpdate);
            }
            update invoicesToUpdateList;
        }

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