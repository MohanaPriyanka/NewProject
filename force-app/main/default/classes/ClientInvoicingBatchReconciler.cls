/**
 * @description Logs an error for all Subscription Orders that should have a CFD different than the existing one assigned
 * Tested by: ClientInvoicingBatchReconcilerTest
 */
public with sharing class ClientInvoicingBatchReconciler implements Database.Batchable<SObject>, Schedulable {
    public Database.QueryLocator start(Database.BatchableContext context) {
        return Database.getQueryLocator('SELECT Id FROM Subscription_Order__c ORDER BY Effective_Date__c, Id');
    }

    public void execute(Database.BatchableContext context, List<SObject> scope) {
        try {
            ClientInvoicingFeeAssignmentService assignmentService =
                new ClientInvoicingFeeAssignmentService(CollectionUtil.getIdSet(scope));
            assignmentService.reconcileSubscriptionOrders();
        } catch (Exception e) {
            Logger.logLater('ClientInvoicingBatchReconciler', 'execute', e.getMessage() + '\n' + e.getStackTraceString(), Logger.ERROR);
        }
    }

    @SuppressWarnings('PMD.EmptyStatementBlock')
    public void finish(Database.BatchableContext context) {
    }

    public void execute(SchedulableContext sc) {
        Database.executeBatch(new ClientInvoicingBatchReconciler(), 2000);
    }
}