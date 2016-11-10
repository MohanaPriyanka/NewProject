public with sharing class BlogComponentController {
    
    @AuraEnabled
    public static BlueWave_Blog__c[] getBlogs(String bType) {
    	BlueWave_Blog__c[] returnList = new BlueWave_Blog__c[0];
    	for(BlueWave_Blog__c bb : [Select Id, CreatedDate, Blog_Type__c, Short_Description__c, Body__c, Name from BlueWave_Blog__c where Blog_Type__c includes (:bType) order by createdDate desc]) {
    		returnList.add(bb);
    	}
    	return returnList;
    }
    
    @AuraEnabled
    public static String getRecordType(Id recordId) {
    	Product_Profile__c pp = [Select Id, Profile_Type__c from Product_Profile__c where Id = :recordId];
    	return pp.Profile_Type__c;
    }
}