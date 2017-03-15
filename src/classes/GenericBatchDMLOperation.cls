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

global class GenericBatchDMLOperation implements Database.Batchable<sObject>,Database.Stateful {
    
    public Set<String> possibleDmlOperation = new Set<String>{'Insert','Update'};
    public String dmlOperation;
    public List<SObject> sobjList = new List<SObject>();
    public SObject statusSObject;
    public String statusSObjectFieldName;
    public AsyncApexJob aAJ;
    public Boolean updateQuote;
    
    global GenericBatchDMLOperation(List<SObject> sobjListPassed,
                                    String dmlOperationPassed) {
        sobjList = sobjListPassed;
        if (possibleDmlOperation.contains(dmlOperationPassed)) {
            dmlOperation = dmlOperationPassed;
        }

    }

    global List<SObject> start(Database.BatchableContext BC) {
    	aAJ = [ SELECT Id, Status, NumberOfErrors, JobItemsProcessed,TotalJobItems, CreatedBy.Email
                FROM AsyncApexJob WHERE Id = :BC.getJobId()];
        return sobjList;
    }
   
    global void execute(Database.BatchableContext batchableContext, List<SObject> scope) {
        if (dmlOperation == 'Insert') {
            Insert scope;
        } else if(dmlOperation == 'Update') {
            Update scope;    
        } else if(dmlOperation == 'Upsert') {
            if (scope.getSObjectType().getDescribe().getName() == 'Utility_Account_Bill__c') {
                Upsert (List<Utility_Account_Bill__c>) scope Unique_Id__c;
            } else {
                Upsert scope;
            }
        }
    }   
    
    global void finish(Database.BatchableContext batchableContext) {
    	aAJ = [ SELECT Id, Status, NumberOfErrors, JobItemsProcessed,TotalJobItems, CreatedBy.Email
                FROM AsyncApexJob WHERE Id = :batchableContext.getJobId()];
    }
}