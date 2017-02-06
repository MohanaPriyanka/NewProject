public class SLPCustomerHandler {    

	@AuraEnabled 
	public static Loan__c getCustomerLoan (String loanId) {
		System.debug('the loanId is ' + loanId);
	    User u = [SELECT Id, Partner_ID__c FROM User WHERE Id = :UserInfo.getUserId()];
		List<Loan__c> loanList = [SELECT Id, Name, Product__r.Name, System_Costt__c, Commencement_Datee__c, 
									Total_Funds_Disbursed__c, Sales_Agent__r.Name, Product__r.ProductCode  
									FROM Loan__c 
									WHERE Id = : loanId];
		System.debug('loanList is ' + loanList);
		return loanList.get(0);    	    
	}

	@AuraEnabled 
	public static String getProgressBarData(String loanId) {
		System.debug('the loanId is ' + loanId);
		String returnTaskName;
	    User u = [SELECT Id, Partner_ID__c FROM User WHERE Id = :UserInfo.getUserId()];
	    List<Partner_Task__c> completedTaskList = [SELECT Id, Name, Status__c, Completion_Date__c, Task_Sequence__c, Loan__r.Name
	    											FROM Partner_Task__c
	    											WHERE Loan__c = : loanId
	    											AND Status__c = 'Complete'
				                                  	AND Parent__c = true
				                                  	AND Sub_Task_Type__c = null
				                                  	AND Parent_Task__c = null    										
	    											ORDER BY Completion_Date__c, Task_Sequence__c DESC
	    											LIMIT 1];
		if(completedTaskList.size() > 0){
			for (Partner_Task__c task : completedTaskList){
				returnTaskName = task.Name;
			}				
		}   											
		//System.debug('the completedTaskList is ' + completedTaskList.get(0).Name);
		return returnTaskName;    	    
	}

   @AuraEnabled
    public static List<Partner_Task__c> getLoanCustomerTasks(String loanId) {
        User u = [SELECT Id, Partner_ID__c FROM User WHERE Id = :UserInfo.getUserId()];
        List<Partner_Task__c> taskList = [SELECT Id, Name, Completion_Date__c, SubTasks__c, Status__c, Loan__r.Id, Loan__c, Task_Sequence__c
                                  			FROM Partner_Task__c 
                                  			WHERE Loan__c = : loanId 
		                                  	AND Parent__c = true
		                                  	AND Sub_Task_Type__c = null
		                                  	AND Parent_Task__c = null                                  			
                                  			ORDER BY Task_Sequence__c ASC];                               
        return taskList;
    }

   @AuraEnabled
    public static List<Partner_Task__c> getLoanParentSubTasks(String taskId) {
        User u = [SELECT Id, Partner_ID__c FROM User WHERE Id = :UserInfo.getUserId()];
        List<Partner_Task__c> taskList = [SELECT Id, Name, Completion_Date__c, SubTasks__c, Parent_Task__r.Name, Status__c, Loan__r.Id, Loan__c, Task_Sequence__c
                                  			FROM Partner_Task__c 
		                                  	WHERE Parent_Task__c = : taskId                                 			
                                  			ORDER BY Task_Sequence__c ASC];                               
        
        System.debug('task list is ' + taskList);
        return taskList;
    }  

   @AuraEnabled
    public static List<Disbursal__c> getLoanDisbursals(String loanId) {
    	System.debug('begin the getLoanDisbursals method');
        User u = [SELECT Id, Partner_ID__c FROM User WHERE Id = :UserInfo.getUserId()];
        List<Disbursal__c> disbursalList = [SELECT Id, Name, Date_of_Disbursal__c, Disbursal_Percentage__c, Status__c, Amount__c, Type__c 
                                  FROM Disbursal__c WHERE Loan__c = : loanId 
                                  ORDER BY Disbursal_Sequence__c ASC];                               
        System.debug('disbursalList is ' + disbursalList);
        return disbursalList;
    }    

   @AuraEnabled
    public static Map<String, List<Partner_Task__c>> getTaskMap (String loanId) {
        Map<String, List<Partner_Task__c>> taskMap = new Map<String, List<Partner_Task__c>>();
        User u = [SELECT Id, Partner_ID__c FROM User WHERE Id = :UserInfo.getUserId()];
        for (Partner_Task__c partnerTask : [SELECT Id, Name, Completion_Date__c, Parent_Task__r.Name, 
        									Status__c, Loan__r.Id, Loan__c, Task_Sequence__c,
        										(SELECT Id, Name, Status__c, Completion_Date__c FROM
        										subTasks__r)
                                  			FROM Partner_Task__c 
		                                  	WHERE Parent__c = true
		                                  	AND Sub_Task_Type__c = null
		                                  	AND Parent_Task__c = null 
		                                  	AND Loan__c = : loanId                                			                                			
                                  			ORDER BY Task_Sequence__c ASC]){
        	taskMap.put(partnerTask.Name, partnerTask.subTasks__r);
        }                              
        
        System.debug('taskMap is ' + taskMap);
        return taskMap;
    }            
}