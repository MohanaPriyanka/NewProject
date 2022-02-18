/**
 * Created by PeterYao on 7/8/2021.
 */
@IsTest
public with sharing class ZuoraGatewayAssignerTest {
    @IsTest
    private static void systemTest() {
        Zuora__PaymentGateway__c ampGateway = new Zuora__PaymentGateway__c(
            Name = 'Amp Gateway',
            Zuora__IsDefault__c = 'false'
        );
        Zuora__PaymentGateway__c bcsGateway = new Zuora__PaymentGateway__c(
            Name = 'BCS Single Gateway',
            Zuora__IsDefault__c = 'true'
        );
        insert new List<Zuora__PaymentGateway__c>{ampGateway, bcsGateway};

        Account account1 = new Account(
            Name = 'Test'
        );
        Account account2 = new Account(
            Name = 'Test2'
        );
        insert new List<Account>{account1, account2};

        Zuora__CustomerAccount__c billingAccount1 = new Zuora__CustomerAccount__c(
            Name = 'Test',
            Zuora__Account__c = account1.Id
        );
        Zuora__CustomerAccount__c billingAccount2 = new Zuora__CustomerAccount__c(
            Name = 'Test2',
            Zuora__PaymentGateway__c = ampGateway.Id,
            Zuora__Account__c = account2.Id
        );
        insert new List<Zuora__CustomerAccount__c>{billingAccount1, billingAccount2};

        Zuora__Payment__c bcsPayment1 = new Zuora__Payment__c(
            Zuora__BillingAccount__c = billingAccount1.Id,
            Zuora__EXT_ID__c = '1234',
            Zuora__Type__c = 'Electronic',
            Lockbox__c = 'BWTrust'
        );
        Zuora__Payment__c bcsPayment2 = new Zuora__Payment__c(
            Zuora__BillingAccount__c = billingAccount1.Id,
            Zuora__EXT_ID__c = '5678',
            Zuora__Type__c = 'Electronic',
            Lockbox__c = 'BWTrust'
        );
        Zuora__Payment__c ampPayment3 = new Zuora__Payment__c(
            Zuora__BillingAccount__c = billingAccount2.Id,
            Zuora__EXT_ID__c = '2345',
            Zuora__Type__c = 'Electronic',
            Lockbox__c = 'BWTrust'
        );
        Zuora__Payment__c ampPayment4 = new Zuora__Payment__c(
            Zuora__BillingAccount__c = billingAccount2.Id,
            Zuora__EXT_ID__c = '6789',
            Zuora__Type__c = 'Electronic',
            Lockbox__c = 'BWTrust'
        );
        Zuora__Payment__c ampPayment5 = new Zuora__Payment__c(
            Zuora__BillingAccount__c = billingAccount2.Id,
            Zuora__EXT_ID__c = '7890',
            Zuora__Type__c = 'External',
            Lockbox__c = 'AmpTrust'
        );
        insert new List<Zuora__Payment__c>{bcsPayment1, bcsPayment2, ampPayment3, ampPayment4, ampPayment5};

        List<Zuora__CustomerAccount__c> customerAccounts = [
            SELECT Id, Name, Zuora__PaymentGateway__c
            FROM Zuora__CustomerAccount__c
            ORDER BY Name
        ];

        Map<Id, Zuora__Payment__c> payments = new Map<Id, Zuora__Payment__c>([
            SELECT Id, Payment_Gateway__c, Lockbox_Formula__c
            FROM Zuora__Payment__c
        ]);
        System.assertEquals(bcsGateway.Id, payments.get(bcsPayment1.Id).Payment_Gateway__c,
            'ZuoraGatewayAssigner should have assigned the default gateway to a billing account without a gateway');
        System.assertEquals(null, payments.get(bcsPayment1.Id).Lockbox_Formula__c,
            'Lockbox should be null for an Electronic payment');
        System.assertEquals(bcsGateway.Id, payments.get(bcsPayment2.Id).Payment_Gateway__c,
            'ZuoraGatewayAssigner should have assigned the default gateway to a billing account without a gateway');
        System.assertEquals(ampGateway.Id, payments.get(ampPayment3.Id).Payment_Gateway__c,
            'ZuoraGatewayAssigner should have assigned the gateway that is on the billing account');
        System.assertEquals(ampGateway.Id, payments.get(ampPayment4.Id).Payment_Gateway__c,
            'ZuoraGatewayAssigner should have assigned the gateway that is on the billing account');
        System.assertEquals(null, payments.get(ampPayment5.Id).Payment_Gateway__c,
            'Payment Gateway should be null for an external payment');
        System.assertEquals(ampPayment5.Lockbox__c, payments.get(ampPayment5.Id).Lockbox_Formula__c,
            'Lockbox should be populated for an External payment');
        System.assertEquals('Test', customerAccounts[0].Name, 'First customer account should be Test');
        System.assertEquals(bcsGateway.Id, customerAccounts[0].Zuora__PaymentGateway__c,
            'First customer account was inserted without a Payment Gateway, and should have been assigned the default');
        System.assertEquals(ampGateway.Id, customerAccounts[1].Zuora__PaymentGateway__c,
            'Second customer account was inserted with the Amp Gateway');

        customerAccounts[0].Zuora__PaymentGateway__c = ampGateway.Id;
        customerAccounts[1].Zuora__PaymentGateway__c = null;
        update customerAccounts;

        customerAccounts = [
            SELECT Id, Name, Zuora__PaymentGateway__c
            FROM Zuora__CustomerAccount__c
            ORDER BY Name
        ];
        System.assertEquals(ampGateway.Id, customerAccounts[0].Zuora__PaymentGateway__c,
            'First customer account was updated to have the Amp Gateway');
        System.assertEquals(bcsGateway.Id, customerAccounts[1].Zuora__PaymentGateway__c,
            'Second customer account was updated to have the default, but should have been assigned the default');

    }

}