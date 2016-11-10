public with sharing class UtilityLoginInformationController {
    
    @AuraEnabled
    public static Boolean needsUtility() {
		try {
    		User u = [Select Id, ContactId from User where Id = :UserInfo.getUserId()];
    		Product_Profile__c pp = [Select Id, Utility_Account_Username__c, Utility_Account_Password__c, Don_t_Adjust_Solar_Subscription__c from Product_Profile__c where Contact__c = :u.ContactId and Profile_Type__c = 'Community Solar' and (Utility_Account_Username__c = null or Utility_Account_Username__c = '') and (Utility_Account_Password__c = null or Utility_Account_Password__c = '') and Create_Utility_Account__c = false and Don_t_Adjust_Solar_Subscription__c = false];
    		return true;
		}
		catch(Exception ex) {
			
		}
		return false;
    }
    
    @AuraEnabled
    public static String setInfo(String username, String password) {
		try {
    		User u = [Select Id, ContactId from User where Id = :UserInfo.getUserId()];
    		Product_Profile__c pp = [Select Id, Utility_Account_Username__c, Utility_Account_Password__c, Don_t_Adjust_Solar_Subscription__c from Product_Profile__c where Contact__c = :u.ContactId and Profile_Type__c = 'Community Solar'];
    		pp.Utility_Account_Username__c = username;
    		pp.Utility_Account_Password__c = password;
    		update pp;
    		return 'Success';
		}
		catch(Exception ex) {
			
		}
		return 'Failure';
    }
    
    @AuraEnabled
    public static String setCreateAccount() {
		try {
    		User u = [Select Id, ContactId from User where Id = :UserInfo.getUserId()];
    		Product_Profile__c pp = [Select Id, Utility_Account_Username__c, Utility_Account_Password__c, Don_t_Adjust_Solar_Subscription__c from Product_Profile__c where Contact__c = :u.ContactId and Profile_Type__c = 'Community Solar'];
    		pp.Create_Utility_Account__c = true;
    		update pp;
    		return 'Success';
		}
		catch(Exception ex) {
			
		}
		return 'Failure';
    }
    
    @AuraEnabled
    public static String setNoAdjustment() {
		try {
    		User u = [Select Id, ContactId from User where Id = :UserInfo.getUserId()];
    		Product_Profile__c pp = [Select Id, Utility_Account_Username__c, Utility_Account_Password__c, Don_t_Adjust_Solar_Subscription__c from Product_Profile__c where Contact__c = :u.ContactId and Profile_Type__c = 'Community Solar'];
    		pp.Don_t_Adjust_Solar_Subscription__c = true;
    		update pp;
    		return 'Success';
		}
		catch(Exception ex) {
			
		}
		return 'Failure';
    }
}