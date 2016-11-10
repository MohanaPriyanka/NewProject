public with sharing class ProductProfileController {
    @AuraEnabled
    public static Product_Profile__c[] getProfiles() {
    	Product_Profile__c[] returnList = new Product_Profile__c[0];
    	User u = [Select ContactId from User where Id = :UserInfo.getUserId()];
    	for(Product_Profile__c pp : [Select Id, Image_URL__c, Profile_Type__c, Project_View__c from Product_Profile__c where Contact__c = :U.contactId]) {
    		returnList.add(pp);
    	}
    	return returnList;
    }
}