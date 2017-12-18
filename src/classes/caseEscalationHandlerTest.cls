@isTest
private class CaseEscalationHandlerTest {
	static testMethod void testCaseInsertFromTask() {

		Account accountOne = new Account ( Name = 'Account One');
		insert accountOne;

		Contact contactOne = new Contact (	FirstName = 'Jordan',
											LastName = 'Pentaleri',
											Phone = '8644217874',
											AccountId = accountOne.Id);

		Contact contactTwo = new Contact (	FirstName = 'Jordan',
											LastName = 'Pentaleri2',
											Phone = '8644217874',
											AccountId = accountOne.Id);

		Contact contactThree = new Contact ( FirstName = 'Jordan',
											LastName = 'Pentaleri3',
											Phone = '8644217874',
											AccountId = accountOne.Id);
		insert new List<Contact>{contactOne, contactTwo, contactThree};

		Task oldTask = new Task (
		 	Subject = 'This is the Subject',
		 	Status = 'New',
		 	Priority = 'High');

		insert oldTask;

		Case caseOne = new Case (
			Subject = 'Test Controller Acct Case',
			Created_From_Task__c = String.valueOf(oldTask.Id).substring(0,15) );

		Case caseTwo = new Case (
			Subject = 'New Voice Message from PENTALERI, JORDAN (864) 421-7874 on 06/05/2017 at 08:25 AM' );

		Case caseThree = new Case (
			Subject = '' );

        insert new List<Case>{caseOne, caseTwo, caseThree};

		Test.startTest();

		List <Task> queriedTasks = [SELECT Id, WhatId
	                                FROM Task];

	    List <Case> queriedCases = [SELECT Id, ContactId, Case_Update__c
	                                FROM Case
	                                WHERE Subject = 'New Voice Message from PENTALERI, JORDAN (864) 421-7874 on 06/05/2017 at 08:25 AM'];

	    System.AssertEquals(1 , queriedTasks.size());
	    
	    for (Task aTask : queriedTasks) {
	    	System.AssertEquals(aTask.WhatId,caseOne.Id);
	    }

	    for (Case aCase : queriedCases){
	    	System.Debug(aCase);
	    	System.AssertEquals(aCase.ContactId,contactOne.Id);
	    	System.AssertNotEquals(aCase.Case_Update__c, NULL);
	    }
	    Test.stopTest();
	}
}