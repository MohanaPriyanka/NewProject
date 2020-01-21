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

    @IsTest
    public static void testGetTransactions(){
        Account accountTwo = new Account(
            Name = 'TestTwo'
        );
        insert accountTwo;

        Zuora__CustomerAccount__c billingAccountTwo = new Zuora__CustomerAccount__c(
            Name = 'Test Two',
            Zuora__Account__c = accountTwo.Id
        );
        insert billingAccountTwo;

        Zuora__Payment__c paymentOne = new Zuora__Payment__c(
            Zuora__BillingAccount__c = billingAccountTwo.Id,
            Zuora__Amount__c = 123.45,
            Zuora__Effective_Date__c = Date.newInstance(2017,03,20)
        );
        Zuora__Payment__c paymentTwo = new Zuora__Payment__c(
            Zuora__BillingAccount__c = billingAccountTwo.Id,
            Zuora__Amount__c = 222.45,
            Zuora__Effective_Date__c = Date.newInstance(2016,03,20)
        );
        Zuora__Payment__c paymentThree = new Zuora__Payment__c(
            Zuora__BillingAccount__c = billingAccountTwo.Id,
            Zuora__Amount__c = 444.45,
            Zuora__Effective_Date__c = Date.newInstance(2017,03,22)
        );
        insert new List<Zuora__Payment__c>{paymentOne,paymentTwo,paymentThree};

        List<Account> accountList = new List<Account>{accountTwo};
        List<Id> accountIdList = new List<Id>{accountTwo.Id};

        System.assertEquals( 3, (ZuoraPaymentSelector.selectByAccount(accountIdList).size()));

        Zuora_Setting__mdt zuoraSetting = ZuoraAPIHelper.getZuoraSetting();
        if (zuoraSetting.Zuora_Is_Live__c){
            System.assertEquals( 3, (PreviewProductionUpdateResults.getTransactions(accountList)).size());
        } else {
            System.assertEquals( 0, (PreviewProductionUpdateResults.getTransactions(accountList)).size());
        }
    }

    @IsTest
    private static void testSelectElectronicPaymentsFromDate() {
        System.assertNotEquals(null, ZuoraPaymentSelector.selectElectronicPaymentsFromDate(System.now()));

    }

    @IsTest
    private static void testGetFailedPaymentRunPaymentsFromLastDay() {
        Datetime dt = Datetime.newInstanceGmt(2019, 12, 31, 0, 0, 0);
        String query = ZuoraPaymentSelector.getFailedPaymentRunPaymentsFromLastDay(dt);
        String endDatetime = query.right(20).left(19);
        Datetime parsedDatetime = Datetime.valueOfGmt(endDatetime);
        System.assertEquals(dt, parsedDatetime, 'Expected to get find the end date');
    }
}