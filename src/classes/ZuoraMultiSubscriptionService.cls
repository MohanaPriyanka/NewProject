/**
 * Created by peteryao on 4/17/20.
 * Tested By: ZuoraMultiSubscriptionServiceTest
 */

public with sharing class ZuoraMultiSubscriptionService {
    private static ZuoraSubscriptionService subscriptionService = new ZuoraSubscriptionService();

    public static List<String> createSubscriptions(List<ZuoraSubscriptionService.SubscriptionParam> subscriptionParams) {
        List<String> subscriptionsCreated = new List<String>();
        checkCallouts(subscriptionParams);

        for (Integer i = subscriptionParams.size()-1; i >= 0; i--) {
            try {
                subscriptionsCreated.addAll(createSubscription(subscriptionParams[i].param, subscriptionParams[i].additionalClientProjects));
            } catch (Exception e) {
                Logger.logLater(
                    'ZuoraMultiSubscriptionService',
                    'createSubscription',
                    'Caught exception, will retry creating subscription for ' + JSON.serialize(subscriptionParams[i]) +
                        e.getMessage() + e.getStackTraceString(),
                    Logger.WARN
                );
                continue;
            }
            subscriptionParams.remove(i);
        }
        Logger.flushLogs();
        return subscriptionsCreated;
    }

    private static void checkCallouts(List<ZuoraSubscriptionService.SubscriptionParam> subscriptionParams) {
        Integer callouts = 0;
        for (ZuoraSubscriptionService.SubscriptionParam subscriptionParam : subscriptionParams) {
            callouts += subscriptionParam.estimateCallouts();
        }
        if (callouts >= Limits.getLimitCallouts() && !Test.isRunningTest()) {
            throw new Util.BWException(callouts + ' callouts would be used by this method with these parameters: ' +
                JSON.serialize(subscriptionParams) + '. Invoke with fewer subscriptions to stay under the limit of ' + Limits.getLimitCallouts());
        }
    }

    @TestVisible
    private static List<String> createSubscription(ZuoraSubscriptionService.OrderActionParam newSubscription, Set<ZuoraSubscriptionService.ClientProject> additionalSubscriptions) {
        List<String> subscriptionNumbersCreated = new List<String>();
        ZuoraAPI.SubscriptionsByAccount sba = subscriptionService.getSubscriptionsByAccount(newSubscription.accountNumber);
        if (sba.subscriptions.isEmpty()) {
            subscriptionNumbersCreated.add(createNewSubscription(newSubscription));
        } else {
            calculateAdditionalSubscriptions(newSubscription, sba, additionalSubscriptions);
        }

        if (additionalSubscriptions == null || additionalSubscriptions.size() == 0) {
            return subscriptionNumbersCreated;
        }

        for (ZuoraSubscriptionService.ClientProject clientProject : additionalSubscriptions) {
            subscriptionNumbersCreated.add(createNewSubscription(clientProject.orderActionParam));
        }
        return subscriptionNumbersCreated;
    }

    private static String createNewSubscription(ZuoraSubscriptionService.OrderActionParam newSubscription) {
        ZuoraAPI.Order createNewSubscription = ZuoraSubscriptionService.getNewOrderRequest(newSubscription);
        HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('POST', '/v1/orders', createNewSubscription, false);
        ZuoraAPI.OrderActionResult newSubscriptionResult =
            (ZuoraAPI.OrderActionResult) JSON.deserialize(response.getBody(), ZuoraAPI.OrderActionResult.class);
        if (!newSubscriptionResult.success || newSubscriptionResult.subscriptions.size() != 1) {
            Logger.logLater('ZuoraMultipleSubscriptionService', 'createNewSubscription', JSON.serializePretty(newSubscriptionResult));
            throw new Util.BWException('Unexpected result creating a new subscription:\n' + JSON.serializePretty(newSubscriptionResult));
        }

        newSubscription.subscriptionNumber = newSubscriptionResult.subscriptions[0].subscriptionNumber;
        return newSubscriptionResult.subscriptions[0].subscriptionNumber;
    }

    @TestVisible
    private static void calculateAdditionalSubscriptions(ZuoraSubscriptionService.OrderActionParam newSubscription,
        ZuoraAPI.SubscriptionsByAccount sba, Set<ZuoraSubscriptionService.ClientProject> additionalSubscriptions) {
        ZuoraSubscriptionService.ClientProject newSubClientProject = new ZuoraSubscriptionService.ClientProject(newSubscription);
        Set<ZuoraSubscriptionService.ClientProject> existingClientProjects = sba.getClientProjects();
        // Since we don't want to create subscriptions for client/projects that already exist, we'll remove them
        additionalSubscriptions.removeAll(existingClientProjects);
        // If the new subscription has a client/project that doesn't exist, we need to add that subscription
        if (!existingClientProjects.contains(newSubClientProject)) {
            additionalSubscriptions.add(newSubClientProject);
        }
    }
}