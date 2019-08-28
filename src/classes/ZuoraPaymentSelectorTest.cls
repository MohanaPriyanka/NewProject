/**
 * Created by PeterYao on 8/28/2019.
 */
@IsTest
public with sharing class ZuoraPaymentSelectorTest {
    @TestSetup
    public static void testDataSetup() {
        Account account = new Account(
            Name = 'Test'
        );
        insert account;

        Zuora__CustomerAccount__c billingAccount = new Zuora__CustomerAccount__c(
            Name = 'Test',
            Zuora__Account__c = account.Id
        );
        insert billingAccount;

        Zuora__Payment__c payment = new Zuora__Payment__c(
            Zuora__BillingAccount__c = billingAccount.Id,
            Zuora__EXT_ID__c = '1234'
        );
        insert payment;
    }

    @IsTest
    public static void testPaymentSelector() {
        Zuora__Payment__c payment = [SELECT Id FROM Zuora__Payment__c LIMIT 1];
        ZuoraPaymentSelector paymentSelector = new ZuoraPaymentSelector();
        List<Zuora__Payment__c> payments = paymentSelector.selectById(new Set<Id>{payment.Id});
        System.assertEquals(1, payments.size());
        System.assertEquals(payment.Id, payments[0].Id);
    }

    @IsTest
    public static void testPaymentSelectorInsufficientPermissions() {
        Zuora__Payment__c payment = [SELECT Id FROM Zuora__Payment__c LIMIT 1];
        ZuoraPaymentSelector paymentSelector = new ZuoraPaymentSelector();
        User pmStandardUser = [SELECT Id FROM User WHERE Profile.Name = 'PM Standard User' AND IsActive = TRUE LIMIT 1];
        Boolean exceptionCaught = false;
        // Singe an PM User should never have permissions to query payments
        System.runAs(pmStandardUser) {
            try {
                paymentSelector.selectById(new Set<Id>{payment.Id});
            } catch (Util.FatalBWException bwe) {
                exceptionCaught = true;
                System.assertEquals('Insufficient permissions', bwe.getMessage());
            }
        }
        System.assert(exceptionCaught);
    }
}