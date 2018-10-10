@IsTest
public with sharing class DocuSignHelperTest {

    @TestSetup public static void setupTestData() {
        Test.loadData(System_Properties__c.SObjectType, 'TestRLSystemProperties');
        Util.disableTrigger('Disable_LoanTrancheTrigger__c');
        Util.disableTrigger('Disable_LeadTrigger__c');
        Util.disableTrigger('Disable_ContactTrigger__c');
        Util.disableTrigger('Disable_OpportunityTrigger__c');
        Util.disableTrigger('Disable_LoanTrigger__c');

        Test.loadData(Partner__c.SObjectType, 'TestRLPartner');
        Test.loadData(BSST__c.SObjectType, 'TestRLBSST');
        Test.loadData(Loan_Data__c.SObjectType, 'TestRLLoanData');
        Test.loadData(Loan_Traunch__c.SObjectType, 'TestRLLoanTraunch');
        Test.loadData(Product2.SObjectType, 'TestRLProduct');
        Test.loadData(Account.SObjectType, 'TestRLAccount');
        Test.loadData(Contact.SObjectType, 'TestRLContact');
        List<Opportunity> opportunities =
            Test.loadData(Opportunity.SObjectType, 'TestRLOpportunity');
        List<Lead> leads =
            Test.loadData(Lead.SObjectType, 'TestRLLead');
        List<LASERCA__Personal_Credit_Report__c> pcrs =
            Test.loadData(LASERCA__Personal_Credit_Report__c.SObjectType, 'TestRLPCR');
        Test.loadData(LASERCA__Trade_Accounts__c.SObjectType, 'TestRLTradeAccounts');
        Test.loadData(Loan__c.SObjectType, 'TestRLLoan');
        Test.loadData(Residential_Equipment__c.SObjectType, 'TestRLResidentialEquipment');
        List<Partner_Task__c> partnerTasks =
            Test.loadData(Partner_Task__c.SObjectType, 'TestRLPartnerTask');
        Test.loadData(dsfs__DocuSign_Status__c.SObjectType, 'TestRLDocuSignStatus');
        Test.loadData(dsfs__DocuSign_Recipient_Status__c.SObjectType, 'TestRLDocuSignRecipient');

        mapPCRtoLead(pcrs);
        mapPCRAndLeadToOpp(leads, pcrs, opportunities);
        setPartnerTaskParentAndUniqueId(partnerTasks);

        Util.enableTrigger('Disable_LoanTrancheTrigger__c');
        Util.enableTrigger('Disable_LeadTrigger__c');
        Util.enableTrigger('Disable_ContactTrigger__c');
        Util.enableTrigger('Disable_OpportunityTrigger__c');
        Util.enableTrigger('Disable_LoanTrigger__c');
    }

    private static void mapPCRAndLeadToOpp(List<Lead> leads, List<LASERCA__Personal_Credit_Report__c> pcrs, List<Opportunity> opportunities) {
        Map<Id, Lead> oppIdToLeadMap = new Map<Id, Lead>();
        for (Lead lead : leads) {
            if (lead.ConvertedOpportunityId != null) {
                oppIdToLeadMap.put(lead.ConvertedOpportunityId, lead);
            }
        }
        Map<Id, LASERCA__Personal_Credit_Report__c> leadToPCRMap = new Map<Id, LASERCA__Personal_Credit_Report__c>();
        for (LASERCA__Personal_Credit_Report__c pcr : pcrs) {
            leadToPCRMap.put(pcr.LASERCA__Lead__c, pcr);
        }
        for (Opportunity opp : opportunities) {
            opp.Lead__c = oppIdToLeadMap.get(opp.Id).Id;
            if (opp.Lead__c != null) {
                opp.Lead_ID__c = ((String) opp.Lead__c).left(15);
            }
            opp.Personal_Credit_Report2__c = leadToPCRMap.get(opp.Lead__c).Id;
        }
        update opportunities;
    }

    private static void setPartnerTaskParentAndUniqueId(List<Partner_Task__c> partnerTasks) {
        Map<Id, Partner_Task__c> partnerTaskMap = new Map<Id, Partner_Task__c>();
        for (Partner_Task__c task : partnerTasks) {
            partnerTaskMap.put(task.Progress_Bar_Name__c, task);
        }
        for (Partner_Task__c task : partnerTasks) {
            Id leadId = task.Lead__c;
            if (leadId == null) {
                leadId = getParentTaskLead(task, partnerTaskMap);
            }
            task.Unique_ID__c = task.Unique_ID__c.replace('LeadId', leadId);
            if (task.Comments__c != null) {
                task.Parent_Task__c = partnerTaskMap.get(task.Comments__c).Id;
            }
        }
        update partnerTasks;
    }

    private static Id getParentTaskLead(Partner_Task__c task, Map<Id, Partner_Task__c> partnerTaskMap) {
        System.assertNotEquals(null, task.Comments__c,
            'A task with no lead is a subtask, which should have a parent task Id in the Comments__c field for loading');
        Partner_Task__c parentTask = partnerTaskMap.get(task.Comments__c);
        if (parentTask.Lead__c != null) {
            return parentTask.Lead__c;
        } else {
            return getParentTaskLead(parentTask, partnerTaskMap);
        }
    }

    private static void mapPCRtoLead(List<LASERCA__Personal_Credit_Report__c> pcrs) {
        Map<Id, LASERCA__Credit_Report_Log__c> triggerNewMap = new Map<Id, LASERCA__Credit_Report_Log__c>();
        for (LASERCA__Personal_Credit_Report__c pcr : pcrs) {
            LASERCA__Credit_Report_Log__c crl = new LASERCA__Credit_Report_Log__c(
                LASERCA__Personal_Credit_Report__c = pcr.Id,
                LASERCA__Status__c = 'Completed'
            );
            triggerNewMap.put(pcr.Id, crl);
        }
        MapPCRtoLeadHandler.mapPCRtoLead(triggerNewMap, null);
    }

    static testMethod void testLoanCreationAndUpdate() {
        Opportunity opp = [
            SELECT Id, Lead__c, Contract_Status__c, Partner_Sales_Agreement_Status__c, BlueWave_Signature_Status__c,
            (SELECT Id FROM Partner_Tasks__r WHERE (Name = 'Obtain Contract Signature' OR Name = 'Provide Sales Agreement')),
            (SELECT Id, dsfs__Envelope_Status__c FROM dsfs__R00N80000002fD9vEAE__r)
            FROM Opportunity
            WHERE Lead__r.FirstName = 'Retired'
        ];
        System.debug(LoggingLevel.ERROR, 'Limit tracking: ' + Limits.getQueries() + ' of ' + Limits.getLimitQueries());
        System.assertEquals(1, opp.dsfs__R00N80000002fD9vEAE__r.size());
        System.assertEquals('Sent', opp.dsfs__R00N80000002fD9vEAE__r[0].dsfs__Envelope_Status__c);
        System.assertEquals(null, DocuSignHelper.oppsToResend);
        System.assertEquals(null, DocuSignHelper.envelopesToVoid);

        opp.Contract_Status__c = 'Completed';
        opp.Partner_Sales_Agreement_Status__c = 'Completed';
        update opp;
        opp.Partner_Tasks__r[0].Status__c = 'Complete';
        opp.Partner_Tasks__r[0].Completion_Date__c = Date.today();
        opp.Partner_Tasks__r[1].Status__c = 'Complete';
        opp.Partner_Tasks__r[1].Completion_Date__c = Date.today();
        update opp.Partner_Tasks__r;
        Test.startTest();
        Test.setMock(WebServiceMock.class, new DocuSignAPIMockImpl());
        Test.setMock(HttpCalloutMock.class, new DocuSignAPIMockImpl());

        Lead lead = new Lead(
            Id = opp.Lead__c,
            Change_Order_Status__c = 'Customer Authorized'
        );
        update lead;
        // This should void the existing package and create a new one
        Test.stopTest();
        // We can't check DocuSign_Status__c results here, because DocuSign might not have written back to Salesforce
        // yet. So Partner Task assertions is the best we can do.
        System.assertEquals(1, DocuSignHelper.oppsToResend.size());
        System.assertEquals(1, DocuSignHelper.envelopesToVoid.size());
        System.assertEquals(1, DocuSignHelper.oppLoansSent.size());

        opp = [
            SELECT Id, Contract_Status__c, Partner_Sales_Agreement_Status__c, BlueWave_Signature_Status__c,
            (SELECT Id, dsfs__Envelope_Status__c FROM dsfs__R00N80000002fD9vEAE__r),
            (SELECT Id, Status__c, Completion_Date__c FROM Partner_Tasks__r WHERE (Name = 'Obtain Contract Signature' OR Name = 'Provide Sales Agreement'))
            FROM Opportunity
            WHERE Id = :opp.Id
        ];
        System.debug(LoggingLevel.ERROR, 'Limit tracking: ' + Limits.getQueries() + ' of ' + Limits.getLimitQueries());
        System.assertEquals('Sent', opp.Contract_Status__c);
        System.assertEquals(null, opp.Partner_Sales_Agreement_Status__c);
        System.assertEquals(2, opp.Partner_Tasks__r.size());
        System.assertEquals('Pending', opp.Partner_Tasks__r[0].Status__c);
        System.assertEquals(null, opp.Partner_Tasks__r[0].Completion_Date__c);
        System.assertEquals('Pending', opp.Partner_Tasks__r[1].Status__c);
        System.assertEquals(null, opp.Partner_Tasks__r[1].Completion_Date__c);
    }

    static testMethod void testVoidFromProcessBuilder() {
        Opportunity opp = [
            SELECT Id, Lead__c, Contract_Status__c, Partner_Sales_Agreement_Status__c, BlueWave_Signature_Status__c,
            (SELECT Id FROM Partner_Tasks__r WHERE (Name = 'Obtain Contract Signature' OR Name = 'Provide Sales Agreement')),
            (SELECT Id, dsfs__Envelope_Status__c, dsfs__DocuSign_Envelope_ID__c FROM dsfs__R00N80000002fD9vEAE__r)
            FROM Opportunity
            WHERE Lead__r.FirstName = 'Retired'
        ];
        System.debug(LoggingLevel.ERROR, 'Limit tracking: ' + Limits.getQueries() + ' of ' + Limits.getLimitQueries());
        System.assertEquals(1, opp.dsfs__R00N80000002fD9vEAE__r.size());
        System.assertEquals('Sent', opp.dsfs__R00N80000002fD9vEAE__r[0].dsfs__Envelope_Status__c);
        System.assertEquals(null, DocuSignHelper.oppsToResend);
        System.assertEquals(null, DocuSignHelper.envelopesToVoid);

        opp.Contract_Status__c = 'Completed';
        opp.Partner_Sales_Agreement_Status__c = 'Completed';
        update opp;
        opp.Partner_Tasks__r[0].Status__c = 'Complete';
        opp.Partner_Tasks__r[0].Completion_Date__c = Date.today();
        opp.Partner_Tasks__r[1].Status__c = 'Complete';
        opp.Partner_Tasks__r[1].Completion_Date__c = Date.today();
        update opp.Partner_Tasks__r;
        Test.startTest();
        Test.setMock(WebServiceMock.class, new DocuSignAPIMockImpl());
        Test.setMock(HttpCalloutMock.class, new DocuSignAPIMockImpl());

        List<Error_Log__c> errors = [SELECT Id FROM Error_Log__c];
        // There shouldn't be any errors when starting
        System.assertEquals(0, errors.size());
        DocuSignVoid_Invocable.VoidRequest voidRequest = new DocuSignVoid_Invocable.VoidRequest();
        voidRequest.envelopeId = opp.dsfs__R00N80000002fD9vEAE__r[0].dsfs__DocuSign_Envelope_ID__c;
        voidRequest.reason = 'Test void reason';
        DocuSignVoid_Invocable.voidPackages(new List<DocuSignVoid_Invocable.VoidRequest>{voidRequest});
        Test.stopTest();

        // Make sure voidPackages() didn't run into any errors. Because DocuSign logs back into the instance to update
        // the void status, and that doesn't happen since it's mocked, and simulating it in the mock would be misleading
        // since the update happens in a separate transaction at a later point in time, we don't check anything else
        // except that the call was made successfully.
        errors = [SELECT Id FROM Error_Log__c];
        System.assertEquals(0, errors.size());
    }

    static testMethod void testVoidCalloutException() {
        Opportunity opp = [
            SELECT Id, Lead__c, Contract_Status__c, Partner_Sales_Agreement_Status__c, BlueWave_Signature_Status__c,
            (SELECT Id FROM Partner_Tasks__r WHERE (Name = 'Obtain Contract Signature' OR Name = 'Provide Sales Agreement')),
            (SELECT Id, dsfs__Envelope_Status__c, dsfs__DocuSign_Envelope_ID__c FROM dsfs__R00N80000002fD9vEAE__r)
            FROM Opportunity
            WHERE Lead__r.FirstName = 'Retired'
        ];

        Test.startTest();
        Test.setMock(WebServiceMock.class, new DocuSignAPIMockImpl());
        Test.setMock(HttpCalloutMock.class, new DocuSignAPIMockImpl());

        DocuSignVoid_Invocable.VoidRequest voidRequest = new DocuSignVoid_Invocable.VoidRequest();
        voidRequest.envelopeId = opp.dsfs__R00N80000002fD9vEAE__r[0].dsfs__DocuSign_Envelope_ID__c;
        voidRequest.reason = 'CalloutException';
        DocuSignVoid_Invocable.voidPackages(new List<DocuSignVoid_Invocable.VoidRequest>{voidRequest});
        Test.stopTest();

        List<Error_Log__c> errors = [SELECT Id, Method__c, Message__c FROM Error_Log__c];
        // There should be one error since the future method catches CalloutException
        System.assertEquals(1, errors.size());
        // And it should be the CalloutExcpetion message
        System.assertEquals('Callout Exception caught voiding envelope', errors[0].Message__c.left(41));
    }

    static testMethod void testVoidChildren() {
        Opportunity opp = [
            SELECT Id, Lead__c, Contract_Status__c, Partner_Sales_Agreement_Status__c, BlueWave_Signature_Status__c,
            (SELECT Id FROM Partner_Tasks__r WHERE (Name = 'Obtain Contract Signature' OR Name = 'Provide Sales Agreement')),
            (SELECT Id, dsfs__Envelope_Status__c, dsfs__DocuSign_Envelope_ID__c FROM dsfs__R00N80000002fD9vEAE__r)
            FROM Opportunity
            WHERE Lead__r.FirstName = 'Retired'
        ];

        dsfs__DocuSign_Status__c envelopeStatus = [
            SELECT Id, dsfs__Envelope_Status__c
            FROM dsfs__DocuSign_Status__c
            WHERE dsfs__DocuSign_Envelope_ID__c = : opp.dsfs__R00N80000002fD9vEAE__r[0].dsfs__DocuSign_Envelope_ID__c
            LIMIT 1
        ];

        System.assertNotEquals('Voided', envelopeStatus.dsfs__Envelope_Status__c);

        List<dsfs__DocuSign_Recipient_Status__c> recipientStatuses = [
            SELECT Id, dsfs__Recipient_Status__c
            FROM dsfs__DocuSign_Recipient_Status__c
            WHERE dsfs__Parent_Status_Record__c = : envelopeStatus.Id
        ];

        for (dsfs__DocuSign_Recipient_Status__c recipientStatus : recipientStatuses) {
            System.assertNotEquals('Voided', recipientStatus.dsfs__Recipient_Status__c);
        }

        Test.startTest();
        envelopeStatus.dsfs__Envelope_Status__c = 'Voided';

        update envelopeStatus;
        Test.stopTest();

        recipientStatuses = [
            SELECT Id, dsfs__Recipient_Status__c
            FROM dsfs__DocuSign_Recipient_Status__c
            WHERE dsfs__Parent_Status_Record__c = : envelopeStatus.Id
        ];

        for (dsfs__DocuSign_Recipient_Status__c recipientStatus : recipientStatuses) {
            System.assertEquals('Voided', recipientStatus.dsfs__Recipient_Status__c);
        }
    }
}