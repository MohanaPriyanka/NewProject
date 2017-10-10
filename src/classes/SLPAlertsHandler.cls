public without sharing class SLPAlertsHandler {
    public static SLPUserHelper.PartnerProfile profile = new SLPUserHelper.PartnerProfile();
    static {
        profile = SLPUserHelper.getPartnerProfile();
    }   
    @AuraEnabled 
    public static List<Partner_Alert__c> getPartnerAlerts (String partnerId) {
        List<Partner_Alert__c> alertList = new List<Partner_Alert__c>();
        for (Partner_Alert__c partnerAlert : [SELECT Id, Name, Date__c, Alert_Body__c, 
                                                    (SELECT Id, Name, Acknowledged__c, Partner__r.Name, Sales_Representative__r.Id 
                                                    FROM Partner_Alert_Filters__r)
                                                FROM Partner_Alert__c
                                                WHERE Active__c = true
                                                ORDER BY Importance__c DESC, Date__c ASC]){
            for (Partner_Alert_Filter__c alertFilter : partnerAlert.Partner_Alert_Filters__r) {
                if(alertFilter.Sales_Representative__r.Id == profile.salesRepId) {
                    alertList.add(partnerAlert);
                }
            }
        }
        return alertList;           
    }

    @AuraEnabled 
    public static Partner_Alert__c getPartnerAlert (String alertId) {
        List<Partner_Alert__c> alertList = new List<Partner_Alert__c>();
        Partner_Alert__c partnerAlert = [SELECT Id, Name, Date__c, Alert_Body__c
                                            FROM Partner_Alert__c
                                            WHERE Id = : alertId];      
        return partnerAlert;        
    }

}