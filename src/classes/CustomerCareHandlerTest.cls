@isTest
    public class CustomerCareHandlerTest{
	
    @testSetup public static void setupTestData() {
        Account accountOne = new Account (Name = 'Account One');
        insert accountOne;
        Contact contactOne = new Contact (FirstName = 'SarahC',
                                          LastName = 'Test1',
                                          Phone = '8649792613',
                                          AccountId = accountOne.Id);

        Contact contactTwo = new Contact (FirstName = 'SarahC',
                                          LastName = 'Test2',
                                          Phone = '8649792613',
                                          AccountId = accountOne.Id);

        Contact contactThree = new Contact (FirstName = 'SarahC',
                                            LastName = 'Test3',
                                            Phone = '8649792613',
                                            AccountId = accountOne.Id);
        insert new List<Contact>{contactOne, contactTwo, contactThree};

        Lead leadOne = new Lead(FirstName = 'SarahL',
                                LastName = 'Test4',
                                Status = 'Pending Credit Review',
                                Company = 'SarahL Test4',
                                Product_Line__c = 'Community Solar');

        Lead leadTwo = new Lead(FirstName = 'SarahL',
                                LastName = 'Test5',
                                Status = 'Pending Credit Review',
                                Product_Line__c = 'Community Solar',
                                Company = 'SarahL Test5');

        Lead leadThree = new Lead(FirstName = 'SarahL',
                                  LastName = 'Test6',
                                  Status = 'Pending Credit Review',
                                  Product_Line__c = 'Community Solar',
                                  Company = 'SarahL Test6');

        insert new List<Lead>{leadOne, leadTwo, leadThree};

        //Task for Contact WhoId
        Task testTask1 = new Task(Subject = 'This is the subject for testTask1',
                                  Status = 'New',
                                  WhoId = contactOne.Id,
                                  Priority = 'High',
                                  Customer_Care_Case__c = false);

        //Task for Lead WhoId
        Task testTask2 = new Task(Subject = 'This is the subject for testTask2',
                                  Status = 'New',
                                  WhoId = leadOne.Id,
                                  Priority = 'High',
                                  Customer_Care_Case__c = false);

        //Set the checkbox to true to test if button is pressed twice 
        //Should create two separate cases
        Task testTask3 = new Task(Subject = 'This is the subject for testTask3',
                                  Status = 'New',
                                  WhoId = leadTwo.Id,
                                  Priority = 'High',
                                  Customer_Care_Case__c = true);

        insert new List<Task>{testTask1, testTask2, testTask3};
    }

    static testMethod void testCreateCase() {

    	List<Task> testTasks = [SELECT Subject, Id, Customer_Care_Case__c, WhoId FROM Task WHERE Subject LIKE 'This is the subject%'];
    	System.assertEquals(3, testTasks.size());

    	List<Case> testCases = [SELECT Lead_Lookup__c, ContactId, Subject, Status, RecordTypeId, Id FROM Case];
    	System.assertEquals(0, testCases.size());
    	
    	Contact contactOne;
    	Lead leadOne;
    	Lead leadTwo;

    	List<Contact> allContacts = [SELECT Id, LastName FROM Contact];

    	for (Contact c : allContacts) {
            if (c.LastName == 'Test1') {
                contactOne = c;
            }
    	}
    	
    	List<Lead> allLeads = [SELECT Id, Product_Line__c, LastName FROM Lead];
    	for (Lead l : allLeads) {
            if (l.LastName == 'Test4') {
                leadOne =l;
            } else if (l.LastName == 'Test5') {
                leadTwo = l;
            }
    	}

    	Test.startTest();
    	for (Task v : testTasks) {
            if ( v.Customer_Care_Case__c) {
                v.Customer_Care_Case__c = false;
            } else {
                v.Customer_Care_Case__c = true;
            }
    	}
        update testTasks; 

    	Case caseCheck1 = [SELECT Subject, ContactId, Status 
                           FROM Case 
                           WHERE Subject = 'This is the subject for testTask1'];
        System.assertEquals(contactOne.Id, caseCheck1.ContactId);
 		
        Case caseCheck2 = [SELECT Subject, Lead_Lookup__c, Status 
                           FROM Case 
                           WHERE Subject = 'This is the subject for testTask2'];
    	System.assertEquals(leadOne.Id, caseCheck2.Lead_Lookup__c);

    	Case caseCheck3 = [SELECT Subject, Lead_Lookup__c, Status 
                           FROM Case 
                           WHERE Subject = 'This is the subject for testTask3'];
    	System.assertEquals(leadTwo.Id, caseCheck3.Lead_Lookup__c);

    	Test.stopTest();

    }

}

