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
        ZuoraAccountSelector selector = new ZuoraAccountSelector();
        ZuoraAPI.ZuoraAccount account = selector.getAccountFromZuora(zuoraId);

        System.assertEquals(false, account.AutoPay);
        System.assertEquals(230.00, account.Balance);
    }

    @IsTest
    static void testGetGateway() {
        ZuoraAccountSelector selector = new ZuoraAccountSelector();
        ZuoraAPI.PaymentGateway shouldBeDefault = selector.getGatewayIdFromGatewayName(null);
        ZuoraAPI.PaymentGateway shouldNotBeDefault = selector.getGatewayIdFromGatewayName('Not Default Gateway');

        System.assertEquals('Default Gateway Name', shouldBeDefault.name);
        System.assertEquals('Not Default Gateway', shouldNotBeDefault.name);
        System.assertNotEquals(shouldBeDefault.id, shouldNotBeDefault.id);
    }

    @IsTest
    private static void testGetAutopayAccountsWithBalance() {
        ZuoraAccountSelector selector = new ZuoraAccountSelector();
        List<ZuoraAPI.ZuoraAccount> accounts = selector.getAutopayAccountsWithBalance();
        System.assert(accounts.size() > 0);
    }
}