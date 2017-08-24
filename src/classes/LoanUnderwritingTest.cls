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
        Lead lead = [SELECT Id, Name 
                     FROM Lead 
                     WHERE FirstName = 'leadMALoanTerm20Rate699'
                     LIMIT 1];
        LoanUnderwriting.LeadWithPCRAttachments retrievedLead = LoanUnderwriting.getLead(lead.Id);
        System.assertEquals(lead.Name, retrievedLead.lead.Name);

        LASERCA__Personal_Credit_Report__c pcr = 
            LoanUnderwriting.getPCRDebt(retrievedLead.lead.Personal_Credit_Report__r.Id);
        System.assertEquals(1, pcr.LASERCA__Trade_Accounts__r.size());

        String[] avidiaReviewStatusOptions = BlueWaveParent.getpicklistFields('LASERCA__Personal_Credit_Report__c', 
                                                                              'Avidia_Review_Status__c');
        String[] creditNoticeOptions = BlueWaveParent.getpicklistFields('LASERCA__Personal_Credit_Report__c', 
                                                                        'Adverse_Credit_Notice_1__c');
    }

    static testMethod void testUpdate() {
        LASERCA__Personal_Credit_Report__c pcr = [SELECT Id, Adverse_Credit_Notice_1__c
                                                  FROM LASERCA__Personal_Credit_Report__c
                                                  WHERE Name LIKE '%Personal Credit Report 4%'
                                                  LIMIT 1];
        Test.startTest();
        System.assertEquals(null, pcr.Adverse_Credit_Notice_1__c);
        pcr.Adverse_Credit_Notice_1__c = 'Bankruptcy';
        BlueWaveParent.updateSObject(pcr);

        LASERCA__Trade_Accounts__c ta = new LASERCA__Trade_Accounts__c(Name = 'Test',
                                                                       LASERCA__Personal_Credit_Report__c = pcr.Id,
                                                                       LASERCA__Monthly_Payment__c = 100);
        BlueWaveParent.insertSObject(ta);

        pcr = [SELECT Id, Adverse_Credit_Notice_1__c
               FROM LASERCA__Personal_Credit_Report__c
               WHERE Id = :pcr.Id];
        System.assertEquals('Bankruptcy', pcr.Adverse_Credit_Notice_1__c);
        
        Lead lead = [SELECT Id, Name, Manual_Credit_Decline__c, Credit_Report_Detail_5__c
                     FROM Lead 
                     WHERE FirstName = 'leadMALoanTerm20Rate699'
                     LIMIT 1];
        System.assertEquals(false, lead.Manual_Credit_Decline__c);
        System.assertEquals(null, lead.Credit_Report_Detail_5__c);

        LoanUnderwriting.LeadWithPCRAttachments retrievedLead = LoanUnderwriting.getLead(lead.Id);
        LoanUnderwriting.updateManualCreditDecline(retrievedLead.lead, false);

        lead = [SELECT Id, Name, Manual_Credit_Decline__c, Credit_Report_Detail_5__c
                FROM Lead 
                WHERE FirstName = 'leadMALoanTerm20Rate699'
                LIMIT 1];
        System.assertEquals(true, lead.Manual_Credit_Decline__c);
        System.assertEquals('INQUIRIES IMPACTED THE CREDIT SCORE', lead.Credit_Report_Detail_5__c);
        
        List<Attachment> a = [SELECT Id, Body
                              FROM Attachment
                              WHERE ParentId = :lead.Id];
        System.assertEquals(true, a.isEmpty());
        
        Id fileId = BlueWaveParent.saveTheChunk(lead.Id, 'testfile.txt', EncodingUtil.base64Encode(Blob.valueOf( 'This is ')), 'text/plain', '');
        BlueWaveParent.saveTheChunk(lead.Id, 'testfile.txt', EncodingUtil.base64Encode(Blob.valueOf('a test')), 'text/plain', fileId);
        
        a = [SELECT Id, Body
             FROM Attachment
             WHERE ParentId = :lead.Id];
        System.assertEquals(1, a.size());
        // Couldn't test body contents here (BLOB is not a valid UTF-8 string), but works through user testing
        Test.stopTest();
    }

    static testMethod void testGetFifthFactor() {
        Test.startTest();
        System.assertEquals(null, LoanUnderwriting.getFifthDetail('039 - SERIOUS DELINQUENCY'));
        System.assertEquals(null, LoanUnderwriting.getFifthDetail(null));
        String s = 
            '039 - SERIOUS DELINQUENCY\n' +
            '014 - LENGTH OF TIME ACCOUNTS HAVE BEEN ESTABLISHED\n' +
            '027 - TOO FEW ACCOUNTS CURRENTLY PAID AS AGREED\n' +
            '003 - PROPORTION OF LOAN BALANCES TO LOAN AMOUNTS IS TOO HIGH\n' +
            'FA - INQUIRIES IMPACTED THE CREDIT SCORE\n';
        System.assertEquals('INQUIRIES IMPACTED THE CREDIT SCORE', LoanUnderwriting.getFifthDetail(s));
        Test.stopTest();
    }
}