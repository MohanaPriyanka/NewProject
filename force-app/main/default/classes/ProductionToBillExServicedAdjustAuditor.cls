/**
 * Description: Ensures that the ProductionToBillService and manual edits result in Production Details that roll up
 * to Externally Serviced UASBs
 * Tested By: ProductionToBillAuditorTest
 */

public without sharing class ProductionToBillExServicedAdjustAuditor implements Database.Batchable<SObject>, Database.Stateful {
    public String externallyServicedAdjustmentsCreatedOrModifiedToday =
        'SELECT Id FROM Bill_Adjustment__c WHERE Externally_Serviced__c = TRUE AND (CreatedDate = TODAY OR LastModifiedDate = TODAY)';
    public String adjustmentsForPDsCreatedOrModifiedToday =
        'SELECT Id ' +
            'FROM Bill_Adjustment__c ' +
            'WHERE CreatedDate != TODAY ' +
            'AND LastModifiedDate != TODAY ' +
            'AND Id IN (SELECT Externally_Serviced_Bill_Adjustment__c ' +
            '           FROM Transfer_Part__c ' +
            '           WHERE Externally_Serviced_Bill_Adjustment__c != NULL ' +
            '           AND (CreatedDate = TODAY OR LastModifiedDate = TODAY))';
    public String query;
    @TestVisible private String errors = '';
    @TestVisible private static AdjustmentSelector adjustmentSelector = new AdjustmentSelector();

    public ProductionToBillExServicedAdjustAuditor() {
        query = externallyServicedAdjustmentsCreatedOrModifiedToday;
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        Logger.logNow('ProductionToBillExServicedAdjustAuditor', 'start', 'Starting auditor with query:\n' + query, Logger.FINE);
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext context, List<Object> scope) {
        try {
            Map<Id, Bill_Adjustment__c> billAdjustmentMap = new Map<Id, Bill_Adjustment__c>((List<Bill_Adjustment__c>) scope);
            List<AggregateResultProxy> aggregateProductionDetails = adjustmentSelector.selectForReconciliation(billAdjustmentMap.values());
            for (AggregateResultProxy aggregateResultProxy : aggregateProductionDetails) {
                reconcileProductionDetailAggregate(aggregateResultProxy, billAdjustmentMap);
            }
            logAdjustmentsWithoutPDs(billAdjustmentMap);
        } catch (Exception e) {
            Logger.logLater('ProductionToBillExServicedAdjustAuditor', 'execute', e.getMessage() + '\n' + e.getStackTraceString(), Logger.ERROR);
        }
    }

    private void reconcileProductionDetailAggregate(AggregateResultProxy aggregateResultProxy, Map<Id, Bill_Adjustment__c> billAdjustmentMap) {
        Map<String, Object> pdAggregate = aggregateResultProxy.getValuesByAlias();
        Id adjustmentId = (Id) pdAggregate.get('Externally_Serviced_Bill_Adjustment__c');
        Decimal amount = (Decimal) pdAggregate.get('AMOUNT');
        Bill_Adjustment__c billAdjustment = billAdjustmentMap.get(adjustmentId);
        if (billAdjustment.Adjustment_Amount__c != amount) {
            errors += 'Adjustment: ' + adjustmentId + ', Amount: ' + billAdjustment.Adjustment_Amount__c + ', PD Sum: ' + amount + '\n';
        }
        billAdjustmentMap.remove(adjustmentId);
    }

    private void logAdjustmentsWithoutPDs(Map<Id, Bill_Adjustment__c> billAdjustmentMap) {
        if (billAdjustmentMap.isEmpty()) {
            return;
        }
        for (Bill_Adjustment__c adjustment : billAdjustmentMap.values()) {
            if (adjustment.Adjustment_Amount__c != 0) {
                errors += 'Adjustment: ' + adjustment.Id + ' has no production details\n';
            }
        }
    }

    public void finish(Database.BatchableContext context) {
        if (errors != '') {
            Logger.logNow('ProductionToBillExServicedAdjustAuditor', 'finish', errors, Logger.ERROR);
        }
        if (!Test.isRunningTest()) {
            queueNextJob();
        }
    }

    @TestVisible
    private Object queueNextJob() {
        if (query == externallyServicedAdjustmentsCreatedOrModifiedToday) {
            ProductionToBillExServicedAdjustAuditor adjustmentAuditor = new ProductionToBillExServicedAdjustAuditor();
            adjustmentAuditor.query = adjustmentsForPDsCreatedOrModifiedToday;
            Database.executeBatch(adjustmentAuditor);
            return adjustmentAuditor;
        }
        return null;
    }
}