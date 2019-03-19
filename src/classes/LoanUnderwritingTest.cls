/*************************************************************************************
 * Created By: Peter Yao
 * Description: Tests LoanUnderwriting VF/Lightning App
 *************************************************************************************/
@isTest
public with sharing class LoanUnderwritingTest {
    @testSetup static void setupTestData() {
        Test.startTest();
        System_Properties__c sysProp = new System_Properties__c(Name = 'System');
        insert sysProp;
        LoanTestRecordWarehouse.getLoanLeadswithVariableFICOsandTerms();
        Test.stopTest();
    }

    static testMethod void testQueries() {
        Lead lead = [
            SELECT Id, Name
            FROM Lead
            WHERE FirstName = 'leadMALoanTerm20Rate699'
            LIMIT 1
        ];
        LoanUnderwriting.LeadWithPCRAttachments retrievedLead = LoanUnderwriting.getLead(lead.Id);
        System.assertEquals(lead.Name, retrievedLead.lead.Name);

        LASERCA__Personal_Credit_Report__c pcr =
            LoanUnderwriting.getPCRDebt(retrievedLead.lead.Personal_Credit_Report__r.Id);
        System.assertEquals(1, pcr.LASERCA__Trade_Accounts__r.size());
        System.assertEquals('Notes', pcr.Adjusted_DTI_Notes__c);

        String[] avidiaReviewStatusOptions = BlueWaveParent.getpicklistFields('LASERCA__Personal_Credit_Report__c',
            'Avidia_Review_Status__c');
        String[] creditNoticeOptions = BlueWaveParent.getpicklistFields('LASERCA__Personal_Credit_Report__c',
            'Adverse_Credit_Notice_1__c');
    }

    static testMethod void testUpdate() {
        LASERCA__Personal_Credit_Report__c pcr = [
            SELECT Id, Adverse_Credit_Notice_1__c
            FROM LASERCA__Personal_Credit_Report__c
            WHERE Name LIKE '%Personal Credit Report 4%'
            LIMIT 1
        ];
        Test.startTest();
        System.assertEquals(null, pcr.Adverse_Credit_Notice_1__c);
        pcr.Adverse_Credit_Notice_1__c = 'Bankruptcy';
        BlueWaveParent.updateSObject(pcr);

        LASERCA__Trade_Accounts__c ta = new LASERCA__Trade_Accounts__c(Name = 'Test',
            LASERCA__Personal_Credit_Report__c = pcr.Id,
            LASERCA__Monthly_Payment__c = 100);
        BlueWaveParent.insertSObject(ta);

        pcr = [
            SELECT Id, Adverse_Credit_Notice_1__c
            FROM LASERCA__Personal_Credit_Report__c
            WHERE Id = :pcr.Id
        ];
        System.assertEquals('Bankruptcy', pcr.Adverse_Credit_Notice_1__c);

        Lead lead = [
            SELECT Id, Name, Manual_Credit_Decline__c, Credit_Report_Detail_5__c
            FROM Lead
            WHERE FirstName = 'leadMALoanTerm20Rate699'
            LIMIT 1
        ];
        System.assertEquals(false, lead.Manual_Credit_Decline__c);
        System.assertEquals(null, lead.Credit_Report_Detail_5__c);

        LoanUnderwriting.LeadWithPCRAttachments retrievedLead = LoanUnderwriting.getLead(lead.Id);
        LoanUnderwriting.updateManualCreditDecline(retrievedLead.lead, false);

        lead = [
            SELECT Id, Name, Manual_Credit_Decline__c, Credit_Report_Detail_5__c
            FROM Lead
            WHERE FirstName = 'leadMALoanTerm20Rate699'
            LIMIT 1
        ];
        System.assertEquals(true, lead.Manual_Credit_Decline__c);
        System.assertEquals('FA - INQUIRIES IMPACTED THE CREDIT SCORE', lead.Credit_Report_Detail_5__c);

        List<Attachment> a = [
            SELECT Id, Body
            FROM Attachment
            WHERE ParentId = :lead.Id
        ];
        System.assertEquals(true, a.isEmpty());

        Id fileId = BlueWaveParent.saveTheChunk(lead.Id, 'testfile.txt', EncodingUtil.base64Encode(Blob.valueOf('This is ')), 'text/plain', '');
        BlueWaveParent.saveTheChunk(lead.Id, 'testfile.txt', EncodingUtil.base64Encode(Blob.valueOf('a test')), 'text/plain', fileId);

        a = [
            SELECT Id, Body
            FROM Attachment
            WHERE ParentId = :lead.Id
        ];
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

    static testMethod void testGetOFAC() {
        Lead lead = [
            SELECT Id, Name
            FROM Lead
            WHERE FirstName = 'leadMALoanTerm20Rate699'
            LIMIT 1
        ];
        LoanUnderwriting.LeadWithPCRAttachments retrievedLead = LoanUnderwriting.getLead(lead.Id);

        LASERCA__Personal_Credit_Report__c pcr =
            LoanUnderwriting.getPCRDebt(retrievedLead.lead.Personal_Credit_Report__r.Id);

        //Create OFAC
        LASERCA__Regulatory_Product__c OFAC = new LASERCA__Regulatory_Product__c(
            Name = 'Test OFAC',
            LASERCA__Personal_Credit_Report__c = pcr.Id,
            LASERCA__Result_Status_Type__c = 'Clear'
        );
        insert OFAC;

        String checkOFAC = LoanUnderwriting.getOFAC(pcr.Id);
        System.assertEquals('Clear', checkOFAC);

    }

    static testMethod void testGetRegO() {
        Test.startTest();
        Lead lead = [
            SELECT Id, Name, Avidia_Service_Provider__c, Type_of_Avidia_Service_Provider__c, Other_Bank_Executive__c
            FROM Lead
            WHERE FirstName = 'leadMALoanTerm20Rate699'
            LIMIT 1
        ];

        String checkRegO = LoanUnderwriting.getRegO(lead, false);
        System.assertEquals('Other Bank Executive', checkRegO);

        Test.stopTest();
    }

    static testMethod void testGetCoAppContact() {
        Lead lead = [SELECT Id, Name, CoApplicant_Contact__c
        FROM Lead
        WHERE FirstName = 'coApplicantLead'
        LIMIT 1];

        Contact coApp = [SELECT Id, Name FROM Contact WHERE Lead__c = :lead.Id LIMIT 1];

        //Lead didnt have CoApplicant_Contact__c populated in LoanWarehouse - would have thought this field was updated
        lead.CoApplicant_Contact__c = coApp.Id;
        update lead;

        LoanUnderwriting.LeadWithPCRAttachments retrievedLead = LoanUnderwriting.getLead(lead.Id);
        Contact checkCoApp = LoanUnderwriting.getCoAppContact(retrievedLead.lead);

        System.assertEquals('000000002', checkCoApp.LASERCA__Social_Security_Number__c);

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
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('AL'), 'Alabama');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('AK'), 'Alaska');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('AZ'), 'Arizona');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('AR'), 'Arkansas');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('CA'), 'California');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('CO'), 'Colorado');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('CT'), 'Connecticut');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('DE'), 'Delaware');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('FL'), 'Florida');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('GA'), 'Georgia');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('HI'), 'Hawaii');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('ID'), 'Idaho');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('IL'), 'Illinois');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('IN'), 'Indiana');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('IA'), 'Iowa');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('KS'), 'Kansas');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('KY'), 'Kentucky');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('LA'), 'Louisiana');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('ME'), 'Maine');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('MD'), 'Maryland');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('MA'), 'Massachusetts');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('MI'), 'Michigan');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('MN'), 'Minnesota');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('MS'), 'Mississippi');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('MO'), 'Missouri');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('MT'), 'Montana');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('NE'), 'Nebraska');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('NV'), 'Nevada');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('NH'), 'New Hampshire');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('NJ'), 'New Jersey');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('NM'), 'New Mexico');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('NY'), 'New York');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('NC'), 'North Carolina');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('ND'), 'North Dakota');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('OH'), 'Ohio');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('OK'), 'Oklahoma');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('OR'), 'Oregon');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('PA'), 'Pennsylvania');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('RI'), 'Rhode Island');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('SC'), 'South Carolina');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('SD'), 'South Dakota');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('TN'), 'Tennessee');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('TX'), 'Texas');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('UT'), 'Utah');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('VT'), 'Vermont');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('VA'), 'Virginia');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('WA'), 'Washington');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('WV'), 'West Virginia');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('WI'), 'Wisconsin');
          System.assertEquals(BlueWaveParent.convertAbbreviationToState('WY'), 'Wyoming');
        Test.stopTest();
    }

    static testMethod void testGetStates() {
        System.assertEquals(50, BlueWaveParent.getUSStates(false).size());
    }

    static testMethod void testPDFGenerationForPrimary() {
        Lead lead = [SELECT Id, Name
                     FROM Lead
                     WHERE FirstName = 'leadMALoanTerm20Rate699'
                     LIMIT 1];
        PageReference pr = Page.LoanUnderwriting;
        Test.setCurrentPage(pr);
        ApexPages.currentPage().getParameters().put('leadId', lead.Id);

        LoanUnderwriting lu = new LoanUnderwriting();
        System.assertEquals(false, lu.hasCoApp);
        System.assertEquals(710, lu.bestFICO);
        System.assertEquals(3, Math.round(lu.bestDTI));

        List<Attachment> attachments = [SELECT Id
                                        FROM Attachment
                                        WHERE ParentId = :lead.Id];
        System.assertEquals(0, attachments.size());

        LoanUnderwriting.renderPDFAndAttach(lead.Id);
        attachments = [SELECT Id
                       FROM Attachment
                       WHERE ParentId = :lead.Id];
        System.assertEquals(1, attachments.size());
    }

    static testMethod void testPDFGenerationWithCoApp() {
        Lead lead = [SELECT Id, Name
                     FROM Lead
                     WHERE FirstName = 'coApplicantLead'
                     LIMIT 1];
        LoanHandlerTestClass.convertLeads(new List<Lead>{lead});
        lead = [SELECT Id, ConvertedContactId FROM Lead WHERE Id = :lead.Id];
        PageReference pr = Page.LoanUnderwriting;
        Test.setCurrentPage(pr);
        ApexPages.currentPage().getParameters().put('leadId', lead.Id);

        Contact coApp = [SELECT Id, Name FROM Contact WHERE Lead__c = :lead.Id LIMIT 1];

        //Lead didnt have CoApplicant_Contact__c populated in LoanWarehouse - would have thought this field was updated
        lead.CoApplicant_Contact__c = coApp.Id;
        update lead;

        LoanUnderwriting lu = new LoanUnderwriting();
        System.assertEquals(true, lu.hasCoApp);
        System.assertEquals(760, lu.bestFICO);
        System.assertEquals(462, Math.round(lu.bestDTI));

        List<Attachment> attachments = [SELECT Id
                                        FROM Attachment
                                        WHERE ParentId = :lead.ConvertedContactId];
        System.assertEquals(0, attachments.size());

        LoanUnderwriting.renderPDFAndAttach(lead.Id);
        attachments = [SELECT Id
                       FROM Attachment
                       WHERE ParentId = :lead.ConvertedContactId];
        System.assertEquals(1, attachments.size());
    }

    static testMethod void testUpdateLeadAndRequestDocument() {
        Lead lead = [SELECT Id, Name, Email, CAP_Stage__c, Sales_Person_Name__c
        FROM Lead
        WHERE FirstName = 'leadMALoanTerm10Rate699'
        LIMIT 1];

        LoanHandlerTestClass.convertLeads(new List<Lead>{lead});
        CAPController.createLoanAndEquipment(lead.Id, lead.Email);
        lead = [SELECT Id, ConvertedContactId FROM Lead WHERE Id = :lead.Id];
        Map<String, Partner_Task__c> taskMap = LoanHandler.getPartnerTasks(new List<String>{
            lead.Id
        });
        Partner_Task__c provideAllDocTask = taskMap.get(lead.Id + ' Provide All Customer Information');
        Partner_Task__c provideIncomeDocTask = taskMap.get(lead.Id + ' Income Documentation');
        provideAllDocTask.Status__c = 'Complete';
        provideIncomeDocTask.Status__c = 'Complete';
        lead.CAP_Stage__c = 'NAV_Income_Doc';

        update provideAllDocTask;
        update provideIncomeDocTask;
        update lead;

        lead = [SELECT Id, Name, Email, CAP_Stage__c, ConvertedOpportunityId, Status, Sales_Person_Name__c
        FROM Lead
        WHERE FirstName = 'leadMALoanTerm10Rate699'
        LIMIT 1];

        Map<String, Partner_Task__c> preUpdatedTaskMap = LoanHandler.getPartnerTasks(new List<String>{
            lead.Id
        });
        Partner_Task__c preUpdatedProvideAllDocTask = preUpdatedTaskMap.get(lead.Id + ' Provide All Customer Information');
        Partner_Task__c preUpdatedProvideIncomeDocTask = preUpdatedTaskMap.get(lead.Id + ' Income Documentation');

        // Assert that the Partner tasks are complete and the customer has finished the application
        System.assertEquals('Complete', preUpdatedProvideAllDocTask.Status__c);
        System.assertEquals('Complete', preUpdatedProvideIncomeDocTask.Status__c);
        System.assertEquals('Qualified', lead.Status);
        System.assertEquals('NAV_Income_Doc', lead.CAP_Stage__c);

        Test.startTest();

        Test.setMock(WebServiceMock.class, new DocuSignAPIMockImpl());
        Test.setMock(HttpCalloutMock.class, new DocuSignAPIMockImpl());
        List<String> docs = new List<String>();
        docs.add('Pay Stub');
        LoanUnderwriting.updateLeadAndRequestDocument(lead, docs);

        lead = [SELECT Id, Name, Email, CAP_Stage__c, Status
        FROM Lead
        WHERE FirstName = 'leadMALoanTerm10Rate699'
        LIMIT 1];

        preUpdatedTaskMap = LoanHandler.getPartnerTasks(new List<String>{
            lead.Id
        });
        preUpdatedProvideAllDocTask = preUpdatedTaskMap.get(lead.Id + ' Provide All Customer Information');
        preUpdatedProvideIncomeDocTask = preUpdatedTaskMap.get(lead.Id + ' Income Documentation');

        // Assert that the tasks have been updated to 'Pending' and CAP Stage is now set to 'Complete
        System.assertEquals('Pending', preUpdatedProvideAllDocTask.Status__c);
        System.assertEquals('Pending', preUpdatedProvideIncomeDocTask.Status__c);
        System.assertEquals('NAV_Complete', lead.CAP_Stage__c);
        System.assertEquals('Awaiting Info Requested from Customer', lead.Status);
        Test.stopTest();
    }

    static testMethod void testSendContinueApplicationRequest() {
        Test.startTest();

        Lead lead = [SELECT Id, Name, Email, CAP_Stage__c, ConvertedOpportunityId, Status, Comments__c, Personal_Credit_Report__c
        FROM Lead
        WHERE FirstName = 'leadMALoanTerm20Rate725'
        LIMIT 1];

        System.assertEquals('Unqualified', lead.Status);

        Test.setMock(WebServiceMock.class, new DocuSignAPIMockImpl());
        Test.setMock(HttpCalloutMock.class, new DocuSignAPIMockImpl());

        LoanUnderwriting.sendContinueApplicationRequest(lead);

        lead = [SELECT Id, Name, Email, CAP_Stage__c, Status
        FROM Lead
        WHERE FirstName = 'leadMALoanTerm20Rate725'
        LIMIT 1];

        System.assertEquals('Awaiting Info Requested from Customer', lead.Status);

        Test.stopTest();
    }
}