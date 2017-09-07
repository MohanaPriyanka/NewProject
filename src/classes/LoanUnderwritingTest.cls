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
        System.assertEquals('FA - INQUIRIES IMPACTED THE CREDIT SCORE', lead.Credit_Report_Detail_5__c);
        
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

    static testMethod void testBlueWaveParentStateConversion() {
        Test.startTest();
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Alabama'), 'AL');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Alaska'), 'AK');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Arizona'), 'AZ');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Arkansas'), 'AR');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('California'), 'CA');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Colorado'), 'CO');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Connecticut'), 'CT');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Delaware'), 'DE');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Florida'), 'FL');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Georgia'), 'GA');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Hawaii'), 'HI');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Idaho'), 'ID');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Illinois'), 'IL');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Indiana'), 'IN');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Iowa'), 'IA');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Kansas'), 'KS');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Kentucky'), 'KY');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Louisiana'), 'LA');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Maine'), 'ME');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Maryland'), 'MD');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Massachusetts'), 'MA');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Michigan'), 'MI');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Minnesota'), 'MN');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Mississippi'), 'MS');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Missouri'), 'MO');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Montana'), 'MT');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Nebraska'), 'NE');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Nevada'), 'NV');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('New Hampshire'), 'NH');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('New Jersey'), 'NJ');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('New Mexico'), 'NM');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('New York'), 'NY');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('North Carolina'), 'NC');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('North Dakota'), 'ND');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Ohio'), 'OH');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Oklahoma'), 'OK');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Oregon'), 'OR');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Pennsylvania'), 'PA');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Rhode Island'), 'RI');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('South Carolina'), 'SC');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('South Dakota'), 'SD');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Tennessee'), 'TN');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Texas'), 'TX');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Utah'), 'UT');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Vermont'), 'VT');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Virginia'), 'VA');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Washington'), 'WA');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('West Virginia'), 'WV');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Wisconsin'), 'WI');
          System.assertEquals(BlueWaveParent.convertStateToAbbreviation('Wyoming'), 'WY');
        Test.stopTest();
    }    
}