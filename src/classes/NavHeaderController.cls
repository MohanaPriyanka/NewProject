public with sharing class NavHeaderController {
    
    @AuraEnabled
    public static String getUserName() {
    	return UserInfo.getFirstName() + ' ' + UserInfo.getLastName();
    }
}