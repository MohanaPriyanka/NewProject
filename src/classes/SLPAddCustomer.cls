public without sharing class SLPAddCustomer {
 @AuraEnabled
    public static void addNewLeadRecord (Lead newLead) {
        System.debug('begin the addCustomer method');
        RecordType leadRecordType;
        String partnerId = SLPUserHelper.getPartnerId();         
        String partnerCustomId = getPartnerCustomId();
        leadRecordType = [SELECT Id FROM RecordType WHERE Name = 'BlueWave Solar Loan' AND SobjectType = 'Lead' LIMIT 1];

        String propertyString = newLead.firstName + ' ' + newLead.lastName;
        newLead.Company = propertyString;
        newLead.Partner_Lookup__c = partnerCustomId;
        newLead.Product_Line__c = 'Residential Loan';
        newLead.RecordType = leadRecordType;
        System.debug('the record type is' + newLead.RecordType);
        insert newLead;
    }
    
    @AuraEnabled
    public static List<String> getPartnerLogo() {
        User u = [Select Id, Partner_ID__c from User where Id = :UserInfo.getUserId()];
        String partnerId = SLPUserHelper.getPartnerId(); 
        if (partnerId == null || partnerId == '') {
          partnerId = SLPUserHelper.getBWCCId();
        }
        String logoId;
        StaticResource logo;
        List<String> logoList = new List<String>();

        List<Partner__c> partnerList = [SELECT Id, Name, Logo__c FROM Partner__c WHERE Id = : partnerId];
        if(partnerList.size() > 0) {    
            logoId = partnerList.get(0).Logo__c;
            logo = [SELECT Id, Name FROM StaticResource WHERE Name = : logoId];
            logoList.add(logoId);
            logoList.add(logo.Id);
        }
        return logoList;
    } 

    @AuraEnabled
    public static String getPartnerCustomId() {
        String partnerId = SLPUserHelper.getPartnerId(); 
        System.debug('partner id is ' + partnerId);
        String customPartnerId;

        if(partnerId == null) {
            partnerId = SLPUserHelper.getBWCCId();
        }
        System.debug('partner id is ' + partnerId);
        Partner__c partnerRecord = [SELECT Id, (SELECT Custom_ID__c FROM Boston_Solar_Sales_Team__r) FROM Partner__c WHERE Id = : partnerId];
        //customPartnerId = partnerRecord.Boston_Solar_Sales_Team__r.get(0).Custom_ID__c;

        System.debug(customPartnerId);
        return partnerRecord.Id;
    }
}