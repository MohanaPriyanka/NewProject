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

    @IsTest
    public static void testPaymentApplicationDetail(){
        ZuoraOutstandingItemsService.OutstandingItem itemOne = new ZuoraOutstandingItemsService.OutstandingItem();
        itemOne.AmountOutstanding = 5;
        itemOne.AmountToApply = 0;
        itemOne.EffectiveDate = Datetime.newInstance(2019,02,20,0,0,0);
        itemOne.IsInvoiceItem = true;

        ZuoraOutstandingItemsService.OutstandingItem itemTwo = new ZuoraOutstandingItemsService.OutstandingItem();
        itemTwo.AmountOutstanding = 50;
        itemTwo.AmountToApply = 0;
        itemTwo.EffectiveDate = Datetime.newInstance(2019,01,20,0,0,0);
        itemTwo.IsInvoiceItem = false;

        // Don't expect this to have more than 2 decimals,
        // but just to double check that rounding issues won't be duplicated in Zuora:
        ZuoraOutstandingItemsService.OutstandingItem itemThree = new ZuoraOutstandingItemsService.OutstandingItem();
        itemThree.AmountOutstanding = 2.008;
        itemThree.AmountToApply = 0;
        itemThree.EffectiveDate = Datetime.newInstance(2019,03,20,0,0,0);
        itemThree.IsInvoiceItem = true;

        ZuoraOutstandingItemsService.OutstandingItem itemFour = new ZuoraOutstandingItemsService.OutstandingItem();
        itemFour.AmountOutstanding = 10;
        itemFour.AmountToApply = 0;
        itemFour.EffectiveDate = Datetime.newInstance(2017,02,20,0,0,0);
        itemFour.IsInvoiceItem = false;

        List<ZuoraOutstandingItemsService.OutstandingItem> unsortedItemList = new List<ZuoraOutstandingItemsService.OutstandingItem>{
            itemFour, itemOne, itemThree, itemTwo
        };
        unsortedItemList.sort();

        ZuoraAPI.Payment payment = new ZuoraAPI.Payment();
        payment.amount = 62.12;

        // Test partial payment:
        ZuoraPaymentPageController.PaymentApplication application;
        application = ZuoraPaymentPageController.applyPaymentToOutstandingItems(unsortedItemList, payment);
        System.assertEquals(1,application.invoices.size());
        System.assertEquals(2,application.debitMemos.size());
        System.assertEquals(10,application.debitMemos[0].amount);
        System.assertEquals(50,application.debitMemos[1].amount);
        System.assertEquals(2.12,application.invoices[0].amount);

        // Test full payment:
        payment.amount = 67;
        ZuoraPaymentPageController.PaymentApplication secondApplication;
        secondApplication = ZuoraPaymentPageController.applyPaymentToOutstandingItems(unsortedItemList, payment);
        System.assertEquals(2,secondApplication.invoices.size());
        System.assertEquals(2,secondApplication.debitMemos.size());
        System.assertEquals(10,secondApplication.debitMemos[0].amount);
        System.assertEquals(50,secondApplication.debitMemos[1].amount);
        System.assertEquals(5,secondApplication.invoices[0].amount);
        System.assertEquals(2,secondApplication.invoices[1].amount);
    }

    @IsTest
    public static void testPaymentApplication(){
        // Don't expect this to have more than 2 decimals,
        // but just to double check that rounding issues won't be duplicated in Zuora:
        ZuoraAPI.Payment payment = new ZuoraAPI.Payment();
        payment.amount = 345.558;
        payment.accountId = '2c92c0f86ae3a4ad016ae5e247886605';
        payment.id = 'XXXXXX';

        List<ZuoraOutstandingItemsService.OutstandingItem> outstandingItems;
        outstandingItems = ZuoraOutstandingItemsService.processOutstandingParentRecordsByDate(payment.accountId);

        System.assertEquals(3,outstandingItems.size());
        System.assertEquals(270,outstandingItems[0].AmountOutstanding);
        System.assertEquals(810,outstandingItems[1].AmountOutstanding);
        System.assertEquals(30,outstandingItems[2].AmountOutstanding);

        System.assert(outstandingItems[0].EffectiveDate < outstandingItems[1].EffectiveDate);
        System.assert(outstandingItems[1].EffectiveDate < outstandingItems[2].EffectiveDate);

        ZuoraPaymentPageController.PaymentApplication application;
        application = ZuoraPaymentPageController.applyPaymentToOutstandingItems(outstandingItems, payment);

        System.assertEquals(2,application.invoices.size());
        System.assertEquals(270,application.invoices[0].amount);
        System.assertEquals(75.56,application.invoices[1].amount);
    }

    @IsTest
    public static void testPaymentApplicationCall() {
        ZuoraAPI.Payment payment = new ZuoraAPI.Payment();
        payment.amount = 200;
        payment.accountId = '2c92c0f86ae3a4ad016ae5e247886605';
        payment.id = 'XXXXXX';

        ZuoraPaymentPageController.applyPaymentToBalance(payment);

        List<Error_Log__c> logs = [
            SELECT Id
            FROM Error_Log__c
            WHERE Class__c = 'ZuoraPaymentPageController'
            AND Method__c = 'applyPaymentToBalance'
        ];

        System.assertEquals(0,logs.size());
    }
}