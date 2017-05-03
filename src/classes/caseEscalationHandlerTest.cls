@isTest
private class caseEscalationHandlerTest {
	static testMethod void testcaseinsertfromtask() {

		Task oldtask = new Task (
		 	Subject = 'This is the Subject',
		 	Status = 'New',
		 	Priority = 'High');

		insert oldtask;

		Case newcase = new Case (
			Subject = 'Test Controller Acct Case',
			Created_From_Task__c = (string.valueof(oldtask.Id)).substring(0,15) );

		insert newcase;

		test.starttest();

		List <Task> queriedtasks = [SELECT Id, WhatId
	                                FROM Task];

	    system.assertEquals(queriedtasks.size(),1);
	    
	    for (Task atask : queriedtasks) {
	    	System.AssertEquals(atask.WhatId,newcase.Id);
	    }

	    test.stoptest();
	}
}