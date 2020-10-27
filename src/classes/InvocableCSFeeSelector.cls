/**
 * @description Selects un-invoiced Subscription Orders and Client Invoicing Memos for invoicing
 * Created by peteryao on 10/17/20.
 */
public without sharing class InvocableCSFeeSelector {
    private static SubscriptionOrderSelector subscriptionOrderSelector = new SubscriptionOrderSelector();
    private static ClientInvoicingMemoSelector clientInvoicingMemoSelector = new ClientInvoicingMemoSelector();

    /**
     * @description Gets Shared Solar Systems with associated Uninvoiced Subscription Orders and Client Invoicing Memos
     * @param requests A list of Client Account Ids for which to get associated Shared Solar Systems
     * @return A serialized list of SharedSolarSystem records (for use in DatatableV2)
     */
    @InvocableMethod(Label='InvocableCSFeeSelector' Description='Gets Uninvoiced Subscription Orders and Client Invoicing Memos')
    public static List<String> getFeesToInvoice(List<FeeRequest> requests) {
        if (requests.size() != 1) {
            throw new Util.BWException('Only one client account supported at this time');
        }
        List<Id> clientAccountIds = new List<Id>{requests[0].clientAccountId};
        Datetime effectiveDate = requests[0].effectiveDate;
        List<AggregateResult> uninvoicedSOs =
            subscriptionOrderSelector.getUninvoicedByClientAccount(clientAccountIds, effectiveDate);
        List<AggregateResult> uninvoicedCIMs =
            clientInvoicingMemoSelector.getUninvoicedByClientAccounts(clientAccountIds, effectiveDate);
        Map<Id, SharedSolarSystem> sharedSolarSystemSummaries = new Map<Id, SharedSolarSystem>();
        updateSummariesWithTotals(uninvoicedSOs, sharedSolarSystemSummaries);
        updateSummariesWithTotals(uninvoicedCIMs, sharedSolarSystemSummaries);
        return new List<String>{JSON.serialize(sharedSolarSystemSummaries.values())};
    }

    /**
     * @description Updates the sharedSolarSystemSummaries map with the total
     * @param uninvoicedSOs AggregateResults, grouped by SSSId with the total un-invoiced dollars and records
     * @param sharedSolarSystemSummaries Map of Shared Solar System Id to SharedSolarSystem
     */
    private static void updateSummariesWithTotals(List<AggregateResult> uninvoicedSOs, Map<Id, SharedSolarSystem> sharedSolarSystemSummaries) {
        for (AggregateResult aggregateResult : uninvoicedSOs) {
            SharedSolarSystem sssSummary = sharedSolarSystemSummaries.get((Id) aggregateResult.get('Id'));
            if (sssSummary != null) {
                sssSummary.updateTotals(aggregateResult);
            } else {
                sssSummary = new SharedSolarSystem(aggregateResult);
                sharedSolarSystemSummaries.put(sssSummary.id, sssSummary);
            }
        }
    }

    /**
     * @description Used to pass multiple parameters from Flow to the selector
     */
    public class FeeRequest {
        @InvocableVariable(Label='Client Account Id')
        public Id clientAccountId;
        @InvocableVariable(Label='Effective Date')
        public Datetime effectiveDate;
    }
}