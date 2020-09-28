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
        openTestCase.Sub_Category__c = 'No Match';
        Case closedTestCase = new CaseFactory().getCase('Customer_Care');
        closedTestCase.Lead_Lookup__c = lead.Id;
        closedTestCase.Status = 'Closed';
        insert openTestCase;
        insert closedTestCase;

        System.assertEquals(1, new CaseSelector().selectOpenNoMatchCasesFromLead(lead).size(), 'Only open no match cases should show up in results. ' +
            'The result should be the 1 open case that was added.');
    }
}