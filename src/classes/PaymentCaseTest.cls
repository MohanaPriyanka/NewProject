/**
 * Created by WParker on 8/1/2018, refactored for Zuora Nov, 2019.
 */

@IsTest
private class PaymentCaseTest {
    private static PaymentCaseCreator pcc = new PaymentCaseCreator();

    @IsTest
    private static void testExecute() {
        Boolean caughtException = false;
        try {
        Test.startTest();
        System.schedule('PaymentCaseCreator Apex Test','0 0 0 ? * * *',pcc);
        
        Test.stopTest();
        } catch (Exception e) {
            caughtException = true;
        }
        System.assert(!caughtException, 'Expected the scheduled job to run without exception');
    }

    @IsTest
    private static void testExecutePostQueryJob() {
        Util.disableTrigger('Send_Payment_Case_Emails__c');
        useMocks();
        ZuoraAPI.Payment payment = new ZuoraAPI.Payment();
        Id accountId = '001S000000yKIZjIAO';
        payment.CrmId = accountId;
        payment.paymentMethodId = '123456';
        payment.accountId = '2c92c0f86e3a939c016e3ca865542888';
        List<ZuoraAPI.Payment> failedAutopayPayments = new List<ZuoraAPI.Payment>{payment};
        String json = JSON.serialize(failedAutopayPayments);
        pcc.executePostQueryJob(null, json);
        System.assertEquals(1, MessagingService.emailsSent.size(), 'Expected one email to be sent for the failed payment');
        List<Error_Log__c> errorLogs = [SELECT Message__c FROM Error_Log__c WHERE Severity__c = :Logger.ERROR AND Method__c = 'createCases'];
        System.assertEquals(1, errorLogs.size(),
            'Expected an error since the payment method does not exist, but got these: ' + errorLogs);
        System.assert(errorLogs[0].Message__c.contains('Foreign key external ID: 123456 not found'));
    }

    @IsTest
    private static void testCreateCases() {
        useMocks();
        ZuoraAPI.Payment payment = new ZuoraAPI.Payment();
        Id accountId = '001S000000yKIZjIAO';
        payment.CrmId = accountId;
        payment.paymentMethodId = '123456';
        payment.accountId = '2c92c0f86e3a939c016e3ca865542888';
        List<ZuoraAPI.Payment> failedAutopayPayments = new List<ZuoraAPI.Payment>{payment};
        pcc.getAccountsForCases(failedAutopayPayments);
        Map<Case, ZuoraAPI.Payment> newCases = pcc.createCases(failedAutopayPayments);
        System.assertEquals(2, newCases.size(), 'Expected a case for the failed autopay and for the missing payment');
        List<Error_Log__c> errorLogs = [SELECT Class__c, Method__c, Message__c, Severity__c FROM Error_Log__c WHERE Severity__c = :Logger.ERROR];
        System.assertEquals(1, errorLogs.size(), 'Expected an error since we the payment method does not exist');
        System.assert(errorLogs[0].Message__c.contains('Foreign key external ID: 123456 not found'));
    }

    @IsTest
    private static void testCreateCaseForPayment() {
        useMocks();
        ZuoraAPI.Payment payment = new ZuoraAPI.Payment();
        Id accountId = '001S000000yKIZjIAO';
        payment.CrmId = accountId;
        payment.paymentMethodId = '123456';
        pcc.getAccountsForCases(new List<ZuoraAPI.Payment>{payment});
        Case newCase = pcc.createCaseForPayment(null, accountId, PaymentCaseCreator.OrderCaseType.InternalError);
        System.assert(newCase.Description.contains('No payment for an autopay account'), 'Expected a description to indicate a null payment');
        System.assertEquals(accountId, newCase.AccountId, 'Expected account id to be set');

        newCase = pcc.createCaseForPayment(payment, accountId, PaymentCaseCreator.OrderCaseType.PaymentStatusError);
        System.assertNotEquals(null, newCase.Zuora_Payment_Method__r, 'Expected payment method to be set');
        System.assertNotEquals(null, newCase.ContactId, 'Expected Contact Id to be set on the case');
    }

    @IsTest
    private static void testDoNotSendEmail() {
        Util.disableTrigger('Send_Payment_Case_Emails__c');
        useMocks();
        ZuoraAPI.Payment payment = new ZuoraAPI.Payment();
        Id accountId = '001S000000yKIZjIAO';
        payment.CrmId = accountId;
        payment.paymentMethodId = '123456';
        payment.GatewayResponse = 'The transaction is currently under review.';
        Case paymentCase = new Case(
            Id = Util.getFakeId(Case.SObjectType)
        );
        Map<Case, ZuoraAPI.Payment> caseToPaymentMap = new Map<Case, ZuoraAPI.Payment>();
        caseToPaymentMap.put(paymentCase, payment);

        pcc.getAccountsForCases(new List<ZuoraAPI.Payment>{payment});
        pcc.sendAllRequiredEmails(caseToPaymentMap);
        System.assertEquals(null, MessagingService.emailsSent, 'Did not expect a payment under review to send an email to the customer');
    }

