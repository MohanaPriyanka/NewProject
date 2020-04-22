/**
 * Created by peteryao on 4/21/20.
 * Tested By: ZuoraCancellationServiceTest
 */

public with sharing class ZuoraCancellationService implements ZuoraDataQueryService.Processor, Queueable, Database.AllowsCallouts {
    List<SubscriptionResult> subscriptionsToCancel;

    public static void queryAndCancelAllSubscriptions() {
        String query = 'SELECT s.Name, a.AccountNumber ' +
            'FROM Subscription s ' +
            'INNER JOIN Account a ON s.AccountId = a.Id ' +
            'WHERE s.Status = \'Active\' ';

        ZuoraDataQueryService.ProcessingParameter processingParameter = new ZuoraDataQueryService.ProcessingParameter();
        processingParameter.className = 'ZuoraCancellationService';
        ZuoraDataQueryService.callFromApex(query, processingParameter);
    }

    public void executePostQueryJob(ZuoraDataQueryService.ProcessingParameter method, String response) {
        subscriptionsToCancel = (List<SubscriptionResult>) JSON.deserialize(response, List<SubscriptionResult>.class);
        System.enqueueJob(this);
    }

    public void execute(QueueableContext context) {
        try {
            while (!subscriptionsToCancel.isEmpty()) {
                cancelSubscription(subscriptionsToCancel[0]);
                subscriptionsToCancel.remove(0);
                if (ZuoraAPIHelper.getCalloutSecondsRemaining() <= 0 ||
                    ZuoraAPIHelper.getCalloutsRemaining() <= 0) {
                    if (!Test.isRunningTest()) {
                        System.enqueueJob(this);
                    }
                    break;
                }
            }
        } catch (Exception e) {
            Logger.logLater('ZuoraCancellationService', 'execute', e.getMessage() + '\n' + e.getStackTraceString(), Logger.ERROR);
        } finally {
            Logger.flushLogs();
        }
    }

    private void cancelSubscription(SubscriptionResult subscription) {
        ZuoraAPI.Order cancelOrder =
            getCancelOrderRequest(subscription.accountNumber, subscription.name, System.today());
        HttpResponse cancelResponse = ZuoraAPIHelper.callJsonEndpoint('POST', '/v1/orders', cancelOrder, false);
        ZuoraAPI.OrderActionResult cancelResult =
            (ZuoraAPI.OrderActionResult) JSON.deserialize(cancelResponse.getBody(), ZuoraAPI.OrderActionResult.class);
        if (!cancelResult.success) {
            Logger.logLater('ZuoraCancellationService', 'execute', JSON.serialize(cancelOrder) + '\n' + JSON.serialize(cancelResult));
        }
    }

    private ZuoraAPI.Order getCancelOrderRequest(String accountNumber, String subscriptionNumber, Date cancellationDate) {
        ZuoraAPI.Order order = new ZuoraAPI.Order(accountNumber, cancellationDate);
        ZuoraAPI.Subscription subscription = order.addSubscription(subscriptionNumber);
        ZuoraAPI.OrderAction orderAction = subscription.addOrderAction('CancelSubscription', cancellationDate);
        orderAction.addCancelSubscription(cancellationDate);
        return order;
    }

    private class SubscriptionResult {
        String name;
        String accountNumber;
    }
}