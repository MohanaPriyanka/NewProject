/*************************************************************************************
 * Created By: peteryao on 2019-05-15  
 * Description: The Zuora API only allows creation of one subscription per call, and we
 * can only make 100 callouts per transaction, so for bulk loads (after a schedule z is
 * enacted or during data migration), we'll start a batches of chained queueables.
 *
 * For example, for 400 subscriptions, ZuoraSubscriptionAsyncService starts batches:
 *   - Batch 1 (100 property accounts with all of their client/project combinations) ->
 *         Queueable Job 1 (as many subscriptions as can be created without hitting the callout limit) ->
 *         Queueable Job 3 (30 subscriptions) -> etc.
 *   - Batch 2 (100 property accounts) ->
 *         Queueable Job 2 (40 subscriptions) ->
 *         Queueable Job 4
 *
 * From anonymous apex:
 *    ZuoraSubscriptionAsyncService asyncService = new ZuoraSubscriptionAsyncService();
 *    asyncService.initForDataLoad();
 *    Database.executeBatch(asyncService, 100);
 * Tested By: ZuoraSubscriptionServiceTest, ScheduleZTriggerHandlerTest
 *************************************************************************************/

public with sharing class ZuoraSubscriptionAsyncService implements Queueable, Database.AllowsCallouts, Database.Batchable<ZuoraSubscriptionService.SubscriptionParam> {
    public List<ZuoraSubscriptionService.SubscriptionParam> allSubscriptionsToCreate;
    // We assume there's only one Product Rate Plan (Community Solar Subscription), and one Product Rate Plan Charge (Utility Credit) for new subscriptions
    // If we use other Product Rate Plan Charges, some of the logic to figure out the client/project combinations will change
    private String productRatePlanId;
    private String productRatePlanChargeId;
    @TestVisible
    private static ZuoraSubscriptionAsyncService nextAsyncService;
    @TestVisible
    private static List<ZuoraSubscriptionService.SubscriptionParam> batchedSubscriptionsToCreate;
    @TestVisible
    private static List<String> subscriptionsCreated;

    public ZuoraSubscriptionAsyncService() {
        allSubscriptionsToCreate = new List<ZuoraSubscriptionService.SubscriptionParam>();
    }

    public void initForDataLoad() {
        try {
            initForDataLoadInternal();
        } catch (Exception e) {
            Logger.logNow('ZuoraSubscriptionAsyncService', 'initForDataLoad', e.getMessage() + '\n' + e.getStackTraceString(), Logger.ERROR);
        }
    }

    public void initForScheduleZEnactment(List<Schedule_Z__c> scheduleZs) {
        try {
            initForScheduleZEnactmentInternal(scheduleZs);
        } catch (Exception e) {
            Set<String> ids = new Set<String>();
            for (Schedule_Z__c sz : scheduleZs) {
                ids.add(sz.Id);
            }
            Logger.logNow('ZuoraSubscriptionAsyncService', 'initForScheduleZEnactment', 'ScheduleZ Enactment for ' + ids +
                ' failed to process zuora subscriptions because of:\n' + e.getMessage() + '\n' + e.getStackTraceString(), Logger.ERROR);
        }
    }

    public void initForScheduleZEnactmentInternal(List<Schedule_Z__c> scheduleZs) {
        getRatePlanIds();
        Set<Id> accountIds = new Set<Id>();
        List<AggregateResult> scheduleZSubscriptionsByAccount = [
            SELECT Utility_Account_Subscription__r.Opportunity__r.Account.Id Id,
                Schedule_Z__r.Shared_Solar_System__r.Id systemId,
                Schedule_Z__r.Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Client_Account__r.Id clientId,
                MIN(Schedule_Z__r.Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Client_Account__r.Account_Number__c) clientName,
                MIN(Schedule_Z__r.Shared_Solar_System__r.Unique_ID__c)  projectName,
                MIN(Schedule_Z__r.Date_Enacted_by_Utility__c) billDate
            FROM Schedule_Z_Subscription__c
            WHERE Schedule_Z__c IN :scheduleZs
            GROUP BY Utility_Account_Subscription__r.Opportunity__r.Account.Id,
                Schedule_Z__r.Shared_Solar_System__r.Id,
                Schedule_Z__r.Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Client_Account__r.Id
        ];
        for (AggregateResult aggregateResult : scheduleZSubscriptionsByAccount) {
            accountIds.add(aggregateResult.Id);
        }
        Map<Id, Account> accountMap = new Map<Id, Account>([
            SELECT Id, Account_Number__c, Zuora_Id__c
            FROM Account
            WHERE Id IN :accountIds
        ]);

        Map<String, ZuoraSubscriptionService.SubscriptionParam> accountNumberToSubscriptionMap =
            new Map<String, ZuoraSubscriptionService.SubscriptionParam>();
        updateSubscriptionMap(scheduleZSubscriptionsByAccount, accountMap, accountNumberToSubscriptionMap);
        allSubscriptionsToCreate = accountNumberToSubscriptionMap.values();
    }

    public void initForDataLoadInternal() {
        getRatePlanIds();
        // We're not adding this to selector classes since they are for one-time data migration
        // Consumes ~31k query rows as of May 2019
        List<AggregateResult> systemsBillsByAccount = [
            SELECT Property_Account__r.Id Id, Shared_Solar_System__r.Id systemId, Client__r.Id clientId,
                MIN(Client__r.Account_Number__c) clientName,
                MIN(Shared_Solar_System__r.Unique_ID__c) projectName,
                MIN(Date__c) billDate
            FROM System_Bill__c
            GROUP BY Property_Account__r.Id, Shared_Solar_System__r.Id, Client__r.Id
        ];
        // Consumes ~3k query rows as of May 2019
        List<AggregateResult> scheduleZSubscriptionsByAccount = [
            SELECT Utility_Account_Subscription__r.Opportunity__r.Account.Id Id,
                Schedule_Z__r.Shared_Solar_System__r.Id systemId,
                Schedule_Z__r.Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Client_Account__r.Id clientId,
                MIN(Schedule_Z__r.Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Client_Account__r.Account_Number__c) clientName,
                MIN(Schedule_Z__r.Shared_Solar_System__r.Unique_ID__c)  projectName,
                MIN(Schedule_Z__r.Date_Enacted_by_Utility__c) billDate
            FROM Schedule_Z_Subscription__c
            WHERE Schedule_Z__r.Status__c IN ('Billing', 'Enacted by Utility')
            GROUP BY Utility_Account_Subscription__r.Opportunity__r.Account.Id,
                Schedule_Z__r.Shared_Solar_System__r.Id,
                Schedule_Z__r.Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Client_Account__r.Id
        ];
        Set<Id> accountIds = new Set<Id>();
        for (AggregateResult aggregateResult : systemsBillsByAccount) {
            accountIds.add(aggregateResult.Id);
        }
        for (AggregateResult aggregateResult : scheduleZSubscriptionsByAccount) {
            accountIds.add(aggregateResult.Id);
        }
        Map<Id, Account> accountMap = new Map<Id, Account>([
            SELECT Id, Account_Number__c, Zuora_Id__c
            FROM Account
            WHERE Id IN :accountIds
        ]);

        Map<String, ZuoraSubscriptionService.SubscriptionParam> accountNumberToSubscriptionMap =
            new Map<String, ZuoraSubscriptionService.SubscriptionParam>();
        updateSubscriptionMap(systemsBillsByAccount, accountMap, accountNumberToSubscriptionMap);
        updateSubscriptionMap(scheduleZSubscriptionsByAccount, accountMap, accountNumberToSubscriptionMap);
        allSubscriptionsToCreate = accountNumberToSubscriptionMap.values();
    }

    public void updateSubscriptionMap(List<AggregateResult> aggregateResults, Map<Id, Account> accountMap,
        Map<String, ZuoraSubscriptionService.SubscriptionParam> accountNumberToSubscriptionMap) {
        for (AggregateResult aggregateResult : aggregateResults) {
            Account propertyAccount = accountMap.get(aggregateResult.Id);
            if (propertyAccount.Zuora_Id__c == null) {
                throw new Util.BWException('Found an account that should have a Zuora Id but didn\'t: ' + aggregateResult.Id);
            }
            ZuoraSubscriptionService.OrderActionParam orderActionParam = new ZuoraSubscriptionService.OrderActionParam();
            orderActionParam.accountNumber = propertyAccount.Account_Number__c;
            Date systemBillDate = (Date) aggregateResult.get('billDate');
            orderActionParam.orderDate = systemBillDate.addMonths(-1);
            orderActionParam.contractEffectiveDate = systemBillDate.addMonths(-1);
            orderActionParam.productRatePlanId = productRatePlanId;
            orderActionParam.productRatePlanChargeId = productRatePlanChargeId;
            orderActionParam.clientName = (String) aggregateResult.get('clientName');
            orderActionParam.projectName = (String) aggregateResult.get('projectName');
            addOrderActionToMap(accountNumberToSubscriptionMap, orderActionParam);
        }
    }

    public void getRatePlanIds() {
        List<zqu__ProductRatePlan__c> ratePlans =
            ZuoraProductRatePlanSelector.getProductRatePlan('Community Solar Subscriptions');
        if (ratePlans.size() != 1) {
            throw new Util.BWException('Found too many Community Solar Subscription Rate Plans');
        }
        productRatePlanId = ratePlans[0].zqu__ZuoraId__c;

        List<zqu__ProductRatePlanCharge__c> ratePlanCharges =
            ZuoraProductRatePlanChargeSelector.getProductRatePlanCharge('Utility Credit', ratePlans[0].Id);
        if (ratePlanCharges.size() != 1) {
            throw new Util.BWException('Found too many Utility Credit Rate Plan Charges');
        }
        productRatePlanChargeId = ratePlanCharges[0].zqu__ZuoraId__c;
    }

    public static void addOrderActionToMap(Map<String, ZuoraSubscriptionService.SubscriptionParam> accountNumberToSubscriptionMap,
        ZuoraSubscriptionService.OrderActionParam orderActionParam) {
        ZuoraSubscriptionService.SubscriptionParam subscriptionParam = accountNumberToSubscriptionMap.get(orderActionParam.accountNumber);
        if (subscriptionParam == null) {
            accountNumberToSubscriptionMap.put(
                orderActionParam.accountNumber,
                new ZuoraSubscriptionService.SubscriptionParam(orderActionParam, null)
            );
        } else {
            if (orderActionParam.clientName == subscriptionParam.param.clientName &&
                orderActionParam.projectName == subscriptionParam.param.projectName) {
                // This client and project is already reflected in the subscription
                return;
            }
            ZuoraSubscriptionService.ClientProject clientProject =
                new ZuoraSubscriptionService.ClientProject(orderActionParam.clientName, orderActionParam.projectName);
            // This client/project combination might already exist, but since additionalClientProjects is a set, it's
            // safe to just add it
            subscriptionParam.additionalClientProjects.add(clientProject);
        }
    }

    public void initForChainedContinuation(List<ZuoraSubscriptionService.SubscriptionParam> remainingSubscriptionParams) {
        allSubscriptionsToCreate = remainingSubscriptionParams;
    }

    public Iterable<ZuoraSubscriptionService.SubscriptionParam> start(Database.BatchableContext context) {
        return allSubscriptionsToCreate;
    }

    public void execute(Database.BatchableContext context, List<ZuoraSubscriptionService.SubscriptionParam> scope) {
        createSubscriptions(scope);
    }

    public void finish(Database.BatchableContext context) {
    }

    public void execute(QueueableContext context) {
        createSubscriptions(allSubscriptionsToCreate);
    }

    public void createSubscriptions(List<ZuoraSubscriptionService.SubscriptionParam> allSubscriptionParams) {
        Integer callouts = 0;
        Integer calloutLimit = Limits.getLimitCallouts();
        Integer allSubscriptionParamsSize = allSubscriptionParams.size();
        // So that we don't need to load as much data for tests...
        if (Test.isRunningTest()) {
            calloutLimit = 5;
        }

        batchedSubscriptionsToCreate = new List<ZuoraSubscriptionService.SubscriptionParam>();
        // We only want to try to create as many subscription params as we have callouts to do
        for (Integer i = allSubscriptionParams.size()-1; i >= 0; i--) {
            if (callouts + allSubscriptionParams[i].estimateCallouts() < calloutLimit) {
                batchedSubscriptionsToCreate.add(allSubscriptionParams[i]);
                callouts += allSubscriptionParams[i].estimateCallouts();
                allSubscriptionParams.remove(i);
            } else {
                break;
            }
        }

        if (batchedSubscriptionsToCreate.size() > 0) {
            subscriptionsCreated = ZuoraSubscriptionService.createSubscriptions(batchedSubscriptionsToCreate);
        }

        // This should be empty if all of the subscriptions were created successfully. If there are any left because we
        // hit an exception (like ReadTimedOut), queue them again. While there is a risk of entering an infinite loop,
        // it's probably more likely that we hit some callout or Zuora exception in createSubscriptions that we want to
        // automatically retry.
        if (batchedSubscriptionsToCreate.size() > 0) {
            allSubscriptionParams.addAll(batchedSubscriptionsToCreate);
        }

        if (allSubscriptionParams.size() > 0) {
            nextAsyncService = new ZuoraSubscriptionAsyncService();
            nextAsyncService.initForChainedContinuation(allSubscriptionParams);
            if (!Test.isRunningTest()) {
                System.enqueueJob(nextAsyncService);
            }
        }
    }
}