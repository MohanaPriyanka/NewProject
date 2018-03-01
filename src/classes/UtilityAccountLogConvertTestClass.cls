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

        Product2 csProduct = new Product2( Name = 'Community Solar - SREC 16-01',
                              Family = 'Community Solar',
                              Product_Type__c = 'Community Solar',
                              State__c = 'MA',
                              ProductCode = 'CS - BlueWave - 10%',
                              IsActive = True,
                              Lender_of_Record__c = 'BlueWave',
                              NMC_Discount__c = 10,
                              Annual_kWh_Maximum__c = 100000000,
                              NM_Rate_Floor__c = 0,
                              Monthly_Late_Fee__c = 1);
        insert csProduct;

        lead newLead = new lead(firstName = 'Cole', lastName = 'Swain', company = 'BlueWave', status = 'Qualified', Parcel_Zip__c = '02052') ;
        newLead.FirstName = 'Cole';
        newLead.Product_Line__c = 'Community Solar';
        newLead.LastName = 'Swain';
        newLead.Unfinished_Lead__c = false;
        newLead.Company = 'BlueWave';
        newLead.Status = 'Qualified';
        newLead.Parcel_Zip__C = '02052';
        newLead.Product__c = csProduct.Id;
        newLead.Electricity_Provider__c = 'Eversource';
        insert newLead;   

        newLead.Status = 'Qualified';
        update newLead; 
         
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