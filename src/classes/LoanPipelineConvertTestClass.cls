@isTest
private class LoanPipelineConvertTestClass
{
 
Static testMethod void loanPipeLineConvert ()
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
        
        newLead.Status = 'Qualified';
        update newLead;
         
        MCEC_Report_Data__c newPipeLine = new MCEC_Report_Data__c ( name = 'Test', lead__c = newLead.id );
        insert newPipeLine;
 
 
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