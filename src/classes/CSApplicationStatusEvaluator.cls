/**
 * @description Per W-021018, updates Lead.Partner_Application_Status__c field to:
 *   - Application Started
 *   - Under Review
 *   - Awaiting Customer Information
 *   - Expired/Unqualified
 *   - Complete
 *  Tested By: CSApplicationStatusEvaluatorTest
 */

public without sharing class CSApplicationStatusEvaluator {
    @TestVisible private static final String APPLICATION_STARTED = 'Application Started';
    @TestVisible private static final String UNDER_REVIEW = 'Under Review';
    @TestVisible private static final String AWAITING_CUSTOMER_INFO = 'Awaiting Information Requested';
    @TestVisible private static final String EXPIRED_UNQUALIFIED = 'Expired/Unqualified';
    @TestVisible private static final String COMPLETE = 'Complete';
    private static final List<String> UNQUALIFIED_LEAD_STATUSES = new List<String>{'Unqualified', 'No Response', 'Lost', 'Expired'};

    private static CaseSelector caseSelector = new CaseSelector();
    private static LeadSelector leadSelector = new LeadSelector();
    private static OpportunitiesSelector opportunitySelector = new OpportunitiesSelector();
    private List<Lead> leadsToEvaluate;
    @TestVisible private MultiMap oppIdToCaseMap;
    @TestVisible private static fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
        new List<Schema.SObjectType> {
            Lead.SObjectType
        }
    );

    /**
     * @description Publishes an Application Status Event for Community Solar leads
     * @param triggerOldMap Trigger.oldMap, or null if called from an insert
     * @param triggerNew Trigger.new
     */
    public static void publishEvent(Map<Id, Lead> triggerOldMap, List<Lead> triggerNew) {
        List<Application_Status_Change__e> applicationStatusChanges = new List<Application_Status_Change__e>();
        for (Lead lead : triggerNew) {
            if (lead.Product_line__c == 'Community Solar' &&
                (triggerOldMap == null ||
                    lead.Status != triggerOldMap.get(lead.Id).Status ||
                    lead.Application_Complete_Date__c != triggerOldMap.get(lead.Id).Application_Complete_Date__c)) {
                applicationStatusChanges.add(new Application_Status_Change__e(LeadId__c = lead.Id));
            }
        }
        logErrors(EventBus.publish(applicationStatusChanges), applicationStatusChanges);
    }

    /**
     * @description Publishes an Application Status Event after insert/update of a QC Case
     * @param triggerOldMap Trigger.oldMap, or null if called from an insert
     * @param triggerNew Trigger.new
     */
    public static void publishEvent(Map<Id, Case> triggerOldMap, List<Case> triggerNew) {
        List<Application_Status_Change__e> applicationStatusChanges = new List<Application_Status_Change__e>();
        for (Case triggerCase : triggerNew) {
            if ((triggerOldMap == null && triggerCase.Category__c == 'QC') ||
                (triggerOldMap != null && (triggerOldMap.get(triggerCase.Id).Category__c == 'QC' || triggerCase.Category__c == 'QC'))) {
                applicationStatusChanges.add(new Application_Status_Change__e(CaseId__c = triggerCase.Id));
            }
        }
        logErrors(EventBus.publish(applicationStatusChanges), applicationStatusChanges);
    }

    /**
     * @description Publishes an Application Change Event after insert/update of any Opportunity
     * @param triggerOldMap Trigger.oldMap or null if called from an insert
     * @param triggerNew Trigger.new
     */
    public static void publishEvent(Map<Id, Opportunity> triggerOldMap, List<Opportunity> triggerNew) {
        List<Application_Status_Change__e> applicationStatusChanges = new List<Application_Status_Change__e>();
        for (Opportunity opportunity : triggerNew) {
            applicationStatusChanges.add(new Application_Status_Change__e(OpportunityId__c = opportunity.Id));
            if (triggerOldMap != null &&
                triggerOldMap.get(opportunity.Id).Lead__c != opportunity.Lead__c) {
                applicationStatusChanges.add(new Application_Status_Change__e(LeadId__c = triggerOldMap.get(opportunity.Id).Lead__c));
            }
        }
        logErrors(EventBus.publish(applicationStatusChanges), applicationStatusChanges);
    }

    /**
     * @description Publishes an Application Change Event after delete of any Opportunity
     * @param triggerOld Trigger.old
     */
    public static void publishEventAfterDelete(List<Opportunity> triggerOld) {
        List<Application_Status_Change__e> applicationStatusChanges = new List<Application_Status_Change__e>();
        for (Opportunity opportunity : triggerOld) {
            applicationStatusChanges.add(new Application_Status_Change__e(LeadId__c = opportunity.Lead__c));
        }
        logErrors(EventBus.publish(applicationStatusChanges), applicationStatusChanges);
    }

    private static void logErrors(List<Database.SaveResult> saveResults, List<Application_Status_Change__e> applicationStatusChanges) {
        Boolean foundError = false;
        for (Database.SaveResult saveResult : saveResults){
            if (!saveResult.isSuccess()) {
                foundError = true;
                Logger.logLater('CSApplicationStatusEvaluator', 'logErrors', 'Did not publish event: ' + summarizeError(saveResult.getErrors()), Logger.ERROR);
            }
        }
        if (foundError) {
            Logger.logLater('CSApplicationStatusEvaluator', 'logErrors', 'applicationStatusChanges: ' + JSON.serialize(applicationStatusChanges), Logger.ERROR);
            Logger.flushLogs();
        }
    }

    private static String summarizeError(List<Database.Error> errors) {
        String errorMessage = '';
        for (Database.Error error : errors) {
            errorMessage += error.getMessage() + '\n';
        }
        return errorMessage;
    }

    /**
     * @description Default constructor for test only
     */
    @TestVisible
    private CSApplicationStatusEvaluator() {
        oppIdToCaseMap = MultiMap.newListInstance();
    }

    /**
     * @description Initializes the class from a list of Application Status Change platform events by finding the related
     * lead. Cases could be related to an Opportunity which is in turn related to a Lead.
     * @param applicationStatusChanges The list of platform events with lead, case, or opportunity ids
     */
    public CSApplicationStatusEvaluator(List<Application_Status_Change__e> applicationStatusChanges) {
        getLeadsToEvaluateFromEvents(applicationStatusChanges);
        getQCCasesRelatedToLeadsViaOpportunity();
    }

    private void getLeadsToEvaluateFromEvents(List<Application_Status_Change__e> applicationStatusChanges) {
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
        uow.registerWork(new Logger());
        for (Lead lead : leadsToEvaluate) {
            registerStatusUpdate(lead);
        }
        Util.disableTrigger('Disable_LeadTrigger__c');
        uow.commitWork();
        Util.enableTrigger('Disable_LeadTrigger__c');
    }

    @TestVisible
    private Lead registerStatusUpdate(Lead lead) {
        String newStatus;

        if (allComplete(lead.Opportunities__r)) {
            newStatus = COMPLETE;
        } else if (hasOpenQCCases(lead)) {
            newStatus = AWAITING_CUSTOMER_INFO;
        } else if (allLost(lead.Opportunities__r) ||
            UNQUALIFIED_LEAD_STATUSES.contains(lead.Status)) {
            newStatus = EXPIRED_UNQUALIFIED;
        } else if (lead.Application_Complete_Date__c == null) {
            newStatus = APPLICATION_STARTED;
        } else {
            newStatus = UNDER_REVIEW;
        }

        if (newStatus != lead.Partner_Application_Status__c) {
            lead.Partner_Application_Status__c = newStatus;
            uow.registerDirty(lead);
        }
        return lead;
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