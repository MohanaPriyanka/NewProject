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
			new Shared_Solar_System__c(Name = 'Waitlist Project', Waitlist__c = true);

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
		userInsertJob.execute(null);
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
		userInsertJob.execute(null);
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
		userInsertJob.execute(null);

		UserHandler secondInsertJob = new UserHandler(contactList);
		secondInsertJob.execute(null);
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

		Shared_Solar_System__c testSSS =
			new Shared_Solar_System__c(Name = 'Shared Solar System');

		Account accountParent = new Account(
			Name = 'Account Parent23457',
			OwnerId = UserInfo.getUserId()
		);
		insert accountParent;

		Account normalAccount = new Account(
			Name = 'Account Parent123456',
			Parent_Account__c = accountParent.Id,
			OwnerId = UserInfo.getUserId()
		);
		insert normalAccount;

		Contact normalContact = new Contact(
			FirstName = 'Peanut',
			LastName = 'Butter',
			Email = 'pbutter@bluewavesolar.com',
			AccountId = accountParent.Id
		);
		insert normalContact;

		Opportunity testOpportunity = new Opportunity(
			Name = 'Peanut Butter',
			AccountId = normalAccount.Id,
			Parent_Account__c = accountParent.Id,
			Shared_Solar_System__c = testSSS.Id,
			BlueWave_Signature_Status__c = 'Complete',
			StageName = 'Complete',
			Product_Line__c = 'Community Solar',
			Contract_Status__c = 'Complete',
			CloseDate = System.today()
		);
		insert testOpportunity;

		Test.startTest();
		OpportunityTriggerHandler.activatePortalUser(new List<Id>{testOpportunity.Id});
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

	@IsTest
	public static void testPortalActivationEmail(){
		Account parentAccount = new Account(
			Name = 'Parent Account 1'
		);
		insert parentAccount;
		Contact newContact = new Contact(
			FirstName = 'Customer',
			LastName = 'Contact3',
			AccountId = parentAccount.Id,
			Email = 'someContactTest@email.com'
		);
		insert newContact;

		List<Task> beforeTasks = [
			SELECT Id
			FROM Task
			WHERE WhoId = : newContact.Id
			AND Subject LIKE '%Portal Activation%'
		];
		System.assertEquals(0,beforeTasks.size());

		Test.startTest();
			User newUser = insertUser(newContact);
			Portal_User_Activated__e portalUserActivatedEvent = new Portal_User_Activated__e(
				User_Id__c = newUser.Id
			);
			EventBus.publish(portalUserActivatedEvent);
		Test.stopTest();

		List<Task> afterTasks = [
			SELECT Id
			FROM Task
			WHERE WhoId = : newContact.Id
			AND Subject LIKE '%Portal Activation%'
		];
		System.assertEquals(1,afterTasks.size());
	}

	private static User insertUser(Contact contact) {
		Profile profileRecord = [SELECT Id FROM Profile WHERE Name = 'Community Solar Community User'];

		User userToInsert = new User(
			FirstName = contact.FirstName,
			LastName = contact.LastName,
			Alias = contact.FirstName.left(2) + contact.LastName.right(6),
			Email = contact.Email,
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			Country = 'United States',
			IsActive = true,
			ContactId = contact.Id,
			ProfileId = profileRecord.Id,
			TimeZoneSidKey = 'America/New_York',
			Username = contact.Email,
			CommunityNickname = contact.FirstName.left(10) + contact.LastName.left(30)
		);

		Util.insertSObj(userToInsert);
		return userToInsert;
	}
}