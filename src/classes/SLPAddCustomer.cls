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
    
}