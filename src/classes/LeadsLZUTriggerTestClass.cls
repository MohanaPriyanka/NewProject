@isTest
private class LeadsLZUTriggerTestClass {

    static testMethod void validateLZUL(){
        Load_U__c newLZU = new Load_U__c (Name = '02052', Load_Zone__c= 'NEMA Eversource', LZ__c = 'NEMA', Utility__c = 'Eversource', Town__c= 'Medfield');
        insert newLZU;

        Lead newLead = new Lead(FirstName = 'Cole', LastName = 'Swain', Company = 'BlueWave', Status = 'contacted', Parcel_Zip__c = '02052', Product_Line__c = 'Community Solar');
        Test.startTest();
        insert newLead;
        Test.stopTest();

        Lead leadQuery = [SELECT FirstName, LZU__C FROM Lead WHERE FirstName = 'Cole'];
        System.assertEquals('NEMA Eversource', leadQuery.LZU__C);
    }
}
