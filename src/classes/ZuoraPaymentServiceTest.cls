/**
 * Created by PeterYao on 1/7/2020.
 */

@IsTest
public with sharing class ZuoraPaymentServiceTest {
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
        ZuoraAPI.ZuoraPaymentApplication application;
        ZuoraPaymentService paymentService = new ZuoraPaymentService();
        application = paymentService.getPaymentApplicationForOutstandingItems(unsortedItemList, payment);
        System.assertEquals(1,application.invoices.size());
        System.assertEquals(2,application.debitMemos.size());
        System.assertEquals(10,application.debitMemos[0].amount);
        System.assertEquals(50,application.debitMemos[1].amount);
        System.assertEquals(2.12,application.invoices[0].amount);

        // Test full payment:
        payment.amount = 67;
        ZuoraAPI.ZuoraPaymentApplication secondApplication;
        secondApplication = paymentService.getPaymentApplicationForOutstandingItems(unsortedItemList, payment);
        System.assertEquals(2,secondApplication.invoices.size());
        System.assertEquals(2,secondApplication.debitMemos.size());
        System.assertEquals(10,secondApplication.debitMemos[0].amount);
        System.assertEquals(50,secondApplication.debitMemos[1].amount);
        System.assertEquals(5,secondApplication.invoices[0].amount);
        System.assertEquals(2,secondApplication.invoices[1].amount);
    }

    @IsTest
    public static void testPaymentApplicationInFuture(){
        Datetime futureDate = System.now() + 3;
        ZuoraOutstandingItemsService.OutstandingItem itemOne = new ZuoraOutstandingItemsService.OutstandingItem();
        itemOne.AmountOutstanding = 5;
        itemOne.AmountToApply = 0;
        itemOne.EffectiveDate = Datetime.newInstance(2019,01,20,0,0,0);
        itemOne.IsInvoiceItem = true;

        ZuoraOutstandingItemsService.OutstandingItem itemTwo = new ZuoraOutstandingItemsService.OutstandingItem();
        itemTwo.AmountOutstanding = 50;
        itemTwo.AmountToApply = 0;
        itemTwo.EffectiveDate = futureDate;
        itemTwo.IsInvoiceItem = false;

        ZuoraOutstandingItemsService.OutstandingItem itemThree = new ZuoraOutstandingItemsService.OutstandingItem();
        itemThree.AmountOutstanding = 40;
        itemThree.AmountToApply = 0;
        itemThree.EffectiveDate = futureDate + 3;
        itemThree.IsInvoiceItem = false;

        List<ZuoraOutstandingItemsService.OutstandingItem> itemList = new List<ZuoraOutstandingItemsService.OutstandingItem>{itemOne};

        ZuoraAPI.Payment payment = new ZuoraAPI.Payment();
        payment.amount = 55;

        ZuoraAPI.ZuoraPaymentApplication application;
        ZuoraPaymentService paymentService = new ZuoraPaymentService();
        application = paymentService.getPaymentApplicationForOutstandingItems(itemList, payment);
        System.assertEquals(1,application.invoices.size());
        System.assertEquals(0,application.debitMemos.size());
        System.assertEquals(DateUtil.convertGmtToDate(System.now()), application.effectiveDate,
            'Expected effective date to be today since outstanding items are effective in the past');

        itemList.add(itemTwo);
        itemList.sort();
        application = paymentService.getPaymentApplicationForOutstandingItems(itemList, payment);
        System.assertEquals(1,application.invoices.size());
        System.assertEquals(1,application.debitMemos.size());
        System.assertEquals(DateUtil.convertGmtToDate(futureDate), application.effectiveDate,
            'Expected effective date to be the latest outstanding item\'s effective date');

        itemList.add(itemThree);
        itemList.sort();
        application = paymentService.getPaymentApplicationForOutstandingItems(itemList, payment);
        System.assertEquals(1,application.invoices.size());
        System.assertEquals(1,application.debitMemos.size());
        System.assertEquals(DateUtil.convertGmtToDate(futureDate), application.effectiveDate,
            'Expected effective date to be the the effective date of the latest outstanding item that is getting applied');
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
        outstandingItems = ZuoraOutstandingItemsService.getOutstandingItemParentsByDate(payment.accountId);

        System.assertEquals(3,outstandingItems.size());
        System.assertEquals(270,outstandingItems[0].AmountOutstanding);
        System.assertEquals(810,outstandingItems[1].AmountOutstanding);
        System.assertEquals(30,outstandingItems[2].AmountOutstanding);

        System.assert(outstandingItems[0].EffectiveDate < outstandingItems[1].EffectiveDate);
        System.assert(outstandingItems[1].EffectiveDate < outstandingItems[2].EffectiveDate);

        ZuoraAPI.ZuoraPaymentApplication application;
        ZuoraPaymentService paymentService = new ZuoraPaymentService();
        application = paymentService.getPaymentApplicationForOutstandingItems(outstandingItems, payment);

        System.assertEquals(2,application.invoices.size());
        System.assertEquals(270,application.invoices[0].amount);
        System.assertEquals(75.56,application.invoices[1].amount);
    }

    @IsTest
    public static void testPostQueryExecution(){
        String response = '' +
            '[{"Id":"2c92c0fa6e3a9395016e3ea23a912962","accountid":"2c92c0f86ae3a4ad016ae5e247886605",' +
            '"unappliedamount":311.930000000,"paymentmethodid":"2c92c0f868a2023a0168a79e7f4f3f70",' +
            '"status":"Processed"},' +
            '{"Id":"2c92c0fb6e3aa322016e3e9c15022235","accountid":"2c92c0f86e3a939f016e3c9d34e33c6a",' +
            '"unappliedamount":152.150000000,"paymentmethodid":"2c92c0f868a2023a0168a79e7f4f3f70",' +
            '"status":"Processed"},' +
            '{"Id":"2c92c0fa6e3a9391016e3e7c5b082795","accountid":"2c92c0f86e3a939c016e3caa3bfc3533",' +
            '"unappliedamount":229.020000000,"paymentmethodid":"2c92c0f868a2023a0168a79e7f4f3f70",' +
            '"status":"Processed"},' +
            '{"Id":"2c92c0fa6e3a9395016e3e802d7b2752","accountid":"2c92c0f86e3a939c016e3ca94c8f2cec",' +
            '"unappliedamount":109.700000000,"paymentmethodid":"2c92c0f868a2023a0168a79e7f4f3f70",' +
            '"status":"Processed"},' +
            '{"Id":"2c92c0fb6e3aa321016e3ea07bfb4d64","accountid":"2c92c0f86e3a939f016e3ca9d2ab17ff",' +
            '"unappliedamount":211.800000000,"paymentmethodid":"2c92c0f868a2023a0168a79e7f4f3f70",' +
            '"status":"Processed"},' +
            '{"Id":"2c92c0fb6e3aa322016e3ea4ab237244","accountid":"2c92c0f96e3aa333016e3ca1efa01cd3",' +
            '"unappliedamount":128.590000000,"paymentmethodid":"2c92c0f868a2023a0168a79e7f4f3f70",' +
            '"status":"Processed"}]';

        List<Error_Log__c> beforeLogs = [
            SELECT Id, Class__c, Method__c, Message__c
            FROM Error_Log__c
            WHERE Method__c = 'callJsonEndpoint'
        ];
        System.assertEquals(0,beforeLogs.size());

        Test.startTest();
        ZuoraPaymentService service = new ZuoraPaymentService();
        ZuoraDataQueryService.ProcessingParameter processingParameter = new ZuoraDataQueryService.ProcessingParameter('PaymentService');
        processingParameter.methodName = 'PaymentsWithUnappliedBalance';
        service.executePostQueryJob(processingParameter, response);
        Test.stopTest();

        List<Error_Log__c> afterLogs = [
            SELECT Id, Class__c, Method__c, Message__c
            FROM Error_Log__c
            WHERE Method__c = 'callJsonEndpoint'
        ];

        Boolean paymentApp = false;
        for (Error_Log__c log : afterLogs){
            if (log.Message__c != null && log.Message__c.contains('/payments/') && log.Message__c.contains('/apply')){
                paymentApp = true;
            }
        }
        System.assert(paymentApp);
    }

    @IsTest
    private static void testApplyToMultiGatewayBalance() {
        ZuoraAPIHelperTest.testSetup();
        String response = '' +
            '[{"id":"2c92c086729245f3017295ab520e6a77","ParentId":"2c92c086729245f3017295ab51ea6a75","IsInvoiceItem":true,"Project":"SSS-000215","Client":"BW-0035924","PaymentGatewayId":"2c92c0f9699ec9fe0169a68ab88b6ae3","AmountOutstanding":71.820000000,"EffectiveDate":"2020-04-20"},\n' +
            '{"id":"2c92c08572923a9d01729583e48a67d0","ParentId":"2c92c08572923a9d01729583e47167ce","IsInvoiceItem":true,"Project":"SSS-000215","Client":"BW-0035924","PaymentGatewayId":"2c92c0f9699ec9fe0169a68ab88b6ae3","AmountOutstanding":84.860000000,"EffectiveDate":"2020-03-20"},\n' +
            '{"id":"2c92c0fa729d8bfc01729e755dc47136","ParentId":"2c92c0fa729d8bfc01729e755dba7135","IsInvoiceItem":false,"Project":"SSS-000214","Client":"BW-0035924","PaymentGatewayId":"2c92c0f96d82c23b016da3c1ad9170f6","AmountOutstanding":43.320000000,"EffectiveDate":"2020-06-10"},\n' +
            '{"id":"2c92c0fa729d8bed01729e7489f17f3a","ParentId":"2c92c0fa729d8bed01729e7489e87f39","IsInvoiceItem":false,"Project":"SSS-000215","Client":"BW-0035924","PaymentGatewayId":"2c92c0f9699ec9fe0169a68ab88b6ae3","AmountOutstanding":1.110000000,"EffectiveDate":"2020-06-10"}]';
        String paymentJSON = '{"unappliedAmount":157.790000000,"paymentMethodId":"2c92c0f9729889aa01729abdd7553ee1",' +
            '"id":"2c92c0fa729d8bed01729e7bcb6c16ea","gatewayName":"CS Receivables Co TEST",' +
            '"gatewayId":"2c92c0f9699ec9fe0169a68ab88b6ae3","amount":157.790000000,"accountId":"2c92c0f972924cb80172957f6e9e6e42"}';
        String otherPaymentsToApplyJSON = '[{"unappliedAmount":43.320000000,"paymentMethodId":"2c92c0f9729889aa01729abdd7553ee1",' +
            '"id":"2c92c0fa729d8bed01729e7bd0c11716","gatewayName":"Joe Jenny","gatewayId":"2c92c0f96d82c23b016da3c1ad9170f6",' +
            '"amount":43.320000000,"accountId":"2c92c0f972924cb80172957f6e9e6e42"}]';
        ZuoraDataQueryService.ProcessingParameter processingParameter = new ZuoraDataQueryService.ProcessingParameter();
        processingParameter.optionalStrings = new Map<String, String>();
        processingParameter.optionalStrings.put('Payment', paymentJSON);
        processingParameter.optionalStrings.put('OtherPaymentsToApply', otherPaymentsToApplyJSON);
        ZuoraPaymentService paymentService = new ZuoraPaymentService();

        Test.startTest();
        List<ZuoraAPI.Payment> otherPaymentsToApply = paymentService.applyToMultiGatewayBalance(response, processingParameter);
        Test.stopTest();

        System.assertEquals(1, ZuoraAPIHelper.endpointsCalled.size(), 'Expected to make one callout');
        System.assert(ZuoraAPIHelper.endpointsCalled[0].endpoint.contains('/apply'), 'Expected callout to be /apply');
        System.assertEquals(otherPaymentsToApplyJSON,  JSON.serialize(otherPaymentsToApply, true),
            'Expected ZuoraPaymentService to queue other payments to apply after applying this payment');

    }

    @IsTest
    private static void testApplyToMultiGatewayBalanceWithLocking() {
        ZuoraAPIHelperTest.testSetup();
        String response = '' +
            '[{"id":"2c92c086729245f3017295ab520e6a77","ParentId":"2c92c086729245f3017295ab51ea6a75","IsInvoiceItem":true,"Project":"SSS-000215","Client":"BW-0035924","PaymentGatewayId":"2c92c0f9699ec9fe0169a68ab88b6ae3","AmountOutstanding":71.820000000,"EffectiveDate":"2020-04-20"},\n' +
            '{"id":"2c92c08572923a9d01729583e48a67d0","ParentId":"2c92c08572923a9d01729583e47167ce","IsInvoiceItem":true,"Project":"SSS-000215","Client":"BW-0035924","PaymentGatewayId":"2c92c0f9699ec9fe0169a68ab88b6ae3","AmountOutstanding":84.860000000,"EffectiveDate":"2020-03-20"},\n' +
            '{"id":"2c92c0fa729d8bfc01729e755dc47136","ParentId":"2c92c0fa729d8bfc01729e755dba7135","IsInvoiceItem":false,"Project":"SSS-000214","Client":"BW-0035924","PaymentGatewayId":"2c92c0f96d82c23b016da3c1ad9170f6","AmountOutstanding":43.320000000,"EffectiveDate":"2020-06-10"},\n' +
            '{"id":"2c92c0fa729d8bed01729e7489f17f3a","ParentId":"2c92c0fa729d8bed01729e7489e87f39","IsInvoiceItem":false,"Project":"SSS-000215","Client":"BW-0035924","PaymentGatewayId":"2c92c0f9699ec9fe0169a68ab88b6ae3","AmountOutstanding":1.110000000,"EffectiveDate":"2020-06-10"}]';
        String paymentJSON = '{"unappliedAmount":157.790000000,"paymentMethodId":"2c92c0f9729889aa01729abdd7553ee1",' +
            '"id":"2c92c0fa729d8bed01729e7bcb6c16eaOPTIMISTICLOCKING","gatewayName":"CS Receivables Co TEST",' +
            '"gatewayId":"2c92c0f9699ec9fe0169a68ab88b6ae3","amount":157.790000000,"accountId":"2c92c0f972924cb80172957f6e9e6e42"}';
        String otherPaymentsToApplyJSON = '[{"unappliedAmount":43.320000000,"paymentMethodId":"2c92c0f9729889aa01729abdd7553ee1",' +
            '"id":"2c92c0fa729d8bed01729e7bd0c11716","gatewayName":"Joe Jenny","gatewayId":"2c92c0f96d82c23b016da3c1ad9170f6",' +
            '"amount":43.320000000,"accountId":"2c92c0f972924cb80172957f6e9e6e42"}]';
        ZuoraDataQueryService.ProcessingParameter processingParameter = new ZuoraDataQueryService.ProcessingParameter();
        processingParameter.optionalStrings = new Map<String, String>();
        processingParameter.optionalStrings.put('Payment', paymentJSON);
        processingParameter.optionalStrings.put('OtherPaymentsToApply', otherPaymentsToApplyJSON);
        processingParameter.enableRetries();
        ZuoraPaymentService paymentService = new ZuoraPaymentService();

        try {
            paymentService.applyToMultiGatewayBalance(response, processingParameter);
            System.assert(false, 'Expected to throw a RetriableException');
        } catch (ZuoraDataQueryService.RetriableException re) {
            System.assertEquals(1, processingParameter.optionalIntegers.get(processingParameter.RETRY_ATTEMPT),
                'Expected the processing parameter retry attempt to be incremented when retrying');
        }
    }

    @IsTest
    private static void testApplyToBalanceWithMultipleGateways() {
        String paymentJSON = '{"unappliedAmount":157.790000000,"paymentMethodId":"2c92c0f9729889aa01729abdd7553ee1",' +
            '"id":"2c92c0fa729d8bed01729e7bcb6c16ea","gatewayName":"CS Receivables Co TEST",' +
            '"gatewayId":"2c92c0f9699ec9fe0169a68ab88b6ae3","amount":157.790000000,"accountId":"2c92c0f972924cb80172957f6e9e6e42"}';
        String otherPaymentsToApplyJSON = '[{"unappliedAmount":43.320000000,"paymentMethodId":"2c92c0f9729889aa01729abdd7553ee1",' +
            '"id":"2c92c0fa729d8bed01729e7bd0c11716","gatewayName":"Joe Jenny","gatewayId":"2c92c0f96d82c23b016da3c1ad9170f6",' +
            '"amount":43.320000000,"accountId":"2c92c0f972924cb80172957f6e9e6e42"}]';
        ZuoraAPI.Payment successfulPayment = (ZuoraAPI.Payment) JSON.deserialize(paymentJSON, ZuoraAPI.Payment.class);
        List<ZuoraAPI.Payment> otherPaymentsToApply = (List<ZuoraAPI.Payment>) JSON.deserialize(otherPaymentsToApplyJSON, List<ZuoraAPI.Payment>.class);
        ZuoraPaymentService zuoraPaymentService = new ZuoraPaymentService();

        System.assertEquals(2, new ZuoraSubscriptionService().getSubscriptionsByAccount(successfulPayment.accountId).getNumberOfGateways(),
            'Expected our test to be for a customer with multiple gateways');

        List<Zuora_Data_Query__c> zuoraDataQueries = [SELECT Id, Processing_Parameter__c FROM Zuora_Data_Query__c];
        System.assertEquals(0, zuoraDataQueries.size());
        zuoraPaymentService.applyPaymentToBalance(successfulPayment, otherPaymentsToApply);
        zuoraDataQueries = [SELECT Id, Processing_Parameter__c FROM Zuora_Data_Query__c];
        System.assertEquals(1, zuoraDataQueries.size(),
            'When applying payments to a multi-gateway customer, we should start a data query to get outstanding items');
        ZuoraDataQueryService.ProcessingParameter processingParameter =
            (ZuoraDataQueryService.ProcessingParameter) JSON.deserialize(zuoraDataQueries[0].Processing_Parameter__c, ZuoraDataQueryService.ProcessingParameter.class);
        System.assertEquals(paymentJSON, processingParameter.optionalStrings.get('Payment'),
            'After outstanding items are retrieved, we apply this payment');
        System.assertEquals(otherPaymentsToApplyJSON, processingParameter.optionalStrings.get('OtherPaymentsToApply'),
            'After applying the payment, we queue other payments to apply');
    }

}