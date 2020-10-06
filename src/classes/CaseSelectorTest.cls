/**
 * Created by IsraelScottGrogin on 9/23/2020.
 */
@IsTest
public with sharing class CaseSelectorTest {
    @IsTest
    public static void testSelectOpenNoMatchCasesFromLead() {

        Lead lead = new Lead(
            FirstName = 'James',
            LastName = 'Testcase',
            Company = 'Company'
        );

        insert lead;
        Case openTestCase = new CaseFactory().getCase('Customer_Care');
        openTestCase.Lead_Lookup__c = lead.Id;
        openTestCase.QC_Case_Subject__c = 'No FICO Match';
        Case closedTestCase = new CaseFactory().getCase('Customer_Care');
        closedTestCase.Lead_Lookup__c = lead.Id;
        closedTestCase.Status = 'Closed';
        insert openTestCase;
        insert closedTestCase;

        System.assertEquals(1, new CaseSelector().selectOpenNoMatchCasesFromLead(lead).size(), 'Only open no match cases should show up in results. ' +
            'The result should be the 1 open case that was added.');
    }
    @IsTest
    public static void testSelectOpenLowMatchCasesFromLead() {

        Lead lead = new Lead(
            FirstName = 'James',
            LastName = 'Testcase',
            Company = 'Company'
        );

        insert lead;
        Case openTestCase = new CaseFactory().getCase('Customer_Care');
        openTestCase.Lead_Lookup__c = lead.Id;
        openTestCase.QC_Case_Subject__c = 'Low FICO Match';
        Case closedTestCase = new CaseFactory().getCase('Customer_Care');
        closedTestCase.Lead_Lookup__c = lead.Id;
        closedTestCase.Status = 'Closed';
        insert openTestCase;
        insert closedTestCase;

        System.assertEquals(1, new CaseSelector().selectOpenLowMatchCasesFromLead(lead).size(), 'Only open low match cases should show up in results. ' +
            'The result should be the 1 open case that was added.');
    }
}