@isTest
private class PCRApprovalHandlerTest {
    @testSetup public static void setupTestData() {
        Test.startTest();
        LoanTestRecordWarehouse.partnerSetup();
        insert LoanTestRecordWarehouse.getLoanProductsVariableInterestRatesandTerms();
        Test.stopTest();
    }
}