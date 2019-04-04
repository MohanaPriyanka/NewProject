@isTest
public with sharing class CreateOrderandPaymentRequestTest {
    @testSetup public static void setupTestData(){
        List<String> partnerSetUpIds = new List<String>();  
        partnerSetUpIds = LoanTestRecordWarehouse.partnerSetup();

        List<Lead> leadList = new List<Lead>(LoanTestRecordWarehouse.getLoanHandlerLeadRecords());
        LoanHandler.createLoan(leadList);
        leadList = [SELECT Id FROM Lead WHERE LASERCA__Home_State__c = 'NY'];
        LoanHandlerTestClass.convertLeads(leadList);
    }
    @isTest static void getLink() {
        List<Opportunity> oppList = [SELECT Id, Name, Email__c FROM Opportunity ORDER BY Name];
        System.assertEquals(1, oppList.size());

        ChargentOrders__ChargentOrder__c orderEntry = new ChargentOrders__ChargentOrder__c(
                                                ChargentOrders__Bank_Account_Number__c = '123456789102',
                                                ChargentOrders__Bank_Routing_Number__c = '123456789',
                                                ChargentOrders__Bank_Account_Name__c = 'Jordan Test',
                                                ChargentOrders__Bank_Name__c = 'Bank of Bank',
                                                ChargentOrders__Bank_Account_Type__c = 'Checking');

        ChargentBase__Gateway__c chGateway  =
        new ChargentBase__Gateway__c(   Name = 'SREC',
                                        ChargentBase__Merchant_ID__c = '235986',
                                        ChargentBase__Available_Payment_Methods__c = 'eCheck',
                                        ChargentBase__Default_Payment_Method_for_PC__c = 'eCheck',
                                        ChargentBase__Default_Payment_Method_for_PR__c = 'eCheck',
                                        ChargentBase__Active__c = True);
        insert chGateway;

        Entity__c srecEntity = new Entity__c(Name = 'BlueWave Finance Group, LLC',
                                             Gateway__c = chGateway.Id);
        insert srecEntity;

        oppList[0].Email__c = 'ddEmailTest@blue.com';
        update oppList[0];
        Test.startTest();

        Boolean shouldFail = false;
        try {
            Loan__c failedRequest = CreateOrderandPaymentRequest.getLoanAndCheckEmail(oppList[0].Id, 'bademail@test.com');
        } catch (Exception excep){
            shouldFail = true;
        }
        System.assertEquals(true, shouldFail);

        Boolean payRequest = CreateOrderandPaymentRequest.submitDDInfoWithoutCharge(oppList[0].Id, 'ddEmailTest@blue.com', orderEntry);

        Test.stopTest();

        List<Loan__c> updatedLoanList = [   SELECT Id, Name, SREC_Direct_Deposit_Order__c
                                            FROM Loan__c
                                            WHERE Opportunity__r.Email__c = 'ddEmailTest@blue.com'];

        List<ChargentOrders__ChargentOrder__c> chOrderList = [  SELECT Id, Name, ChargentOrders__Gateway__c, Entity__r.Name,
                                                                ChargentOrders__Billing_Email__c
                                                                FROM ChargentOrders__ChargentOrder__c];
        System.assertEquals(true, payRequest);
        System.assertEquals(1, chOrderList.size());
        System.assertEquals(1, updatedLoanList.size());
        System.assertEquals(chOrderList[0].Id, updatedLoanList[0].SREC_Direct_Deposit_Order__c);
        System.assertEquals('BlueWave Finance Group, LLC',chOrderList[0].Entity__r.Name);
        System.assertEquals('compliance@bluewavesolar.com',chOrderList[0].ChargentOrders__Billing_Email__c);
    }

    @isTest static void testUpdateOrderToStopped() {
        ChargentBase__Gateway__c activeGateway  = new ChargentBase__Gateway__c(
            Name = 'Active Gateway',
            ChargentBase__Merchant_ID__c = '235986',
            ChargentBase__Debug__c = true,
            ChargentBase__Available_Payment_Methods__c = 'eCheck',
            ChargentBase__Default_Payment_Method_for_PC__c = 'eCheck',
            ChargentBase__Default_Payment_Method_for_PR__c = 'eCheck',
            ChargentBase__Active__c = true
        );

        // needs to start as active in order to insert the chargent orders, we'll set to inactive later
        ChargentBase__Gateway__c inactiveGateway = new ChargentBase__Gateway__c(
            Name = 'Inactive Gateway',
            ChargentBase__Merchant_ID__c = '235986',
            ChargentBase__Debug__c = true,
            ChargentBase__Available_Payment_Methods__c = 'eCheck',
            ChargentBase__Default_Payment_Method_for_PC__c = 'eCheck',
            ChargentBase__Default_Payment_Method_for_PR__c = 'eCheck',
            ChargentBase__Active__c = true
        );

        insert new List<ChargentBase__Gateway__c>{activeGateway, inactiveGateway};


        Entity__c entity1 = new Entity__c (
            Name = 'Test Entity',
            Gateway__c = activeGateway.Id
        );
        insert entity1;

        // need to disable chargent order trigger because it will automatically update gateway to gateway for entity
        Util.disableTrigger('Disable_ChargentOrderTrigger__c');

        ChargentOrders__ChargentOrder__c activeRecurring = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Billing_First_Name__c = 'ActiveRecurring',
            ChargentOrders__Payment_Method__c = 'Credit Card',
            ChargentOrders__Card_Number__c = '111111111',
            ChargentOrders__Card_Expiration_Month__c = '02',
            ChargentOrders__Card_Expiration_Year__c = '2020',
            ChargentOrders__Billing_Address__c = '200 Street',
            ChargentOrders__Billing_City__c = 'City',
            ChargentOrders__Billing_State__c = 'MA',
            ChargentOrders__Billing_Zip_Postal__c  = '02114',
            ChargentOrders__Billing_Last_Name__c = 'Assertion 1',
            Entity__c = entity1.Id,
            ChargentOrders__Gateway__c = activeGateway.Id,
            ChargentOrders__Payment_Status__c = 'Recurring',
            ChargentOrders__Payment_Frequency__c = 'Monthly',
            ChargentOrders__Payment_Stop__c = 'Unending',
            ChargentOrders__Charge_Date__c = '01',
            ChargentOrders__Payment_Start_Date__c = Date.today()
        );

        ChargentOrders__ChargentOrder__c activeErrored = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Billing_First_Name__c = 'ActiveErrored',
            ChargentOrders__Payment_Method__c = 'Credit Card',
            ChargentOrders__Card_Number__c = '111111111',
            ChargentOrders__Card_Expiration_Month__c = '02',
            ChargentOrders__Card_Expiration_Year__c = '2020',
            ChargentOrders__Billing_Address__c = '200 Street',
            ChargentOrders__Billing_City__c = 'City',
            ChargentOrders__Billing_State__c = 'MA',
            ChargentOrders__Billing_Zip_Postal__c  = '02114',
            ChargentOrders__Billing_Last_Name__c = 'Assertion 2',
            Entity__c = entity1.Id,
            ChargentOrders__Gateway__c = activeGateway.Id,
            ChargentOrders__Payment_Status__c = 'Error'
        );

        ChargentOrders__ChargentOrder__c inactiveRecurring = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Billing_First_Name__c = 'InactiveRecurring',
            ChargentOrders__Payment_Method__c = 'Credit Card',
            ChargentOrders__Card_Number__c = '111111111',
            ChargentOrders__Card_Expiration_Month__c = '02',
            ChargentOrders__Card_Expiration_Year__c = '2020',
            ChargentOrders__Billing_Address__c = '200 Street',
            ChargentOrders__Billing_City__c = 'City',
            ChargentOrders__Billing_State__c = 'MA',
            ChargentOrders__Billing_Zip_Postal__c  = '02114',
            ChargentOrders__Billing_Last_Name__c = 'Assertion 3',
            Entity__c = entity1.Id,
            ChargentOrders__Gateway__c = inactiveGateway.Id,
            ChargentOrders__Payment_Status__c = 'Recurring',
            ChargentOrders__Payment_Frequency__c = 'Monthly',
            ChargentOrders__Payment_Stop__c = 'Unending',
            ChargentOrders__Charge_Date__c = '01',
            ChargentOrders__Payment_Start_Date__c = Date.today()
        );

        ChargentOrders__ChargentOrder__c inactiveErrored = new ChargentOrders__ChargentOrder__c(
            ChargentOrders__Billing_First_Name__c = 'InactiveErrored',
            ChargentOrders__Payment_Method__c = 'Credit Card',
            ChargentOrders__Card_Number__c = '111111111',
            ChargentOrders__Card_Expiration_Month__c = '02',
            ChargentOrders__Card_Expiration_Year__c = '2020',
            ChargentOrders__Billing_Address__c = '200 Street',
            ChargentOrders__Billing_City__c = 'City',
            ChargentOrders__Billing_State__c = 'MA',
            ChargentOrders__Billing_Zip_Postal__c  = '02114',
            ChargentOrders__Billing_Last_Name__c = 'Assertion 4',
            Entity__c = entity1.Id,
            ChargentOrders__Gateway__c = inactiveGateway.Id,
            ChargentOrders__Payment_Status__c = 'Error'
        );

        insert new List<ChargentOrders__ChargentOrder__c>{
            activeRecurring,
            activeErrored,
            inactiveRecurring,
            inactiveErrored
        };

        inactiveGateway.ChargentBase__Active__c = false;
        update inactiveGateway;

        List<ChargentOrders__ChargentOrder__c> originalChargentOrders = [
            SELECT Id, ChargentOrders__Payment_Status__c, Reason_for_Recurring_Stop__c, Entity__r.Gateway__c,
                ChargentOrders__Gateway__c, ChargentOrders__Gateway__r.ChargentBase__Active__c,
                ChargentOrders__Billing_First_Name__c
            FROM ChargentOrders__ChargentOrder__c
        ];

        for (ChargentOrders__ChargentOrder__c chOrder : originalChargentOrders) {
            if (chOrder.ChargentOrders__Billing_First_Name__c == 'ActiveRecurring') {
                activeRecurring = chOrder;
            } else if (chOrder.ChargentOrders__Billing_First_Name__c == 'ActiveErrored') {
                activeErrored = chOrder;
            } else if (chOrder.ChargentOrders__Billing_First_Name__c == 'InactiveRecurring') {
                inactiveRecurring = chOrder;
            } else if (chOrder.ChargentOrders__Billing_First_Name__c == 'InactiveErrored') {
                inactiveErrored = chOrder;
            }
        }


        System.assertEquals(activeRecurring.ChargentOrders__Gateway__c, activeGateway.Id);
        System.assert(activeRecurring.ChargentOrders__Gateway__r.ChargentBase__Active__c, 'Gateway should be active');
        System.assertEquals(activeRecurring.ChargentOrders__Payment_Status__c, 'Recurring');

        System.assertEquals(activeErrored.ChargentOrders__Gateway__c, activeGateway.Id);
        System.assert(activeErrored.ChargentOrders__Gateway__r.ChargentBase__Active__c, 'Gateway should be active');
        System.assertEquals(activeErrored.ChargentOrders__Payment_Status__c, 'Error');

        System.assertEquals(inactiveRecurring.ChargentOrders__Gateway__c, inactiveGateway.Id);
        System.assert(!inactiveRecurring.ChargentOrders__Gateway__r.ChargentBase__Active__c, 'Gateway should not be active');
        System.assertEquals(inactiveRecurring.ChargentOrders__Payment_Status__c, 'Recurring');

        System.assertEquals(inactiveErrored.ChargentOrders__Gateway__c, inactiveGateway.Id);
        System.assert(!inactiveErrored.ChargentOrders__Gateway__r.ChargentBase__Active__c, 'Gateway should not be active');
        System.assertEquals(inactiveErrored.ChargentOrders__Payment_Status__c, 'Error');

        CreateOrderandPaymentRequest.updateChargentOrdersToStopped(originalChargentOrders);

        List<ChargentOrders__ChargentOrder__c> updatedChargentOrders = [
            SELECT Id, ChargentOrders__Payment_Status__c, Reason_for_Recurring_Stop__c, Entity__r.Gateway__c,
                ChargentOrders__Gateway__c, ChargentOrders__Gateway__r.ChargentBase__Active__c,
                ChargentOrders__Billing_First_Name__c
            FROM ChargentOrders__ChargentOrder__c
        ];

        for (ChargentOrders__ChargentOrder__c chOrder : updatedChargentOrders) {
            if (chOrder.ChargentOrders__Billing_First_Name__c == 'ActiveRecurring') {
                activeRecurring = chOrder;
            } else if (chOrder.ChargentOrders__Billing_First_Name__c == 'ActiveErrored') {
                activeErrored = chOrder;
            } else if (chOrder.ChargentOrders__Billing_First_Name__c == 'InactiveRecurring') {
                inactiveRecurring = chOrder;
            } else if (chOrder.ChargentOrders__Billing_First_Name__c == 'InactiveErrored') {
                inactiveErrored = chOrder;
            }
        }

        System.assertEquals(activeRecurring.ChargentOrders__Gateway__c, activeGateway.Id, 'Gateway should be the active gateway');
        System.assert(activeRecurring.ChargentOrders__Gateway__r.ChargentBase__Active__c, 'Gateway should be active');
        System.assertEquals(activeRecurring.ChargentOrders__Payment_Status__c, 'Stopped');

        System.assertEquals(activeErrored.ChargentOrders__Gateway__c, activeGateway.Id, 'Gateway should be the active gateway');
        System.assert(activeErrored.ChargentOrders__Gateway__r.ChargentBase__Active__c, 'Gateway should be active');
        System.assertEquals(activeErrored.ChargentOrders__Payment_Status__c, 'Complete');

        System.assertEquals(inactiveRecurring.ChargentOrders__Gateway__c, activeGateway.Id, 'Gateway should be the active gateway');
        System.assert(inactiveRecurring.ChargentOrders__Gateway__r.ChargentBase__Active__c, 'Gateway should be active');
        System.assertEquals(inactiveRecurring.ChargentOrders__Payment_Status__c, 'Stopped');

        System.assertEquals(inactiveErrored.ChargentOrders__Gateway__c, activeGateway.Id, 'Gateway should be the active gateway');
        System.assert(inactiveErrored.ChargentOrders__Gateway__r.ChargentBase__Active__c, 'Gateway should be active');
        System.assertEquals(inactiveErrored.ChargentOrders__Payment_Status__c, 'Complete');
    }

}