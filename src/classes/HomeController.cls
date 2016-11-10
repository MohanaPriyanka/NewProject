public with sharing class HomeController {
    public ImageScrollerController.ImageObject[] images {get;set;}
    public Boolean hasCommunity{get;set;}
    public Boolean hasLoan{get;set;}
    public BlueWave_Blog__c[] blogEntries {get;set;}  
    public Product_Profile__c[] community {get;set;}
    public Product_Profile__c[] solarLoan {get;set;}
    
    
    public HomeController() {
    	images = new ImageScrollerController.ImageObject[0];
    	for(Project_Scroller__c ps : [Select Id, Name, Description__c, (Select Id, Name from Attachments) from Project_Scroller__c]) {
    		if(ps.Attachments != null && ps.Attachments.size() > 0)
    		images.add(new ImageScrollerController.ImageObject(ps.Attachments[0].Id, ps.Name, ps.Description__c));
    	}
    	hasCommunity = false;
    	hasLoan = false;
    	User u = [Select Id, ContactId from User where Id = :UserInfo.getUserId()];
    	community = new Product_Profile__c[0];
    	solarLoan = new Product_Profile__c[0];
    	try {
    		for(Product_Profile__c pp : [Select Id, Project_View__c, Commencement_Date__c, Profile_Type__c from Product_Profile__c where Contact__c = :u.ContactId]) {
    			if(pp.Profile_Type__c == 'Community Solar') {
    				hasCommunity = true;
    				community.add(pp);
    			}
    			if(pp.Profile_Type__c == 'Solar Loan') {
    				hasLoan = true;
    				solarLoan.add(pp);
    			}
    		}
    	}
    	catch(Exception ex) {
    		
    	}
    	blogEntries = new BlueWave_Blog__c[0];
    	for(BlueWave_Blog__c bb : [Select Id, CreatedDate, Body__c, Blog_Type__c, Name from BlueWave_Blog__c order by createddate desc limit 10]) {
    		if(bb.Blog_Type__c == 'Community Solar' && hasCommunity)
    			blogEntries.add(bb);
    		else if(bb.Blog_Type__c == 'Solar Loan' && hasLoan)
    			blogEntries.add(bb);
    		else if(bb.Blog_Type__c == 'General')
    			blogEntries.add(bb);
    	}
    }
}