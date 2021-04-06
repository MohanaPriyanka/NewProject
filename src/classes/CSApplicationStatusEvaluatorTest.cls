/**
 * Created by PeterYao on 12/1/2020.
 */
@IsTest
private with sharing class CSApplicationStatusEvaluatorTest {

    @IsTest
    private static void systemTest() {
        Lead ssfLead = new Lead(
            FirstName = 'SSF',
            LastName = 'Test',
            Company = 'Test',
            Product_line__c = 'Community Solar'
        );
        insert ssfLead;

        Test.getEventBus().deliver();
        ssfLead = [
            SELECT Id, Partner_Application_Status__c
            FROM Lead
            WHERE Id = :ssfLead.Id
        ];
        System.assertEquals(CSApplicationStatusEvaluator.APPLICATION_STARTED, ssfLead.Partner_Application_Status__c);

        ssfLead.Application_Complete_Date__c = System.now();
        update ssfLead;
        Test.getEventBus().deliver();
        ssfLead = [
            SELECT Id, Partner_Application_Status__c
            FROM Lead
            WHERE Id = :ssfLead.Id
        ];
        System.assertEquals(CSApplicationStatusEvaluator.UNDER_REVIEW, ssfLead.Partner_Application_Status__c);

        Case qcCase = new Case(
            Lead_Lookup__c = ssfLead.Id,
            Category__c = 'QC',
            Status = 'New',
            RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Customer Care').getRecordTypeId()
        );
        insert qcCase;
        Test.getEventBus().deliver();
        ssfLead = [
            SELECT Id, Partner_Application_Status__c
            FROM Lead
            WHERE Id = :ssfLead.Id
        ];
        System.assertEquals(CSApplicationStatusEvaluator.AWAITING_CUSTOMER_INFO, ssfLead.Partner_Application_Status__c);

        qcCase.Status = 'Closed';
        qcCase.Resolution__c = 'Resolved with KB article';
        update qcCase;
        Test.getEventBus().deliver();
        ssfLead = [
            SELECT Id, Partner_Application_Status__c
            FROM Lead
            WHERE Id = :ssfLead.Id
        ];
        System.assertEquals(CSApplicationStatusEvaluator.UNDER_REVIEW, ssfLead.Partner_Application_Status__c);

        Opportunity opportunity = new Opportunity(
            Name = 'Test Opp',
            CloseDate = System.today(),
            Lead__c = ssfLead.Id,
            StageName = 'Complete'
        );
        insert opportunity;
        Test.getEventBus().deliver();
        ssfLead = [
            SELECT Id, Partner_Application_Status__c
            FROM Lead
            WHERE Id = :ssfLead.Id
        ];
        System.assertEquals(CSApplicationStatusEvaluator.COMPLETE, ssfLead.Partner_Application_Status__c);

        delete opportunity;
        Test.getEventBus().deliver();
        ssfLead = [
            SELECT Id, Partner_Application_Status__c
            FROM Lead
            WHERE Id = :ssfLead.Id
        ];
        System.assertEquals(CSApplicationStatusEvaluator.UNDER_REVIEW, ssfLead.Partner_Application_Status__c);
    }

    @IsTest
    private static void exceptionTest() {
        CSApplicationStatusEvaluator.uow = (fflib_SObjectUnitOfWork) Test.createStub(fflib_SObjectUnitOfWork.class, new MockUOW());
        Lead ssfLead = new Lead(
            FirstName = 'SSF',
            LastName = 'Test',
            Company = 'Test',
            Product_line__c = 'Community Solar'
        );
        insert ssfLead;

        Test.getEventBus().deliver();
        List<Error_Log__c> errorLogs = [
            SELECT Id, Message__c
            FROM Error_Log__c
            WHERE Class__c = 'ApplicationStatusChangeTrigger'
        ];
        System.assertEquals(1, errorLogs.size(), 'Expected the mock uow to throw on exception:' + errorLogs);
        System.assert(errorLogs[0].Message__c.contains('Test exception'), errorLogs[0].Message__c);
    }

    @IsTest
    private static void testScheduleOnLockedRow() {
        Datetime testStarted = System.now();
        useMocks();
        List<Application_Status_Change__e> applicationStatusChanges = new List<Application_Status_Change__e>{
            new Application_Status_Change__e(LeadId__c = Util.getFakeId(Lead.SObjectType))
        };
        List<CronTrigger> cronTriggers = [
            SELECT Id
            FROM CronTrigger
            WHERE CronJobDetail.Name LIKE '%ApplicationStatusChangeEvaluatorAutoSchedule%'
            AND CreatedDate >= :testStarted
        ];
        System.assertEquals(0, cronTriggers.size(),
            'There should be no ApplicationStatusChangeEvaluatorAutoSchedule jobs created since this test started, but got: ' + cronTriggers);
        Test.startTest();
        CSApplicationStatusEvaluator evaluator = new CSApplicationStatusEvaluator(applicationStatusChanges);
        evaluator.updatePartnerApplicationStatus();

        cronTriggers = [
            SELECT Id
            FROM CronTrigger
            WHERE CronJobDetail.Name LIKE '%ApplicationStatusChangeEvaluatorAutoSchedule%'
            AND CreatedDate >= :testStarted
        ];
        System.assertEquals(1, cronTriggers.size(), 'Should have scheduled the evaluator since the mock threw a Record Currently Unavailable exception');
        System.assert(cronTriggers[0].CronJobDetail.Name.contains('ApplicationStatusChangeEvaluatorAutoSchedule'), 'Cron trigger name should contain auto schedule: ' + cronTriggers[0].CronJobDetail.Name);
        Test.stopTest();
        cronTriggers = [
            SELECT Id, CronJobDetail.Name
            FROM CronTrigger
            WHERE CronJobDetail.Name = '%ApplicationStatusChangeEvaluatorAutoSchedule%'
            AND CreatedDate >= :testStarted
            AND Id != :cronTriggers[0].Id
        ];
        System.assertEquals(1, cronTriggers.size(), 'Expected the evaluator to schedule a new job if the record is still unavailable');
    }

    @IsTest
    private static void testStatusEvaluation() {
        CSApplicationStatusEvaluator evaluator = new CSApplicationStatusEvaluator(null);
        evaluator.oppIdToCaseMap = MultiMap.newListInstance();

        // Application Started Tests
        Lead lead = getLead(new LeadParams('{"status":"New"}'));
        System.assertEquals(CSApplicationStatusEvaluator.APPLICATION_STARTED, evaluator.registerStatusUpdate(lead).Partner_Application_Status__c,
            'Expected a lead with no cases or opps to be assigned Application Started: ' + JSON.serialize(lead));

        // Under Review Tests
        lead = getLead(new LeadParams('{"status":"New","applicationCompleteDate":"2020-12-02T16:24:36.525Z"}'));
        System.assertEquals(CSApplicationStatusEvaluator.UNDER_REVIEW, evaluator.registerStatusUpdate(lead).Partner_Application_Status__c,
            'Expected a lead with an Application Complete date to be assigned Under Review: ' + JSON.serialize(lead));

        lead = getLead(new LeadParams('{"status":"New","applicationCompleteDate":"2020-12-02T16:24:36.525Z","openQCCases":0,"completeOpps":1,"inprocessOpps":2}'));
        System.assertEquals(CSApplicationStatusEvaluator.UNDER_REVIEW, evaluator.registerStatusUpdate(lead).Partner_Application_Status__c,
            'Expected a lead with a incomplete opps to be assigned Under Review if there are no open QC cases: ' + JSON.serialize(lead));

        // Awaiting Customer Information tests
        lead = getLead(new LeadParams('{"status":"New","applicationCompleteDate":"2020-12-02T16:24:36.525Z","openQCCases":1}'));
        System.assertEquals(CSApplicationStatusEvaluator.AWAITING_CUSTOMER_INFO, evaluator.registerStatusUpdate(lead).Partner_Application_Status__c,
            'Expected a lead with an open QC case to be assigned Awaiting Customer Information: ' + JSON.serialize(lead));

        lead = getLead(new LeadParams('{"status":"New","applicationCompleteDate":"2020-12-02T16:24:36.525Z","inprocessOpps":1}'));
        evaluator.oppIdToCaseMap.putValue(lead.Opportunities__r[0].Id, new Case(Category__c = 'QC', Status = 'New'));
        System.assertEquals(CSApplicationStatusEvaluator.AWAITING_CUSTOMER_INFO, evaluator.registerStatusUpdate(lead).Partner_Application_Status__c,
            'Expected a lead with an open QC case to be assigned Awaiting Customer Information if there is a case on the Opportunity: ' + JSON.serialize(lead));
        evaluator.oppIdToCaseMap.remove(lead.Opportunities__r[0].Id);

        lead = getLead(new LeadParams('{"status":"Unqualified","openQCCases":1}'));
        System.assertEquals(CSApplicationStatusEvaluator.AWAITING_CUSTOMER_INFO, evaluator.registerStatusUpdate(lead).Partner_Application_Status__c,
            'Expected a lead with an open QC case and Unqualified to be Awaiting Customer Info: ' + JSON.serialize(lead));

        // Expired/Unqualified tests
        lead = getLead(new LeadParams('{"status":"Unqualified"}'));
        System.assertEquals(CSApplicationStatusEvaluator.EXPIRED_UNQUALIFIED, evaluator.registerStatusUpdate(lead).Partner_Application_Status__c,
            'Expected a lead with an unqualified status to be assigned Unqualified: ' + JSON.serialize(lead));

        lead = getLead(new LeadParams('{"status":"Unqualified","applicationCompleteDate":"2020-12-02T16:24:36.525Z"}'));
        System.assertEquals(CSApplicationStatusEvaluator.EXPIRED_UNQUALIFIED, evaluator.registerStatusUpdate(lead).Partner_Application_Status__c,
            'Expected a lead with an unqualified status to be assigned Unqualified even if Application Complete: ' + JSON.serialize(lead));

        lead = getLead(new LeadParams('{"status":"Qualified","applicationCompleteDate":"2020-12-02T16:24:36.525Z","deadOpps":1}'));
        System.assertEquals(CSApplicationStatusEvaluator.EXPIRED_UNQUALIFIED, evaluator.registerStatusUpdate(lead).Partner_Application_Status__c,
            'Expected a lead with all lost opps to be assigned Unqualified: ' + JSON.serialize(lead));

        // Complete tests
        lead = getLead(new LeadParams('{"status":"New","applicationCompleteDate":"2020-12-02T16:24:36.525Z","openQCCases":1,"completeOpps":1}'));
        System.assertEquals(CSApplicationStatusEvaluator.COMPLETE, evaluator.registerStatusUpdate(lead).Partner_Application_Status__c,
            'Expected a lead with a complete opp to be assigned Complete even if there is an open QC case: ' + JSON.serialize(lead));

        lead = getLead(new LeadParams('{"status":"New","applicationCompleteDate":"2020-12-02T16:24:36.525Z","openQCCases":1,"completeOpps":1}'));
        System.assertEquals(CSApplicationStatusEvaluator.COMPLETE, evaluator.registerStatusUpdate(lead).Partner_Application_Status__c,
            'Expected a lead with a complete opp to be assigned Complete even if there is an open QC case: ' + JSON.serialize(lead));

    }

    @IsTest
    private static void testPublisherErrorLogging() {
        List<Error_Log__c> errorLogs = [SELECT Id FROM Error_Log__c WHERE Class__c = 'CSApplicationStatusEvaluator'];
        System.assertEquals(0, errorLogs.size(), 'Expected no error logs to start');
        Database.SaveResult sr = (Database.SaveResult)
            JSON.deserialize('{' +
                '"success":false,' +
                '"errors":[{"message":"The number of published platform event messages exceeded the hourly publishing limit or the test limit for event messages published from an Apex test context.","statusCode":"LIMIT_EXCEEDED"}' +
                ']}', Database.SaveResult.class);
        List<Application_Status_Change__e> applicationStatusChanges = new List<Application_Status_Change__e>();
        CSApplicationStatusEventPublisher.logErrors(new List<Database.SaveResult>{sr}, applicationStatusChanges);
        errorLogs = [SELECT Id, Message__c FROM Error_Log__c WHERE Class__c = 'CSApplicationStatusEvaluator'];
        System.assertEquals(1, errorLogs.size(), 'Expected to log the save result');
        System.assert(errorLogs[0].Message__c.contains('exceeded the hourly publishing limit'), 'Should have included the error message, but got this: ' + errorLogs);
    }

    private class LeadParams {
        String status;
        String partnerApplicationStatus;
        Datetime applicationCompleteDate;
        Integer openQCCases;
        Integer closedQCCases;
        Integer completeOpps;
        Integer inProcessOpps;
        Integer deadOpps;
        private LeadParams(String json) {
            LeadParams params = (LeadParams) System.JSON.deserialize(json, LeadParams.class);
            this.status = params.status;
            this.partnerApplicationStatus = params.partnerApplicationStatus;
            this.applicationCompleteDate = params.applicationCompleteDate;
            this.openQCCases = Util.nullToZero(params.openQCCases).intValue();
            this.closedQCCases = Util.nullToZero(params.closedQCCases).intValue();
            this.completeOpps = Util.nullToZero(params.completeOpps).intValue();
            this.inProcessOpps = Util.nullToZero(params.inProcessOpps).intValue();
            this.deadOpps = Util.nullToZero(params.deadOpps).intValue();
        }
    }

    private static Lead getLead(LeadParams param) {
        Id leadId = Util.getFakeId(Lead.SObjectType);
        Id maxCaseId = Util.getFakeId(Case.SObjectType);
        Id maxOppId = Util.getFakeId(Opportunity.SObjectType);
        List<sfab_FabricatedSObject> fabbedCases = new List<sfab_FabricatedSObject>();
        List<sfab_FabricatedSObject> fabbedOpps = new List<sfab_FabricatedSObject>();

        sfab_FabricatedSObject fabbedLead = new sfab_FabricatedSObject(Lead.class);
        fabbedLead.setField(Lead.Id, leadId);
        fabbedLead.setField(Lead.Status, param.status);
        fabbedLead.setField(Lead.Partner_Application_Status__c, param.partnerApplicationStatus);
        fabbedLead.setField(Lead.Application_Complete_Date__c, param.applicationCompleteDate);
        fabbedLead.setChildren('Cases__r', fabbedCases);
        fabbedLead.setChildren('Opportunities__r', fabbedOpps);

        for (Integer i = 0; i < param.openQCCases; i++) {
            fabbedCases.add(getQCCaseOnLead(maxCaseId, leadId, 'New'));
            maxCaseId = Util.incrementFakeId(maxCaseId);
        }

        for (Integer i = 0; i < param.closedQCCases; i++) {
            fabbedCases.add(getQCCaseOnLead(maxCaseId, leadId, 'Closed'));
            maxCaseId = Util.incrementFakeId(maxCaseId);
        }

        for (Integer i = 0; i < param.completeOpps; i++) {
            fabbedOpps.add(getOppportunityForLead(maxOppId, leadId, 'Complete'));
            maxOppId = Util.incrementFakeId(maxOppId);
        }

        for (Integer i = 0; i < param.inProcessOpps; i++) {
            fabbedOpps.add(getOppportunityForLead(maxOppId, leadId, 'Pending Quality Control Signature'));
            maxOppId = Util.incrementFakeId(maxOppId);
        }

        for (Integer i = 0; i < param.deadOpps; i++) {
            fabbedOpps.add(getOppportunityForLead(maxOppId, leadId, 'Expired'));
            maxOppId = Util.incrementFakeId(maxOppId);
        }

        return (Lead) fabbedLead.toSObject();
    }
    
    private static sfab_FabricatedSObject getQCCaseOnLead(Id caseId, Id leadId, String status) {
        sfab_FabricatedSObject fabbedCase = new sfab_FabricatedSObject(Case.class);
        fabbedCase.setField(Case.Id, caseId);
        fabbedCase.setField(Case.Status, status);
        fabbedCase.setField(Case.IsClosed, status=='Closed'?true:false);
        fabbedCase.setField(Case.Category__c, 'QC');
        fabbedCase.setField(Case.Lead_Lookup__c, leadId);
        return fabbedCase;
    }

    private static sfab_FabricatedSObject getOppportunityForLead(Id oppId, Id leadId, String stageName) {
        sfab_FabricatedSObject fabbedOpportunity = new sfab_FabricatedSObject(Opportunity.class);
        fabbedOpportunity.setField(Opportunity.Id, oppId);
        fabbedOpportunity.setField(Opportunity.Lead__c, leadId);
        fabbedOpportunity.setField(Opportunity.StageName, stageName);
        return fabbedOpportunity;
    }

    @TestVisible
    private class MockUOW extends MockProvider {
        public override Object handleMethodCall(MethodCall methodCall) {
            throw new Util.BWException('Test exception');
        }
    }


    /*************
      *** MOCKS ***
      *************/
    public static void useMocks() {
        CSApplicationStatusEvaluator.leadSelector = (LeadSelector) Test.createStub(LeadSelector.class, new MockedLeadSelector());
    }

    public class MockedLeadSelector extends MockProvider {
        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'getLeadsForPartnerApplicationStatus' {
                    throw new QueryException('Record Currently Unavailable');
                }
            }
            return null;
        }
    }

}