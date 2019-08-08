/*************************************************************************************
 * Created By: peteryao on 2019-04-11  
 * Description: 
 * Test: 
 *************************************************************************************/
@IsTest
public with sharing class ZuoraPaymentPageControllerTest {
    public static Zuora__CustomerAccount__c testSetupCreateAccount() {
        Account newSFAccount = new Account(
            Name = 'Account Name',
            Zuora_Id__c = '2c92c0f86b78f56c016b7b00480c2e24'
        );

        insert newSFAccount;

        Zuora__CustomerAccount__c newAccount = new Zuora__CustomerAccount__c(
            Name = 'Account Name',
            Zuora__Account__c = newSFAccount.Id,
            Zuora__Zuora_Id__c = '2c92c0f86b78f56c016b7b00480c2e24'
        );
        insert newAccount;
        return newAccount;
    }

    @IsTest
    public static void testGetPageMetadata() {
        Test.setMock(HttpCalloutMock.class, new ZuoraAPIMock());
        ZuoraPaymentPageController.PaymentPageMetadata paymentPageMetadata = ZuoraPaymentPageController.getPageMetadata();
        System.assertEquals('30689', paymentPageMetadata.ccRsaSignature.tenantId);

        Organization o = [SELECT IsSandbox FROM Organization];
        List<Zuora_Setting__mdt> zuoraSettings = [
            SELECT Id, API_Endpoint_URL__c
            FROM Zuora_Setting__mdt
            WHERE Is_Sandbox__c = :o.IsSandbox
        ];
        System.assertEquals(zuoraSettings[0].API_Endpoint_URL__c, paymentPageMetadata.zuoraSetting.API_Endpoint_URL__c);
    }

    @IsTest
    public static void testGetPaymentMethod() {
        Test.setMock(HttpCalloutMock.class, new ZuoraAPIMock());
        ZuoraAPI.PaymentMethod paymentMethod = ZuoraPaymentPageController.getPaymentMethod('foo');
        System.assertEquals('AmericanExpress', paymentMethod.CreditCardType);
    }

    @IsTest
    public static void testMakePayment() {
        Zuora__CustomerAccount__c sfAccount = testSetupCreateAccount();

        ZuoraAccountSelector.AccountWithPaymentMethod acctWithPay;
        acctWithPay = ZuoraPaymentPageController.getAccountAndPayMethodFromZuora(sfAccount.Id);

        System.assertEquals('2c92c0f86b78f56c016b7b00480c2e24', acctWithPay.account.Id);
        System.assertEquals('2c92c0f86a0c41a5016a1f41d63a2f96', acctWithPay.paymentMethod.Id);

        ZuoraPaymentPageController.PaymentResponse payResponse;
        payResponse = ZuoraPaymentPageController.makePayment(
            acctWithPay.account.Id,
            acctWithPay.account.PaymentGateway,
            acctWithPay.paymentMethod.Id,
            23.00
        );

        system.assertEquals('Processed',payResponse.status);
        system.assertEquals(true,payResponse.success);
        system.assertEquals('This transaction has been approved.',payResponse.gatewayResponse);
        system.assertEquals('1',payResponse.gatewayResponseCode);
    }

    @IsTest
    public static void testToggleAutopay() {
        Zuora__CustomerAccount__c sfAccount = testSetupCreateAccount();

        ZuoraAccountSelector.AccountWithPaymentMethod acctWithPay;
        acctWithPay = ZuoraPaymentPageController.getAccountAndPayMethodFromZuora(sfAccount.Id);

        System.assertEquals('2c92c0f86b78f56c016b7b00480c2e24', acctWithPay.account.Id);
        System.assertEquals('2c92c0f86a0c41a5016a1f41d63a2f96', acctWithPay.paymentMethod.Id);

        Boolean turnOnAutopay = ZuoraPaymentPageController.toggleAutopayAndPaymentMethod(
            acctWithPay.account.Id,
            true,
            acctWithPay.paymentMethod.Id
        );

        Boolean turnOffAutopay = ZuoraPaymentPageController.toggleAutopayAndPaymentMethod(
            acctWithPay.account.Id,
            false,
            null
        );

        System.assertEquals(true,turnOnAutopay);
        System.assertEquals(true,turnOffAutopay);
    }

    @IsTest
    public static void testLinkPayMethod() {
        Zuora__CustomerAccount__c sfAccount = testSetupCreateAccount();

        ZuoraAccountSelector.AccountWithPaymentMethod acctWithPay;
        acctWithPay = ZuoraPaymentPageController.getAccountAndPayMethodFromZuora(sfAccount.Id);

        System.assertEquals('2c92c0f86b78f56c016b7b00480c2e24', acctWithPay.account.Id);
        System.assertEquals('2c92c0f86a0c41a5016a1f41d63a2f96', acctWithPay.paymentMethod.Id);

        Boolean isSuccess = ZuoraPaymentPageController.linkPaymentMethodToAccount(
            acctWithPay.account.Id,
            acctWithPay.paymentMethod.Id
        );

        System.assertEquals(true, isSuccess);
    }
}