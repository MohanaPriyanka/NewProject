/*************************************************************************************
 * Created By: peteryao on 2019-05-15  
 * Description: 
 * Tested By: ZuoraSubscriptionServiceTest
 *************************************************************************************/

public with sharing class ZuoraSubscriptionService {
    @TestVisible
    private static Map<String, ZuoraAPI.OrderBySubscriptionOwner> ordersBySubscriptionOwnerCache = new Map<String, ZuoraAPI.OrderBySubscriptionOwner>();

    public static List<String> createSubscriptions(List<SubscriptionParam> subscriptionParams) {
        List<String> subscriptionsCreated = new List<String>();
        Integer callouts = 0;
        for (SubscriptionParam subscriptionParam : subscriptionParams) {
            callouts += subscriptionParam.estimateCallouts();
        }
        if (callouts >= Limits.getLimitCallouts() && !Test.isRunningTest()) {
            throw new Util.BWException(callouts + ' callouts would be used by this method with these parameters: ' +
                JSON.serialize(subscriptionParams) + '. Invoke with fewer subscriptions to stay under the limit of ' + Limits.getLimitCallouts());
        }

        // We want to return the subscriptions created, and also
        for (Integer i = subscriptionParams.size()-1; i >= 0; i--) {
            try {
                subscriptionsCreated.add(createSubscription(subscriptionParams[i].param, subscriptionParams[i].additionalClientProjects));
            } catch (Exception e) {
                Logger.logLater('ZuoraSubscriptionService', 'createSubscription', e.getMessage() + e.getStackTraceString());
                continue;
            }
            subscriptionParams.remove(i);
        }
        Logger.flushLogs();
        return subscriptionsCreated;
    }

    // Unfortunately, we can't create a subscription with multiple rate plan charges at once:
    // ("message" : "Not Allow use more than one chargeOverride on one product rateplan charge"),
    // so we create the subscription with one SRPC, and then do an order action for each client/project combination.
    @TestVisible
    private static String createSubscription(OrderActionParam newSubscription, Set<ClientProject> additionalClientProjects) {
        ZuoraAPI.OrderBySubscriptionOwner obso = getOrderBySubscriptionOwner(newSubscription.accountNumber);
        if (obso.hasSubscription()) {
            // Since there's already a subscription, we won't create a new one (which includes a client/project that we'll
            // need to add if it doesn't exist
            newSubscription.subscriptionNumber = obso.getSubscriptionNumber();
            // We don't want to do any order actions with a contract effective earlier than the existing contract effective
            // date (for instance, we loaded with a system bill date, and then a new SZ is enacted with an earlier date).
            Date existingContractEffectiveDate = obso.getContractEffective();
            if (newSubscription.orderDate < existingContractEffectiveDate) {
                newSubscription.orderDate = existingContractEffectiveDate;
            }
            ClientProject newSubClientProject = new ClientProject(newSubscription.clientName, newSubscription.projectName);
            Set<ClientProject> existingClientProjects = obso.getClientProjectsFromOrders();
            // Since we don't want to add any client/projects that already exist, we'll remove them
            additionalClientProjects.removeAll(existingClientProjects);
            // But if the new subscription has a client/project that doesn't exist, we need to add it as an additional
            // client project since we won't be creating a new subscription
            if (!existingClientProjects.contains(newSubClientProject)) {
                additionalClientProjects.add(newSubClientProject);
            }
        } else {
            ZuoraAPI.Order createNewSubscription = ZuoraSubscriptionService.getNewOrderRequest(newSubscription);
            HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('POST', '/v1/orders', createNewSubscription, false);
            ZuoraAPI.OrderActionResult newSubscriptionResult =
                (ZuoraAPI.OrderActionResult) JSON.deserialize(response.getBody(), ZuoraAPI.OrderActionResult.class);
            if (!newSubscriptionResult.success || newSubscriptionResult.subscriptions.size() != 1) {
                Logger.logLater('ZuoraSubscriptionService', 'createSubscriptionInternal', JSON.serializePretty(newSubscriptionResult));
                throw new Util.BWException('Unexpected result creating a new subscription');
            }

            newSubscription.subscriptionNumber = newSubscriptionResult.subscriptions[0].subscriptionNumber;
        }

        if (additionalClientProjects == null || additionalClientProjects.size() == 0) {
            return newSubscription.subscriptionNumber;
        }

        for (ClientProject clientProject : additionalClientProjects) {
            newSubscription.clientName = clientProject.clientName;
            newSubscription.projectName = clientProject.projectName;
            ZuoraAPI.Order addProduct = ZuoraSubscriptionService.getAddProductRequest(newSubscription);
            HttpResponse addProductResponse = ZuoraAPIHelper.callJsonEndpoint('POST', '/v1/orders', addProduct, false);
            ZuoraAPI.OrderActionResult addProductResult =
                (ZuoraAPI.OrderActionResult) JSON.deserialize(addProductResponse.getBody(), ZuoraAPI.OrderActionResult.class);
            if (!addProductResult.success) {
                Logger.logLater('ZuoraSubscriptionService', 'createSubscriptionInternal', JSON.serializePretty(addProductResult));
                throw new Util.BWException('Unexpected result adding a rate plan charge to a new subscription');
            }
        }
        return newSubscription.subscriptionNumber;
    }

    public static ZuoraAPI.Order getNewOrderRequest(OrderActionParam param) {
        ZuoraAPI.Order order = new ZuoraAPI.Order(param.accountNumber, param.orderDate);
        ZuoraAPI.Subscription subscription = order.addSubscription();
        ZuoraAPI.OrderAction orderAction = subscription.addOrderAction('CreateSubscription', param.contractEffectiveDate);
        ZuoraAPI.CreateSubscription createSubscription = orderAction.addCreateSubscription();
        createSubscription.addEvergreenTerm();
        ZuoraAPI.SubscribeToRatePlan subscribeToRatePlan = createSubscription.addSubscribeToRatePlan(param.productRatePlanId);
        subscribeToRatePlan.addChargeOverride(param.productRatePlanChargeId, param.clientName, param.projectName);
        return order;
    }

    // Used to create a JSON body to add a Subscription Rate Plan Charge to an existing subscription
    public static ZuoraAPI.Order getAddProductRequest(OrderActionParam param) {
        ZuoraAPI.Order order = new ZuoraAPI.Order(param.accountNumber, param.orderDate);
        ZuoraAPI.Subscription subscription = order.addSubscription(param.subscriptionNumber);
        ZuoraAPI.OrderAction orderAction = subscription.addOrderAction('AddProduct', param.contractEffectiveDate);
        ZuoraAPI.AddProduct addProduct = orderAction.addAddProduct(param.productRatePlanId);
        addProduct.addChargeOverride(param.productRatePlanChargeId, param.clientName, param.projectName);
        return order;
    }

    public static ZuoraAPI.OrderBySubscriptionOwner getOrderBySubscriptionOwner(String accountNumber) {
        if (ordersBySubscriptionOwnerCache.containsKey(accountNumber)) {
            return ordersBySubscriptionOwnerCache.get(accountNumber);
        }
        ZuoraAPI.OrderBySubscriptionOwner obso =
            getOrderBySubscriptionOwnerPage('/v1/orders/subscriptionOwner/' + accountNumber + '?pageSize=40', null);
        ordersBySubscriptionOwnerCache.put(accountNumber, obso);
        return obso;
    }

    @TestVisible
    private static ZuoraAPI.OrderBySubscriptionOwner getOrderBySubscriptionOwnerPage(String url, List<ZuoraAPI.Order> ordersAlreadyRetrieved) {
        HttpResponse response =
            ZuoraAPIHelper.callJsonEndpoint('GET', url, null, false);
        String cleanJSON = ZuoraAPIHelper.cleanJSON(response.getBody());
        ZuoraAPI.OrderBySubscriptionOwner obso =
            (ZuoraAPI.OrderBySubscriptionOwner) JSON.deserialize(cleanJSON, ZuoraAPI.OrderBySubscriptionOwner.class);
        if (ordersAlreadyRetrieved != null) {
            obso.orders.addAll(ordersAlreadyRetrieved);
        }
        ordersAlreadyRetrieved = obso.orders;

        if (obso.nextPage != null) {
            return getOrderBySubscriptionOwnerPage(obso.nextPage, ordersAlreadyRetrieved);
        } else {
            return obso;
        }
    }

    // The OrderActionParam represents the subscription that we'll create. We always need to create a Subscription Rate
    // Plan Charge with the client/project combination - that is mandatory.
    // There can be a list of client/project combinations included with the OrderActionParam (in the SubscriptionParam
    // structure) that get turned into additional Subscription Rate Plan Charges.
    public class OrderActionParam {
        public String accountNumber;
        public String subscriptionNumber;
        public Date orderDate;
        public Date contractEffectiveDate;
        public String productRatePlanId;
        public String productRatePlanChargeId;
        public String clientName;
        public String projectName;
    }

    public class ClientProject {
        public String clientName;
        public String projectName;
        public String chargeNumber;
        public String productRatePlanChargeId;
        public ClientProject(String clientName, String projectName) {
            this.clientName = clientName;
            this.projectName = projectName;
        }
        public ClientProject(String clientName, String projectName, String chargeNumber, String productRatePlanChargeId) {
            this.clientName = clientName;
            this.projectName = projectName;
            this.chargeNumber = chargeNumber;
            this.productRatePlanChargeId = productRatePlanChargeId;
        }
        // Required because we have sets of Client Projects for data load
        public Boolean equals(Object o) {
            if ((o == null) || !(o instanceof ClientProject)) {
                return false;
            }
            ClientProject clientProject = (ClientProject) o;
            return (clientProject.clientName == this.clientName && clientProject.projectName == this.projectName);
        }
        public Integer hashCode() {
            return (clientName +  projectName).hashCode();
        }
    }

    public class SubscriptionParam {
        public OrderActionParam param;
        public Set<ClientProject> additionalClientProjects;
        public SubscriptionParam(OrderActionParam param, Set<ClientProject> additionalClientProjects) {
            this.param = param;
            if (additionalClientProjects != null) {
                this.additionalClientProjects = additionalClientProjects;
            } else {
                this.additionalClientProjects = new Set<ClientProject>();
            }

        }
        public Integer estimateCallouts() {
            // One query to get existing subscriptions, another query to create the subscription, and then queries
            // to create each of the additional client projects
            return 2 + additionalClientProjects.size();
        }
    }
}