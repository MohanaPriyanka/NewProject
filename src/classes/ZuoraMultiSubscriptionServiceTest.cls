/**
 * Created by peteryao on 4/17/20.
 */
@IsTest
public with sharing class ZuoraMultiSubscriptionServiceTest {
    @IsTest
    public static void testCreateSubscription() {
        ZuoraAPI.SubscriptionsByAccount sba = new ZuoraSubscriptionService().getSubscriptionsByAccount('BW-00000076');
        System.assert(sba.getClientProjects().contains(getClientProject('BW-0009470', 'SSS-000009')),
            'Mock should have BW-0009470/SSS-000009 in it');

        ZuoraSubscriptionService.OrderActionParam param = new ZuoraSubscriptionService.OrderActionParam();
        param.accountNumber = 'BW-00000076';
        param.orderDate = Date.newInstance(2019,5,20);
        param.contractEffectiveDate = Date.newInstance(2019,5,20);
        param.productRatePlanId = '2c92c0f869c8e5c50169caec86e07095';
        param.productRatePlanChargeId = '2c92c0f969c8f15e0169caed586a1909';
        param.clientName = 'AES Distributed Energy';
        param.projectName = 'Albany Post Road Solar Farm';

        Set<ZuoraSubscriptionService.ClientProject> clientProjects = new Set<ZuoraSubscriptionService.ClientProject>();
        clientProjects.add(getClientProject('Norton Solar Development', 'Norton Solar Farm'));
        clientProjects.add(getClientProject('AMP', 'Dudley #3'));

        ZuoraSubscriptionService.SubscriptionParam subscriptionParam = new ZuoraSubscriptionService.SubscriptionParam(param, clientProjects);
        List<String> subscriptions = ZuoraMultiSubscriptionService.createSubscriptions(new List<ZuoraSubscriptionService.SubscriptionParam>{subscriptionParam});
        System.assertEquals('A-S00000090', subscriptions[0]);
    }

    @IsTest
    public static void testExistingSubscriptionWithDifferentSRPC() {
        ZuoraAPI.SubscriptionsByAccount sba = new ZuoraSubscriptionService().getSubscriptionsByAccount('ExistingAccount');
        System.assert(sba.getClientProjects().contains(getClientProject('BW-0009470', 'SSS-000009')),
            'Mock should have BW-0009470/SSS-000009 in it');

        ZuoraSubscriptionService.OrderActionParam newSubscription = new ZuoraSubscriptionService.OrderActionParam();
        newSubscription.accountNumber = 'ExistingAccount';
        newSubscription.productRatePlanId = '2c92c0f86ab120de016ab427c7d8234d';
        newSubscription.productRatePlanChargeId = '2c92c0f86ab120de016ab427c97b2368';
        newSubscription.clientName = 'AMP';
        newSubscription.projectName = 'Dudley';
        // ExistingAccount should have BW-9470/SSS-9, but not AMP/Dudley. So we should expect to see one
        // /orders call to add an AMP/Dudley subscription
        ZuoraMultiSubscriptionService.createSubscription(newSubscription, new Set<ZuoraSubscriptionService.ClientProject>{getClientProject('BW-0009470', 'SSS-000009')});

        // Expect one error log for ZuoraAPIHelper, callJSONEndpoint, Fine
        System.assertEquals(1, Logger.logs.values().size());
        // Expect two messages, one for the subscriptions by account query, and the other for the orders call
        System.assertEquals(2, Logger.logs.values()[0].size());
        System.assert(Logger.logs.values()[0][0].message.contains('/v1/subscriptions/account'));
        System.assert(Logger.logs.values()[0][1].message.contains('/v1/orders'));
        System.assert(Logger.logs.values()[0][1].message.contains('"customFields":{"Project__c":"Dudley","ClientOwner__c":"AMP"}'));
    }

    @IsTest
    public static void testExistingSubscriptionWithSameSRPC() {
        ZuoraAPI.SubscriptionsByAccount sba = new ZuoraSubscriptionService().getSubscriptionsByAccount('ExistingAccount');
        System.assert(sba.getClientProjects().contains(getClientProject('BW-0009470', 'SSS-000009')),
            'Mock should have BW-0009470/SSS-000009 in it');

        ZuoraSubscriptionService.OrderActionParam newSubscription = new ZuoraSubscriptionService.OrderActionParam();
        newSubscription.accountNumber = 'ExistingAccount';
        newSubscription.productRatePlanId = '2c92c0f86ab120de016ab427c7d8234d';
        newSubscription.productRatePlanChargeId = '2c92c0f86ab120de016ab427c97b2368';
        newSubscription.clientName = 'BW-0009470';
        newSubscription.projectName = 'SSS-000009';
        newSubscription.orderDate = Date.newInstance(2000,1,1);
        newSubscription.contractEffectiveDate = Date.newInstance(2000,1,1);
        // ExistingAccount has BW-9470/SSS-000009, but not AMP/Dudley. So we should expect to see an orders call to creat the AMP/Dudley
        ZuoraMultiSubscriptionService.createSubscription(newSubscription, new Set<ZuoraSubscriptionService.ClientProject>{getClientProject('AMP', 'Dudley')});

        // Expect one error log for ZuoraAPIHelper, callJSONEndpoint, Fine
        System.assertEquals(1, Logger.logs.values().size());
        // Expect two messages, one for the subscriptionByAccount query, and the other for the orders call
        System.assertEquals(2, Logger.logs.values()[0].size());
        System.assert(Logger.logs.values()[0][0].message.contains('/v1/subscriptions/account'));
        System.assert(Logger.logs.values()[0][1].message.contains('/v1/orders'));
        System.assert(Logger.logs.values()[0][1].message.contains('"customFields":{"Project__c":"Dudley","ClientOwner__c":"AMP"}'));
    }

    @IsTest
    public static void testExistingSubscription() {
        ZuoraAPI.SubscriptionsByAccount sba = new ZuoraSubscriptionService().getSubscriptionsByAccount('ExistingAccount');
        System.assert(sba.getClientProjects().contains(getClientProject('BW-0009470', 'SSS-000009')),
            'Mock should have BW-0009470/SSS-000009 in it');
        System.assert(sba.getClientProjects().contains(getClientProject('BW-0021776', 'SSS-000009')),
            'Mock should have BW-0021776/SSS-000009 in it');

        ZuoraSubscriptionService.OrderActionParam newSubscription = new ZuoraSubscriptionService.OrderActionParam();
        newSubscription.accountNumber = 'ExistingAccount';
        newSubscription.productRatePlanId = '2c92c0f86ab120de016ab427c7d8234d';
        newSubscription.productRatePlanChargeId = '2c92c0f86ab120de016ab427c97b2368';
        newSubscription.clientName = 'BW-0009470';
        newSubscription.projectName = 'SSS-000009';
        ZuoraMultiSubscriptionService.createSubscription(newSubscription, new Set<ZuoraSubscriptionService.ClientProject>{getClientProject('BW-0021776', 'SSS-000009')});

        // Expect one error log for ZuoraAPIHelper, callJSONEndpoint, Fine
        System.assertEquals(1, Logger.logs.values().size());
        // Expect one messages, for for the subscriptionsByAccount query
        System.assertEquals(1, Logger.logs.values()[0].size());
        System.assert(Logger.logs.values()[0][0].message.contains('/v1/subscriptions/account'));
    }

    @IsTest
    private static void testCalculateAdditionalSubscriptions() {
        // BW-0001/SSS-0001 is enacted
        ZuoraSubscriptionService.OrderActionParam newSubscription = new ZuoraSubscriptionService.OrderActionParam();
        newSubscription.clientName = 'BW-0001';
        newSubscription.projectName = 'SSS-0001';

        // For a customer that already has this subscription
        ZuoraAPI.SubscriptionsByAccount existingSubscriptions = new ZuoraAPI.SubscriptionsByAccount();
        ZuoraAPI.Subscription subscription = new ZuoraAPI.Subscription();
        existingSubscriptions.subscriptions = new List<ZuoraAPI.Subscription>{subscription};
        ZuoraAPI.RatePlan ratePlan = new ZuoraAPI.RatePlan();
        subscription.ratePlans = new List<ZuoraAPI.RatePlan>{ratePlan};
        subscription.status = 'Active';
        ZuoraAPI.RatePlanCharge ratePlanCharge = new ZuoraAPI.RatePlanCharge();
        ratePlan.ratePlanCharges = new List<ZuoraAPI.RatePlanCharge>{ratePlanCharge};
        ratePlanCharge.ClientOwner_Zcustom = 'BW-0001';
        ratePlanCharge.Project_Zcustom = 'SSS-0001';

        Set<ZuoraSubscriptionService.ClientProject> additionalClientProjects = new Set<ZuoraSubscriptionService.ClientProject>();
        ZuoraMultiSubscriptionService.calculateAdditionalSubscriptions(newSubscription, existingSubscriptions, additionalClientProjects);
        System.assertEquals(0, additionalClientProjects.size(),
            'Expected to not need any additional client projects since the new subscription is in the existing subscription');

        ZuoraSubscriptionService.ClientProject clientProject = getClientProject('BW-0001', 'SSS-0001');
        additionalClientProjects.add(clientProject);
        ZuoraMultiSubscriptionService.calculateAdditionalSubscriptions(newSubscription, existingSubscriptions, additionalClientProjects);
        System.assertEquals(0, additionalClientProjects.size(),
            'Expected to not need any additional client projects since the new subscription adn additional subscriptions is in the existing subscription');

        additionalClientProjects.add(getClientProject('BW-0001', 'SSS-0001'));
        additionalClientProjects.add(getClientProject('BW-0002', 'SSS-0002'));
        additionalClientProjects.add(getClientProject('BW-0003', 'SSS-0003'));
        ZuoraMultiSubscriptionService.calculateAdditionalSubscriptions(newSubscription, existingSubscriptions, additionalClientProjects);
        System.assertEquals(2, additionalClientProjects.size(), 'Expected to need a client project for BW-0002/SSS-0002 and BW-0003/SSS-0003');
        System.assert(additionalClientProjects.contains(getClientProject('BW-0002', 'SSS-0002')));
        System.assert(additionalClientProjects.contains(getClientProject('BW-0003', 'SSS-0003')));
    }

    private static ZuoraSubscriptionService.ClientProject getClientProject(String client, String project) {
        ZuoraSubscriptionService.OrderActionParam orderActionParam = new ZuoraSubscriptionService.OrderActionParam();
        orderActionParam.accountNumber = 'BW-01234';
        Date systemBillDate = Date.newInstance(2020,1,1);
        orderActionParam.orderDate = systemBillDate.addMonths(-1);
        orderActionParam.contractEffectiveDate = systemBillDate.addMonths(-1);
        orderActionParam.productRatePlanId = '12345';
        orderActionParam.productRatePlanChargeId = '12345';
        orderActionParam.clientName = client;
        orderActionParam.projectName = project;
        orderActionParam.zuoraAccountId = '123123123';
        return new ZuoraSubscriptionService.ClientProject(orderActionParam);
    }
}