/**
 * Description: Ensures that the ProductionToBillService and manual edits result in Production Details that roll up
 * to Journal Entry amounts
 * Tested By: ProductionToBillAuditorTest
 */

public without sharing class ProductionToBillJEAuditor implements Database.Batchable<SObject>, Database.Stateful {
    public String jesCreatedOrModifiedToday =
        'SELECT Id, Amount__c, Credit_Memo_Unapplied_Amount__c FROM Journal_Entry__c WHERE CreatedDate = TODAY OR LastModifiedDate = TODAY';
    public String jesForPDsCreatedOrModifiedToday =
        'SELECT Id, Amount__c, Credit_Memo_Unapplied_Amount__c\n' +
            'FROM Journal_Entry__c\n' +
            'WHERE CreatedDate != TODAY AND LastModifiedDate != TODAY\n' +
            'AND Id IN (SELECT Journal_Entry__c\n' +
            '           FROM Transfer_Part__c\n' +
            '           WHERE Journal_Entry__c != NULL\n' +
            '           AND (CreatedDate = TODAY OR LastModifiedDate = TODAY))';
    public String query;
    @TestVisible private String errors = '';
    @TestVisible private static JournalEntrySelector journalEntrySelector = new JournalEntrySelector();

    public ProductionToBillJEAuditor() {
        query = jesCreatedOrModifiedToday;
    }

    public Database.QueryLocator start(Database.BatchableContext context) {
        Logger.logNow('ProductionToBillJEAuditor', 'start', 'Starting auditor with query:\n' + query, Logger.FINE);
        return Database.getQueryLocator(query);
    }

    public void execute(Database.BatchableContext context, List<Object> scope) {
        try {
            Map<Id, Journal_Entry__c> journalEntryMap = new Map<Id, Journal_Entry__c>((List<Journal_Entry__c>) scope);
            List<AggregateResultProxy> aggregateProductionDetails  = journalEntrySelector.selectForReconciliation(journalEntryMap.values());
            for (AggregateResultProxy aggregateResultProxy : aggregateProductionDetails) {
                reconcileProductionDetailAggregate(aggregateResultProxy, journalEntryMap);
            }
            logJournalEntriesWithoutPDs(journalEntryMap);
        } catch (Exception e) {
            Logger.logNow('ProductionToBillJEAuditor', 'execute', e.getMessage() + '\n' + e.getStackTraceString(), Logger.ERROR);
        }
    }

    private void reconcileProductionDetailAggregate(AggregateResultProxy aggregateResultProxy, Map<Id, Journal_Entry__c> journalEntryMap) {
        Map<String, Object> pdAggregate = aggregateResultProxy.getValuesByAlias();
        Id jeId = (Id) pdAggregate.get('Journal_Entry__c');
        String objectType = (String) pdAggregate.get('Object_Type__c');
        String reasonCode = (String) pdAggregate.get('Reason_Code__c');
        Decimal amount = (Decimal) pdAggregate.get('AMOUNT');
        Journal_Entry__c journalEntry = journalEntryMap.get(jeId);
        Decimal amountToCompare = amount;
        if ((objectType == 'CreditMemo' && reasonCode == 'Production') || objectType == 'DebitMemo') {
            amountToCompare = -amount;
        }
        // The Credit Memo Unapplied Amount will show up as a PD in the future, but for now, add it to the aggregate amount
        amountToCompare += Util.nullToZero(journalEntry.Credit_Memo_Unapplied_Amount__c);
        if (journalEntry.Amount__c != amountToCompare) {
            errors += 'JE: ' + jeId + ', Amount: ' + journalEntry.Amount__c + ', PD Sum: ' + amount +
                ', type: ' + objectType + ', reason:' + reasonCode + '\n';
        }
        journalEntryMap.remove(jeId);
    }

    private void logJournalEntriesWithoutPDs(Map<Id, Journal_Entry__c> journalEntryMap) {
        if (journalEntryMap.isEmpty()) {
            return;
        }
        for (Journal_Entry__c je : journalEntryMap.values()) {
            if (je.Amount__c != 0) {
                errors += 'JE: ' + je.Id + ' has no production details\n';
            }
        }
    }

    public void finish(Database.BatchableContext context) {
        if (errors != '') {
            Logger.logNow('ProductionToBillJEAuditor', 'finish', errors, Logger.ERROR);
        }
        if (!Test.isRunningTest()) {
            queueNextJob();
        }
    }

    @TestVisible
    private Object queueNextJob() {
        if (query == jesCreatedOrModifiedToday) {
            ProductionToBillJEAuditor pdAuditor = new ProductionToBillJEAuditor();
            pdAuditor.query = jesForPDsCreatedOrModifiedToday;
            Database.executeBatch(pdAuditor);
            return pdAuditor;
        } else if (query == jesForPDsCreatedOrModifiedToday) {
            ProductionToBillExServicedUASBAuditor externallyServicedUASBAuditor = new ProductionToBillExServicedUASBAuditor();
            Database.executeBatch(externallyServicedUASBAuditor);
            return externallyServicedUASBAuditor;
        }
        return null;
    }

}