public class SLPAddCustomer {
 @AuraEnabled
    public static void addNewLeadRecord (Lead newLead) {
        System.debug('begin the addCustomer method');
        RecordType leadRecordType;
        User u = [SELECT Id, Partner_ID__c FROM User WHERE Id = :UserInfo.getUserId()];
        leadRecordType = [SELECT Id FROM RecordType WHERE Name = 'BlueWave Solar Loan' AND SobjectType = 'Lead' LIMIT 1];

        String propertyString = newLead.firstName + ' ' + newLead.lastName;
        newLead.Company = propertyString;
        newLead.Custom_ID__c = 'BWCCSwain';
        newLead.Product_Line__c = 'Residential Loan';
        newLead.RecordType = leadRecordType;
        System.debug('the record type is' + newLead.RecordType);
        insert newLead;
    }
    
    @AuraEnabled
    public static List<String> getPartnerLogo() {
        User u = [Select Id, Partner_ID__c from User where Id = :UserInfo.getUserId()];
        Partner__c partner;
        String logoId;
        StaticResource logo;
        List<String> logoList = new List<String>();

        partner = [SELECT Id, Name, Logo__c FROM Partner__c WHERE Name = 'BlueWave Customer Care'];
        logoId = partner.Logo__c;
        logo = [SELECT Id, Name FROM StaticResource WHERE Name = : logoId];
        logoList.add(logoId);
        logoList.add(logo.Id);
        return logoList;
    }      
    
}