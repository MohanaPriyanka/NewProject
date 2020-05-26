@isTest
public class ZuoraCreditDebitMemoServiceTest {
    @testSetup public static void testDataSetup() {
        MultipleMonthProductionUpdateTest.multipleMonthTest();
        setBillsToUnPublished();

        List<Utility_Account_Subscription__c> uasList = [
            SELECT Id, Opportunity__r.Shared_Solar_System__r.Unique_ID__c, Opportunity__r.AccountId
            FROM Utility_Account_Subscription__c
            LIMIT 2
        ];

        Account clientAccount = [
            SELECT Id, Name, Account_Number__c
            FROM Account
            WHERE Name = 'Test Client'
            LIMIT 1
        ];

        Bill_Adjustment__c adjustOne = new Bill_Adjustment__c(
            Name = 'UASoneAdjustment',
            Utility_Account_Subscription__c = uasList[0].Id,
            Account__c = uasList[0].Opportunity__r.AccountId,
            Adjustment_Type__c = 'BW Credit',
            Client__c = clientAccount.Id,
            Adjustment_Amount__c = -90,
            Approval_Status__c = 'Approved',
            Reason_For_Adjustment__c = 'Needs adjustment');

        Bill_Adjustment__c adjustTwo = new Bill_Adjustment__c(
            Name = 'UASoneAdjustment2',
            Utility_Account_Subscription__c = uasList[0].Id,
            Account__c = uasList[0].Opportunity__r.AccountId,
            Adjustment_Type__c = 'Client Credit',
            Client__c = clientAccount.Id,
            Adjustment_Amount__c = -45,
            Approval_Status__c = 'Approved',
            Reason_For_Adjustment__c = 'Needs adjustment');

        Bill_Adjustment__c adjustThree = new Bill_Adjustment__c(
            Name = 'UASoneAdjustment3',
            Utility_Account_Subscription__c = uasList[1].Id,
            Account__c = uasList[1].Opportunity__r.AccountId,
            Adjustment_Type__c = 'BW Credit',
            Client__c = clientAccount.Id,
            Adjustment_Amount__c = -15,
            Approval_Status__c = 'Approved',
            Reason_For_Adjustment__c = 'Needs adjustment');

        Bill_Adjustment__c adjustFour = new Bill_Adjustment__c(
            Name = 'UASoneAdjustment4',
            Utility_Account_Subscription__c = uasList[1].Id,
            Account__c = uasList[1].Opportunity__r.AccountId,
            Adjustment_Type__c = 'BW Credit',
            Client__c = clientAccount.Id,
            Adjustment_Amount__c = -99,
            Approval_Status__c = 'Approved',
            Zuora_Id__c = 'XXXXXXXXXXXXXXXXXX',
            Reason_For_Adjustment__c = 'Needs adjustment');

        Bill_Adjustment__c adjustFive = new Bill_Adjustment__c(
            Name = 'UASoneAdjustment5',
            Utility_Account_Subscription__c = uasList[1].Id,
            Account__c = uasList[1].Opportunity__r.AccountId,
            Adjustment_Type__c = 'BW Credit',
            Client__c = clientAccount.Id,
            Adjustment_Amount__c = 12,
            Approval_Status__c = 'Approved',
            Reason_For_Adjustment__c = 'Needs adjustment');

        Bill_Adjustment__c adjustSix = new Bill_Adjustment__c(
            Name = 'UASoneAdjustment6',
            Utility_Account_Subscription__c = uasList[1].Id,
            Account__c = uasList[1].Opportunity__r.AccountId,
            Adjustment_Type__c = 'BW Credit',
            Client__c = clientAccount.Id,
            Adjustment_Amount__c = 18,
            Approval_Status__c = 'Approved',
            Reason_For_Adjustment__c = 'Needs adjustment');

        Bill_Adjustment__c adjustSeven = new Bill_Adjustment__c(
            Name = 'UASoneAdjustment7',
            Utility_Account_Subscription__c = uasList[1].Id,
            Account__c = uasList[1].Opportunity__r.AccountId,
            Adjustment_Type__c = 'BW Credit',
            Client__c = clientAccount.Id,
            Adjustment_Amount__c = 22,
            Approval_Status__c = 'Pending',
            Effective__c = 'Post When Approved',
            Reason_For_Adjustment__c = 'Needs adjustment');

        Bill_Adjustment__c adjustEight = new Bill_Adjustment__c(
            Name = 'UASoneAdjustment8',
            Utility_Account_Subscription__c = uasList[1].Id,
            Account__c = uasList[1].Opportunity__r.AccountId,
            Adjustment_Type__c = 'BW Credit',
            Client__c = clientAccount.Id,
            Adjustment_Amount__c = 23,
            Approval_Status__c = 'Pending',
            Effective__c = 'Post When Approved',
            Reason_For_Adjustment__c = 'Needs adjustment');


        insert new List<Bill_Adjustment__c>{adjustOne, adjustTwo, adjustThree, adjustFour, adjustFive, adjustSix, adjustSeven, adjustEight};

        List<Account> accounts = [
            SELECT Id, Name, Zuora_Id__c
            FROM Account
        ];

        // See ZuoraAPIMock.getOrderByOwnerResponse()
        // If ZuoraId contains CID, mocked subscriptions will be returned for this client/shared solar system pair:
        String accountKey = 'CID' +
            clientAccount.Account_Number__c +
            'SID' +
            uasList[0].Opportunity__r.Shared_Solar_System__r.Unique_ID__c +
            'END';

        for (Account accts : accounts){
            accts.Zuora_Id__c = accountKey;
        }
        update accounts;
    }

