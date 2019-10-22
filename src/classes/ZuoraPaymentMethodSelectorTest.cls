@IsTest
public with sharing class ZuoraPaymentMethodSelectorTest {
    @TestSetup public static void testDataSetup() {
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

        Zuora__PaymentMethod__c payMethod2 = new Zuora__PaymentMethod__c(
            Name = 'XX',
            Zuora__BillingAccount__c = billingAccount.Id,
            Zuora__External_Id__c = '2c92c0f86a0c41a5016a1f41d63a2f88'
        );
        insert payMethod2;

        Zuora__Payment__c payment2 = new Zuora__Payment__c(
            Zuora__PaymentMethodId__c = '2c92c0f86a0c41a5016a1f41d63a2f88',
            Name = 'PY1234',
            Zuora__BillingAccount__c = billingAccount.Id,
            Zuora__Amount__c = 23
        );
        insert payment2;
    }

    @IsTest
    private static void testGetDefaultPaymentMethodId() {
        String payMethod = ZuoraPaymentMethodSelector.getDefaultPaymentMethodId();
        System.assertEquals('2c92c0f869330b78016949ef5a7517ab',payMethod);
    }

    @IsTest
    private static void testGetSFRecordFromZuoraId() {
        List<String> zuoraIds = new List<String>{'2c92c0f86a0c41a5016a1f41d63a2f96','2c92c0f86a0c41a5016a1f41d63a2f88'};

        List<Zuora__PaymentMethod__c> payMethods = ZuoraPaymentMethodSelector.getSFRecordFromZuoraId(zuoraIds);
        System.assertEquals(2,payMethods.size());
    }
}