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

        Loan_Data__c capitalPool = new Loan_Data__c(Name = 'Revolving Credit Line',
                                                Total_Capital__c = 10000000,
                                                Investor__c = 'The Bank',
                                                Pool_Type__c = 'Revolving Credit Line');
        insert capitalPool;

        Date myDate = Date.newInstance(2015, 2, 17);
        Date codDate = Date.newInstance(2015, 4, 17);
        Date codDateTwo = Date.newInstance(2015, 7, 17);

        Loan_Traunch__c loanTrancheMA = new Loan_Traunch__c(
            Name = 'Avidia 1',
            Tranche_Cap__c = 1000000,
            Tranche_Type__c = 'Standard',
            State__c = 'MA',
            Stage__c = 'Open',
            Loan_Data__c = capitalPool.id);
        insert loanTrancheMA;  

        Loan_Traunch__c loanTranchePending = new Loan_Traunch__c(
            Name = 'Tranche Assignment Pending',
            Tranche_Type__c = 'Holding',
            Stage__c = 'Closed',
            Loan_Data__c = capitalPool.id);
        insert loanTranchePending;                  

        partner__c partner = new partner__c(name = 'Partner');
        insert partner;

        bsst__c newSalesId = new BSST__c (name = 'Cole Swain', partner__c = partner.id, custom_id__c = 'Cole 1');
        
        insert NewSalesId;  
             
        bsst__c salesIdQuery = [SELECT id FROM Bsst__c WHERE Name = 'Cole Swain'];

        Lead newLead = new lead(FirstName = 'Retired',
                                    LastName = 'Test',
                                    Loan_Amount__c = 25000,
                                    Company = 'Cole Swain',
                                    Retired__c = true,
                                    LASERCA__Social_Security_Number__c = '000000001',
                                    Product_Line__c = 'Residential Loan',
                                    LASERCA__Home_State__c = 'MA',
                                    System_Cost__c = 25000,
                                    Unfinished_Lead__c = true,
                                    Custom_Id__c = 'test',
                                    Loan_Term__c = 120,
                                    Partner_Lookup__c = partner.Id,
                                    //Personal_Credit_Report__c = creditReportRecord.Id,
                                    Annual_Income_Currency__c = 150000,
                                    Product__c = null,
                                    Product_Program__c = 'BlueWave Solar Loan',
                                    Automatic_Product_Assignment__c = true,
                                    Pre_Approval_Form__c = TRUE,
                                    Status = 'Ready for Credit Check');
        insert newLead;
        newLead.Unfinished_Lead__c = false;
        update newLead;
        newLead.Status = 'Pending Information';
        update newLead;
        newLead.Status = 'Qualified';
        update newLead;
        
        List<Partner_Task__c> partnerTasks = [SELECT Id, Name FROM Partner_Task__c];
        System.debug('Partner tasks are ' + partnerTasks);
         
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