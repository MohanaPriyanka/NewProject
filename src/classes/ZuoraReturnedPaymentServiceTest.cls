/**
 * Created by PeterYao on 8/26/2019.
 */
@IsTest
public with sharing class ZuoraReturnedPaymentServiceTest {
    public static void useMocks() {
        ZuoraController.paymentSelector = (ZuoraPaymentSelector) Test.createStub(ZuoraPaymentSelector.class, new MockZuoraPaymentSelector());
    }
    @TestSetup public static void testDataSetup() {
        ZuoraCreditDebitMemoServiceTest.testDataSetup();
        ZuoraAPIHelperTest.testSetup();
        GatewaySelectorTest.testDataSetup();

        Account property = new Account(name = 'Account Property');
        insert property;

        Zuora__CustomerAccount__c billingAccount = new Zuora__CustomerAccount__c(
            Name = 'Test BillingAccount',
            Zuora__Zuora_Id__c = 'XXXXXXXXXX123',
            Zuora__Account__c = property.Id
        );
        insert billingAccount;

        Zuora__PaymentMethod__c payMethod = new Zuora__PaymentMethod__c(
            Name = 'XX',
            Zuora__BillingAccount__c = billingAccount.Id,
            Zuora__External_Id__c = '2c92c0f86a0c41a5016a1f41d63a2f96'
        );
        insert payMethod;

        Zuora__Payment__c payment = new Zuora__Payment__c(
            Zuora__PaymentMethodId__c = '2c92c0f86a0c41a5016a1f41d63a2f96',
            Name = 'PY1234',
            Zuora__BillingAccount__c = billingAccount.Id,
            Zuora__Amount__c = 23
        );
        insert payment;
    }

    @IsTest
    private static void testConvertPaymentToDebitMemos() {
        Test.startTest();
        ZuoraReturnedPaymentService returnedPaymentService = new ZuoraReturnedPaymentService();
        List<ZuoraAPI.DebitMemo> debitMemos =
            returnedPaymentService.convertPaymentToDebitMemos('2c92c0fb6cb90e36016cc137e05d46dc');
        Test.stopTest();
        Integer itemPartCalls = 0, invoiceItemCalls = 0, debitMemoCalls = 0;
        for (ZuoraAPIHelper.EndpointCall endpointCall : ZuoraAPIHelper.endpointsCalled) {
            if (endpointCall.endpoint.contains('itemparts')) {
                itemPartCalls++;
            } else if (endpointCall.endpoint.contains('invoice-item')) {
                invoiceItemCalls++;
            } else if (endpointCall.endpoint.contains('debitmemos')) {
                debitMemoCalls++;
            }
        }
        // This payment has 2 parts: a debit memo and invoice. The invoice has two invoice items
        System.assertEquals(2, itemPartCalls);
        System.assertEquals(1, debitMemoCalls);
        System.assertEquals(2, invoiceItemCalls);
        System.assertEquals(3, debitMemos.size(), 'Expected to get three debit memos to reverse this payment');
        for (ZuoraAPI.DebitMemo debitMemo : debitMemos) {
            if (debitMemo.charges[0].amount == 13.67) {
                debitMemo.ClientOwner_Zcustom = 'BW-0023170';
                debitMemo.Project_Zcustom = 'SSS-000024';
            } else if (debitMemo.charges[0].amount == 134.70) {
                debitMemo.ClientOwner_Zcustom = 'BW-00000385';
                debitMemo.Project_Zcustom = 'SSS-000099';
            } else if (debitMemo.charges[0].amount == 120.21) {
                debitMemo.ClientOwner_Zcustom = 'BW-00000385';
                debitMemo.Project_Zcustom = 'SSS-000098';
            } else {
                System.assert(false, 'Debit memos should be one of the amounts of the payment part items!');
            }
        }
    }

    @IsTest
    private static void testMarkReturn() {
        Test.startTest();
        ZuoraReturnedPaymentService returnedPaymentService = new ZuoraReturnedPaymentService();
        Boolean exceptionCaught = false;
        try {
            returnedPaymentService.convertPaymentToDebitMemos('ALREADYRETURNED');
        } catch (Exception e) {
            exceptionCaught = true;
            System.assert(e.getMessage().contains('This payment is already marked as returned'),
                'Excepted to catch an error that prevents payments from being returned twice');
        }
        System.assert(exceptionCaught, 'Excepted to catch an error that prevents payments from being returned twice');
        Test.stopTest();
    }

    @IsTest
    private static void testPaymentReturnWebservice() {
        Test.startTest();
        useMocks();
        ZuoraController.reverseReturnedPayment(Util.getFakeId(Schema.Zuora__Payment__c.SObjectType));
        Test.stopTest();
        Integer paymentCalls = 0, debitMemoCalls = 0;
        for (ZuoraAPIHelper.EndpointCall endpointCall : ZuoraAPIHelper.endpointsCalled) {
            if (endpointCall.endpoint.contains('payments')) {
                paymentCalls++;
            } else if (endpointCall.endpoint.contains('debitmemos')) {
                debitMemoCalls++;
            }
        }
        System.assertEquals(5, paymentCalls, 'Expected a GET payment, GET payment part, two GET payment part items, and PUT payment');
        System.assertEquals(7, debitMemoCalls, 'Expected a GET debitmemo, 3 POST debitmemo, and 3 POST debitmemo/post');
    }

    @IsTest
    private static void testNotEnoughCalloutsToReversePayment() {
        // Reversing the payment requires 10 callouts, plus 6 callouts to create/post debit memos, and 1 to update the payment.
        // Setting the number of callouts used at 85 won't give it enough
        ZuoraAPIHelper.numberCalloutsForZuoraNamespace = 85;
        Test.startTest();
        useMocks();
        ZuoraController.reverseReturnedPayment(Util.getFakeId(Schema.Zuora__Payment__c.SObjectType));
        Test.stopTest();
        List<Error_Log__c> errorLogs = [
            SELECT Id, Message__c
            FROM Error_Log__c
            WHERE Class__c = 'ZuoraController'
            AND (NOT Method__c = 'getPaymentMethod')
            AND Severity__c = :Logger.ERROR
        ];
        System.assertEquals(1, errorLogs.size());
        System.assert(errorLogs[0].Message__c.contains('Not enough callouts'));
    }

    /*************
     *** MOCKS ***
     *************/

    public class MockZuoraPaymentSelector extends MockProvider {
        public MockZuoraPaymentSelector() {
        }

        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'selectById' {
                    List<Zuora__Payment__c> payments = new List<Zuora__Payment__c>();
                    payments.add(new Zuora__Payment__c(
                        Zuora__External_Id__c = '2c92c0fb6cb90e36016cc137e05d46dc',
                        Zuora__EXT_ID__c = '2c92c0fb6cb90e36016cc137e05d46dc'
                    ));
                    return payments;
                }
            }
            return null;
        }
    }

    @IsTest
    private static void testCaseCreation() {
        List<Zuora__Payment__c> payment = [
            SELECT Id, Zuora__BillingAccount__r.Zuora__Account__c, Zuora__PaymentMethodId__c
            FROM Zuora__Payment__c
        ];
        System.assertEquals(1,payment.size());
        System.assertNotEquals(null,payment[0].Zuora__BillingAccount__r.Zuora__Account__c);
        System.assertNotEquals(null,payment[0].Zuora__PaymentMethodId__c);

        List<Case> beforeCases = [
            SELECT Id, Zuora_Payment_Method__c, AccountId
            FROM Case
        ];
        System.assertEquals(0,beforeCases.size());

        Test.startTest();
            ZuoraPaymentSelector selector = new ZuoraPaymentSelector();
            List<Zuora__Payment__c> paymentList = selector.selectById(new Set<Id>{payment[0].Id});
            ZuoraReturnedPaymentService returnedPaymentService = new ZuoraReturnedPaymentService();
            List<Zuora__PaymentMethod__c> methods = ZuoraPaymentMethodSelector.getSFRecordFromZuoraId(new List<String>{payment[0].Zuora__PaymentMethodId__c});
            returnedPaymentService.payMethod = methods[0];
            Case caseToInsert = returnedPaymentService.createCaseForReturns(paymentList[0]);
            insert caseToInsert;
        Test.stopTest();

        List<Case> afterCases = [
            SELECT Id, Zuora_Payment_Method__r.Zuora__External_Id__c, AccountId
            FROM Case
        ];

        System.assertEquals(1, afterCases.size());
        System.assertEquals(payment[0].Zuora__BillingAccount__r.Zuora__Account__c, afterCases[0].AccountId);
        System.assertEquals(payment[0].Zuora__PaymentMethodId__c, afterCases[0].Zuora_Payment_Method__r.Zuora__External_Id__c);
    }

    @IsTest
    private static void testPaymentMethodUpdate() {
        List<Error_Log__c> beforeLogs = [
            SELECT Id, Message__c, Method__c, Class__c
            FROM Error_Log__c
            WHERE Method__c = 'callJsonEndpoint'
        ];
        System.assertEquals(0,beforeLogs.size());

        List<Zuora__Payment__c> payment = [
            SELECT Id, Zuora__BillingAccount__r.Zuora__Account__c, Zuora__Payment_Method__c
            FROM Zuora__Payment__c
        ];
        System.assertEquals(1,payment.size());

        Test.startTest();
            ZuoraPaymentSelector selector = new ZuoraPaymentSelector();
            List<Zuora__Payment__c> paymentList = selector.selectById(new Set<Id>{payment[0].Id});
            ZuoraReturnedPaymentService returnedPaymentService = new ZuoraReturnedPaymentService();
            Boolean needsUpdate = returnedPaymentService.removePaymentMethodFromAccount(paymentList[0]);
            Logger.flushLogs();
        Test.stopTest();

        System.assert(needsUpdate);

        List<Error_Log__c> afterLogs = [
            SELECT Id, Message__c, Method__c, Class__c
            FROM Error_Log__c
            WHERE Method__c = 'callJsonEndpoint'
        ];
        System.assertEquals(1,afterLogs.size());
        System.assert(afterLogs[0].Message__c.contains('/v1/action/query'));
        System.assert(afterLogs[0].Message__c.contains('/v1/action/update'));
    }
}