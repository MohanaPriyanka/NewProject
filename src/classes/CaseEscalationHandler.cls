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

  
  public static void findContactFromVM (List<Case> newlyCreatedCase) {
    Map<String, Case> phoneMap = new Map<String, Case>(); 
    for (Case insertedCase : newlyCreatedCase) {
      if (insertedCase.Subject != null) {
        String subjectString = insertedCase.Subject;
        if (subjectString.contains('New Voice Message')) {
          Integer indexnum = subjectString.indexOf(' (');
          String plainTextPhone = subjectString.substring(indexNum + 2, indexNum + 5) 
                                  + subjectString.substring(indexNum + 7, indexNum + 10)
                                  + subjectString.substring(indexNum + 11, indexNum + 15);
          phoneMap.put(plainTextPhone, insertedCase);
        }
      }
    }
    if (phoneMap.size() > 0) {
      for (Contact cnT : [SELECT Id, Plain_Text_Phone__c, LastActivityDate
                            FROM Contact
                            WHERE Plain_Text_Phone__c IN : phoneMap.keySet()
                            ORDER BY LastActivityDate DESC NULLS LAST]) {
        if (phoneMap.get(cnT.Plain_Text_Phone__c).ContactId == NULL ) {
              phoneMap.get(cnT.Plain_Text_Phone__c).ContactId = cnT.Id;
        } else if (phoneMap.get(cnT.Plain_Text_Phone__c).Case_Update__c != NULL) {
              phoneMap.get(cnT.Plain_Text_Phone__c).Case_Update__c = phoneMap.get(cnT.Plain_Text_Phone__c).Case_Update__c + ', ' + cnT.Id;
        } else {
              phoneMap.get(cnT.Plain_Text_Phone__c).Case_Update__c = 'Alternative Contact(s): '+ cnT.Id;
        }
      }
    }
  }
}