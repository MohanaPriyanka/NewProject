/*************************************************************************************
 * Created by aingram on 4/14/22.
 * Description:
 * Tested By: ZuoraSubscriptionServiceTest
 *************************************************************************************/

public with sharing class ZuoraRatePlanChargeService {
    private static Map<String, Map<String, ZuoraOutstandingItemsService.RatePlanCharge>> ratePlanChargesByAccountCache =
        new Map<String, Map<String, ZuoraOutstandingItemsService.RatePlanCharge>>();
    @TestVisible private static Integer maximumCriteriaSupportedByZOQL = 200;

    public static Map<String, ZuoraOutstandingItemsService.RatePlanCharge> getAllRatePlanChargesByAccountId(String zuoraAcctId) {
        if (ratePlanChargesByAccountCache.containsKey(zuoraAcctId)) {
            return ratePlanChargesByAccountCache.get(zuoraAcctId);
        }
        // When a subscription is changed through an Order, for instance to add another Rate Plan Charge, the previous
        // subscription is expired and another one created with copies of the previous Rate Plan Charges. So even though
        // an account may only have one active subscription, we should get all subscriptions and their corresponding RPCs
        // in case an invoice line item is referencing the expired RPC.
        Set<String> subscriptionIds =
            ZuoraAPIHelper.queryIds('SELECT Id FROM Subscription WHERE AccountId = \''+zuoraAcctId+'\'');
        if (subscriptionIds.isEmpty()) {
            throw new Util.BWException('Did not find any subscriptions for Account: ' + zuoraAcctId);
        }
        Set<String> ratePlanIds = getRatePlansBySubscriptionIds(subscriptionIds);
        List<ZuoraOutstandingItemsService.RatePlanCharge> ratePlanCharges = getRatePlanChargesByRatePlanId(ratePlanIds);

        Map<String, ZuoraOutstandingItemsService.RatePlanCharge> ratePlanChargesByChargeId =
            new Map<String, ZuoraOutstandingItemsService.RatePlanCharge>();
        for (ZuoraOutstandingItemsService.RatePlanCharge ratePlanCharge : ratePlanCharges) {
            ratePlanChargesByChargeId.put(ratePlanCharge.Id, ratePlanCharge);
        }
        ratePlanChargesByAccountCache.put(zuoraAcctId, ratePlanChargesByChargeId);
        return ratePlanChargesByChargeId;
    }

    private static Set<String> getRatePlansBySubscriptionIds(Set<String> subscriptionIds) {
        String subscriptionFilter = 'WHERE ';
        for (String subscriptionId : subscriptionIds) {
            subscriptionFilter += 'SubscriptionId = \'' + subscriptionId + '\' OR ';
        }
        subscriptionFilter = subscriptionFilter.left(subscriptionFilter.length()-4);

        return ZuoraAPIHelper.queryIds('SELECT Id FROM RatePlan ' + subscriptionFilter);
    }

    private static List<ZuoraOutstandingItemsService.RatePlanCharge> getRatePlanChargesByRatePlanId(Set<String> ratePlanIds) {
        String ratePlanFilter = 'WHERE ';

        Integer criteriaAdded = 0;
        for (String ratePlanId : ratePlanIds) {
            ratePlanFilter += 'RatePlanId = \'' + ratePlanId + '\' OR ';
            ratePlanIds.remove(ratePlanId);
            criteriaAdded++;
            if(criteriaAdded == maximumCriteriaSupportedByZOQL) {
                break;
            }
        }
        ratePlanFilter = ratePlanFilter.left(ratePlanFilter.length() - 4);
        String ratePlanChargeJSON =
            ZuoraAPIHelper.query('SELECT Id, Name, ChargeNumber, ProductRatePlanChargeid, ClientOwner__c, Project__c FROM RatePlanCharge ' + ratePlanFilter, false);
        ratePlanChargeJSON = ratePlanChargeJSON.replace('__c', '_Zcustom');

        ZuoraOutstandingItemsService.QueryResultRatePlanCharge queryResult =
            (ZuoraOutstandingItemsService.QueryResultRatePlanCharge)JSON.deserialize(ratePlanChargeJSON, ZuoraOutstandingItemsService.QueryResultRatePlanCharge.class);

        if(!ratePlanIds.isEmpty()) {
            queryResult.Records.addAll(getRatePlanChargesByRatePlanId(ratePlanIds));
        }
        return queryResult.Records;
    }

}