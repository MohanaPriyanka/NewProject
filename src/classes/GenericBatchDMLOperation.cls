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

public without sharing class GenericBatchDMLOperation implements Database.Batchable<sObject>,Database.Stateful {
    
    public Set<String> possibleDmlOperation = new Set<String>{'Insert','Update','Upsert','Delete'};
    public String dmlOperation;
    public List<SObject> sobjList = new List<SObject>();
    public String log = '';
    public List<String> triggersToDisable;

    public GenericBatchDMLOperation(List<SObject> sobjListPassed,
                                    String dmlOperationPassed) {
        sobjList = sobjListPassed;
        if (possibleDmlOperation.contains(dmlOperationPassed)) {
            dmlOperation = dmlOperationPassed;
        }
    }

    public List<SObject> start(Database.BatchableContext bc) {
        return sobjList;
    }
   
    public void execute(Database.BatchableContext batchableContext, List<SObject> scope) {
        if (triggersToDisable != null){
            for (String triggerAsString : triggersToDisable){
                Util.disableTrigger(triggerAsString);
                System.debug('TRIGGER' + triggerAsString);
            }
        }
        GenericResult[] resultList;
        if (dmlOperation == 'Insert') {
            resultList = saveResult2GR(Database.insert(scope, false));
        } else if (dmlOperation == 'Update') {
            resultList = saveResult2GR(Database.update(scope, false));
        } else if (dmlOperation == 'Upsert') {
            // Unfortunately, upsert with a field specification requires a concrete SObject type,
            // so this isn't quite Generic.
            // https://success.salesforce.com/ideaView?id=08730000000aNhVAAU
            // Added upsert with externalID for EnergyUsageUpdateTriggerHandler
            if (scope.getSObjectType().getDescribe().getName() == 'Utility_Account_Bill__c') {
                Schema.SObjectField externalId = Utility_Account_Bill__c.Unique_Id__c;
                resultList = upsertResult2GR(Database.upsert((List<Utility_Account_Bill__c>) scope, externalId, false));
            }  else if (scope.getSObjectType().getDescribe().getName() == 'Journal_Entry__c') {
                Schema.SObjectField externalId = Journal_Entry__c.External_Id__c;
                resultList = upsertResult2GR(Database.upsert((List<Journal_Entry__c>) scope, externalId, false));
            } else {
                resultList = upsertResult2GR(Database.upsert(scope, false));
            }
        } else if (dmlOperation == 'Delete') {
            resultList = deleteResult2GR(Database.delete(scope, false));
        }
        for (Integer i = 0; i < resultList.size(); i++) {
            if (!resultList[i].isSuccess()) {
                this.log += '\nError in Batch DML ' + dmlOperation + ' Execution for object: ' +
                    scope.getSObjectType().getDescribe().getName() + ' and id: ' +
                    scope[i].Id + '. Error msg = ' +
                    resultList[i].getErrors()[0].getMessage();
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
        if (triggersToDisable != null){
            for (String triggerString : triggersToDisable){
                Util.enableTrigger(triggerString);
            }
        }
    }

    // https://salesforce.stackexchange.com/questions/125880/do-the-result-objects-in-database-have-a-common-ancestor
    public List<GenericResult> saveResult2GR(List<Database.SaveResult> resultList) {
        List<GenericResult> genericResultList = new List<GenericResult>();
        for (Database.SaveResult result : resultList) {
            genericResultList.add(new GenericResult(result));
        }
        return genericResultList;
    }
    public List<GenericResult> upsertResult2GR(List<Database.UpsertResult> resultList) {
        List<GenericResult> genericResultList = new List<GenericResult>();
        for (Database.UpsertResult result : resultList) {
            genericResultList.add(new GenericResult(result));
        }
        return genericResultList;
    }
    public List<GenericResult> deleteresult2GR(List<Database.DeleteResult> resultList) {
        List<GenericResult> genericResultList = new List<GenericResult>();
        for (Database.DeleteResult result : resultList) {
            genericResultList.add(new GenericResult(result));
        }
        return genericResultList;
    }

    public class GenericResult
    {
        final Id recordId;
        final List<Database.Error> errors;
        final Boolean isSuccess;
        public Id getId() { return recordId; }
        public List<Database.Error> getErrors() { return errors; }
        public Boolean isSuccess() {return isSuccess; }

        public GenericResult(Id recordId, List<Database.Error> errors, Boolean success)
        {
            this.recordId = recordId;
            this.errors = (errors != null) ? errors : new List<Database.Error>();
            this.isSuccess = success;
        }
        public GenericResult(Database.SaveResult result)
        {
            this(result.getId(), result.getErrors(), result.isSuccess());
        }
        public GenericResult(Database.UpsertResult result)
        {
            this(result.getId(), result.getErrors(), result.isSuccess());
        }
        public GenericResult(Database.DeleteResult result)
        {
            this(result.getId(), result.getErrors(), result.isSuccess());
        }
    }
}