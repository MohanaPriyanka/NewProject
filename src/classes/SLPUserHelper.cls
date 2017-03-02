public without sharing class SLPUserHelper {
	@AuraEnabled 
	public static String getPartnerId () {
		System.debug('begin the getPartnerId method');
		String partnerId;
	  	User u = [SELECT Id, Partner_Id__c, Contact.Partner_Lookup__c FROM User WHERE Id = :UserInfo.getUserId()];
        partnerId = String.valueOf(u.Partner_Id__c).subString(0,15);            
		return partnerId;    	    
	}

	@AuraEnabled 
	public static String getBWCCId () {
		System.debug('begin the getBWCCId method');
		String partnerId;
	  	User u = [SELECT Id, Partner_Id__c FROM User WHERE Name = 'BlueWave Customer Care'];
        System.debug('the user is ' + u);
	  	partnerId = String.valueOf(u.Partner_Id__c).subString(0,15);
		return partnerId;    	    
	}	

    @AuraEnabled
    public static List<String> getPartnerLogo() {
        String partnerId = getPartnerId();
        if (partnerId == null || partnerId == '') {
          partnerId = getBWCCId();
        }        
        Partner__c partner;
        String logoId;
        StaticResource logo;
        List<String> logoList = new List<String>();

        partner = [SELECT Id, Name, Logo__c FROM Partner__c WHERE Id = : partnerId];
        logoId = partner.Logo__c;
        logo = [SELECT Id, Name FROM StaticResource WHERE Name = : logoId];
        logoList.add(logoId);
        logoList.add(logo.Id);
        return logoList;
    }	
}