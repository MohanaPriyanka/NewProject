public with sharing class UpdateLastContactDateHandler { }

/*

 
  private boolean m_isExecuting = false;
  private Integer BatchSize = 0;
    
  public UpdateLastContactDateHandler (boolean isExecuting, Integer size){
      m_isExecuting = isExecuting;
      BatchSize = size;
  }
 
  public void OnBeforeInsert (Task[] trigTask){
      UpdateLastContactDateinsert(trigTask);
  }

  public void OnBeforeUpdate (Task[] oldTasks, Task[] trigTasks){
      UpdateLastContactDate(oldTasks, trigTasks);
  }

  private void UpdateLastContactDateinsert (List<Task> trigTasks){ 
    integer m;
    integer i;
    integer j;
    List <Task> triggeredtasks = new list <Task> ();
    List <string> contactids = new list <string> ();
    List <string> accountids = new list <string> ();
    
        for(m = 0; m < trigTasks.size(); m++){  
          if(trigTasks.get(m).Do_Not_Fire_Triggers__c == False && trigTasks.get(m).Status == 'Completed'){
                if(trigTasks.get(m).WhoId != null){
                  contactids.add(trigTasks.get(m).WhoId);
                }
                if(trigTasks.get(m).WhatId != null){
                  accountids.add(trigTasks.get(m).WhatId);
                }
          }      
        } 

        system.debug(accountids);
        system.debug(contactids);

        if(contactids.size()>0){
            List <Contact> listContact = [  SELECT Id, Account_ID__c
                                            FROM Contact
                                            WHERE Id IN : contactids];
            system.debug(listContact);

            for(i = 0; i < listContact.size(); i++){ 
              if(listContact.get(i).Account_ID__c != null){ 
                  accountids.add(listContact.get(i).Account_ID__c);
                  system.debug(listContact.get(i).Account_ID__c);
              }
            }
            system.debug(accountids);
        }

        if(accountids.size()>0){
            List <Account> listAccount = [  SELECT Id, Last_Contact_Date__c
                                            FROM Account
                                            WHERE Id IN : accountids];
            system.debug(listAccount);  

            for(j = 0; j < listAccount.size(); j++){ 
                  Date myDate = Date.today();
                  listAccount.get(j).Last_Contact_Date__c = myDate;
            }

            update listAccount;
        }
  }

  private void UpdateLastContactDate (List<Task> oldTasks, List<Task> trigTasks){ 

        system.debug(oldTasks);
        system.debug(trigTasks);

        integer m;
        integer i;
        integer j;

        Map<Id, Task> oldvalues = new Map<Id, Task> ();
        List <Task> triggeredtasks = new list <Task> ();
        List <string> contactids = new list <string> ();
        List <string> accountids = new list <string> ();

        for(Task oldTask: oldTasks){
              oldvalues.put(oldTask.id, oldTask);
        }

        for(m = 0; m < trigTasks.size(); m++){  
          if(trigTasks.get(m).Do_Not_Fire_Triggers__c == False){
              string newvalueID = trigTasks.get(m).Id;
              string newcstatus = trigTasks.get(m).Status;
              string oldstatus = oldvalues.get(newvalueID).Status;
                  if (newcstatus == 'Completed' && oldstatus != 'Completed') { 
                        triggeredtasks.add(trigTasks.get(m));
                            if(trigTasks.get(m).WhoId != null){
                              contactids.add(trigTasks.get(m).WhoId);
                            }
                            if(trigTasks.get(m).WhatId != null){
                              accountids.add(trigTasks.get(m).WhatId);
                            }      
                  }
          }
        } 

        system.debug(triggeredtasks);
        system.debug(accountids);
        system.debug(contactids);

        if(contactids.size()>0){
            List <Contact> listContact = [  SELECT Id, Account_ID__c
                                            FROM Contact
                                            WHERE Id IN : contactids];
            system.debug(listContact);

            for(i = 0; i < listContact.size(); i++){ 
              if(listContact.get(i).Account_ID__c != null){ 
                  accountids.add(listContact.get(i).Account_ID__c);
                  system.debug(listContact.get(i).Account_ID__c);
              }
            }
            system.debug(accountids);
        }

        if(accountids.size()>0){
            List <Account> listAccount = [  SELECT Id, Last_Contact_Date__c
                                            FROM Account
                                            WHERE Id IN : accountids];
            system.debug(listAccount);  

            for(j = 0; j < listAccount.size(); j++){ 
                  Date myDate = Date.today();
                  listAccount.get(j).Last_Contact_Date__c = myDate;
            }

            update listAccount;
        }

  }
}
*/