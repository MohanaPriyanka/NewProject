@isTest
private class LeadsLZUTriggerTestClass {

    static testMethod void validateLZUL(){
        Utility__c eversource = new Utility__c(
            Name = 'Eversource',
            Number_of_Decimal_Places__c = 2
        );

        insert new List<Utility__c>{eversource};

        Load_U__c newLZU = new Load_U__c (Name = '02052', LZ__c = 'NEMA', Utility_Relationship_1__c = eversource.Id, Town__c= 'Medfield');
        insert newLZU;

        Lead newLead = new Lead(FirstName = 'Cole', LastName = 'Swain', Company = 'BlueWave', Status = 'contacted', Parcel_Zip__c = '02052', Product_Line__c = 'Community Solar');
        Test.startTest();
        insert newLead;
        Test.stopTest();

        Lead leadQuery = [SELECT FirstName, LoadZone__c FROM Lead WHERE FirstName = 'Cole'];
        System.assertEquals('NEMA', leadQuery.LoadZone__c);
    }
}