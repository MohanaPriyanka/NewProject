@isTest
private class mapDebtToIncomeTestClass {

Static testMethod void mapDebtToIncomeTest(){

lead newLead = new lead(firstName = 'Cole', lastName = 'Swain', company = 'BlueWave', status = 'contacted', annual_income_currency__c = 105000) ;

LASERCA__Personal_Credit_Report__c newPCR = new LASERCA__Personal_Credit_Report__c ( name = 'TestCase', LASERCA__Total_High_Credit__c =50000, LASERCA__Credit_Score__c= '715', LASERCA__Lead__c = newLead.id);

Insert newPCR;

test.startTest();
 
insert newLead;
 
test.stopTest();
 
lead leadQuery = [SELECT FICO_score_approval__c, Debt_Income_Status__c FROM lead WHERE firstName = 'Cole'];
 
system.assertEquals(null, leadQuery.FICO_score_approval__c);
 
 
}
}