    public static void setBillsToUnPublished() {
        List <Account_Bill__c> listAccountBills = [
            SELECT Id, Published__c
            FROM Account_Bill__c
            WHERE Published__c = TRUE
        ];
        for (Account_Bill__c acctBill : listAccountBills) {
            acctBill.Published__c = FALSE;
            acctBill.Reason_For_Unpublish__c = 'Test reason for unpublishing this bill';
        }
        update listAccountBills;
    }

    @IsTest
    private static void testBatch() {
        // disableTrigger just sets a system property checkbox to true
        Util.disableTrigger('Update_Usage_Records_With_ZuoraId__c');
        ZuoraCreditDebitMemoService.featureService = (FeatureService) Test.createStub(FeatureService.class, new FeatureService.Mock(false));

        // 6 adjustments exist, but one should be excluded, because already has a zuora ID:
        Database.QueryLocator queryLocator = AdjustmentSelector.getAdjustmentsNotYetInZuora(false, ZuoraCreditMemoBatchSend.AdjustmentType.PostNextBill);
        Database.QueryLocatorIterator iterator = queryLocator.iterator();
        List<Bill_Adjustment__c> beforeCallList = new List<Bill_Adjustment__c>();
        Integer i = 0;
        while (iterator.hasNext()) {
            beforeCallList.add((Bill_Adjustment__c) iterator.next());
            i++;
        }
        System.assertEquals(5, i);

        Test.startTest();
        ZuoraCreditMemoBatchSend zSend = new ZuoraCreditMemoBatchSend();
        zSend.executeBatch();
        Test.stopTest();

        // Credit Memos:
        List<Bill_Adjustment__c> creditList = [
            SELECT Id, Name, Zuora_Id__c
            FROM Bill_Adjustment__c
            WHERE Zuora_Id__c = '2c92c0fa6a3458e1016a45ac238e0d74'
        ];
        System.assertEquals(3, creditList.size());

        // Debit Memos:
        List<Bill_Adjustment__c> debitList = [
            SELECT Id, Name, Zuora_Id__c
            FROM Bill_Adjustment__c
            WHERE Zuora_Id__c = '2c92c0fa6a3458e1016a45ac238e0d66'
        ];
        System.assertEquals(2, debitList.size());
    }

    // Tests for the case raised in this error log: https://bluewavesolar.my.salesforce.com/a3u0a000000E1zz
    @IsTest
    private static void testBatchWithNoIds() {
        ZuoraAPIMock.createCMWithNoId = true;
        ZuoraAPIMock.createDMWithNoId = true;
        ZuoraCreditDebitMemoService.featureService = (FeatureService) Test.createStub(FeatureService.class, new FeatureService.Mock(false));

        // disableTrigger just sets a system property checkbox to true
        Util.disableTrigger('Update_Usage_Records_With_ZuoraId__c');

        // 8 adjustments exist, but one should be excluded, because already has a zuora ID and 2 should be
        // excluded because they are not approved:
        Database.QueryLocator queryLocator = AdjustmentSelector.getAdjustmentsNotYetInZuora(false, ZuoraCreditMemoBatchSend.AdjustmentType.PostNextBill);
        Database.QueryLocatorIterator iterator = queryLocator.iterator();
        List<Bill_Adjustment__c> beforeCallList = new List<Bill_Adjustment__c>();
        Integer i = 0;
        while (iterator.hasNext()) {
            beforeCallList.add((Bill_Adjustment__c) iterator.next());
            i++;
        }
        System.assertEquals(5, i);

        Test.startTest();
        ZuoraCreditMemoBatchSend zSend = new ZuoraCreditMemoBatchSend();
        zSend.executeBatch();
        Test.stopTest();

        List<Error_Log__c> errorLogs = [
            SELECT Message__c FROM Error_Log__c WHERE Severity__c = :Logger.ERROR
        ];
        System.assertEquals(1, errorLogs.size());
        System.assert(errorLogs[0].Message__c.contains('Memo did not successfully create:'));
    }

