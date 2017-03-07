public without sharing class SLPUserHelper {
    private static String partnerId;

    @AuraEnabled 
    public static String getPartnerId() {
        if (partnerId == null) {
            // The saved Partner ID isn't set... set it
            User u = [SELECT Id, Partner_Id__c, Contact.Partner_Lookup__c 
                      FROM User 
                      WHERE Id = :UserInfo.getUserId()];
            if (u.Partner_Id__c == null) {
                // No Partner ID for this internal user, use the BWCC user's Partner ID instead
                partnerId = getBWCCId();
            } else {
                // Needs to be 15 characters since that's what is used in the Partner field on the Contact record?
                partnerId = String.valueOf(u.Partner_Id__c).subString(0,15);
            }
        }

        return partnerId;
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
        String logoId;
        StaticResource logo;
        List<String> logoList = new List<String>();

        partner = [SELECT Id, Name, Logo__c FROM Partner__c WHERE Id = : getPartnerId()];
        logoId = partner.Logo__c;
        logo = [SELECT Id, Name FROM StaticResource WHERE Name = : logoId];
        logoList.add(logoId);
        logoList.add(logo.Id);
        return logoList;
    }	
}