public without sharing class SLPAlertsHandler {
	@AuraEnabled 
	public static List<Partner_Alert__c> getPartnerAlerts (String partnerId) {
		System.debug('Begin the getPartnerAlerts method');
		List<Partner_Alert__c> alertList = new List<Partner_Alert__c>();
	    String partnerKey = SLPUserHelper.getpartnerId(); 
	    Partner__c partnerRecord;
	    if (partnerKey == null || partnerKey == '') {
	      partnerKey = SLPUserHelper.getBWCCId();
	    }

	 	for (Partner_Alert__c partnerAlert : [SELECT Id, Name, Body__c, Date__c, 
	 												(SELECT Id, Name, Acknowledged__c, Partner__r.Name 
	 												FROM Partner_Alert_Filters__r)
	 							  				FROM Partner_Alert__c
	 							  				WHERE Active__c = true
	 							  				ORDER BY Importance__c DESC, Date__c ASC]){
	 		for (Partner_Alert_Filter__c alertFilter : partnerAlert.Partner_Alert_Filters__r) {
	 			if(alertFilter.Partner__r.Id == partnerKey) {
	 				alertList.add(partnerAlert);
	 			}
	 		}
	 	}
	 	return alertList;   	    
	}

	@AuraEnabled 
	public static Partner_Alert__c getPartnerAlert (String alertId) {
		System.debug('Begin the getPartnerAlert method');
		List<Partner_Alert__c> alertList = new List<Partner_Alert__c>();
	 	Partner_Alert__c partnerAlert = [SELECT Id, Name, Body__c, Date__c
 							  				FROM Partner_Alert__c
 							  				WHERE Id = : alertId];	 	
	 	return partnerAlert;   	    
	}

}