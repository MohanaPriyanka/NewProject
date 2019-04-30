@IsTest
public class UserHandlerTest {
	@TestSetup public static void testSetup(){
		Account accountParent = new Account(
			Name = 'Account Parent',
			OwnerId = UserInfo.getUserId()
		);
		Account parentTwo = new Account(
			Name = 'Two Parent',
			OwnerId = UserInfo.getUserId()
		);
		Account parentThree = new Account(
			Name = 'Three Parent',
			OwnerId = UserInfo.getUserId()
		);
		insert new List<Account>{accountParent, parentTwo, parentThree};

		Contact normalContact = new Contact(
			FirstName = 'First',
			LastName = 'NotUniqueLast',
			Email = 'notUniqueEmail@bluewavesolar.com',
			AccountId = parentTwo.Id
		);
		Contact duplicateUsernameContact = new Contact(
			FirstName = 'First',
			LastName = 'UniqueLastname',
			Email = 'notUniqueEmail@bluewavesolar.com',
			AccountId = accountParent.Id
		);
		Contact duplicateNicknameContact = new Contact(
			FirstName = 'First',
			LastName = 'NotUniqueLast',
			Email = 'uniqueEmail@bluewavesolar.com',
			AccountId = parentThree.Id
		);
		Contact incompleteInfoContact = new Contact(
			FirstName = 'First',
			LastName = 'Lastname',
			AccountId = accountParent.Id
		);
		Contact noAccountContact = new Contact(
			FirstName = 'No',
			LastName = 'Account',
			Email = 'foo@bar.com'
		);
		insert new List<Contact>{normalContact, duplicateUsernameContact, duplicateNicknameContact, incompleteInfoContact, noAccountContact};

		Account normalAccount = new Account(
			Name = 'Normal Account',
			Parent_Account__c = parentTwo.Id,
			Send_Bills_Contact__c = normalContact.Id,
			OwnerId = UserInfo.getUserId()
		);
		Account duplicateUsernameAccount = new Account(
			Name = 'Duplicate Username',
			Parent_Account__c = accountParent.Id,
			Send_Bills_Contact__c = duplicateUsernameContact.Id,
			OwnerId = UserInfo.getUserId()
		);
		Account duplicateNicknameAccount = new Account(
			Name = 'Duplicate Nickname',
			Parent_Account__c = parentThree.Id,
			Send_Bills_Contact__c = duplicateNicknameContact.Id,
			OwnerId = UserInfo.getUserId()
		);
		Account incompleteInfoAccount = new Account(
			Name = 'Incomplete Info',
			Parent_Account__c = accountParent.Id,
			Send_Bills_Contact__c = incompleteInfoContact.Id,
			OwnerId = UserInfo.getUserId()
		);
		Account loanAccount = new Account(
			Name = 'Loan',
			OwnerId = UserInfo.getUserId()
		);
		insert new List<Account>{normalAccount, duplicateUsernameAccount, duplicateNicknameAccount, incompleteInfoAccount, loanAccount};

		Shared_Solar_System__c nonWaitlistSSS =
			new Shared_Solar_System__c(Name = 'Shared Solar System');

		Shared_Solar_System__c waitlistSSS =
			new Shared_Solar_System__c(Name = 'Waitlist Project');

		insert new List<Shared_Solar_System__c>{nonWaitlistSSS, waitlistSSS};

		Opportunity oppOne = new Opportunity(
			Name = 'NonWaitlist Opp',
			AccountId = normalAccount.Id,
			Parent_Account__c = parentTwo.Id,
			Shared_Solar_System__c = nonWaitlistSSS.Id,
			StageName = 'Complete',
			Product_Line__c = 'Community Solar',
			CloseDate = System.today()
		);

		Opportunity oppTwo = new Opportunity(
			Name = 'Waitlist Opp',
			AccountId = duplicateNicknameAccount.Id,
			Parent_Account__c = parentThree.Id,
			Shared_Solar_System__c = waitlistSSS.Id,
			StageName = 'Complete',
			Product_Line__c = 'Community Solar',
			CloseDate = System.today()
		);

		Opportunity oppThree = new Opportunity(
			Name = 'Loan',
			AccountId = loanAccount.Id,
			StageName = 'Complete',
			CloseDate = System.today()
		);
		insert new List<Opportunity>{oppOne, oppTwo, oppThree};
	}