    @IsTest
    private static void testDoSendEmail() {
        Util.disableTrigger('Send_Payment_Case_Emails__c');
        useMocks();
        ZuoraAPI.Payment payment = new ZuoraAPI.Payment();
        Id accountId = '001S000000yKIZjIAO';
        payment.CrmId = accountId;
        payment.paymentMethodId = '123456';
        payment.GatewayResponse = 'Invalid Route.';
        Case paymentCase = new Case(
            Id = Util.getFakeId(Case.SObjectType)
        );
        Map<Case, ZuoraAPI.Payment> caseToPaymentMap = new Map<Case, ZuoraAPI.Payment>();
        caseToPaymentMap.put(paymentCase, payment);

        pcc.getAccountsForCases(new List<ZuoraAPI.Payment>{payment});
        pcc.sendAllRequiredEmails(caseToPaymentMap);
        System.assertEquals(1, MessagingService.emailsSent.size(), 'Expected a single email to be sent');
    }

    @IsTest
    private static void testCloseAutopayCasesOnPaymentMethodUpdate() {
        useMocks();
        Id customerAccountId = Util.getFakeId(Zuora__CustomerAccount__c.SObjectType);

        Zuora__CustomerAccount__c oldCustomerAccount = new Zuora__CustomerAccount__c(
            Id = customerAccountId,
            Zuora__Account__c = '001S000000yKIZjIAO',
            Name = 'Old'
        );
        Zuora__CustomerAccount__c newCustomerAccount = new Zuora__CustomerAccount__c(
            Id = customerAccountId,
            Zuora__Account__c = '001S000000yKIZjIAO',
            Name = 'Old',
            Zuora__Default_Payment_Method__c = Util.getFakeId(Zuora__PaymentMethod__c.SObjectType)
        );
        Test.startTest();
        pcc.closeAutopayCasesOnPaymentMethodUpdate(
            new Map<Id, Zuora__CustomerAccount__c>{oldCustomerAccount.Id => oldCustomerAccount},
            new Map<Id, Zuora__CustomerAccount__c>{newCustomerAccount.Id => newCustomerAccount}
        );
        Test.stopTest();
        List<Error_Log__c> errorLogs = [
            SELECT Class__c, Method__c, Message__c
            FROM Error_Log__c
            WHERE Method__c = 'closeAutopayCasesFuture'
            AND Severity__c = :Logger.ERROR
        ];
        System.assertEquals(1, errorLogs.size());
        System.assert(errorLogs[0].Message__c.contains('Database error INVALID_CROSS_REFERENCE_KEY: invalid cross reference id'),
            'Expected to try to update a case but fail because of mocked data');
    }

    @IsTest
    private static void testDoNotCloseAutopayCasesOnPaymentMethodUpdate() {
        useMocks();
        Id customerAccountId = Util.getFakeId(Zuora__CustomerAccount__c.SObjectType);

        Zuora__CustomerAccount__c oldCustomerAccount = new Zuora__CustomerAccount__c(
            Id = customerAccountId,
            Zuora__Account__c = '001S000000yKIZjIAO',
            Name = 'Old',
            Zuora__Default_Payment_Method__c = Util.getFakeId(Zuora__PaymentMethod__c.SObjectType)
        );
        Zuora__CustomerAccount__c newCustomerAccount = new Zuora__CustomerAccount__c(
            Id = customerAccountId,
            Zuora__Account__c = '001S000000yKIZjIAO',
            Name = 'Updated',
            Zuora__Default_Payment_Method__c = Util.getFakeId(Zuora__PaymentMethod__c.SObjectType)
        );
        Test.startTest();
        pcc.closeAutopayCasesOnPaymentMethodUpdate(
            new Map<Id, Zuora__CustomerAccount__c>{oldCustomerAccount.Id => oldCustomerAccount},
            new Map<Id, Zuora__CustomerAccount__c>{newCustomerAccount.Id => newCustomerAccount}
        );
        Test.stopTest();
        List<Error_Log__c> errorLogs = [
            SELECT Class__c, Method__c, Message__c
            FROM Error_Log__c
            WHERE Method__c = 'closeAutopayCasesFuture'
            AND Severity__c = :Logger.ERROR
        ];
        System.assertEquals(0, errorLogs.size());
    }

    @IsTest
    private static void testCloseAutopayCasesFuture() {
        useMocks();
        Test.startTest();
        PaymentCaseCreator.closeAutopayCasesFuture(new Set<Id>());
        Test.stopTest();
        List<Error_Log__c> errorLogs = [
            SELECT Class__c, Method__c, Message__c
            FROM Error_Log__c
            WHERE Method__c = 'closeAutopayCasesFuture'
            AND Severity__c = :Logger.ERROR
        ];
        System.assertEquals(1, errorLogs.size());
        System.assert(errorLogs[0].Message__c.contains('Database error INVALID_CROSS_REFERENCE_KEY: invalid cross reference id'),
            'Expected to try to update a case but fail because of mocked data');
    }