    @IsTest
    private static void testAPICallWithMock() {
        // disableTrigger just sets a system property checkbox to true
        Util.disableTrigger('Update_Usage_Records_With_ZuoraId__c');
        ZuoraCreditDebitMemoService.featureService = (FeatureService) Test.createStub(FeatureService.class, new FeatureService.Mock(false));

        // 8 adjustments exist, but one should be excluded, because already has a zuora ID and 2 should be
        // excluded because they are not approved:
        Database.QueryLocator queryLocator = AdjustmentSelector.getAdjustmentsNotYetInZuora(false, ZuoraCreditMemoBatchSend.AdjustmentType.PostNextBill);
        Database.QueryLocatorIterator iterator = queryLocator.iterator();
        List<Bill_Adjustment__c> beforeCallList = new List<Bill_Adjustment__c>();
        Integer i = 0;
        while (iterator.hasNext()) {
            beforeCallList.add((Bill_Adjustment__c) iterator.next());
            i++;
        }
        System.assertEquals(5, i);

        List<Bill_Adjustment__c> adjustmentsToUpdate = new List<Bill_Adjustment__c>();

        Test.startTest();
        for (Bill_Adjustment__c adjust : beforeCallList){
            adjustmentsToUpdate.add(ZuoraCreditDebitMemoService.createCreditOrDebitMemo(adjust, System.today()));
        }
        Test.stopTest();

        System.assertEquals(5,adjustmentsToUpdate.size());
        for (Bill_Adjustment__c adjustment : adjustmentsToUpdate){
            System.assertNotEquals(null, adjustment.Zuora_Id__c);
        }
    }

    @IsTest
    private static void testCallWithoutUpdatingAdjustment() {
        Database.QueryLocator queryLocator = AdjustmentSelector.getAdjustmentsNotYetInZuora(false, ZuoraCreditMemoBatchSend.AdjustmentType.PostNextBill);
        Database.QueryLocatorIterator iterator = queryLocator.iterator();
        List<Bill_Adjustment__c> beforeCallList = new List<Bill_Adjustment__c>();
        Integer i = 0;
        while (iterator.hasNext()) {
            beforeCallList.add((Bill_Adjustment__c) iterator.next());
            i++;
        }
        System.assertEquals(5, i);

        Test.startTest();
        ZuoraCreditMemoBatchSend zSend = new ZuoraCreditMemoBatchSend();
        zSend.executeBatch();
        Test.stopTest();

        List<Bill_Adjustment__c> adjustList = [
            SELECT Id, Name, Zuora_Id__c
            FROM Bill_Adjustment__c
            WHERE Zuora_Id__c = '2c92c0fa6a3458e1016a45ac238e0d74'
        ];
        System.assertEquals(0, adjustList.size());
    }

    @IsTest
    private static void testOnApprovalSend(){
        // disableTrigger just sets a system property checkbox to true
        Util.disableTrigger('Update_Usage_Records_With_ZuoraId__c');
        ZuoraCreditDebitMemoService.featureService = (FeatureService) Test.createStub(FeatureService.class, new FeatureService.Mock(false));

        List<Bill_Adjustment__c> beforeAdjustments = [
            SELECT Id
            FROM Bill_Adjustment__c
            WHERE Zuora_Id__c != null
        ];
        system.assertEquals(1,beforeAdjustments.size());

        List<Bill_Adjustment__c> unapprovedAdjustments = [
            SELECT Id
            FROM Bill_Adjustment__c
            WHERE Approval_Status__c != 'Approved'
        ];

        for (Bill_Adjustment__c adjust : unapprovedAdjustments){
            adjust.Approval_Status__c = 'Approved';
        }
        System.assertEquals(2,unapprovedAdjustments.size());

        Test.startTest();
            update unapprovedAdjustments;
        Test.stopTest();

        // 8 adjustments exist, 1 already has Zuora_ID__c, 2 Post on Approval, 5 Post on Next Bill:
        List<Bill_Adjustment__c> afterAdjustments = [
            SELECT Id
            FROM Bill_Adjustment__c
            WHERE Zuora_Id__c != null
        ];
        system.assertEquals(3,afterAdjustments.size());
    }

