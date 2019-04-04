/*************************************************************************************
 * Created By: peteryao on 10/17/18  
 * Description: 
 * Test: 
 *************************************************************************************/
@IsTest
public with sharing class AutopayCheckerTest {
    @TestSetup public static void setupTestData() {
        CSPaymentTest.CSPaymentSetupTestData();
    }

    @IsTest static void testTotalAmountByGateway() {
        List<ChargentOrders__ChargentOrder__c> orders = [
            SELECT Id, ChargentOrders__Gateway__c, Entity__c, ChargentOrders__Subtotal__c, ChargentOrders__Charge_Amount__c,
                ChargentOrders__Charge_Date__c, ChargentOrders__Payment_Status__c, ChargentOrders__Payment_Start_Date__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE ChargentOrders__Charge_Date__c = '27'
        ];
        // Should be one from test data, we want to test charge dates of '01' and '1' being treated the same
        System.assertEquals(1, orders.size());
        orders[0].ChargentOrders__Charge_Date__c = '01';
        update orders[0];
        ChargentOrders__ChargentOrder__c newOrder = orders[0].clone(false, false, false, false);
        newOrder.ChargentOrders__Charge_Date__c = '1';
        insert newOrder;

        // There should be 2 orders for the first for a total of 200.44
        String expectedMessage = 'Chargent Gateway Two: $200.44';
        AutopayChecker autopayChecker = new AutopayChecker(null);
        String actualMessage = autopayChecker.getTotalAmountByGateway().message;
        System.assert(actualMessage.contains(expectedMessage), 'Unexpected message: ' + actualMessage);
    }

    @IsTest static void testRecurringOrdersOnLastAccountBill() {
        List<ChargentOrders__ChargentOrder__c> orders = [
            SELECT Id, Account_Bill__c, Account_Bill__r.Due_Date_SB__c, ChargentOrders__Billing_Last_Name__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE ChargentOrders__Payment_Status__c = 'Recurring'
        ];
        Set<Id> accountBillIds = new Set<Id>();
        for (ChargentOrders__ChargentOrder__c order : orders) {
            accountBillIds.add(order.Account_Bill__c);
        }
        List<Account_Bill__c> bills = [
            SELECT Id, Due_Date_SB__c,
            (SELECT Id, Date__c FROM System_Bills__r)
            FROM Account_Bill__c
            WHERE Id = :accountBillIds
        ];

        // Should be three orders on account bills in the past, two orders on account bills without system bills,
        // and six orders without account bills
        AutopayChecker autopayChecker = new AutopayChecker(null);
        AutopayChecker.QCResult qcResult = autopayChecker.checkRecurringOrdersOnLastAccountBill();
        System.assert(!qcResult.passed, 'Expected recurring orders on wrong account bill');
        System.assert(qcResult.message.contains('are not on the latest account bill'), qcResult.message);

        List<ChargentOrders__ChargentOrder__c> ordersToDelete = new List<ChargentOrders__ChargentOrder__c>();
        for (ChargentOrders__ChargentOrder__c order : orders) {
            if (order.Account_Bill__c == null ||
                order.Account_Bill__r.Due_Date_SB__c == null ||
                order.ChargentOrders__Billing_Last_Name__c == 'AutoEmailer-Order1') {
                ordersToDelete.add(order);
            }
        }
        delete ordersToDelete;

        List<System_Bill__c> systemBills = new List<System_Bill__c>();
        for (Account_Bill__c bill : bills) {
            if (bill.System_Bills__r.size() > 0) {
                for (System_Bill__c systemBill : bill.System_Bills__r) {
                    systemBill.Date__c = Date.today() + 30;
                    systemBills.add(systemBill);
                }
            }
        }
        update systemBills;

        autopayChecker = new AutopayChecker(null);
        qcResult = autopayChecker.checkRecurringOrdersOnLastAccountBill();
        // Now, with the due dates fixed and erroneous orders deleted, this check should pass.
        System.assert(qcResult.passed, 'Expected recurring orders to be on correct bill');
        System.assert(qcResult.message.contains('All recurring orders are the latest account bill'), qcResult.message);
    }

    @IsTest static void testSingleOrderPerAccountEntity() {
        AutopayChecker autopayChecker = new AutopayChecker(null);
        AutopayChecker.QCResult qcResult = autopayChecker.checkSingleOrderPerAccountEntity();
        // There shouldn't be multiple orders per account and entity
        System.assert(qcResult.passed, 'Expected unique orders per account and entity');

        List<ChargentOrders__ChargentOrder__c> orders = [
            SELECT Id, Account_Bill__c, ChargentOrders__Payment_Status__c, Entity__c, ChargentOrders__Payment_Start_Date__c,
                ChargentOrders__Charge_Date__c, ChargentOrders__Gateway__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE ChargentOrders__Payment_Status__c = 'Recurring'
        ];
        insert orders.deepClone(false, false, false);
        autopayChecker = new AutopayChecker(null);
        qcResult = autopayChecker.checkSingleOrderPerAccountEntity();
        // There shouldn't be multiple orders per account and entity
        System.assert(!qcResult.passed, 'Expected to find duplicate orders per account and entity');

    }

    @IsTest static void testChargeAmountEqualsCarryoverBalance() {
        List<ChargentOrders__ChargentOrder__c> orders = [
            SELECT Id, Account_Bill__c, Account_Bill__r.Carry_Over_Balance__c, ChargentOrders__Charge_Amount__c,
                Property_Account_ID__c, Entity__c, Account_Bill__r.Bill_Number__c,
                ChargentOrders__Account__r.Max_Account_Bill_Number__c, Account_Bill__r.Due_Date_SB__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE ChargentOrders__Payment_Status__c = 'Recurring'
            AND Account_Bill__c != NULL
        ];

        AutopayChecker autopayChecker = new AutopayChecker(null);
        AutopayChecker.QCResult qcResult = autopayChecker.checkChargeAmountEqualsCarryoverBalance();
        // Charge amounts in the test data aren't correct
        System.assert(!qcResult.passed, 'Test data are expected to be incorrect');

        // Create new bills to move chargent orders to
        List<Energy_Usage_Update__c> prodUpdates = [
            SELECT Id, Name
            FROM Energy_Usage_Update__c
            WHERE Name IN ('sssA - March 2016', 'sssB - March 2016')
        ];
        for (Energy_Usage_Update__c prodUpdate : prodUpdates) {
            // Generate $0 bills for one system
            if (prodUpdate.Name == 'sssA - March 2016') {
                prodUpdate.Production__c = 0;
                prodUpdate.Total_System_NMCs__c = 0;
            }
            TestBillCreationandPayment.runProductionUpdate(new List<Id>{prodUpdate.Id});
        }

        orders = [
            SELECT Id, Account_Bill__c, Account_Bill__r.Carry_Over_Balance__c, ChargentOrders__Charge_Amount__c,
                Property_Account_ID__c, Entity__c, Account_Bill__r.Bill_Number__c, ChargentOrders__Charge_Date__c,
                ChargentOrders__Account__r.Max_Account_Bill_Number__c, Account_Bill__r.Due_Date_SB__c,
                ChargentOrders__Payment_Start_Date__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE ChargentOrders__Payment_Status__c = 'Recurring'
            AND Account_Bill__c != NULL
        ];

        RecurringPaymentsHandler rph = new RecurringPaymentsHandler();
        rph.updateRecurringOrders(orders);

        orders = [
            SELECT Id, Account_Bill__c, Account_Bill__r.Carry_Over_Balance__c, ChargentOrders__Charge_Amount__c,
                Property_Account_ID__c, Entity__c, Account_Bill__r.Bill_Number__c, ChargentOrders__Charge_Date__c,
                ChargentOrders__Account__r.Max_Account_Bill_Number__c, Account_Bill__r.Due_Date_SB__c,
                ChargentOrders__Payment_Start_Date__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE ChargentOrders__Payment_Status__c = 'Recurring'
            AND Account_Bill__c != NULL
        ];

        System.assert(orders.size() >= 3, 'Should be at least 3 recurring orders');
        autopayChecker = new AutopayChecker(null);
        qcResult = autopayChecker.checkChargeAmountEqualsCarryoverBalance();
        // After running the RecurringPaymentsHandler, amounts should be consistent
        System.assert(qcResult.passed, 'RecurringPaymentsHandler should have fixed charge amounts');
    }

    @IsTest static void testZeroDollarChargentOrdersNotToFire() {
        // Recurring orders without a charge date should be caught by another QC check and test
        List<ChargentOrders__ChargentOrder__c> ordersWithNoChargeDate = [
            SELECT Id FROM ChargentOrders__ChargentOrder__c
            WHERE ChargentOrders__Payment_Status__c = 'Recurring'
            AND ChargentOrders__Charge_Date__c = NULL
        ];
        delete ordersWithNoChargeDate;

        ChargentOrders__ChargentOrder__c orderToMakeNegative = [
            SELECT Id, Account_Bill__c, Account_Bill__r.Carry_Over_Balance__c, ChargentOrders__Charge_Amount__c,
                Property_Account_ID__c, Entity__c, Account_Bill__r.Bill_Number__c, ChargentOrders__Charge_Date__c,
                ChargentOrders__Account__r.Max_Account_Bill_Number__c, Account_Bill__r.Due_Date_SB__c,
                ChargentOrders__Payment_Start_Date__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE ChargentOrders__Payment_Status__c = 'Recurring'
            AND Account_Bill__c != null
            AND ChargentOrders__Charge_Amount__c > 0
            LIMIT 1
        ];

        orderToMakeNegative.ChargentOrders__Charge_Amount__c = -1;
        update orderToMakeNegative;

        List<ChargentOrders__ChargentOrder__c> orders = [
            SELECT Id, Account_Bill__c, Account_Bill__r.Carry_Over_Balance__c, ChargentOrders__Charge_Amount__c,
                Property_Account_ID__c, Entity__c, Account_Bill__r.Bill_Number__c, ChargentOrders__Charge_Date__c,
                ChargentOrders__Account__r.Max_Account_Bill_Number__c, Account_Bill__r.Due_Date_SB__c,
                ChargentOrders__Payment_Start_Date__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE ChargentOrders__Payment_Status__c = 'Recurring'
            AND Account_Bill__c != null
        ];
        List<ChargentOrders__ChargentOrder__c> zeroOrNegDollarOrders = new List<ChargentOrders__ChargentOrder__c>();
        Integer countZeroDollarOrders = 0;
        Integer countNegativeDollarOrders = 0;

        for (ChargentOrders__ChargentOrder__c order : orders) {
            if (order.ChargentOrders__Charge_Amount__c <= 0) {
                order.ChargentOrders__Payment_Start_Date__c = Date.newInstance(Date.today().year()+1, 1, 1);
                zeroOrNegDollarOrders.add(order);
            }
            if (order.ChargentOrders__Charge_Amount__c == 0) {
                countZeroDollarOrders += 1;
            } else if (order.ChargentOrders__Charge_Amount__c < 0) {
                countNegativeDollarOrders += 1;
            }
        }
        update zeroOrNegDollarOrders;
        System.assert(countZeroDollarOrders > 0, 'There should be atleast 1 zero dollar order');
        System.assert(countNegativeDollarOrders > 0, 'There should be atleast 1 negative dollar order');

        AutopayChecker autopayChecker = new AutopayChecker(null);
        AutopayChecker.QCResult qcResult = autopayChecker.checkZeroDollarChargentOrdersNotToFire();
        System.assert(qcResult.passed, 'All $0 orders should be for the future');

        for (ChargentOrders__ChargentOrder__c order : zeroOrNegDollarOrders) {
            order.ChargentOrders__Payment_Start_Date__c = Date.newInstance(2010, 1, 1);
        }
        update orders;

        autopayChecker = new AutopayChecker(null);
        qcResult = autopayChecker.checkZeroDollarChargentOrdersNotToFire();
        System.assert(!qcResult.passed, 'Should have caught the $0 orders set to go');
    }

    @IsTest static void testChargentOrderEntitiesAndGatewaysAgainstAccountBill() {
        List<ChargentOrders__ChargentOrder__c> orders = [
            SELECT Id, Entity__c, Entity__r.Name, ChargentOrders__Gateway__c, ChargentOrders__Gateway__r.Name, Account_Bill__c
            FROM ChargentOrders__ChargentOrder__c
            WHERE ChargentOrders__Payment_Status__c = 'Recurring'
            AND Account_Bill__c != NULL
        ];
        Set<Id> accountBillIds = new Set<Id>();
        for (ChargentOrders__ChargentOrder__c order : orders) {
            accountBillIds.add(order.Account_Bill__c);
        }
        Map<Id, Account_Bill__c> accountBillMap = new Map<Id, Account_Bill__c>([
            SELECT Id,
            (SELECT Id, Shared_Solar_System__r.BWC_Project_Entity_Manual__c,
                Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Name,
                Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Gateway__c,
                Shared_Solar_System__r.BWC_Project_Entity_Manual__r.Gateway__r.Name
            FROM System_Bills__r)
            FROM Account_Bill__c
            WHERE Id = :accountBillIds
        ]);
        System.assert(orders.size() >= 3, 'Expect at least 3 recurring orders');
        // The test data has an order on an Account Bill without System Bills, which should cause the check to fail
        List<ChargentOrders__ChargentOrder__c> orderOnAccountBillWithoutSystemBills = new List<ChargentOrders__ChargentOrder__c>();
        for (ChargentOrders__ChargentOrder__c order : orders) {
            if (accountBillMap.get(order.Account_Bill__c).System_Bills__r.size() == 0) {
                order.ChargentOrders__Payment_Status__c = 'Stopped';
                orderOnAccountBillWithoutSystemBills.add(order);
            }
        }
        System.assertEquals(3, orderOnAccountBillWithoutSystemBills.size());

        AutopayChecker autopayChecker = new AutopayChecker(null);
        AutopayChecker.QCResult qcResult = autopayChecker.checkChargentOrderEntitiesAndGatewaysAgainstAccountBill();
        System.assert(!qcResult.passed, 'There should be unexpected Entities/Gateways on chargent orders');

        // After removing the stopping the order, orders should line up to Account Bills
        update orderOnAccountBillWithoutSystemBills;
        autopayChecker = new AutopayChecker(null);
        qcResult = autopayChecker.checkChargentOrderEntitiesAndGatewaysAgainstAccountBill();
        System.assert(qcResult.passed, 'Should have found the expected Entity/Gateway on Chargent Orders');

        Entity__c placeholderEntity = [
            SELECT Id, Gateway__c
            FROM Entity__c
            WHERE Name = 'BWC Holdings, LLC'
            LIMIT 1
        ];
        for (ChargentOrders__ChargentOrder__c order : orders) {
            order.Entity__c = placeholderEntity.Id;
            order.ChargentOrders__Gateway__c = placeholderEntity.Gateway__c;
        }
        update orders;

        autopayChecker = new AutopayChecker(null);
        qcResult = autopayChecker.checkChargentOrderEntitiesAndGatewaysAgainstAccountBill();
        System.assert(!qcResult.passed, 'There should be unexpected Entities/Gateways on chargent orders');

    }
}