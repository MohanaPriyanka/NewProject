/**
 * An apex page controller that exposes the site forgot password functionality
 */
@IsTest public with sharing class ForgotPasswordControllerTest {
    @IsTest public static void testForgotPasswordControllerInvalidUser() {
        User guest = [
            SELECT Id, IsActive, Username, Email, Profile.Name
            FROM User
            WHERE Name LIKE '%Guest%'
            AND IsActive = TRUE
            AND Profile.Name = 'BlueWave Member Portal Profile'
            LIMIT 1
        ];
        System.runAs(guest) {
            // Instantiate a new controller with all parameters in the page
            ForgotPasswordController controller = new ForgotPasswordController();
            controller.username = 'test@salesforce.com';

            System.assertEquals(null, controller.forgotPassword());
            System.assertEquals(controller.ERRORMSGSTRING, controller.errorMsg);

            controller.send();
        }
        List<Case> passwordCase = [
            SELECT Id
            FROM Case
            WHERE Subject LIKE 'Please help setup%'
        ];
        System.assertEquals(1, passwordCase.size(), 'Expected the ForgotPassword page to create a case to get help');
    }

    @IsTest public static void testForgotPasswordControllerValidUser() {
        Profile profileRecord = [SELECT Id FROM Profile WHERE Name = 'Community Solar Community User'];
        Account parentAccount = new Account(Name = 'Parent Account');
        insert parentAccount;
        Contact customerContact = new Contact(
            AccountId = parentAccount.Id,
            FirstName = 'Test',
            LastName = 'Contact',
            Email = 'test@foo.bar'
        );
        insert customerContact;

        User bfgUser = new User(
            FirstName = 'First',
            LastName = parentAccount.Name,
            Alias = ((String) parentAccount.Id).right(6),
            Email = customerContact.Email,
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            ProfileId = profileRecord.Id,
            Country = 'United States',
            IsActive = true,
            TimeZoneSidKey = 'Pacific/Tongatapu',
            ContactId = customerContact.Id,
            Username = 'bfguser@test.com');
        Util.insertSObj(bfgUser);

        User guest = [
            SELECT Id, IsActive, Username, Email, Profile.Name
            FROM User
            WHERE Name LIKE '%Guest%'
            AND IsActive = TRUE
            AND Profile.Name = 'BlueWave Member Portal Profile'
            LIMIT 1
        ];
        System.runAs(guest) {
            // Instantiate a new controller with all parameters in the page
            ForgotPasswordController controller = new ForgotPasswordController();
            controller.username = 'bfguser@test.com';
            controller.forgotPassword();
            // forgotPassword always returns false if called outside of a VF page:
            // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_sites.htm
            System.assertEquals(null, controller.errorMsg, 'Expected to find the user and reset their password');
        }
    }

}