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

public without sharing class GenericBatchDMLOperation implements Database.Batchable<SObject>,Database.Stateful {
    
    private Set<String> possibleDmlOperation = new Set<String>{'Insert','Update','Upsert','Delete','Convert'};
    private String dmlOperation;
    private List<SObject> sobjList = new List<SObject>();
    private String log = '';
    public List<String> triggersToDisable = new List<String>();
    private LeadConvertOption leadConvertOption;
    private String postBatchOperationClass;

    public GenericBatchDMLOperation(List<SObject> sobjListPassed,
                                    String dmlOperationPassed) {
        sobjList = sobjListPassed;
        if (possibleDmlOperation.contains(dmlOperationPassed)) {
            dmlOperation = dmlOperationPassed;
        } else {
            throw new Util.BWException('Unexpected dmlOperation: ' + dmlOperationPassed);
        }
    }

    @InvocableMethod(Label='genericBatchUpdate')
    public static void callUpdateFromFlow(List<List<SObject>> recordsToUpdate){
        Database.executeBatch(new GenericBatchDMLOperation(recordsToUpdate[0], 'Update'),50);
    }

    public void setLeadConvertOption(LeadConvertOption leadConvertOption) {
        this.leadConvertOption = leadConvertOption;
    }

    public void setPostBatchOperation(String className) {
        this.postBatchOperationClass = className;
    }

    public List<SObject> start(Database.BatchableContext bc) {
        return sobjList;
    }
   
    public void execute(Database.BatchableContext batchableContext, List<SObject> scope) {
        for (String triggerAsString : triggersToDisable) {
            Util.disableTrigger(triggerAsString);
        }
        GenericResult[] resultList;
        switch on dmlOperation {
            when 'Insert' {
                resultList = saveResult2GR(Database.insert(scope, false));
            } when 'Update' {
                resultList = saveResult2GR(Database.update(scope, false));
            } when 'Upsert' {
                // Unfortunately, upsert with a field specification requires a concrete SObject type,
                // so this isn't quite Generic.
                // https://success.salesforce.com/ideaView?id=08730000000aNhVAAU
                // Added upsert with externalID for EnergyUsageUpdateTriggerHandler
                resultList = handleUpsertWithExternalIds(scope);
            } when 'Delete' {
                resultList = deleteResult2GR(Database.delete(scope, false));
            } when 'Convert' {
                resultList = handleLeadConversion(scope);
            }
        }
        updateErrorLog(resultList, scope);
        Logger.logNow('GenericBatchDMLOperation', 'execute', 'Execute complete for ' + scope.size() + ' records', Logger.FINE);
        for (String triggerString : triggersToDisable) {
            Util.enableTrigger(triggerString);
        }
    }

    private void updateErrorLog(GenericResult[] resultList, List<SObject> scope) {
        for (Integer i = 0; i < resultList.size(); i++) {
            if (!resultList[i].isSuccess()) {
                this.log += '\nError in Batch DML ' + dmlOperation + ' Execution for object: ' +
                    scope.getSObjectType().getDescribe().getName() + ' and id: ' +
                    scope[i].Id + '. Error msg = ' +
                    resultList[i].getErrors()[0].getMessage();
            }
        }
    }

    private List<GenericResult> handleLeadConversion(List<SObject> scope) {
        List<GenericResult> resultList = new List<GenericResult>();
        if (!(scope instanceof List<Lead>)) {
            throw new Util.FatalBWException('Expected a list of Lead but got list of ' + scope.getSObjectType());
        }
        List<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>();
        for (Lead lead : (List<Lead>) scope) {
            Database.LeadConvert leadConvert = leadConvertOption.getNewLeadConvert();
            leadConvert.setLeadId(lead.Id);
            leadConverts.add(leadConvert);
        }
        resultList = leadConvertResult2GR(Database.convertLead(leadConverts, false));
        return resultList;
    }

    private List<GenericResult> handleUpsertWithExternalIds(List<SObject> scope) {
        List<GenericResult> resultList = new List<GenericResult>();
        if (scope.getSObjectType().getDescribe().getName() == 'Journal_Entry__c') {
            Schema.SObjectField externalId = Journal_Entry__c.External_Id__c;
            resultList = upsertResult2GR(Database.upsert((List<Journal_Entry__c>) scope, externalId, false));
        } else {
            resultList = upsertResult2GR(Database.upsert(scope, false));
        }
        return resultList;
    }


    public interface PostBatchOperation {
        Object executePostBatch();
    }

    public void finish(Database.BatchableContext batchableContext) {
        if (!String.isEmpty(this.log)) {
            Logger.logNow('GenericBatchDMLOperation', 'finish', this.log, Logger.ERROR);
        }
        executePostBatchOperation(postBatchOperationClass);
    }

    /**
     * @description Instantiates a class that implements PostBatchOperation and calls the executePostBatch method
     * @param operationClass The class to instantiate
     * @return An object, to aid with testing
     */
    public static Object executePostBatchOperation(String operationClass) {
        if (operationClass != null) {
            PostBatchOperation postBatchOperation = (PostBatchOperation) Type.forName(operationClass).newInstance();
            Object obj = postBatchOperation.executePostBatch();
            Logger.logNow('GenericBatchDMLOperation', 'executePostBatchOperation', 'PostBatchOperation Finished for ' + operationClass, Logger.FINE);
            return obj;
        }
        return null;
    }

    // https://salesforce.stackexchange.com/questions/125880/do-the-result-objects-in-database-have-a-common-ancestor
    private List<GenericResult> saveResult2GR(List<Database.SaveResult> resultList) {
        List<GenericResult> genericResultList = new List<GenericResult>();
        for (Database.SaveResult result : resultList) {
            genericResultList.add(new GenericResult(result));
        }
        return genericResultList;
    }
    private List<GenericResult> upsertResult2GR(List<Database.UpsertResult> resultList) {
        List<GenericResult> genericResultList = new List<GenericResult>();
        for (Database.UpsertResult result : resultList) {
            genericResultList.add(new GenericResult(result));
        }
        return genericResultList;
    }
    private List<GenericResult> deleteResult2GR(List<Database.DeleteResult> resultList) {
        List<GenericResult> genericResultList = new List<GenericResult>();
        for (Database.DeleteResult result : resultList) {
            genericResultList.add(new GenericResult(result));
        }
        return genericResultList;
    }
    private List<GenericResult> leadConvertResult2GR(List<Database.LeadConvertResult> resultList) {
        List<GenericResult> genericResultList = new List<GenericResult>();
        for (Database.LeadConvertResult result : resultList) {
            genericResultList.add(new GenericResult(result));
        }
        return genericResultList;
    }

    public class LeadConvertOption {
        private String convertedStatus;
        public Boolean doNotCreateOpportunity = false;
        private Boolean overwriteLeadSource = false;
        private String ownerId = null;
        private Boolean sendNotificationEmail = false;

        public LeadConvertOption(String convertedStatus) {
            this.convertedStatus = convertedStatus;
        }

        private Database.LeadConvert getNewLeadConvert() {
            Database.LeadConvert leadConvert = new Database.LeadConvert();
            leadConvert.setConvertedStatus(convertedStatus);
            leadConvert.setDoNotCreateOpportunity(doNotCreateOpportunity);
            leadConvert.setOverwriteLeadSource(overwriteLeadSource);
            leadConvert.setOwnerId(ownerId);
            leadConvert.setSendNotificationEmail(sendNotificationEmail);
            return leadConvert;
        }
    }

    private class GenericResult
    {
        private final Id recordId;
        private final List<Database.Error> errors;
        private final Boolean isSuccess;
        private List<Database.Error> getErrors() { return errors; }
        private Boolean isSuccess() {return isSuccess; }

        private GenericResult(Id recordId, List<Database.Error> errors, Boolean success)
        {
            this.recordId = recordId;
            this.errors = (errors != null) ? errors : new List<Database.Error>();
            this.isSuccess = success;
        }
        private GenericResult(Database.SaveResult result)
        {
            this(result.getId(), result.getErrors(), result.isSuccess());
        }
        private GenericResult(Database.UpsertResult result)
        {
            this(result.getId(), result.getErrors(), result.isSuccess());
        }
        private GenericResult(Database.DeleteResult result)
        {
            this(result.getId(), result.getErrors(), result.isSuccess());
        }
        private GenericResult(Database.LeadConvertResult result)
        {
            this(result.getLeadId(), result.getErrors(), result.isSuccess());
        }
    }
}