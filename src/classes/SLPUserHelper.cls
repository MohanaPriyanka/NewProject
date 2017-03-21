public without sharing class SLPUserHelper {
    private static String partnerIdVar;

    @AuraEnabled 
    public static String getPartnerId() {
        if (partnerIdVar == null) {
            // The saved Partner ID isn't set... set it
            User u = [SELECT Id, Partner_Id__c, Contact.Partner_Lookup__c 
                      FROM User 
                      WHERE Id = :UserInfo.getUserId()];
            if (u.Partner_Id__c == null) {
                // No Partner ID for this internal user, use the BWCC user's Partner ID instead
                partnerIdVar = getBWCCId();
            } else {
                // Needs to be 15 characters since that's what is used in the Partner field on the Contact record?
                partnerIdVar = String.valueOf(u.Partner_Id__c).subString(0,15);
            }
        }

        return partnerIdVar;
    }

    @AuraEnabled 
        
    // Get the BlueWave Customer Care Partner Id, or if that doesn't exist, another test Partner to use
    public static String getBWCCId() {
        Partner__c partnerRecord;
        Partner__c[] partnerRecords = [SELECT Id FROM Partner__c WHERE Name = 'BlueWave Customer Care'];
        if (partnerRecords.size() > 0) {
            partnerRecord = partnerRecords[0];
        } else {
            partnerRecord = [SELECT Id FROM Partner__c 
                             WHERE Name like 'BlueWave%' or Name like '%Testcase%' LIMIT 1];
        }
        return(String.valueOf(partnerRecord.Id).subString(0,15));
    }

    @AuraEnabled
        public static List<String> getPartnerLogo() {
        Partner__c partner;
        List<String> logoList = new List<String>();

        partner = [SELECT Id, Name, Logo__c FROM Partner__c WHERE Id = : getPartnerId()];
        logoList.add(partner.Logo__c);
        return logoList;
    }	

    @AuraEnabled
    public static List<Partner_Alert__c> getPartnerAlerts() {
        System.debug('Begin the getPartnerAlerts method');
        List<Partner_Alert__c> partnerAlertList = new List<Partner_Alert__c>();
        String partnerId = SLPUserHelper.getPartnerId();
        if (partnerId == null || partnerId == '') {
          partnerId = SLPUserHelper.getBWCCId();
        }        
        Date today = Date.today();
        for (Partner_Alert__c partnerAlert : [SELECT Id, Name, Body__c, Importance__c, Active__c, Date__c,
                                                (SELECT Id, Partner__r.Name, Partner__r.Id, Partner_Alert__r.Name
                                                 FROM Partner_Alert_Filters__r
                                                 WHERE Acknowledged__c != true
                                                 AND (Date_of_Reminder__c <= : today 
                                                 OR Date_of_Reminder__c = null))
                                               FROM Partner_Alert__c]){
            for (Partner_Alert_Filter__c partnerFilter : partnerAlert.Partner_Alert_Filters__r) {
                if (partnerFilter.Partner__r.Id == partnerId) { //adjust to fit all partners
                    partnerAlertList.add(partnerAlert);
                }
            }
        }
        return partnerAlertList;
    }

    @AuraEnabled
    public static void acknowledgePartnerAlert(String partnerAlertId) {
        System.debug('Begin the acknowledgePartnerAlert method');
        List<Partner_Alert_Filter__c> partnerAlertFilterList = new List<Partner_Alert_Filter__c>();   
        String partnerId = SLPUserHelper.getPartnerId();
        if (partnerId == null || partnerId == '') {
          partnerId = SLPUserHelper.getBWCCId();
        }        
        for (Partner_Alert__c partnerAlert : [SELECT Id, (SELECT Id, Acknowledged__c, Partner__r.Name FROM Partner_Alert_Filters__r   ) 
                                         FROM Partner_Alert__c 
                                         WHERE Id = : partnerAlertId
                                         ORDER BY Importance__c ASC, createdDate DESC
                                         LIMIT 1]){
            for (Partner_Alert_Filter__c partnerAlertFilter : partnerAlert.Partner_Alert_Filters__r ) {
                if(partnerAlertFilter.Partner__r.Id == partnerId) {
                    partnerAlertFilter.Acknowledged__c = true;
                    partnerAlertFilterList.add(partnerAlertFilter);
                }
            }
        }
        update partnerAlertFilterList;
    }

    @AuraEnabled
    public static void partnerAlertRemindLater(String partnerAlertId) {
        System.debug('Begin the partnerAlertRemindLater method');
        List<Partner_Alert_Filter__c> partnerAlertFilterList = new List<Partner_Alert_Filter__c>();   
        String partnerId = SLPUserHelper.getPartnerId();
        if (partnerId == null || partnerId == '') {
          partnerId = SLPUserHelper.getBWCCId();
        }        
        for (Partner_Alert__c partnerAlert : [SELECT Id, (SELECT Id, Acknowledged__c, Partner__r.Name FROM Partner_Alert_Filters__r   ) 
                                         FROM Partner_Alert__c 
                                         WHERE Id = : partnerAlertId
                                         ORDER BY Importance__c ASC, createdDate DESC
                                         LIMIT 1]){
            for (Partner_Alert_Filter__c partnerAlertFilter : partnerAlert.Partner_Alert_Filters__r ) {
                if (partnerAlertFilter.Partner__r.Id == partnerId) {
                    partnerAlertFilter.Remind_Later__c = Date.today();
                    partnerAlertFilterList.add(partnerAlertFilter);
                }
            }
        }
        update partnerAlertFilterList;
    }             
}