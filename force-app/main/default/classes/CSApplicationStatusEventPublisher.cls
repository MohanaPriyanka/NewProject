/**
 * @description Convenience methods to publish an Application_Status_Change__e Event
 * Tested By: CSApplicationStatusEvaluatorTest
 */
public without sharing class CSApplicationStatusEventPublisher {
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

    @TestVisible
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
}