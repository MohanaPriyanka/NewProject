@isTest
private class CoApplicantConvertTestClass{
 
Static testMethod void CoApplicantConvertTestClass()
{

        Load_U__c newLZU = new Load_U__c ( name = '02052', Load_zone__c= 'NEMA Eversource', LZ__c= 'NEMA', Utility__c = 'Eversource', town__c = 'Medfield');
        newLZU.name = '02052';
        newLZU.Load_Zone__C = 'NEMA Eversource';
        newLZU.LZ__C = 'NEMA';
        newLZU.Utility__c = 'Eversource';
        newLZU.town__c = 'Medfield';
        insert newLZU;

        Date myDate = Date.newInstance(2015, 8, 30);

        loan_data__c newLoanData = new loan_data__c (name = 'Loan Data', month__c = 'August', year__c = '2015');
        insert newLoanData;

        loan_traunch__c newLoanTranche = new loan_traunch__c (loan_data__c = newLoanData.id, name = 'Loan Tranche', Tranche_Cap__c = 500000);
        insert newLoanTranche;

        loan_traunch__c newLoanTranchePending = new loan_traunch__c (loan_data__c = newLoanData.id, name = 'Tranche Assignment Pending', Tranche_Cap__c = 500000);
        insert newLoanTranchePending;  

        lead newLead = new lead(firstName = 'Cole', lastName = 'Swain', company = 'BlueWave', status = 'Qualified', Parcel_Zip__c = '02052') ;
        newLead.Product_line__c = 'Residential Loan';
        newLead.application_type__c = 'Joint';
        newLead.FirstName = 'Cole';
        newLead.LastName = 'Swain';
        newLead.Company = 'BlueWave';
        newLead.Status = 'Qualified';
        newLead.Parcel_Zip__C = '02052';
        insert newLead;    
        
        newLead.Status = 'Qualified';
        update newLead;
        
         
        account newAccount = new account(name = 'Test');
        insert newAccount; 
         
        contact newContact = new contact(  firstName = 'Cole', lastName = 'Swain', lead__c = newLead.id, account = newAccount );
        insert newContact;
 
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