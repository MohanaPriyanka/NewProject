@isTest
private class createLoanTestClass{

Static testMethod void createLoanHandler(){

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

Opportunity newOpportunityMA = new Opportunity(
    Name = 'Tester', 
    Type = 'New Business', 
    CloseDate = myDate, 
    StageName='Complete',
    Product_line__c = 'Residential Loan',
    State_ab__c = 'MA'); 

Opportunity newOpportunitySC = new Opportunity(
    Name = 'Tester', 
    Type = 'New Business', 
    CloseDate = myDate, 
    StageName='Complete',
    Product_line__c = 'Residential Loan',
    State_ab__c = 'SC'); 

Opportunity newOpportunityMSLP = new Opportunity(
    Name = 'Tester', 
    Type = 'New Business', 
    CloseDate = myDate, 
    StageName='Complete',
    Product_line__c = 'Residential Loan',
    State_ab__c = 'MA',
    DOER_Solar_Loan__c = TRUE); 

Test.startTest();
insert newOpportunityMA;
insert newOpportunitySC;
insert newOpportunityMSLP;
update newOpportunityMA;
update newOpportunitySC;
update newOpportunityMSLP;
Test.stopTest();

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