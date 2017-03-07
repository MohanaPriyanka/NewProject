public with sharing class PartnerAlertHandler {
    
    public void OnAfterInsert(Partner_Alert__c[] newPartnerAlerts){
        createPartnerAlertFilters(newPartnerAlerts);
    }

    public string createPartnerAlertFilters (Partner_Alert__c[] partnerAlerts){
        Date today = Date.today();
        List<Partner_Alert_Filter__c> partnerAlertFilterList = new List<Partner_Alert_Filter__c>();
        for (Partner__c partner : [SELECT Id, Name FROM Partner__c WHERE Products__c INCLUDES ('Residential Loan')]) {
            for (Partner_Alert__c partnerAlert : partnerAlerts) {
                Partner_Alert_Filter__c alertFilter = new Partner_Alert_Filter__c(
                Partner_Alert__c = partnerAlert.Id,
                Partner__c = partner.Id,
                Name = partner.name + ' - ' + partnerAlert.Name + ' - ' + today);
                partnerAlertFilterList.add(alertFilter);                
            }
        }    

//global with sharing class PartnerAlertHandler {
//    webservice static string PartnerAlertHandler (String partnerAlertId){
//    	Date today = Date.today();
//    	List<Partner_Alert_Filter__c> partnerAlertFilterList = new List<Partner_Alert_Filter__c>();
//    	for (Partner__c partner : [SELECT Id, Name FROM Partner__c WHERE Products__c INCLUDES ('Residential Loan')]) {
//    		Partner_Alert_Filter__c alertFilter = new Partner_Alert_Filter__c(
//    			Partner_Alert__c = partnerAlertId,
//    			Partner__c = partner.Id,
//    			Name = partner.name + ' - ' + partnerAlertId + ' - ' + today);
//    		partnerAlertFilterList.add(alertFilter);
//    	}
    	insert partnerAlertFilterList;
    	return 'Success';	
    }   
}