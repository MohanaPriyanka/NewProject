/*************************************************************************************
 * Created By: peteryao on 2019-05-15  
 * Description: 
 * Tested By: ZuoraSubscriptionServiceTest
 *************************************************************************************/

public with sharing class ZuoraSubscriptionService {
    public static Boolean allAccountsInZuora(List<Schedule_Z__c> scheduleZs) {
        // for each account on the schedule z
        // does it have a Zuora Id?
        // if not, log an error
        return true;
    }

    public static List<String> createSubscriptions(List<SubscriptionParam> subscriptionParams) {
        List<String> subscriptionsCreated = new List<String>();
        Integer callouts = 0;
        for (SubscriptionParam subscriptionParam : subscriptionParams) {
            callouts += subscriptionParam.estimateCallouts();
        }
        if (callouts >= 50) {
            throw new Util.BWException(callouts + ' callouts would be used by this method with these parameters: ' +
                JSON.serialize(subscriptionParams) + '. Invoke with fewer subscriptions');
        }

        for (SubscriptionParam subscriptionParam : subscriptionParams) {
            try {
                subscriptionsCreated.add(createSubscription(subscriptionParam.param, subscriptionParam.additionalClientProjects));
            } catch (Exception e) {
                Logger.logLater('ZuoraSubscriptionService', 'createSubscription', e.getMessage() + e.getStackTraceString());
            }
        }
        Logger.flushLogs();
        return subscriptionsCreated;
    }

    // Unfortunately, we can't create a subscription with multiple rate plan charges at once:
    // ("message" : "Not Allow use more than one chargeOverride on one product rateplan charge"),
    // so we create the subscription with one SRPC, and then do an order action for each client/project combination.
    private static String createSubscription(OrderActionParam param, List<ClientProject> additionalClientProjects) {
        ZuoraAPI.Order createNewSubscription = ZuoraSubscriptionService.getNewOrderRequest(param);
        HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('POST', '/v1/orders', createNewSubscription, false);
        ZuoraAPI.OrderActionResult newSubscriptionResult =
            (ZuoraAPI.OrderActionResult) JSON.deserialize(response.getBody(), ZuoraAPI.OrderActionResult.class);
        if (!newSubscriptionResult.success || newSubscriptionResult.subscriptions.size() != 1) {
            Logger.logLater('ZuoraSubscriptionService', 'createSubscriptionInternal', JSON.serializePretty(newSubscriptionResult));
            throw new Util.BWException('Unexpected result creating a new subscription');
        }

        param.subscriptionNumber = newSubscriptionResult.subscriptions[0].subscriptionNumber;

        if (additionalClientProjects == null || additionalClientProjects.size() == 0) {
            return param.subscriptionNumber;
        }

        for (ClientProject clientProject : additionalClientProjects) {
            param.clientName = clientProject.clientName;
            param.projectName = clientProject.projectName;
            ZuoraAPI.Order addProduct = ZuoraSubscriptionService.getAddProductRequest(param);
            HttpResponse addProductResponse = ZuoraAPIHelper.callJsonEndpoint('POST', '/v1/orders', addProduct, false);
            ZuoraAPI.OrderActionResult addProductResult =
                (ZuoraAPI.OrderActionResult) JSON.deserialize(addProductResponse.getBody(), ZuoraAPI.OrderActionResult.class);
            if (!addProductResult.success) {
                Logger.logLater('ZuoraSubscriptionService', 'createSubscriptionInternal', JSON.serializePretty(addProductResult));
                throw new Util.BWException('Unexpected result adding a rate plan charge to a new subscription');
            }
        }
        return param.subscriptionNumber;
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
        public ClientProject(String clientName, String projectName) {
            this.clientName = clientName;
            this.projectName = projectName;
        }
    }

    public class SubscriptionParam {
        public OrderActionParam param;
        public List<ClientProject> additionalClientProjects;
        public SubscriptionParam(OrderActionParam param, List<ClientProject> additionalClientProjects) {
            this.param = param;
            if (additionalClientProjects != null) {
                this.additionalClientProjects = additionalClientProjects;
            } else {
                this.additionalClientProjects = new List<ClientProject>();
            }

        }
        public Integer estimateCallouts() {
            return 1 + additionalClientProjects.size();
        }
    }
}