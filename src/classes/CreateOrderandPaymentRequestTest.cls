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
        System.assertEquals(null,chOrderList[0].ChargentOrders__Billing_Email__c);
        System.assertEquals(1, MessagingService.emailsSent.size());
    }
}