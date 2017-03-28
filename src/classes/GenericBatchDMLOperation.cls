/*************************************************************************************
 * Created By:  Peter Yao 
 * Description: This is a generic class which can be used to run 5 DML operations in SF for all sObjects
 *              The constructor needs to be passed the following 4 parameters
 *                   1)  sobjListPassed 	 - List of objects that will have the dml operations executed upon.
 *                   2)  dmlOperationPassed 	 - 'Insert','Update','Delete','Upsert', 'Undelete' 
 *                       (removed delete, upsert and undelete due to lack of use and test coverage
 *              
 * Harry Dhanoa 8/July/2015
 * https://developer.salesforce.com/forums/?id=906F00000008yXCIAY
 * Harry's version includes full functionality including status object adn other DML operations
 * 
 * Tested By: PostSandboxRefresherTest
 *************************************************************************************/

public class GenericBatchDMLOperation implements Database.Batchable<sObject>,Database.Stateful {
    
    public Set<String> possibleDmlOperation = new Set<String>{'Insert','Update','Upsert'};
    public String dmlOperation;
    public List<SObject> sobjList = new List<SObject>();
    public String log = '';
    
    public GenericBatchDMLOperation(List<SObject> sobjListPassed,
                                    String dmlOperationPassed) {
        sobjList = sobjListPassed;
        if (possibleDmlOperation.contains(dmlOperationPassed)) {
            dmlOperation = dmlOperationPassed;
        }
    }

    public List<SObject> start(Database.BatchableContext BC) {
        return sobjList;
    }
   
    public void execute(Database.BatchableContext batchableContext, List<SObject> scope) {
        Database.SaveResult[] srList = new Database.SaveResult[]{};
        Database.UpsertResult[] urList = new Database.UpsertResult[]{};
        if (dmlOperation == 'Insert') {
            srList = Database.insert(scope, false);
        } else if(dmlOperation == 'Update') {
            srList = Database.update(scope, false);
        } else if(dmlOperation == 'Upsert') {
            // Unfortunately, upsert with a field specification requires a concrete SObject type,
            // so this isn't quite Generic.
            // https://success.salesforce.com/ideaView?id=08730000000aNhVAAU
            // Added upsert with externalID for EnergyUsageUpdateTriggerHandler
            if (scope.getSObjectType().getDescribe().getName() == 'Utility_Account_Bill__c') {
                Schema.SObjectField externalId = Utility_Account_Bill__c.Unique_Id__c;
                urList = Database.upsert((List<Utility_Account_Bill__c>) scope, externalId, false);
            } else {
                urList = Database.upsert(scope, false);
            }
        }
        for (Integer i = 0; i < srList.size(); i++) {
            if (!srList[i].isSuccess()) {
                this.log += '\nError in Batch DML ' + dmlOperation + ' Execution for object: ' +
                    scope.getSObjectType().getDescribe().getName() + ' and id: ' +
                    scope[i].Id + '. Error msg = ' +
                    srList[i].getErrors()[0].getMessage();
            }
        }
        for (Integer i = 0; i < urList.size(); i++) {
            if (!urList[i].isSuccess()) {
                this.log += '\nError in Batch DML ' + dmlOperation + ' Execution for object: ' +
                    scope.getSObjectType().getDescribe().getName() + ' and id: ' +
                    scope[i].Id + '. Error msg = ' +
                    urList[i].getErrors()[0].getMessage();
            }
        }
    }   
    
    public void finish(Database.BatchableContext batchableContext) {
        String emailErrorsTo;
        List<System_Properties__c> systemProperties = System_Properties__c.getall().values();
        if (systemProperties.isEmpty() ||
            systemProperties[0].Error_Email__c == null) {
            emailErrorsTo = 'product@bluewavesolar.com';
        } else {
            emailErrorsTo = systemProperties[0].Error_Email__c;
        }            

        if (!String.isEmpty(this.log)) {
            System.debug(LoggingLevel.ERROR, 'Batch DML Error: ' + this.log);
            Logger.log('GenericBatchDMLOperation', 'finish', this.log, System.now());
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String> {emailErrorsTo});
            email.setSubject('Error in Batch DML process!');
            email.setPlainTextBody(this.log);
            MessagingService.sendEmail(new List<Messaging.SingleEmailMessage>{email});
        }
    }
}
