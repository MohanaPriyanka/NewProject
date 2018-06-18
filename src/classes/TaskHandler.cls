/*************************************************************************************
 * Created By: peteryao on 6/9/18  
 * Description: Moves new tasks from Converted Lead to Contact, since for converted leads,
 * we want to move new tasks to the converted contact so they're visible in activity history.
 * Test: TaskHandlerTest
 *************************************************************************************/

public with sharing class TaskHandler {
     public static void moveTaskToConvertedContact(List<Task> newTasks) {
        String leadPrefix = Schema.SObjectType.Lead.getKeyPrefix();
        Set<Id> leadIds = new Set<Id>();
        for (Task task : newTasks) {
            if (task.WhoId != null &&
                ((String)task.WhoId).startsWith(leadPrefix)) {
                leadIds.add(task.WhoId);
            }
        }
        Map<Id, Id> leadToContactMap = new Map<Id, Id>();
        List<Lead> leads = [SELECT Id, ConvertedContactId FROM Lead WHERE Id =: leadIds];
        for (Lead lead : leads) {
            if (lead.ConvertedContactId != null) {
                leadToContactMap.put(lead.Id, lead.ConvertedContactId);
            }
        }
        for (Task task : newTasks) {
            if (task.WhoId != null &&
                ((String)task.WhoId).startsWith(leadPrefix) &&
                leadToContactMap.containsKey(task.WhoId)) {
                task.WhoId = leadToContactMap.get(task.WhoId);
            }
        }
    }
}