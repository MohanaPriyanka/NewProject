/**
 * Created by aingram on 9/23/21.
 * @description Tests for UserChangeEventTriggerHandler
 */

@IsTest
public with sharing class UserChangeEventTriggerHandlerTest {

    @TestSetup
    public static void testSetup() {
        Test.enableChangeDataCapture();
        Account partnerAccount = new Account(
            Name = 'Test Partner Account',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Partner_Account').getRecordTypeId()
        );
        insert partnerAccount;

        Contact partnerContact = new Contact(
            AccountId = partnerAccount.Id,
            FirstName = 'Test',
            LastName = 'Partner',
            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByDeveloperName().get('Partner_Contact').getRecordTypeId()
        );
        insert partnerContact;

        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'Partner Portal Community User'].Id,
            ContactId = partnerContact.Id,
            FirstName = 'Partner',
            LastName = 'Test',
            Email = 'test@gearscrm.test',
            Username = 'test@gearscrm.test' + System.currentTimeMillis(),
            CommunityNickname = 'pt',
            CompanyName = 'GearsCRM',
            Title = 'Tester',
            Alias = 'test',
            TimeZoneSidKey = 'America/New_York',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US'
        );
        insert u;

    }

    @IsTest
    public static void updateUserContactsOnEmailChangeTest() {
        Test.enableChangeDataCapture();
        String newEmail = 'updatedemail@invalid.com';

        User userToUpdate = [SELECT Id, Email, ContactId FROM User WHERE Email = 'test@gearscrm.test' LIMIT 1];

        Test.startTest();
        userToUpdate.Email = newEmail;
        update userToUpdate;
        Test.stopTest(); 


        User updatedUser = [SELECT Id, Email FROM User WHERE Id = :userToUpdate.Id LIMIT 1];

        System.assertEquals(newEmail, updatedUser.Email, 'Users email should be updated to new email');

        Contact updatedContact = [SELECT Id, Email FROM Contact WHERE Id = :userToUpdate.ContactId LIMIT 1];

        System.assertEquals(newEmail, updatedContact.Email, 'Contact should have new email address');

    }

}