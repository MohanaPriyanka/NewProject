/*************************************************************************************
 * Created By:  Sarah Renfro
 * Description: Called from TaskTrigger. 
 *              Creates new Customer Care case when button is triggered on Task.
 *              Populates fields on case with subject, status, record type, and either 
 *              the contact or lead information 
 *              
 * Test: CustomerCareHandlerTest
 *************************************************************************************/

public class CustomerCareHandler {
    public  void createCases (List<Task> updatedTasks, Map <Id,Task> oldTaskMap) {
        List <Task> triggeredvalues = new List <Task> ();

        //Check if old value = new value in order to concentrate on tasks that have been updated 
        for (Task checkValue : updatedTasks) {
            if (oldTaskMap.get(checkValue.Id).Customer_Care_Case__c != checkValue.Customer_Care_Case__c) {
                triggeredvalues.add(checkvalue);
            }
        }

        List<Case> newCases = new List<Case>();

        Id ccRecordTypeId = 
            Schema.SObjectType.Case.getRecordTypeInfosByName().get('Customer Care').getRecordTypeId();

        for (Task triggerCase : triggeredvalues) {
            String taskID = String.valueOf(triggerCase.WhoID);
            Case newCase = new Case(Subject = triggerCase.Subject,
                                    Status = 'New',
                                    ContactId = (taskID.startsWith('003')?triggerCase.WhoId:null),
                                    Lead_Lookup__c = (taskID.startsWith('00Q')?triggerCase.WhoId:null),
                                    RecordTypeId = ccRecordTypeId);

            // Set Unique ID field on task object in order for javascript button to open new case in window
            String uniqueID = newCase.Id;
            triggerCase.Customer_Case_Unique_ID__c = uniqueID; 

            newCases.add(newCase);
        }

        insert newCases;
    }


}