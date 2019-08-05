@IsTest
public with sharing class ZuoraAccountSelectorTest {
    @IsTest
    static void testAccountQuery() {
        Account newSFAccount = new Account(
            Name = 'Account Name'
        );

        insert newSFAccount;

        Zuora__CustomerAccount__c newAccount = new Zuora__CustomerAccount__c(
            Name = 'Account Name',
            Zuora__Account__c = newSFAccount.Id,
            Zuora__Zuora_Id__c = '2c92c0f86b78f56c016b7b00480c2e24'
        );
        insert newAccount;

        ZuoraAccountSelector.AccountWithPaymentMethod acctWithPayMethod;
        acctWithPayMethod = ZuoraAccountSelector.getAccountWithDefaultPaymentMethod(newAccount.Id);

        System.assertEquals(230.00, acctWithPayMethod.account.Balance);
        System.assertEquals(false, acctWithPayMethod.account.AutoPay);
        System.assertEquals('***********0002', acctWithPayMethod.paymentMethod.CreditCardMaskNumber);
        System.assertEquals('CreditCard', acctWithPayMethod.paymentMethod.Type);
    }

    @IsTest
    static void testAccountWithPaymentMethodQuery() {
        String zuoraId = '2c92c0f86b78f56c016b7b00480c2e24';
        ZuoraAPI.ZuoraAccount account = ZuoraAccountSelector.getAccountFromZuora(zuoraId);

        System.assertEquals(false, account.AutoPay);
        System.assertEquals(230.00, account.Balance);
    }

    @IsTest
    static void testGetGateway() {
        ZuoraAPI.PaymentGateway shouldBeDefault = ZuoraAccountSelector.getGatewayIdFromGatewayName(null);
        ZuoraAPI.PaymentGateway shouldNotBeDefault = ZuoraAccountSelector.getGatewayIdFromGatewayName('Not Default Gateway');

        System.assertEquals('Default Gateway Name', shouldBeDefault.name);
        System.assertEquals('Not Default Gateway', shouldNotBeDefault.name);
        System.assertNotEquals(shouldBeDefault.id, shouldNotBeDefault.id);
    }
}