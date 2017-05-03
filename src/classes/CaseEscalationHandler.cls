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
  private boolean m_isExecuting = false;
  private Integer BatchSize = 0;
    
  public CaseEscalationHandler (boolean isExecuting, Integer size) {
      m_isExecuting = isExecuting;
      BatchSize = size;
  }

  public void OnAfterInsert (Case [] newlycreatedcase) {
      linktasktocase (newlycreatedcase);
  }
  
  public static void linktasktocase (List <Case> newlycreatedcase) {
    List <String> taskidlist = new List <String> ();
    Map <String, Id> tasktocasemap = new Map <String, Id> ();
    for (Case newcase : newlycreatedcase) {
      if (newcase.Created_From_Task__c != null) {
          taskidlist.add(newcase.Created_From_Task__c);
          tasktocasemap.put(newcase.Created_From_Task__c, newcase.Id);
      }
    }

    List <Task> queriedtasks = [SELECT Id, WhatId
                                FROM Task
                                WHERE Id IN : taskidlist];

    for (Task origintask : queriedtasks) {
      string taskid = (string.valueof(origintask.Id).substring(0,15));
      if (tasktocasemap.ContainsKey(taskid)) {
        origintask.WhatId = tasktocasemap.get(taskid);
      }
    }
    update queriedtasks;
  }
}