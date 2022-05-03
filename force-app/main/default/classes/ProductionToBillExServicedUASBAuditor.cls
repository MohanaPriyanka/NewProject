/**
 * Description: Ensures that the ProductionToBillService and manual edits result in Production Details that roll up
 * to Externally Serviced UASBs
 * Tested By: ProductionToBillAuditorTest
 */

public without sharing class ProductionToBillExServicedUASBAuditor implements Database.Batchable<SObject>, Database.Stateful {
    public String externallyServicedUASBsCreatedOrModifiedToday =
        'SELECT Id, Credits_Allocated__c FROM UASB__c WHERE Externally_Serviced__c = TRUE AND (CreatedDate = TODAY OR LastModifiedDate = TODAY)';
    public String uasbsForPDsCreatedOrModifiedToday =
        'SELECT Id, Credits_Allocated__c\n' +
            'FROM UASB__c\n' +
            'WHERE CreatedDate != TODAY\n' +
            'AND LastModifiedDate != TODAY\n' +
            'AND Id IN (SELECT Externally_Serviced_UASB__c\n' +
            '           FROM Transfer_Part__c\n' +
            '           WHERE Externally_Serviced_UASB__c != NULL\n' +
            '           AND (CreatedDate = TODAY OR LastModifiedDate = TODAY))';
    public String query;
    @TestVisible private String errors = '';
    @TestVisible private static UASBSelector uasbSelector = new UASBSelector();

    public ProductionToBillExServicedUASBAuditor() {
        query = externallyServicedUASBsCreatedOrModifiedToday;
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        Logger.logNow('ProductionToBillExServicedUASBAuditor', 'start', 'Starting auditor with query:\n' + query, Logger.FINE);
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext context, List<Object> scope) {
        try {
            Map<Id, UASB__c> uasbMap = new Map<Id, UASB__c>((List<UASB__c>) scope);
            List<AggregateResultProxy> aggregateProductionDetails = uasbSelector.selectForReconciliation(uasbMap.values());
            for (AggregateResultProxy aggregateResultProxy : aggregateProductionDetails) {
                reconcileProductionDetailAggregate(aggregateResultProxy, uasbMap);
            }
            logUASBsWithoutPDs(uasbMap);
        } catch (Exception e) {
            Logger.logNow('ProductionToBillExServicedUASBAuditor', 'execute', e.getMessage() + '\n' + e.getStackTraceString(), Logger.ERROR);
        }
    }

    private void reconcileProductionDetailAggregate(AggregateResultProxy aggregateResultProxy, Map<Id, UASB__c> uasbMap) {
        Map<String, Object> pdAggregate = aggregateResultProxy.getValuesByAlias();
        Id uasbId = (Id) pdAggregate.get('Externally_Serviced_UASB__c');
        Decimal amount = (Decimal) pdAggregate.get('AMOUNT');
        UASB__c uasb = uasbMap.get(uasbId);
        if (uasb.Credits_Allocated__c != amount) {
            errors += 'UASB: ' + uasbId + ' Amount: ' + uasb.Credits_Allocated__c + ', PD Sum: ' + amount + '\n';
        }
        uasbMap.remove(uasbId);
    }

    private void logUASBsWithoutPDs(Map<Id, UASB__c> uasbMap) {
        if (uasbMap.isEmpty()) {
            return;
        }
        for (UASB__c uasb : uasbMap.values()) {
            if (uasb.Credits_Allocated__c != 0) {
                errors += 'UASB: ' + uasb.Id + ' has no production details\n';
            }
        }
    }

    public void finish(Database.BatchableContext context) {
        if (errors != '') {
            Logger.logNow('ProductionToBillExServicedUASBAuditor', 'finish', errors, Logger.ERROR);
        }
        if (!Test.isRunningTest()) {
            queueNextJob();
        }
    }

    @TestVisible
    private Object queueNextJob() {
        if (query == externallyServicedUASBsCreatedOrModifiedToday) {
            ProductionToBillExServicedUASBAuditor exUASBAuditor = new ProductionToBillExServicedUASBAuditor();
            exUASBAuditor.query = uasbsForPDsCreatedOrModifiedToday;
            Database.executeBatch(exUASBAuditor);
            return exUASBAuditor;
        } else if (query == uasbsForPDsCreatedOrModifiedToday) {
            ProductionToBillExServicedAdjustAuditor exAdjustAuditor = new ProductionToBillExServicedAdjustAuditor();
            Database.executeBatch(exAdjustAuditor);
            return exAdjustAuditor;
        }
        return null;
    }
}