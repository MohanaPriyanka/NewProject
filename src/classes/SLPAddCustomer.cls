public class SLPAddCustomer {
 @AuraEnabled
    public static void addNewLeadRecord (Lead newLead) {
        System.debug('begin the addCustomer method');

        User u = [SELECT Id, Partner_ID__c FROM User WHERE Id = :UserInfo.getUserId()];
        String propertyString = newLead.firstName + ' ' + newLead.lastName;
        newLead.Company = propertyString;
        newLead.Custom_ID__c = 'BWCCSwain';
        newLead.Product_Line__c = 'Residential Loan';

        //Lead newLead = new Lead(
        //	FirstName = firstName,
        //	LastName = lastName,
        //	Company = propertyString,
        //	LASERCA__Home_Address__c = street,
        //	LASERCA__Home_City__c = state,
        //	LASERCA__Home_State__c = city,
        //	LASERCA__Home_Zip__c = zip,
        //	Email = email,
        //	LASERCA__Social_Security_Number__c = ssn);
        insert newLead;
        //String firstName, String lastName, String street, String state, String city, String zip, String email, String ssn
    }
    
}