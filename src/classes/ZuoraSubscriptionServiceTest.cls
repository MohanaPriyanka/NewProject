/*************************************************************************************
 * Created By: peteryao on 2019-05-15  
 * Description:
 * Test:
 *************************************************************************************/
@IsTest
public with sharing class ZuoraSubscriptionServiceTest {
    @IsTest
    public static void testCreateSubscription() {
        ZuoraSubscriptionService.OrderActionParam param = new ZuoraSubscriptionService.OrderActionParam();
        param.accountNumber = 'BW-00000076';
        param.orderDate = Date.newInstance(2019,5,20);
        param.contractEffectiveDate = Date.newInstance(2019,5,20);
        param.productRatePlanId = '2c92c0f869c8e5c50169caec86e07095';
        param.productRatePlanChargeId = '2c92c0f969c8f15e0169caed586a1909';
        param.clientName = 'AES Distributed Energy';
        param.projectName = 'Albany Post Road Solar Farm';

        List<ZuoraSubscriptionService.ClientProject> clientProjects = new List<ZuoraSubscriptionService.ClientProject>();
        ZuoraSubscriptionService.ClientProject norton = new ZuoraSubscriptionService.ClientProject('Norton Solar Development', 'Norton Solar Farm');
        clientProjects.add(norton);
        ZuoraSubscriptionService.ClientProject dudley = new ZuoraSubscriptionService.ClientProject('AMP', 'Dudley #3');
        clientProjects.add(dudley);

        ZuoraSubscriptionService.SubscriptionParam subscriptionParam = new ZuoraSubscriptionService.SubscriptionParam(param, clientProjects);
        List<String> subscriptions = ZuoraSubscriptionService.createSubscriptions(new List<ZuoraSubscriptionService.SubscriptionParam>{subscriptionParam});
        System.assertEquals('A-S00000090', subscriptions[0]);
    }
}