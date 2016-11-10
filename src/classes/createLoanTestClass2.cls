@isTest
private class createLoanTestClass2{

Static testMethod void createLoanHandler(){

// Lead Convert

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
        newLead.DOER_Solar_Loan__c = TRUE;
        newlead.Technical_Approval_Verified__c = TRUE;
        newlead.Income_Verified__c = TRUE;
        newlead.Is_there_a_Partner_Record__c = TRUE;
        insert newLead;   
        
        
        newLead.Unfinished_Lead__c = TRUE;
        update newLead;
        
        newLead.Status = 'Qualified';
        newLead.Unfinished_Lead__c = FALSE;
        update newLead;
        
           database.leadConvert lc = new database.leadConvert();
               lc.setLeadId(newLead.id);
 
               leadStatus convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1];
               lc.setConvertedStatus(convertStatus.MasterLabel);
 
               Database.LeadConvertResult lcr = Database.convertLead(lc);
               System.assert(lcr.isSuccess());
 
               lc.setOpportunityName('Cole Swain');


// OPP to Loan


Date myDate = Date.newInstance(2015, 2, 17);
Date codDate = Date.newInstance(2015, 4, 17);
Date codDateTwo = Date.newInstance(2015, 7, 17);

Loan_Data__c capitalPool = new Loan_Data__c(
    Name = 'Avidia - Solar Loans',
    Investor__c = 'Avidia',
    Pool_Type__c = 'Revolving Credit Line',
    Total_Capital__c = 5000000);
        insert capitalPool;

Loan_Traunch__c loanTrancheMA = new Loan_Traunch__c(
    Name = 'Avidia 1',
    Tranche_Cap__c = 100000,
    Tranche_Type__c = 'Standard',
    State__c = 'MA',
    Stage__c = 'Open',
    Loan_Data__c = capitalPool.id);
        insert loanTrancheMA;

Loan_Traunch__c loanTrancheMSLP = new Loan_Traunch__c(
    Name = 'Avidia 1',
    Tranche_Cap__c = 100000,
    Tranche_Type__c = 'MSLP - Holding Tranche',
    State__c = 'MA',
    Stage__c = 'Open',
    Loan_Data__c = capitalPool.id);
        insert loanTrancheMSLP;

Loan_Traunch__c loanTrancheSC = new Loan_Traunch__c(
    Name = 'Avidia 1',
    Tranche_Cap__c = 100000,
    Tranche_Type__c = 'BlueWave - Holding Tranche',
    State__c = 'SC',
    Stage__c = 'Open',
    Loan_Data__c = capitalPool.id);
        insert loanTrancheSC;
        
           
 MCEC_Report_Data__c newpipeline = new MCEC_Report_Data__c (
     Name = 'Tester Two'     );
     
     insert newpipeline;

Opportunity newOpportunityMSLP = new Opportunity(
    Name = 'Tester', 
    Type = 'New Business', 
    CloseDate = myDate, 
    StageName='New',
    Product_line__c = 'Residential Loan',
    State_ab__c = 'MA',
    DOER_Solar_Loan__c = TRUE); 
    
insert newOpportunityMSLP;

newpipeline.Opportunity__c = newOpportunityMSLP.id;
update newpipeline;

newOpportunityMSLP.StageName = 'Complete';
update newOpportunityMSLP;
     
system.debug(newpipeline);




/*Loan__c verifyLoanMSLP = [SELECT Opportunity__r.Id FROM Loan__c WHERE Opportunity__r.Id = : newOpportunityMSLP.Id];
System.debug(verifyLoanMSLP);
Loan__c  verifyLoanSC = [SELECT Opportunity__r.Id FROM Loan__c WHERE Opportunity__r.Id = : newOpportunitySC.Id];
System.debug(verifyLoanSC);
Loan__c verifyLoanMA = [SELECT Opportunity__r.Id FROM Loan__c WHERE Opportunity__r.Id = : newOpportunityMA.Id];
System.debug(verifyLoanMA);

System.assertEquals(newOpportunityMSLP.Id, verifyLoanMSLP.Opportunity__r.Id);
System.assertEquals(newOpportunityMA.Id, verifyLoanMA.Opportunity__r.Id);
System.assertEquals(newOpportunitySC.Id, verifyLoanSC.Opportunity__r.Id);
*/
}
}