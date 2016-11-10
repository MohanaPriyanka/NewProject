@isTest
private class UtilityAccountLogConvertTestClass
{
 
Static testMethod void utilityAccountLogConversion()
{

        Load_U__c newLZU = new Load_U__c ( name = '02052', Load_zone__c= 'NEMA Eversource', LZ__c= 'NEMA', Utility__c = 'Eversource', town__c = 'Medfield');
        newLZU.name = '02052';
        newLZU.Load_Zone__C = 'NEMA Eversource';
        newLZU.LZ__C = 'NEMA';
        newLZU.Utility__c = 'Eversource';
        newLZU.town__c = 'Medfield';
        insert newLZU;

        lead newLead = new lead(firstName = 'Cole', lastName = 'Swain', company = 'BlueWave', status = 'Qualified', Parcel_Zip__c = '02052') ;
        newLead.FirstName = 'Cole';
        newLead.LastName = 'Swain';
        newLead.Company = 'BlueWave';
        newLead.Status = 'Qualified';
        newLead.Parcel_Zip__C = '02052';
        insert newLead;    
         
        utility_account_log__c newUtilityAccount = new utility_account_log__c ( name = '32456', annual_cost_of_electricity__c = 1000, lead__c = newLead.id );
        insert newUtilityAccount;
 
 
        test.startTest();
        
               database.leadConvert lc = new database.leadConvert();
               lc.setLeadId(newLead.id);
 
               leadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
               lc.setConvertedStatus(convertStatus.MasterLabel);
 
               Database.LeadConvertResult lcr = Database.convertLead(lc);
               System.assert(lcr.isSuccess());
 
               lc.setOpportunityName('Cole Swain');
 
        test.stopTest();

}
}