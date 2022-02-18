/**
 * @description Per W-021018, updates Lead.Partner_Application_Status__c field to:
 *   - Application Started
 *   - Under Review
 *   - Awaiting Customer Information
 *   - Expired/Unqualified
 *   - Complete
 *  Tested By: CSApplicationStatusEvaluatorTest
 */

public without sharing class CSApplicationStatusEvaluator implements Schedulable {
    @TestVisible private static final String APPLICATION_STARTED = 'Application Started';
    @TestVisible private static final String UNDER_REVIEW = 'Under Review';
    @TestVisible private static final String AWAITING_CUSTOMER_INFO = 'Awaiting Information Requested';
    @TestVisible private static final String EXPIRED_UNQUALIFIED = 'Expired/Unqualified';
    @TestVisible private static final String COMPLETE = 'Complete';
    private static final List<String> UNQUALIFIED_LEAD_STATUSES = new List<String>{'Unqualified', 'No Response', 'Lost', 'Expired'};

    private static CaseSelector caseSelector = new CaseSelector();
    @TestVisible private static LeadSelector leadSelector = new LeadSelector();
    private static OpportunitiesSelector opportunitySelector = new OpportunitiesSelector();
    private List<Application_Status_Change__e> applicationStatusChanges;
    private List<Lead> leadsToEvaluate;
    @TestVisible private MultiMap oppIdToCaseMap;
    @TestVisible private static fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
        new List<Schema.SObjectType> {
            Lead.SObjectType
        }
    );

    /**
     * @description Constructor, just saving the list of events to evaluate
     * @param applicationStatusChanges The list to evaluate
     */
    public CSApplicationStatusEvaluator(List<Application_Status_Change__e> applicationStatusChanges) {
        this.applicationStatusChanges = applicationStatusChanges;
    }

    private void getLeadsToEvaluateFromEvents() {
        Set<Id> eventLeadIds = new Set<Id>();
        Set<Id> eventCaseIds = new Set<Id>();
        Set<Id> eventOppIds = new Set<Id>();
        for (Application_Status_Change__e applicationStatusChange : applicationStatusChanges) {
            eventLeadIds.add(applicationStatusChange.LeadId__c);
            eventCaseIds.add(applicationStatusChange.CaseId__c);
            eventOppIds.add(applicationStatusChange.OpportunityId__c);
        }
        List<Case> eventCases = caseSelector.selectForPartnerApplicationStatusEvaluation(eventCaseIds);
        for (Case eventCase : eventCases) {
            eventLeadIds.add(eventCase.Lead_Lookup__c);
            eventLeadIds.add(eventCase.Related_Opportunity__r.Lead__c);
        }
        List<Opportunity> eventOpportunities = OpportunitiesSelector.selectByIds(new List<Id>(eventOppIds));
        for (Opportunity eventOpp : eventOpportunities) {
            eventLeadIds.add(eventOpp.Lead__c);
        }
        leadsToEvaluate = leadSelector.getLeadsForPartnerApplicationStatus(eventLeadIds);
    }

    private void getQCCasesRelatedToLeadsViaOpportunity() {
        List<Opportunity> leadOpportunities = new List<Opportunity>();
        for (Lead lead : leadsToEvaluate) {
            leadOpportunities.addAll(lead.Opportunities__r);
        }

        oppIdToCaseMap = opportunitySelector.getOpportunitiesWithOpenQCCases(CollectionUtil.getIdSet(leadOpportunities));
    }

    /**
     * @description If necessary, updates each of the leads that were found during initialization
     */
    public void updatePartnerApplicationStatus() {
        try {
            getLeadsToEvaluateFromEvents();
            getQCCasesRelatedToLeadsViaOpportunity();
        } catch (Exception e) {
            if (e.getMessage().contains('Record Currently Unavailable') || e.getMessage().contains('UNABLE_TO_LOCK_ROW')) {
                Datetime now = Datetime.now().addMinutes(2);
                String cron = '0 '+ now.minute() + ' ' + now.hour() + ' ' + now.day() + ' ' + now.month() + ' ? ' + now.year();
                Logger.logNow(
                    'CSApplicationStatusEvaluator',
                    'updatePartnerApplicationStatus',
                    'Retrying in 2 minutes ('+ now.getTime() +') because of:\n' + e.getMessage() + '\n' + JSON.serialize(applicationStatusChanges),
                    Logger.WARN
                );
                System.schedule('ApplicationStatusChangeEvaluatorAutoSchedule'+now.getTime(), cron, new CSApplicationStatusEvaluator(applicationStatusChanges));
                return;
            } else {
                throw new Util.BWException(e.getMessage());
            }
        }

        uow.registerWork(new Logger());
        for (Lead lead : leadsToEvaluate) {
            registerStatusUpdate(lead);
        }
        Util.disableTrigger('Disable_LeadTrigger__c');
        uow.commitWork();
        Util.enableTrigger('Disable_LeadTrigger__c');
    }

    public void execute(SchedulableContext context) {
        try {
            System.abortJob(context.getTriggerId());
            updatePartnerApplicationStatus();
        } catch (Exception e) {
            Logger.logNow('' +
                'ApplicationStatusChangeEvaluator',
                'execute',
                e.getMessage() + '\n' + e.getStackTraceString() + '\n' + JSON.serialize(applicationStatusChanges),
                Logger.ERROR);
        }
    }

    @TestVisible
    private Lead registerStatusUpdate(Lead leadToEvaluate) {
        String newStatus;

        if (allComplete(leadToEvaluate.Opportunities__r)) {
            newStatus = COMPLETE;
        } else if (hasOpenQCCases(leadToEvaluate)) {
            newStatus = AWAITING_CUSTOMER_INFO;
        } else if (allLost(leadToEvaluate.Opportunities__r) ||
            UNQUALIFIED_LEAD_STATUSES.contains(leadToEvaluate.Status)) {
            newStatus = EXPIRED_UNQUALIFIED;
        } else if (leadToEvaluate.Application_Complete_Date__c == null) {
            newStatus = APPLICATION_STARTED;
        } else {
            newStatus = UNDER_REVIEW;
        }

        if (newStatus != leadToEvaluate.Partner_Application_Status__c) {
            leadToEvaluate.Partner_Application_Status__c = newStatus;
            uow.registerDirty(leadToEvaluate, new List<SObjectField>{
                Lead.Partner_Application_Status__c
            });
        }
        return leadToEvaluate;
    }

    private Boolean hasOpenQCCases(Lead lead) {
        if (!lead.Cases__r.isEmpty()) {
            return true;
        }
        if (lead.Opportunities__r.isEmpty()) {
            return false;
        }
        for (Opportunity opportunity : lead.Opportunities__r) {
            if (oppIdToCaseMap.containsKey(opportunity.Id)) {
                return true;
            }
        }
        return false;
    }

    private Boolean allComplete(List<Opportunity> opportunities) {
        OppSummary oppSummary = getSummary(opportunities);
        return oppSummary.hasComplete && !oppSummary.hasInProgress && !oppSummary.hasLost;
    }

    private Boolean allLost(List<Opportunity> opportunities) {
        OppSummary oppSummary = getSummary(opportunities);
        return oppSummary.hasLost && !oppSummary.hasInProgress && !oppSummary.hasComplete;
    }

    private OppSummary getSummary(List<Opportunity> opportunities) {
        Boolean hasComplete = false;
        Boolean hasLost = false;
        Boolean hasInProgress = false;
        for (Opportunity opportunity : opportunities) {
            switch on opportunity.StageName {
                when 'Complete' {
                    hasComplete = true;
                } when 'Cancelled', 'Unqualified', 'DUPLICATE', 'Expired', 'Dead' {
                    hasLost = true;
                } when else {
                    hasInProgress = true;
                }
            }
        }
        OppSummary oppSummary = new OppSummary();
        oppSummary.hasComplete = hasComplete;
        oppSummary.hasLost = hasLost;
        oppSummary.hasInProgress = hasInProgress;
        return oppSummary;
    }

    private class OppSummary {
        Boolean hasComplete = false;
        Boolean hasLost = false;
        Boolean hasInProgress = false;
    }

}