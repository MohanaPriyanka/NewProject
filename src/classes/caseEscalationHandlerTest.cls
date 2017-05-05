@isTest
private class CaseEscalationHandlerTest {
	static testMethod void testCaseInsertFromTask() {

		Task oldTask = new Task (
		 	Subject = 'This is the Subject',
		 	Status = 'New',
		 	Priority = 'High');

		insert oldTask;

		Case newCase = new Case (
			Subject = 'Test Controller Acct Case',
			Created_From_Task__c = String.valueOf(oldTask.Id).substring(0,15) );

		insert newCase;

		Test.startTest();

		List <Task> queriedTasks = [SELECT Id, WhatId
	                                FROM Task];

	    System.AssertEquals(1 , queriedTasks.size());
	    
	    for (Task aTask : queriedTasks) {
	    	System.AssertEquals(aTask.WhatId,newCase.Id);
	    }


	    Test.stopTest();
	}
}