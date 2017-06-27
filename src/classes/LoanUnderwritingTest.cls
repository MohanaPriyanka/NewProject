/*************************************************************************************
 * Created By: Peter Yao
 * Description: Tests LoanUnderwriting VF/Lightning App
 *************************************************************************************/
@isTest
public with sharing class LoanUnderwritingTest {
    @testSetup static void setupTestData() {
        System_Properties__c sysProp = new System_Properties__c(Name = 'System');
        insert sysProp;
        LoanTestRecordWarehouse.getLoanLeadswithVariableFICOsandTerms();
    }
    
    static testMethod void testQueries() {
        Lead lead = [SELECT Id, Name from Lead LIMIT 1];
        Lead retrievedLead = LoanUnderwriting.getLead(lead.Id);
        System.assertEquals(lead.Name, retrievedLead.Name);

        String[] avidiaReviewStatusOptions = LoanUnderwriting.getAvidiaReviewStatus();
        String[] slApprovalStatusOptions = LoanUnderwriting.getSLApprovalStatus();
        String[] creditNoticeOptions = LoanUnderwriting.getCreditNoticeOptions();
    }

    static testMethod void testUpdate() {
        LASERCA__Personal_Credit_Report__c pcr = [SELECT Id, Adverse_Credit_Notice_1__c
                                                  FROM LASERCA__Personal_Credit_Report__c
                                                  LIMIT 1];
        System.assertEquals(null, pcr.Adverse_Credit_Notice_1__c);
        pcr.Adverse_Credit_Notice_1__c = 'Bankruptcy';
        LoanUnderwriting.updatePCR(pcr);

        pcr = [SELECT Id, Adverse_Credit_Notice_1__c
               FROM LASERCA__Personal_Credit_Report__c
               WHERE Id = :pcr.Id];
        System.assertEquals('Bankruptcy', pcr.Adverse_Credit_Notice_1__c);
        
    }
}
