@isTest
private class opp4LZUTriggerTestClass 
{
 
Static testMethod void validateLZU()
{
        Utility__c eversource = new Utility__c(
            Name = 'Eversource',
            Number_of_Decimal_Places__c = 2
        );

        Utility__c nationalGrid = new Utility__c(
            Name = 'National Grid',
            Number_of_Decimal_Places__c = 2
        );

        insert new List<Utility__c>{eversource, nationalGrid};

        Load_U__c newLZU = new Load_U__c ( name = '02052', LZ__c= 'NEMA', Utility_Relationship_1__c = eversource.Id, town__c = 'Medfield');
        newLZU.name = '02052';
        newLZU.LZ__C = 'NEMA';
        newLZU.Utility_Relationship_1__c = eversource.Id;
        newLZU.town__c = 'Medfield';
        insert newLZU;
        
        partner__c newPartner = new partner__c(name = 'Partner');
        insert newPartner;
        
        bsst__c newBSST = new BSST__c (name ='Cole Swain', partner__c = newPartner.id, custom_id__c = 'BWCSwain');
        Insert newBSST;

        lead newLead = new lead(firstName = 'Cole', lastName = 'Swain', company = 'BlueWave', status = 'Qualified', Parcel_Zip__c = '02052', custom_id__c = 'BWCSwain') ;

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
               
               opportunity opQuery = [SELECT name,Load_Zone_Utility_4__c FROM opportunity WHERE name != null];
               system.assertEquals(null, opQuery.Load_Zone_Utility_4__c);
 
 
}
}