	@IsTest public static void testSuccessfulUserCreation() {
		List<Contact> contactList = [SELECT Id, FirstName, LastName, Email, AccountId FROM Contact];

		List<User> oldUserList = [SELECT Id, ContactId FROM User WHERE IsActive = TRUE];
		Integer previousNumberUsers = oldUserList.size();

		Test.startTest();
		UserHandler userInsertJob = new UserHandler(contactList);
		System.enqueueJob(userInsertJob);
		Test.stopTest();

		List<User> userListUpdated = [SELECT Id, ContactId FROM User WHERE IsActive = TRUE];
		System.assertEquals(previousNumberUsers + 3, userListUpdated.size());
	}

	@IsTest public static void testFailedUserCreation() {
		List<Contact> newContactList = new List<Contact>();

		// 3 Contacts with same username/nickname: can fix the second but not the third:
		for (Contact contactToEdit : [SELECT Id, FirstName, LastName, Email, AccountId FROM Contact]) {
			contactToEdit.FirstName = 'First';
			contactToEdit.LastName = 'NotUniqueLast1234';
			contactToEdit.Email = 'notUniqueEmail1234@bluewavesolar.com';
			newContactList.add(contactToEdit);
		}
		List<User> oldUserList = [SELECT Id, ContactId FROM User WHERE IsActive = TRUE];
		Integer previousNumberUsers = oldUserList.size();

		Test.startTest();
		UserHandler userInsertJob = new UserHandler(newContactList);
		System.enqueueJob(userInsertJob);
		Test.stopTest();

		List<User> userListUpdated = [SELECT Id, ContactId FROM User WHERE IsActive = TRUE];
		System.assertEquals(previousNumberUsers + 2, userListUpdated.size());
	}

	@IsTest public static void testAlreadyActivatedPortal() {
		List<Contact> contactList = [SELECT Id, FirstName, LastName, Email, AccountId FROM Contact];

		List<User> firstUserList = [SELECT Id, ContactId FROM User WHERE IsActive = TRUE];
		Integer firstNumberUsers = firstUserList.size();

		Test.startTest();
		UserHandler userInsertJob = new UserHandler(contactList);
		System.enqueueJob(userInsertJob);

		UserHandler secondInsertJob = new UserHandler(contactList);
		System.enqueueJob(secondInsertJob);
		Test.stopTest();

		List<User> newUserList = [SELECT Id, ContactId FROM User WHERE IsActive = TRUE];
		Integer newNumberUsers = newUserList.size();

		System.assertEquals(firstNumberUsers + 3, newNumberUsers);
	}

	@IsTest public static void testPortalActivation() {

		List<User> oldUserList = [
			SELECT Id, ContactId
			FROM User
			WHERE IsActive = TRUE
		];

		Integer previousNumberUsers = oldUserList.size();

		Account accountParent = new Account(
			Name = 'Account Parent',
			OwnerId = UserInfo.getUserId()
		);
		insert accountParent;

		Account normalAccount = new Account(
			Name = 'Account Parent',
			OwnerId = UserInfo.getUserId()
		);
		insert normalAccount;

		Contact normalContact = new Contact(
			FirstName = 'First',
			LastName = 'UniqueLasttte',
			Email = 'uniqueEmail6734@bluewavesolar.com',
			AccountId = accountParent .Id
		);
		insert normalContact;

		Opportunity testOpportunity = new Opportunity(
			Name = 'Blue Wave Signature Complete',
			AccountId = normalAccount.Id,
			Parent_Account__c = accountParent.Id,
			BlueWave_Signature_Status__c = 'Completed',
			StageName = 'Complete',
			Product_Line__c = 'Community Solar',
			Contract_Status__c = 'Complete',
			CloseDate = System.today()
		);
		insert testOpportunity;


		List<Opportunity> newOpportunities = [SELECT Id, Parent_Account_ID__c FROM Opportunity];

		Test.startTest();
		OpportunityTriggerHandler.activatePortalUser(new List<String>{testOpportunity.Id});
		Test.stopTest();

		List<User> userListUpdated = [
			SELECT Id, ContactId
			FROM User
			WHERE IsActive = TRUE
		];

		System.assertEquals(previousNumberUsers + 1, userListUpdated.size());
	}


	@IsTest public static void testLoanOpp() {
		Opportunity loanOpp = [SELECT Id FROM Opportunity WHERE Name = 'Loan'];
		loanOpp.Contract_Status__c = 'Completed';

		Test.startTest();
		update loanOpp;
		Test.stopTest();

		List<User> accounts = [SELECT Id FROM User WHERE LastName = 'Account'];
		System.assertEquals(0, accounts.size());
		List<Error_Log__c> errors = [SELECT Id, Message__c FROM Error_Log__c WHERE Class__c = 'UserHandler'];
		System.assertEquals(0, errors.size());
	}


}