    @IsTest
    private static void testInvoiceItemSortNewestToOldest() {
        List<ZuoraAPI.InvoiceItem> invoiceItems = new List<ZuoraAPI.InvoiceItem>();
        ZuoraAPI.InvoiceItem invoiceItem = new ZuoraAPI.InvoiceItem();
        invoiceItem.id = 'C';
        invoiceItem.chargeDate = '2019-11-05T19:18:19.000-05:00';
        invoiceItems.add(invoiceItem);
        invoiceItem = new ZuoraAPI.InvoiceItem();
        invoiceItem.id = 'A';
        invoiceItem.chargeDate = '2020-03-31T14:53:39.000-04:00';
        invoiceItems.add(invoiceItem);
        invoiceItem = new ZuoraAPI.InvoiceItem();
        invoiceItem.id = 'A';
        invoiceItem.chargeDate = '2020-03-31T14:53:39.000-04:00';
        invoiceItems.add(invoiceItem);
        invoiceItem = new ZuoraAPI.InvoiceItem();
        invoiceItem.id = 'B';
        invoiceItem.chargeDate = '2020-02-28T14:53:39.000-04:00';
        invoiceItems.add(invoiceItem);
        invoiceItems.sort();
        System.assertEquals('A', invoiceItems[0].id);
        System.assertEquals('A', invoiceItems[1].id);
        System.assertEquals('B', invoiceItems[2].id);
        System.assertEquals('C', invoiceItems[3].id);
    }

    @IsTest
    private static void testConvertSFAdjustToDebitMemoFromInvoiceMatch() {
        String adjustJSON = '{' +
            '"Id":"a0p3I000002ziZoQAI",' +
            '"Name":"Test",' +
            '"Utility_Account_Subscription__c":"a1d3I000000HP97QAG",' +
            '"Client__c":"0013I00000I77klQAB",' +
            '"Adjustment_Amount__c":100.00,' +
            '"Adjustment_Type__c":"Client Credit",' +
            '"Credits_Allocated__c":100.00,' +
            '"Utility_Account_Subscription__r":{' +
            '"Id":"a1d3I000000HP97QAG",' +
            '"Opportunity__c":"0063I000002Y9OuQAK",' +
            '"Utility_Account_Log__c":"a1b3I000000Hk6fQAC",' +
            '"Opportunity__r":{"Id":"0063I000002Y9OuQAK","Shared_Solar_System__c":"a1J3I0000003QoOUAU","AccountId":"0013I00000I77l8QAB",' +
            '"Shared_Solar_System__r":{"Id":"a1J3I0000003QoOUAU","Utility__c":"a1M3I0000009HazUAE","Name":"Project E Dog St","Unique_ID__c":"SSS-000099",' +
            '"Utility__r":{"Id":"a1M3I0000009HazUAE","Name":"National Grid"}},' +
            '"Account":{"Id":"0013I00000I77l8QAB","Zuora_Id__c":"2c92c0f96e3aa331016e3ca8eb2c48b7"}}},' +
            '"Client__r":{"Id":"0013I00000I77klQAB","Account_Number__c":"BW-00000385"}}';
        Bill_Adjustment__c adjust = (Bill_Adjustment__c) JSON.deserialize(adjustJSON, Bill_Adjustment__c.class);
        ZuoraAPI.DebitMemo debitMemo = ZuoraCreditDebitMemoService.convertSFAdjustToDebitMemoFromInvoice(adjust, System.today());
        System.assertEquals('SSS-000099', debitMemo.Project_Zcustom);
        System.assertEquals('BW-00000385', debitMemo.ClientOwner_Zcustom);
        System.assertEquals('2c92c094713a9cad01714d1bb4b26b4d', debitMemo.invoiceId);
        System.assertEquals(1, debitMemo.items.size());
        System.assertEquals('2c92c094713a9cad01714d1bb4de6b4e', debitMemo.items[0].invoiceItemId);
    }

