@isTest
public with sharing class CAPControllerTest {
    @testSetup static void setupTestData(){
        LoanTestRecordWarehouse.partnerSetup();
        insert LoanTestRecordWarehouse.getLoanProductsVariableInterestRatesandTerms();
    }

    @isTest static void testAddNewLeadRecord() {
        Product2 p = [SELECT Id FROM Product2 WHERE IsActive = TRUE LIMIT 1];
        Partner__c partner = [SELECT Id FROM Partner__c WHERE Name = 'Bluewave Inside Sales' LIMIT 1];
        BSST__c salesRep = [SELECT Id FROM BSST__c WHERE Name = 'BlueWave User' LIMIT 1];
        Lead l = new Lead(FirstName = 'Tester',
                          LastName = 'Testcase',
                          Company = 'Test',
                          Product__c = p.Id,
                          Email = 'test@tester.com',
                          LASERCA__Home_State__c = 'MA',
                          Requested_Loan_Amount__c = 3500,
                          Partner_Lookup__c = partner.Id,
                          Bs_Sales_ID__c = salesRep.Id);
        insert l;
        Test.startTest();
        System.assertEquals(null, CAPController.getLead(l.id, 'foo'));
        System.assertEquals('Tester', CAPController.getLead(l.id, 'test@tester.com').FirstName);
        Test.stopTest();
    }
}
