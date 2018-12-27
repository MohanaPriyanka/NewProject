@isTest
public class UserHandlerTest {
	@testSetup public static void testSetup(){
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
		insert new List<Contact>{normalContact, duplicateUsernameContact, duplicateNicknameContact, incompleteInfoContact};

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
		insert new List<Account>{normalAccount, duplicateUsernameAccount, duplicateNicknameAccount, incompleteInfoAccount};

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
		insert new List<Opportunity>{oppOne, oppTwo};
	}

	@isTest public static void testSuccessfulUserCreation() {
		List<Contact> contactList = [SELECT Id, FirstName, LastName, Email FROM Contact];

		List<User> oldUserList = [SELECT Id, ContactId FROM User WHERE IsActive = true];
		Integer previousNumberUsers = oldUserList.size();

		test.startTest();
		UserHandler.createCSCommunityUser(contactList);
		test.stopTest();

		List<User> userListUpdated = [SELECT Id, ContactId FROM User WHERE IsActive = true];
		System.assertEquals(previousNumberUsers + 3, userListUpdated.size());
	}

	@isTest public static void testFailedUserCreation() {
		List<Contact> newContactList = new List<Contact>();

		// 3 Contacts with same username/nickname: can fix the second but not the third:
		for (Contact contactToEdit : [SELECT Id, FirstName, LastName, Email FROM Contact]){
			contactToEdit.FirstName = 'First';
			contactToEdit.LastName = 'NotUniqueLast1234';
			contactToEdit.Email = 'notUniqueEmail1234@bluewavesolar.com';
			newContactList.add(contactToEdit);
		}
		List<User> oldUserList = [SELECT Id, ContactId FROM User WHERE IsActive = true];
		Integer previousNumberUsers = oldUserList.size();

		test.startTest();
		UserHandler.createCSCommunityUser(newContactList);
		test.stopTest();

		List<User> userListUpdated = [SELECT Id, ContactId FROM User WHERE IsActive = true];
		System.assertEquals(previousNumberUsers + 2, userListUpdated.size());
	}

	@isTest public static void testAlreadyActivatedPortal() {
		List<Contact> contactList = [SELECT Id, FirstName, LastName, Email FROM Contact];

		List<User> firstUserList = [SELECT Id, ContactId FROM User WHERE IsActive = true];
		Integer firstNumberUsers = firstUserList.size();

		test.startTest();
		UserHandler.createCSCommunityUser(contactList);

		List<User> secondUserList = [SELECT Id, ContactId FROM User WHERE IsActive = true];
		Integer secondNumberUsers = secondUserList.size();

		UserHandler.createCSCommunityUser(contactList);

		List<User> thirdUserList = [SELECT Id, ContactId FROM User WHERE IsActive = true];
		Integer thirdNumberUsers = thirdUserList.size();
		test.stopTest();

		System.assertEquals(firstNumberUsers + 3, secondNumberUsers);
		System.assertEquals(firstNumberUsers + 3, thirdNumberUsers);
	}

	@isTest public static void testOpportunityTrigger() {
		Shared_Solar_System__c nonWaitlist = [
			SELECT Id, Name
			FROM Shared_Solar_System__c
			WHERE Name = 'Shared Solar System' LIMIT 1];

		List<Opportunity> oppList = [
			SELECT Id, Name
			FROM Opportunity
			ORDER BY Name];

		oppList[0].Contract_Status__c = 'Completed';
		oppList[1].Shared_Solar_System__c = nonWaitlist.Id;

		List<User> oldUserList = [
			SELECT Id, ContactId
			FROM User
			WHERE IsActive = true];
		Integer previousNumberUsers = oldUserList.size();

		Test.startTest();
		update oppList;
		Test.stopTest();

		List<User> userListUpdated = [
			SELECT Id, ContactId
			FROM User
			WHERE IsActive = true];

		System.assertEquals(previousNumberUsers + 2, userListUpdated.size());
	}
}