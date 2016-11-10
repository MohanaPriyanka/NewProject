public class MySolarFarmController {
    @AuraEnabled
    public static Shared_Solar_System__c getSolarSystem() {
    	User u = [Select Id, ContactId from User where Id = :UserInfo.getUserId()];
    	Shared_Solar_System__c ss;
    	if(u.ContactId != null) {
    		try {
	    		Product_Profile__c pp = [Select Id, Shared_Solar_System__c, My_Current_Balance__c from Product_Profile__c where Contact__c = :u.ContactId and Profile_Type__c = 'Community Solar'];
	    		ss = [Select Id, Name, Estimated_COD_Date__c, Capacity_Available_to_be_Reserved__c from Shared_Solar_System__c  where Id = :pp.Shared_Solar_System__c];
    		}
    		catch(Exception ex) {
    			
    		}
    	}
    	return ss;
    } 
    
    @AuraEnabled
    public static User[] getUsers() {
    	User u = [Select Id, ContactId from User where Id = :UserInfo.getUserId()];
    	User[] returnList = new User[0];
    	if(u.ContactId != null) {
    		try {
	    		Product_Profile__c pp = [Select Id, Shared_Solar_System__c, My_Current_Balance__c from Product_Profile__c where Contact__c = :u.ContactId and Profile_Type__c = 'Community Solar'];
	    		Id[] contactIds = new Id[0];
	    		for(Product_Profile__c pprof : [Select Id, Contact__c from Product_Profile__c where Shared_Solar_System__c = :pp.Shared_Solar_System__c]) {
	    			contactIds.add(pprof.Contact__c);
	    		}
	    		returnList = [Select Id, SmallPhotoUrl from User where ContactId in :contactIds];
    		}
    		catch(Exception ex) {
    			
    		}
    	}
    	return returnList;
    }
    
    @AuraEnabled
    public static Product_Profile__c getProject() {
    	User u = [Select Id, ContactId from User where Id = :UserInfo.getUserId()];
    	Product_Profile__c returnProject;
    	if(u.ContactId != null) {
    		try {
	    		returnProject = [Select Id, Project_View__c from Product_Profile__c where Contact__c = :u.ContactId and Profile_Type__c = 'Community Solar'];
    		}
    		catch(Exception ex) {
    			
    		}
    	}
    	return returnProject;
    }
}