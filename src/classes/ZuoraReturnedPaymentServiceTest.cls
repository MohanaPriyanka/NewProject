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
}