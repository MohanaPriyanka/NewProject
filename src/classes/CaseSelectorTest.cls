/**
 * Created by IsraelScottGrogin on 9/23/2020.
 */
@IsTest
public with sharing class CaseSelectorTest {
    @IsTest
    public static void testSelectOpenCasesFromLeadId(){
        Lead lead = new Lead(
        FirstName = 'FirstName',
        LastName = 'LastName',
        Company = 'Company'
        );

        insert lead;
        Case openTestCase = new CaseFactory().getCase('Customer_Care');
        openTestCase.Lead_Lookup__c = lead.Id;
        Case closedTestCase = new CaseFactory().getCase('Customer_Care');
        closedTestCase.Lead_Lookup__c = lead.Id;
        closedTestCase.Status = 'Closed';
        insert openTestCase;
        insert closedTestCase;

        System.assertEquals(1,new CaseSelector().selectOpenCasesFromLeadId(lead.Id).size(),'Only open cases should show up in results. ' +
            'The result should be the 1 open case that was added.');
    }
}