    /*************
      *** MOCKS ***
      *************/
    public static void useMocks() {
        PaymentCaseCreator.accountsSelector = (AccountsSelector) Test.createStub(AccountsSelector.class, new AccountsSelectorMockImpl());
        PaymentCaseCreator.zuoraAccountSelector = (ZuoraAccountSelector) Test.createStub(ZuoraAccountSelector.class, new ZuoraAccountSelectorMockImpl());
    }

    public class AccountsSelectorMockImpl extends MockProvider {
        public AccountsSelectorMockImpl() {
    }

        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'selectAll' {
                    String json = '[{"attributes":{"type":"Account","url":"/services/data/v47.0/sobjects/Account/001S000000yKIZjIAO"},' +
                        '"Id":"001S000000yKIZjIAO","Name":"Denise Corcoran","BillingStreet":"90 Main","BillingCity":"Boston",' +
                        '"BillingState":"Massachusetts","BillingStateCode":"MA","BillingPostalCode":"12312","BillingCountry":"United States",' +
                        '"Send_Bills_Contact__c":"003S0000016Y24OIAS","Client_Brand_Key__c":"BluewaveLogo","Count_of_Large_Offtake_Opps__c":0,' +
                        '"Zuora_Id__c":"2c92c0f86e5e38b0016e5fc9f3da1612",' +
                         '"Cases":{"totalSize":1,"done":true,"records":[{"attributes":{"type":"Case","url":"/services/data/v47.0/sobjects/Case/500S000000BJ9ZOIA2"},' +
                         '"AccountId":"001S000000yKIZjIAO","Id":"500S000000BJ9ZOIA1","Zuora_Payment_Method__c":"a70S0000000E6KCIA1"}]},' +
                        '"Zuora__Invoices__r":{"totalSize":1,"done":true,"records":[' +
                        '{"attributes":{"type":"Zuora__ZInvoice__c","url":"/services/data/v47.0/sobjects/Zuora__ZInvoice__c/a7KS0000000ELWfMAO"},' +
                        '"Zuora__Account__c":"001S000000yKIZjIAO","Id":"a7KS0000000ELXKMA4","Zuora__DueDate__c":"2019-11-09"}]},' +
                        '"Opportunities":{"totalSize":1,"done":true,"records":[' +
                        '{"attributes":{"type":"Opportunity","url":"/services/data/v47.0/sobjects/Opportunity/006S000000CwOjyIAF"},' +
                        '"AccountId":"001S000000yKIZjIAO","Id":"006S000000CwOjyIAF","Shared_Solar_System__c":"a1JS0000003BMvJMAW",' +
                        '"Shared_Solar_System__r":{"attributes":{"type":"Shared_Solar_System__c","url":"/services/data/v47.0/sobjects/Shared_Solar_System__c/a1JS0000003BMvJMAW"},' +
                        '"Id":"a1JS0000003BMvJMAW","Product__c":"01tS0000005j7AWIAY","Utility__c":"a1MS0000008BldqMAC",' +
                        '"Product__r":{"attributes":{"type":"Product2","url":"/services/data/v47.0/sobjects/Product2/01tS0000005j7AWIAY"},' +
                        '"Id":"01tS0000005j7AWIAY","Program__c":"SREC - Community Solar"}}}]},' +
                        '"Send_Bills_Contact__r":{"attributes":{"type":"Contact","url":"/services/data/v47.0/sobjects/Contact/003S0000016Y24OIAS"},' +
                        '"Id":"003S0000016Y24OIAS","Email":"pyao@bluewavesolar.com","FirstName":"Albert","LastName":"Price 10"}}]';
                    List<Account> accounts = (List<Account>) System.JSON.deserialize(json, List<Account>.class);
                    return accounts;
        }
        }
            return null;
        }
        }
    public class ZuoraAccountSelectorMockImpl extends MockProvider {
        public ZuoraAccountSelectorMockImpl() {
    }

        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'getAutopayAccountsWithBalance' {
                    String json = '[' +
                        '{"Id":"2c92c0f86e3a939c016e3ca865542986","CrmId":"001S000000yKIPoIAO","Balance":0.04},' +
                        '{"Id":"2c92c0f86e3a939c016e3ca865542888","CrmId":"001S000000yKIZjIAO","Balance":4.44}' +
                        ']';
                    List<ZuoraAPI.ZuoraAccount> accounts = (List<ZuoraAPI.ZuoraAccount>) System.JSON.deserialize(json, List<ZuoraAPI.ZuoraAccount>.class);
                    return accounts;
            }
        }
            return null;
        }
    }
}