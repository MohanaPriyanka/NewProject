/*************************************************************************************
 + * Created By:  Jordan Pentaleri 
 + * Description: When a case is created off the "Escalate to Case" button on a task,
 + * the field "Created from Task" on the Case holds the Id of that task. This trigger 
 + * finds that task, and relates it to the newly created Case, so it shows up in the
 + * related activity
 +*
 + * Tested By: caseEscalationHandlerTest
 + *************************************************************************************/

public with sharing class CaseEscalationHandler {
  
  public static void linkTaskToCase(List<Case> newlyCreatedCase) {
    List<String> taskIdList = new List<String>();
    Map<String, Id> taskToCaseMap = new Map<String, Id>();
    for (Case newCase : newlyCreatedCase) {
      if (newCase.Created_From_Task__c != null) {
          taskIdList.add(newCase.Created_From_Task__c);
          taskToCaseMap.put(newCase.Created_From_Task__c, newCase.Id);
      }
    }

    List <Task> queriedTasks = [SELECT Id, WhatId
                                FROM Task
                                WHERE Id IN : taskIdList];

    for (Task originTask : queriedTasks) {
      String taskId = String.valueOf(originTask.Id).substring(0,15);
      if (taskToCaseMap.ContainsKey(taskId)) {
        originTask.WhatId = taskToCaseMap.get(taskId);
      }
    }
    update queriedTasks;
  }
}