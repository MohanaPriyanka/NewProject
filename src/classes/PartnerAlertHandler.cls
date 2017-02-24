global with sharing class PartnerAlertHandler {
    webservice static string PartnerAlertHandler (String partnerAlertId){
    	Date today = Date.today();
    	List<Partner_Alert_Filter__c> partnerAlertFilterList = new List<Partner_Alert_Filter__c>();
    	for (Partner__c partner : [SELECT Id, Name FROM Partner__c WHERE Products__c INCLUDES ('Residential Loan')]) {
    		Partner_Alert_Filter__c alertFilter = new Partner_Alert_Filter__c(
    			Partner_Alert__c = partnerAlertId,
    			Partner__c = partner.Id,
    			Name = partner.name + ' - ' + partnerAlertId + ' - ' + today);
    		partnerAlertFilterList.add(alertFilter);
    	}
    	insert partnerAlertFilterList;
    	return 'Success';	
    }   
}