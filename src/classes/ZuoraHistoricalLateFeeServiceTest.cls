@isTest
public class ZuoraHistoricalLateFeeServiceTest {
    @testSetup public static void testDataSetup() {
        MultipleMonthProductionUpdateTest.multipleMonthTest();
    }

    @IsTest
    private static void testConvertLateFeeToDebit() {
        Test.startTest();
        List<Account_Bill__c> allAB = [
            SELECT Id, Published__c, Reason_For_Unpublish__c
            FROM Account_Bill__c
        ];
        for (Account_Bill__c ab : allAB){
            ab.Published__c = false;
            ab.Reason_For_Unpublish__c = 'fake reason fro unpublishing bill';
        }
        update allAB;

        List<System_Bill__c> allSB = [
            SELECT Id, Waive_Late_Fees__c
            FROM System_Bill__c
        ];
        for (System_Bill__c sb : allSB){
            sb.Waive_Late_Fees__c = false;
        }
        update allSB;

        List<System_Bill__c> billWithFee = [
            SELECT Id, Late_Fees__c, Account_Bill__r.Parent_Account__r.Zuora_Id__c,
                Account_Bill__r.Parent_Account__r.Id,
                Account_Bill__r.Date__c, Client__r.Account_Number__c,
                Opportunity__r.Shared_Solar_System__r.Unique_ID__c
            FROM System_Bill__c
            WHERE Late_Fees__c > 0
        ];

        // See ZuoraAPIMock.getOrderByOwnerResponse()
        // If ZuoraId contains CID, mocked subscriptions will be returned for this client/shared solar system pair:
        String accountKey = 'CID' +
            billWithFee[0].Client__r.Account_Number__c +
            'SID' +
            billWithFee[0].Opportunity__r.Shared_Solar_System__r.Unique_ID__c +
            'END';
        Account acctToUpdate = new Account();
        acctToUpdate.Id = billWithFee[0].Account_Bill__r.Parent_Account__r.Id;
        acctToUpdate.Zuora_Id__c = accountKey;
        update acctToUpdate;

        List<System_Bill__c> sbWithLateFee = [
            SELECT Id, Late_Fees__c, Account_Bill__r.Parent_Account__r.Zuora_Id__c,
                Account_Bill__r.Parent_Account__r.Id,
                Account_Bill__r.Date__c, Client__r.Account_Number__c,
                Opportunity__r.Shared_Solar_System__r.Unique_ID__c
            FROM System_Bill__c
            WHERE Late_Fees__c > 0
        ];

        System.assertEquals(1, sbWithLateFee.size());
        ZuoraAPI.DebitMemo debitMemo = ZuoraHistoricalLateFeeService.convertSFLateFeesToDebitMemos(sbWithLateFee[0]);
        System.assertEquals(debitMemo.Charges[0].Amount,sbWithLateFee[0].Late_Fees__c);
        System.assertEquals(debitMemo.Charges[0].Amount,18.73);
        Test.stopTest();
    }

    @isTest
    private static void testBatch(){
        Test.startTest();
        ZuoraHistoricalLateFeeService service = new ZuoraHistoricalLateFeeService();
        service.executeBatch();
        Test.stopTest();
    }
}