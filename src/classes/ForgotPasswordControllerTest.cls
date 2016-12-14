/**
 * An apex page controller that exposes the site forgot password functionality
 */
@IsTest public with sharing class ForgotPasswordControllerTest {
    @IsTest public static void testForgotPasswordControllerInvalidUser() {
    	// Instantiate a new controller with all parameters in the page
    	ForgotPasswordController controller = new ForgotPasswordController();
    	controller.username = 'test@salesforce.com';
    
    	System.assertEquals(null, controller.forgotPassword()); 
        System.assertEquals(ForgotPasswordController.ERRORMSGSTRING + controller.username, controller.errorMsg);
    }

    @IsTest public static void testForgotPasswordControllerValidUser() {
        Profile bfgStandardUser = 
            [SELECT Id from Profile WHERE Name = 'BFG Standard User'];
        User bfgUser = new User (ProfileId = bfgStandardUser.Id,
                                 FirstName = 'Test',
                                 LastName = 'BFG_User',
                                 Username = 'bfguser@test.com',
                                 Email = 'bfguser@test.com',
                                 Alias = 'bfg_usr',
                                 CommunityNickname = 'bfg_usr',
                                 TimeZoneSidKey = 'America/New_York',
                                 LocaleSidKey = 'en_US',
                                 EmailEncodingKey = 'ISO-8859-1',
                                 LanguageLocaleKey = 'en_US',
                                 IsActive = true);
        insert bfgUser;

    	// Instantiate a new controller with all parameters in the page
    	ForgotPasswordController controller = new ForgotPasswordController();
    	controller.username = 'bfguser@test.com';     	
        controller.forgotPassword();
        // forgotPassword always returns false if called outside of a VF page:
        // https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_sites.htm
    	System.assertEquals(null, controller.errorMsg); 
    }

}