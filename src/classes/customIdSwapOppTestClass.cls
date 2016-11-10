@isTest
private class customIdSwapOppTestClass 
{
 
Static testMethod void customIdSwap()
{

        partner__c partner = new partner__c(name = 'Partner');
        insert partner;

        bsst__c newSalesId = new BSST__c (name = 'Cole Swain', partner__c = partner.id, custom_id__c = 'Cole 1');
        
        insert NewSalesId;  
             
        bsst__c salesIdQuery = [SELECT id FROM bsst__c WHERE name = 'Cole Swain'];
        
      

       

        lead newLead = new lead(firstName = 'Cole', lastName = 'Swain', company = 'BlueWave', status = 'contacted', custom_id__c = 'Cole 1') ;
        newLead.FirstName = 'Cole';
        newLead.LastName = 'Swain';
        newLead.Company = 'BlueWave';
        newLead.Status = 'Qualified';
        newLead.custom_id__C = 'Cole 1';
        insert newLead;    
 
        test.startTest();
        
               database.leadConvert lc = new database.leadConvert();
               lc.setLeadId(newLead.id);
 
               leadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
               lc.setConvertedStatus(convertStatus.MasterLabel);
 
               Database.LeadConvertResult lcr = Database.convertLead(lc);
               System.assert(lcr.isSuccess());
 
               lc.setOpportunityName('Cole Swain');
 
        test.stopTest();
               
               opportunity opQuery = [SELECT bs_sales_id__c, custom_id__c FROM opportunity WHERE name != null];
               system.assertEquals(salesIdQuery.id, opQuery.bs_sales_id__c);
 
 
}
}