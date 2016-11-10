public without sharing class AccountInfoController {
    
    @AuraEnabled
    public static Contact getContactInfo() {
    	User u =  [Select Id, ContactId from User where Id = :UserInfo.getUserId()];
    	Contact c;
    	if(u.ContactId != null) {
    		try {
    			c = [Select Id, Phone, Email, FirstName, LastName, MailingStreet, MailingCity, MailingState, MailingPostalCode from Contact where Id = :u.ContactId];
    		}
    		catch(Exception ex) {
    			
    		}
    	}
    	return c;
    }
    
    @AuraEnabled
    public static Product_Profile__c getProductInfo() {
    	User u =  [Select Id, ContactId from User where Id = :UserInfo.getUserId()];
    	Product_Profile__c pp;
    	if(u.ContactId != null) {
    		try {
				pp = [Select Id, Subscription__c, Utility__c from Product_Profile__c where Contact__c = :u.ContactId and Profile_Type__c = 'Community Solar'];
    		}
    		catch(Exception ex) {
    			
    		}
    	}
    	return pp;
    }
    
    @AuraEnabled
    public static User getUserInfo() {
    	return  [Select Id, SmallPhotoUrl, Username, Email, Phone from User where Id = :UserInfo.getUserId()];
    }
    
    @AuraEnabled
    public static String setInfo(String email, String phone, String password, String username) {
    	try {
    		User u = [Select Id, ContactId from User where Id = :UserInfo.getUserId()];
    		if(u.ContactId != null) {
	    		Contact c = [Select Id from Contact where Id = :u.ContactId];
    			if(email != null && email != '') {
	    			c.Email = email;
    				u.Email = email;
    			}
    			if(phone != null && phone != '') {
	    			c.Phone = phone;
    				u.Phone = phone;
	    		}
    			if(username != null && username != '') {
	    			u.UserName = username;
    			}
				update c;
				update u;
    		}
    		if(password != null && password != '') {
	    		System.setPassword(UserInfo.getUserId(), password);
    		}
    	}
    	catch(Exception ex) {
    		return ex.getMessage();
    	}
    	return 'success';
    }

	
    @AuraEnabled
	public static String saveTheFile(String fileName, String base64Data, String contentType) {
        try {
        	base64Data = EncodingUtil.urlDecode(base64Data, 'UTF-8');
        
	        Blob b = EncodingUtil.base64Decode(base64Data);
        	ConnectApi.Photo photo = ConnectApi.UserProfiles.setPhoto(null, UserInfo.getUserId(),  new ConnectApi.BinaryInput(b,contentType,fileName));
        }
        catch(Exception ex) {
        	return ex.getMessage();
        }
        return 'success';
        
    }
    
    @AuraEnabled
   	public static Document[] getDocuments() {
   		Folder f = [Select Id from Folder where DeveloperName = 'Community_Documents'];
   		Document[] returnList = new Document[0];
   		try {
   			returnList = [Select Id, Name from Document where FolderId = :f.Id];
   		}
   		catch(Exception ex) {
   		}
   		return returnList;
   	}
    
}