    @IsTest
    private static void testConvertSFAdjustToDebitMemoFromInvoiceNoMatch() {
        String adjustJSON = '{' +
            '"Id":"a0p3I000002ziZoQAI",' +
            '"Name":"Test",' +
            '"Utility_Account_Subscription__c":"a1d3I000000HP97QAG",' +
            '"Client__c":"0013I00000I77klQAB",' +
            '"Adjustment_Amount__c":100.00,' +
            '"Adjustment_Type__c":"Client Credit",' +
            '"Credits_Allocated__c":100.00,' +
            '"Utility_Account_Subscription__r":{' +
            '"Id":"a1d3I000000HP97QAG",' +
            '"Opportunity__c":"0063I000002Y9OuQAK",' +
            '"Utility_Account_Log__c":"a1b3I000000Hk6fQAC",' +
            '"Opportunity__r":{"Id":"0063I000002Y9OuQAK","Shared_Solar_System__c":"a1J3I0000003QoOUAU","AccountId":"0013I00000I77l8QAB",' +
            '"Shared_Solar_System__r":{"Id":"a1J3I0000003QoOUAU","Utility__c":"a1M3I0000009HazUAE","Name":"Project E Dog St","Unique_ID__c":"SSS-000099",' +
            '"Utility__r":{"Id":"a1M3I0000009HazUAE","Name":"National Grid"}},' +
            '"Account":{"Id":"0013I00000I77l8QAB","Zuora_Id__c":"2c92c0f96e3aa331016e3ca8eb2c48b7"}}},' +
            '"Client__r":{"Id":"0013I00000I77klQAB","Account_Number__c":"BW-0000000"}}';
        Bill_Adjustment__c adjust = (Bill_Adjustment__c) JSON.deserialize(adjustJSON, Bill_Adjustment__c.class);
        try {
            ZuoraCreditDebitMemoService.convertSFAdjustToDebitMemoFromInvoice(adjust, System.today());
            System.assert(false, 'Should have thrown an exception since there is no invoice line for client BW-0000000');
        } catch (Util.BWException bwe) {
            System.assert(bwe.getMessage().contains('Could not relate adjustment'));
        }
    }

    @IsTest
    private static void testHandleCreditMemo() {
        Map<String, Boolean> featureFlagMap = new Map<String, Boolean>{'Relate_Debit_Memos_To_Invoices'=>false,'Multiple_Subscriptions'=>true};
        ZuoraCreditDebitMemoService.featureService = (FeatureService) Test.createStub(FeatureService.class, new FeatureService.Mock(featureFlagMap));

        String adjustJSON = '{' +
            '"Id":"a0p3I000002ziZoQAI",' +
            '"Name":"Test",' +
            '"Utility_Account_Subscription__c":"a1d3I000000HP97QAG",' +
            '"Client__c":"0013I00000I77klQAB",' +
            '"Adjustment_Amount__c":-100.00,' +
            '"Adjustment_Type__c":"Client Credit",' +
            '"Credits_Allocated__c":100.00,' +
            '"Utility_Account_Subscription__r":{' +
            '"Id":"a1d3I000000HP97QAG",' +
            '"Opportunity__c":"0063I000002Y9OuQAK",' +
            '"Utility_Account_Log__c":"a1b3I000000Hk6fQAC",' +
            '"Opportunity__r":{"Id":"0063I000002Y9OuQAK","Shared_Solar_System__c":"a1J3I0000003QoOUAU","AccountId":"0013I00000I77l8QAB",' +
            '"Shared_Solar_System__r":{"Id":"a1J3I0000003QoOUAU","Utility__c":"a1M3I0000009HazUAE","Name":"Project E Dog St","Unique_ID__c":"SSS-000099",' +
            '"Utility__r":{"Id":"a1M3I0000009HazUAE","Name":"National Grid"}},' +
            '"Account":{"Id":"0013I00000I77l8QAB","Zuora_Id__c":"2c92c0f96e3aa331016e3ca8eb2c48b7"}}},' +
            '"Client__r":{"Id":"0013I00000I77klQAB","Account_Number__c":"BW-00000385"}}';
        Bill_Adjustment__c adjust = (Bill_Adjustment__c) JSON.deserialize(adjustJSON, Bill_Adjustment__c.class);
        adjust = ZuoraCreditDebitMemoService.handleCreditMemo(adjust, System.today());
        System.assertNotEquals(null, adjust.Zuora_Id__c, 'Expected to have a credit memo uploaded to Zuora');
    }
}