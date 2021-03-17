// JP 1/10/20 : Rename this "BillGenerationServiceTest" after migration away from SB / AB and delete existing
@SuppressWarnings('PMD.AvoidHardcodingId, PMD.ExcessivePublicCount')
@IsTest
public class TransferSheetBillingTest {

    // Like a test setup method, but don't actually insert records
    private static Transfer__c getTestTransfer() {
        Date todaysDate = Date.today();
        Date oneMonthAgo = todaysDate.addMonths(-1);

        Shared_Solar_System__c sssOne = new Shared_Solar_System__c(
            Id = 'a1J19000001MFvAEAW',
            Name = 'Project A Oak Road'
        );
        Schedule_Z__c allocationSchedule = new Schedule_Z__c(
            Id = 'a3z190000009UUvAAM',
            Shared_Solar_System__r = sssOne
        );
        Bill_Period__c billPeriod = new Bill_Period__c(
            Id = 'a8x19000000DXkGAAW',
            Bill_Date__c = todaysDate
        );
        Transfer__c transfer = new Transfer__c(
            Allocation_Schedule__c = 'a3z190000009UUvAAM',
            Allocation_Schedule__r = allocationSchedule,
            Shared_Solar_System__c = 'a1J19000001MFvAEAW',
            Date_of_Transfer__c = oneMonthAgo,
            Bill_Period__r = billPeriod,
            Bill_Period__c = 'a8x19000000DXkGAAW',
            Transfer_Type__c = 'Main',
            Attempted_kWh_Transfer__c = 73072.00,
            Attempted_Transfer__c =  12033.73,
            Transfer_Amount__c =  12033.73,
            Default_Credit_Value__c = 0.1848
        );
        return transfer;
    }

    @IsTest
    public static void testGetScheduleZSubscriptionMock() {
        useMocks();
        Transfer__c transfer = getTestTransfer();
        BillGenerationService billGenService = new BillGenerationService(transfer, BillGenerationService.BillType.BOTH);

        // (Mocked) 6 Allocation Schedule Subscriptions to Generate Bills For:
        List<Schedule_Z_Subscription__c> szsList = billGenService.getScheduleZSubscriptionList();
        System.assertEquals(6,szsList.size());

        // Should match Percent_Share__c on SZS in Mock:
        System.assertEquals(1.7982,szsList[0].Percent_Share__c);
        System.assertEquals(0.8300,szsList[1].Percent_Share__c);
        System.assertEquals(1.1758,szsList[2].Percent_Share__c);
        System.assertEquals(1.1758,szsList[3].Percent_Share__c);
        System.assertEquals(0.4841,szsList[4].Percent_Share__c);
    }

    @IsTest
    public static void testUASBsWithDifferentProducts() {
        useMocks();
        Transfer__c transfer = getTestTransfer();
        BillGenerationService billGenService = new BillGenerationService(transfer, BillGenerationService.BillType.BOTH);
        List<UASB__c> uasbs = billGenService.calculateUASBsFromTransfer();

        System.assertEquals(6,uasbs.size());

        // Discounts are set by Product linked to a SZS:
        System.assertEquals(12,uasbs[0].NMC_Discount__c);
        System.assertEquals(25,uasbs[4].NMC_Discount__c);

        // Even though 2 SZS have the same size, because they are either using the NMC or kWH
        // billing method, they have different credits allocated:
        System.assert(uasbs[2].Size_off_NMCs__c);
        System.assertEquals(1.1758,uasbs[2].Share_of_System__c);
        System.assertEquals(859,uasbs[2].Subscription_Production_kWh_Static__c);
        System.assertEquals(141.49,uasbs[2].Credits_Allocated__c);

        System.assert(!uasbs[3].Size_off_NMCs__c);
        System.assertEquals(1.1758,uasbs[3].Share_of_System__c);
        System.assertEquals(859.18,uasbs[3].Subscription_Production_kWh_Static__c);
        System.assertEquals(158.77,uasbs[3].Credits_Allocated__c);
    }

    @IsTest
    private static void testUASBsWithDifferentUtilityRounding() {
        useMocks();
        Transfer__c transfer = getTestTransfer();
        List<UASB__c> beforeUASBs;

        BillGenerationService.testQuiddityOverride = System.Quiddity.AURA;
        BillGenerationService service = new BillGenerationService(transfer, BillGenerationService.BillType.ONTIME);
        List<Schedule_Z_Subscription__c> szsList = service.getScheduleZSubscriptionList();
        System.assert(!szsList.isEmpty(),'SZS list should contain records');

        beforeUASBs = service.calculateUASBesFromSZSes(null);
        System.assertEquals(5,beforeUASBs.size());
        System.assertEquals(859, beforeUASBs[2].Subscription_Production_kWh_Static__c, 'Rounding to 0 decimals for Utility');
        System.assertEquals(859.18, beforeUASBs[3].Subscription_Production_kWh_Static__c, 'Rounding to 2 decimal places for Utility');
    }

    @IsTest
    public static void testProductEscalators() {
        useMocks();
        Transfer__c transfer = getTestTransfer();
        BillGenerationService.testQuiddityOverride = System.Quiddity.AURA;
        BillGenerationService billGenService = new BillGenerationService(transfer, BillGenerationService.BillType.BOTH);
        List<Schedule_Z_Subscription__c> szsList = billGenService.getScheduleZSubscriptionList();
        Map<Id,List<Product_Escalator__c>> productEscalatorMap = billGenService.productEscalatorMap;
        System.assert(productEscalatorMap.size() >= 1);

        String mapKeyScheduleId = szsList[1].Utility_Account_Subscription__r.Opportunity__r.Product_Escalation_Schedule__c;
        System.assertEquals('a6o19000000CsuGAAS', mapKeyScheduleId);

        // For different periods, use different solar electric rates:
        Test.startTest();
        UASB uasb = new UASB(szsList[1], transfer, productEscalatorMap);
        Product_Escalator__c escOne = uasb.getActiveEscalator(productEscalatorMap, 0, mapKeyScheduleId);
        Product_Escalator__c escTwo = uasb.getActiveEscalator(productEscalatorMap, 2, mapKeyScheduleId);
        Product_Escalator__c escThree = uasb.getActiveEscalator(productEscalatorMap, 4, mapKeyScheduleId);
        Test.stopTest();

        System.assertEquals(0.13,escOne.New_Solar_Electricity_Rate__c);
        System.assertEquals(0.18,escTwo.New_Solar_Electricity_Rate__c);
        System.assertEquals(0.18,escThree.New_Solar_Electricity_Rate__c);

        // Mock sets count of transfer = 2, so should use 0.18 rate
        System.assertEquals(2,szsList[1].Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Number_of_Billed_Production_Periods__c);
        List<UASB__c> uasbs = billGenService.calculateUASBsFromTransfer();
        System.assertEquals(0.18,uasbs[1].Solar_Electricity_Rate__c);
    }

    @IsTest
    public static void testDifferentTransferAmount(){
        useMocks();
        Transfer__c transfer = getTestTransfer();
        transfer.Attempted_Transfer__c =  120000.25;
        transfer.Attempted_kWh_Transfer__c = 50000.00;

        BillGenerationService.testQuiddityOverride = System.Quiddity.AURA;
        BillGenerationService billGenService = new BillGenerationService(transfer, BillGenerationService.BillType.BOTH);
        List<UASB__c> firstBillGroup = billGenService.calculateUASBsFromTransfer();

        System.assertEquals(242.05,firstBillGroup[4].Subscription_Production_kWh_Static__c);
        System.assertEquals(580.92,firstBillGroup[4].Credits_Allocated__c);

        // Credit value is doubled, kWH is the same:
        transfer.Attempted_Transfer__c =  240000.50;
        transfer.Attempted_kWh_Transfer__c = 50000.00;

        List<UASB__c> secondBillGroup = billGenService.calculateUASBsFromTransfer();

        System.assertEquals(242.05,secondBillGroup[4].Subscription_Production_kWh_Static__c);
        System.assertEquals(1161.84,secondBillGroup[4].Credits_Allocated__c);
    }

    @IsTest
    public static void testCancelledCustomer(){
        useMocks();
        Transfer__c transfer = getTestTransfer();
        BillGenerationService.testQuiddityOverride = System.Quiddity.AURA;

        BillGenerationService billGenService1 = new BillGenerationService(transfer, BillGenerationService.BillType.ONTIME);
        List<UASB__c> onTimeUASB = billGenService1.calculateUASBsFromTransfer();

        BillGenerationService billGenService2 = new BillGenerationService(transfer, BillGenerationService.BillType.OVERDUE);
        List<UASB__c> overdueUASB = billGenService2.calculateUASBsFromTransfer();

        System.assertEquals(5,onTimeUASB.size());
        System.assertEquals(1,overdueUASB.size());

        // Normal Bills:
        System.assertEquals(859,onTimeUASB[2].Subscription_Production_kWh_Static__c);
        System.assertEquals(141.49,onTimeUASB[2].Credits_Allocated__c);
        System.assertEquals(859.18,onTimeUASB[3].Subscription_Production_kWh_Static__c);
        System.assertEquals(158.77,onTimeUASB[3].Credits_Allocated__c);

        // Cancelled:
        System.assertEquals(0,overdueUASB[0].Subscription_Production_kWh_Static__c);
        System.assertEquals(0,overdueUASB[0].Credits_Allocated__c);
    }

    @IsTest
    public static void testStopCreditTransfer(){
        useMocks();
        Transfer__c transfer = getTestTransfer();
        List<UASB__c> beforeUASBs;
        List<UASB__c> afterUASBs;

        BillGenerationService.testQuiddityOverride = System.Quiddity.AURA;
        BillGenerationService billGenService = new BillGenerationService(transfer, BillGenerationService.BillType.ONTIME);
        List<Schedule_Z_Subscription__c> szsList = billGenService.getScheduleZSubscriptionList();

        beforeUASBs = billGenService.calculateUASBesFromSZSes(null);
        System.assertEquals(5,beforeUASBs.size());
        for (UASB__c uasb : beforeUASBs){
            System.assertNotEquals(0,uasb.Credits_Allocated__c);
        }

        Test.startTest();
            // Override szs list selector for mock test
            for (Schedule_Z_Subscription__c szs : szsList){
                szs.Stop_Credit_Transfer__c = true;
            }
        Test.stopTest();

        afterUASBs = billGenService.calculateUASBesFromSZSes(szsList);
        System.assertEquals(5,afterUASBs.size());
        for (UASB__c uasb : afterUASBs){
            System.assertEquals(0,uasb.Credits_Allocated__c);
        }
    }

    @IsTest
    private static void testConvertTransferSheetToUASB(){
        // Wrong Column Headers:
        String transferSheetWrongColumnHeaders = 'UtilityNumber,Credits,Production,XXX\n 123456789,12,2300,12\n';
        Map<Integer, List<String>> dataMap = Util.readCSV(transferSheetWrongColumnHeaders);
        Boolean errorThrown = false;
        TransferSheetService.initializeClass(getTestTransfer());
        try {
            TransferSheetService.convertTransferCsvToUASBs(dataMap);
        } catch (AuraHandledException excep){
            errorThrown = true;
            System.assert(excep.getMessage().contains('Expected column 4 named CreditValue, found XXX'));
        }
        System.assert(errorThrown);

        // Mix of spaces, dashes in Utility Number && Production and Credit Value are missing from some data
        String transferSheetData = 'UtilityNumber,Credits,Production,CreditValue\n' +
            ' 12345  6789,12,2300,\n' +
            '123-678,13.45,2500,\n' +
            '123678,10,2500,\n' +
            '00123 - 45678,14.12,,0.1355\n' +
            '223232,15,,0.1447\n' +
            '2323224,16,,0.1355\n';

        Map<Integer, List<String>> rowNumberToDataMap = Util.readCSV(transferSheetData);

        List<String> dataStringList = rowNumberToDataMap.get(2);
        System.assertEquals(4,dataStringList.size());
        System.assertEquals('123-678',dataStringList[0]);

        Map<String,UASB__c> utilNumberToUASB = TransferSheetService.convertTransferCsvToUASBs(rowNumberToDataMap);

        UASB__c uasbOne = utilNumberToUASB.get('123456789');
        UASB__c uasbTwo = utilNumberToUASB.get('123678');
        UASB__c uasbThree = utilNumberToUASB.get('0012345678');
        UASB__c uasbFour = utilNumberToUASB.get('223232');
        UASB__c uasbFive = utilNumberToUASB.get('2323224');

        System.assertEquals(12,uasbOne.Credits_Allocated__c);
        System.assertEquals(23.45,uasbTwo.Credits_Allocated__c);
        System.assertEquals(14.12,uasbThree.Credits_Allocated__c);
        System.assertEquals(15,uasbFour.Credits_Allocated__c);
        System.assertEquals(16,uasbFive.Credits_Allocated__c);

        System.assertEquals(2300,uasbOne.Subscription_Production_kWh_Static__c);
        System.assertEquals(2500,uasbTwo.Subscription_Production_kWh_Static__c);
        System.assertEquals(null,uasbThree.Subscription_Production_kWh_Static__c);
        System.assertEquals(null,uasbFour.Subscription_Production_kWh_Static__c);
        System.assertEquals(null,uasbFive.Subscription_Production_kWh_Static__c);

        System.assertEquals(null,uasbOne.NMC_Rate__c);
        System.assertEquals(null,uasbTwo.NMC_Rate__c);
        System.assertEquals(0.1355,uasbThree.NMC_Rate__c);
        System.assertEquals(0.1447,uasbFour.NMC_Rate__c);
        System.assertEquals(0.1355,uasbFive.NMC_Rate__c);
    }

    @IsTest
    private static List<TransferSheetService.UASBWithStatus> setupTestSFBillsToTransferMA(){
        useMocks();
        TestFactory.setCSBillSettings();
        // MA: Transfer Sheet does NOT have Production (kWH) and NMC Rate ($/kWh)

        // First, Get SF Generated Bills:
        Transfer__c transfer = getTestTransfer();
        BillGenerationService billGenService = new BillGenerationService(
            transfer, BillGenerationService.BillType.ONTIME
        );
        List<UASB__c> sfUASBs = billGenService.calculateUASBsFromTransfer();
        System.assertEquals(5,sfUASBs.size());

        // Second, Get Transfer Sheet Bills:
        String transferSheetData = 'UtilityNumber,Credits,Production,CreditValue\n' +
            '12345-6789,242.82,,\n' +
            '123 678,99,,\n' +
            '123678,$10.88,,\n' +
            '0012 3456789,99.88,,\n' +
            '223232,$141.40,,\n' +
            '23232 24,99.88,,\n';
        Map<Integer, List<String>> rowNumberToDataMap = Util.readCSV(transferSheetData);
        TransferSheetService.initializeClass(transfer);
        Map<String,UASB__c> transferUASBs = TransferSheetService.convertTransferCsvToUASBs(rowNumberToDataMap);
        // CSV has 6 rows, but 5 unique utility account numbers:
        System.assertEquals(5,transferUASBs.values().size());

        // Third, Compare SF to Transfer:
        List<TransferSheetService.UASBWithStatus> matchList;
        matchList = TransferSheetService.compareSFBillsToTransferSheet(sfUASBs, transferUASBs);
        System.assertEquals(6,matchList.size());
        return matchList;
    }

    @IsTest
    private static void testCompareSFBillsToTransferMA(){
        List<TransferSheetService.UASBWithStatus> matchList = setupTestSFBillsToTransferMA();
        Integer countOfLineItemsWithoutSZS = 0;
        /*
            Expect 3 matches (same between transfer sheet and SF OR within tolerance)
            1 credit mismatches (found utility number in both, but credits allocated are different)
            1 missing transfer (record in SF is not on transfer sheet)
            1 missing bill (transfer record is not in SF)
        */
        for (TransferSheetService.UASBWithStatus lineItem : matchList) {
            String utilityNumber = lineItem.sfUASB.PreGen_Utility_Acct__c;
            switch on utilityNumber {
                when '12-34-56-789' {
                    System.assertEquals('MATCH', lineItem.status);
                    System.assert(lineItem.overdue);
                } when '23 23 224' {
                    System.assertEquals('MATCH', lineItem.status);
                    System.assert(lineItem.overdue);
                } when '223232' {
                    System.assertEquals(141.49, lineItem.sfUASB.Credits_Allocated__c);
                    System.assertEquals('MATCH', lineItem.status);
                    System.assert(lineItem.overdue);
                } when ' 00 12 34 56789' {
                    System.assertEquals(158.77, lineItem.sfUASB.Credits_Allocated__c);
                    System.assertEquals('CREDIT_MISMATCH', lineItem.status);
                    System.assert(lineItem.overdue);
                } when '777888' {
                    System.assertEquals('MISSING_TRANSFER', lineItem.status);
                    System.assert(!lineItem.overdue);
                } when else {
                    countOfLineItemsWithoutSZS += 1;
                    System.assertEquals('MISSING_BILL', lineItem.status);
                }
            }
        }
        System.assertEquals(1,countOfLineItemsWithoutSZS);
    }

    @IsTest
    private static void testCompareSFBillsToTransferMN(){
        useMocks();

        // MN: Transfer Sheet has Production (kWH) and NMC Rate ($/kWh)

        // First, Get SF Generated Bills:
        Transfer__c transfer = getTestTransfer();
        BillGenerationService billGenService = new BillGenerationService(transfer, BillGenerationService.BillType.ONTIME);
        List<UASB__c> sfUASBs = billGenService.calculateUASBsFromTransfer();
        System.assertEquals(5,sfUASBs.size());

        // Second, Get Transfer Sheet Bills:
        String transferSheetData = 'UtilityNumber,Credits,Production,CreditValue\n' +
            '12345-6789,242.82,1300.98,0.1848\n' +
            '123 678,99,2600,0.1848\n' +
            '00123456789,10.00,,\n' +
            '0012 3456789,148.77,859.18,0.1848\n' +
            '223232,141.49,859,0.1848\n' +
            '23232 24,99.88,606.50,0.1324\n';
        Map<Integer, List<String>> rowNumberToDataMap = Util.readCSV(transferSheetData);
        TransferSheetService.initializeClass(transfer);
        Map<String,UASB__c> transferUASBs = TransferSheetService.convertTransferCsvToUASBs(rowNumberToDataMap);
        // CSV has 6 rows, but 5 unique utility account numbers:
        System.assertEquals(5,transferUASBs.values().size());

        // Third, Compare SF to Transfer:
        List<TransferSheetService.UASBWithStatus> matchList;
        matchList = TransferSheetService.compareSFBillsToTransferSheet(sfUASBs, transferUASBs);
        System.assertEquals(6,matchList.size());

        Integer countOfLineItemsWithoutSZS = 0;

        /*
            Expect 3 matches (same between transfer sheet and SF OR within tolerance)
            1 credit mismatch (found utility number, but credits allocated are different)
            2 missing transfers (record in SF is not on transfer sheet)
            1 missing bill (transfer record is not in SF)
        */

        for (TransferSheetService.UASBWithStatus lineItem : matchList) {
            String utilityNumber = lineItem.sfUASB.PreGen_Utility_Acct__c;
            switch on utilityNumber {
                when '12-34-56-789' {
                    System.assertEquals('CREDIT_MISMATCH', lineItem.status);
                } when '23 23 224' {
                    System.assertEquals('MATCH', lineItem.status);
                } when '223232' {
                    System.assertEquals('MATCH', lineItem.status);
                } when ' 00 12 34 56789' {
                    System.assertEquals('MATCH', lineItem.status);
                } when '777888' {
                    System.assertEquals('MISSING_TRANSFER', lineItem.status);
                } when else {
                    countOfLineItemsWithoutSZS += 1;
                    System.assertEquals('MISSING_BILL', lineItem.status);
                }
            }
        }
        System.assertEquals(1,countOfLineItemsWithoutSZS);
    }

    @IsTest
    private static void testCompareSFBillsToTransferWithZerosAndNulls(){
        useMocks();

        // First, Get SF Generated Bills:
        Transfer__c transfer = getTestTransfer();
        BillGenerationService billGenService = new BillGenerationService(transfer, BillGenerationService.BillType.ONTIME);
        List<UASB__c> sfUASBs = billGenService.calculateUASBsFromTransfer();
        System.assertEquals(5,sfUASBs.size());

        // Second, Get Transfer Sheet Bills:
        String transferSheetData = 'UtilityNumber,Credits,Production,CreditValue\n' +
            '0012 3456789,158.77,,\n' +
            '0012 3456789,,,\n' +
            '223232,0,859,0.1848\n';
        Map<Integer, List<String>> rowNumberToDataMap = Util.readCSV(transferSheetData);
        TransferSheetService.initializeClass(transfer);
        Map<String,UASB__c> transferUASBs = TransferSheetService.convertTransferCsvToUASBs(rowNumberToDataMap);

        // Third, Compare SF to Transfer:
        List<TransferSheetService.UASBWithStatus> matchList;
        matchList = TransferSheetService.compareSFBillsToTransferSheet(sfUASBs, transferUASBs);
        for (TransferSheetService.UASBWithStatus lineItem : matchList){
            String utilityNumber = lineItem.sfUASB?.PreGen_Utility_Acct__c;
            if (utilityNumber == '223232') {
                System.assertEquals('CREDIT_MISMATCH', lineItem.status,
                    'Utility number 223232 should not have matches because credits on the transfer sheet is 0: ' +
                        JSON.serializePretty(lineItem));
            } else if (utilityNumber == ' 00 12 34 56789') {
                System.assertEquals('MATCH', lineItem.status,
                    'Utility number 00 12 34 56789 should have matched even though Production and Credit Value on the' +
                        ' transfer are null: ' + JSON.serializePretty(lineItem));
            }
        }
    }

    @IsTest
    private static void testResolveLWC(){
        TransferSheetService.initializeClass(mockTransferServiceInitObjectNonUCB());
        String apexDataAsJSON = mockGetApexDataFromLWC();
        List<String> overrideValues = mockGetResolutionDataFromLWC();
        List<TransferSheetService.UASBWithStatus> uasbWithStatusList;
        uasbWithStatusList = (List<TransferSheetService.UASBWithStatus>) System.JSON.deserialize(apexDataAsJSON, List<TransferSheetService.UASBWithStatus>.class);
        Map<Id,String> resolutionMap = TransferSheetService.readDataFromLWC(overrideValues);

        // 4 UASBs being Resolved:
        System.assertEquals(4,uasbWithStatusList.size());
        for (TransferSheetService.UASBWithStatus uasbStatus : uasbWithStatusList){
            if (uasbStatus.status == 'CREDIT_MISMATCH'){
                System.assert(!uasbStatus.overdue);
                uasbStatus.overdue = true;
            }
        }

        List<UASB__c> firstUASBList = TransferSheetService.resolveUASBs(uasbWithStatusList, resolutionMap);

        // Only 2 Inserted because 1 is MISSING_BILL, and 1 is MISSING_TRANSFER with UseUtility Resolution:
        System.assertEquals(2,firstUASBList.size());

        // Update MISSING_TRANSFER resolution to UseSalesforce, and a bill should be made:
        System.assertEquals('UseUtility',resolutionMap.get('a54540000001oN4AAI'));
        resolutionMap.put('a54540000001oN4AAI','UseSalesforce');

        List<UASB__c> secondUASBList = TransferSheetService.resolveUASBs(uasbWithStatusList, resolutionMap);
        System.assertEquals(3,secondUASBList.size());
        System.assertNotEquals(null,secondUASBList[0].Transfer_Sheet_Resolution__c);
        System.assertNotEquals(null,secondUASBList[1].Transfer_Sheet_Resolution__c);
        System.assertNotEquals(null,secondUASBList[2].Transfer_Sheet_Resolution__c);
    }

    @IsTest
    private static void testResolveCreditMismatchUseUtility(){
        TransferSheetService.initializeClass(mockTransferServiceInitObjectNonUCB());
        String apexDataAsJSON = mockGetApexDataFromLWC();
        List<String> overrideValues = mockGetResolutionDataFromLWC();
        List<TransferSheetService.UASBWithStatus> uasbWithStatusList;
        uasbWithStatusList = (List<TransferSheetService.UASBWithStatus>) System.JSON.deserialize(apexDataAsJSON, List<TransferSheetService.UASBWithStatus>.class);
        Map<Id,String> resolutionMap = TransferSheetService.readDataFromLWC(overrideValues);

        Id creditMismatchRecord = 'a54540000001oN2AAI';
        Boolean confirmRecordExists = false;
        for (TransferSheetService.UASBWithStatus uasbStatus : uasbWithStatusList){
            if (uasbStatus.status == 'CREDIT_MISMATCH'){
                System.assertEquals(149.22,uasbStatus.sfUASB.Credits_Allocated__c);
                System.assertEquals(251.33,uasbStatus.utilUASB.Credits_Allocated__c);
                System.assertEquals(1015.18,uasbStatus.sfUASB.Subscription_Production_kWh_Static__c);
                System.assertEquals(null,uasbStatus.utilUASB.Subscription_Production_kWh_Static__c);
                confirmRecordExists = true;
            }
        }
        System.assert(confirmRecordExists);
        confirmRecordExists = false;

        List<UASB__c> firstUASBList = TransferSheetService.resolveUASBs(uasbWithStatusList, resolutionMap);

        // CREDIT_MISMATCH with UseUtility Resolution. If any field is blank on the transfer (ie, Production kWh here)
        // do not override SF values:
        for (UASB__c uasb : firstUASBList){
            if (uasb.Schedule_Z_Subscription__c == creditMismatchRecord){
                System.assertEquals(251.33,uasb.Credits_Allocated__c);
                System.assertEquals(1015.18,uasb.Subscription_Production_kWh_Static__c);
                confirmRecordExists = true;
            }
        }
        System.assert(confirmRecordExists);
        confirmRecordExists = false;
    }

    @IsTest
    private static void testResolveCreditMismatchUseSF(){
        TransferSheetService.initializeClass(mockTransferServiceInitObjectNonUCB());
        String apexDataAsJSON = mockGetApexDataFromLWC();
        List<String> overrideValues = mockGetResolutionDataFromLWC();
        List<TransferSheetService.UASBWithStatus> uasbWithStatusList;
        uasbWithStatusList = (List<TransferSheetService.UASBWithStatus>) System.JSON.deserialize(apexDataAsJSON, List<TransferSheetService.UASBWithStatus>.class);
        Map<Id,String> resolutionMap = TransferSheetService.readDataFromLWC(overrideValues);

        Boolean confirmRecordExists = false;
        for (TransferSheetService.UASBWithStatus uasbStatus : uasbWithStatusList){
            if (uasbStatus.status == 'CREDIT_MISMATCH'){
                System.assertEquals(149.22,uasbStatus.sfUASB.Credits_Allocated__c);
                System.assertEquals(251.33,uasbStatus.utilUASB.Credits_Allocated__c);
                System.assertEquals(1015.18,uasbStatus.sfUASB.Subscription_Production_kWh_Static__c);
                System.assertEquals(null,uasbStatus.utilUASB.Subscription_Production_kWh_Static__c);
                confirmRecordExists = true;
            }
        }
        System.assert(confirmRecordExists);
        confirmRecordExists = false;

        Id creditMismatchRecord = 'a54540000001oN2AAI';
        resolutionMap.put(creditMismatchRecord,'UseSalesforce');
        System.assertEquals('UseSalesforce',resolutionMap.get(creditMismatchRecord));

        List<UASB__c> firstUASBList = TransferSheetService.resolveUASBs(uasbWithStatusList, resolutionMap);

        for (UASB__c uasb : firstUASBList){
            if (uasb.Schedule_Z_Subscription__c == creditMismatchRecord){
                System.assertEquals(149.22,uasb.Credits_Allocated__c);
                System.assertEquals(1015.18,uasb.Subscription_Production_kWh_Static__c);
                confirmRecordExists = true;
            }
        }
        System.assert(confirmRecordExists);
    }

    @IsTest
    private static void testResolveLWCWithOverdue(){
        TransferSheetService.initializeClass(mockTransferServiceInitObjectNonUCB());
        String apexDataAsJSON = mockGetApexDataFromLWC();
        List<String> overrideValues = mockGetResolutionDataFromLWC();
        List<TransferSheetService.UASBWithStatus> uasbWithStatusList;
        uasbWithStatusList = (List<TransferSheetService.UASBWithStatus>) System.JSON.deserialize(apexDataAsJSON, List<TransferSheetService.UASBWithStatus>.class);
        Map<Id,String> resolutionMap = TransferSheetService.readDataFromLWC(overrideValues);

        // 4 UASBs being Resolved:
        System.assertEquals(4,uasbWithStatusList.size());

        List<UASB__c> firstUASBList = TransferSheetService.resolveUASBs(uasbWithStatusList, resolutionMap);

        // Only 2 Inserted because 1 is MISSING_BILL, and 1 is MISSING_TRANSFER with UseUtility Resolution:
        System.assertEquals(2,firstUASBList.size());

        // Update MISSING_TRANSFER bill to be Overdue = true, and a $0 bill will be made
        // even though it has a "UseUtility" resolution (ie, no bill)
        for (TransferSheetService.UASBWithStatus uasbStatus : uasbWithStatusList){
            if (uasbStatus.status == 'MISSING_TRANSFER'){
                System.assert(!uasbStatus.overdue);
                uasbStatus.overdue = true;
            }
        }

        List<UASB__c> secondUASBList = TransferSheetService.resolveUASBs(uasbWithStatusList, resolutionMap);
        System.assertEquals(3,secondUASBList.size());
    }

    @IsTest
    private static void testPostUASBInsertProcessing(){
        Util.disableTrigger('Disable_TransferTrigger__c');
        Shared_Solar_System__c sss1 = new Shared_Solar_System__c(
            Name = 'Test Project',
            Billing_Method__c = 'NMC'
        );
        insert sss1;

        Bill_Period__c billPeriod = new Bill_Period__c(
            Shared_Solar_System__c = sss1.Id,
            Name = 'Bill Period One',
            Bill_Status__c = 'Ready To Generate'
        );
        insert billPeriod;

        Transfer__c transferOne = new Transfer__c(
            Name = 'TransferA',
            Bill_Period__c = billPeriod.Id,
            Transfer_Type__c = 'Main',
            Bills_Generated__c = false,
            Shared_Solar_System__c = sss1.Id,
            Attempted_Transfer__c = 1000,
            Attempted_kWh_Transfer__c = 19000,
            Transfer_Amount__c = 1000,
            Date_of_Transfer__c = Date.newInstance(2019, 6, 4)
        );
        insert transferOne;

        List<String> mockTransferSheetScreenData = new List<String>();
        mockTransferSheetScreenData.add('{"Uniqueid":"a548A0000009d1iQAA","customername":"Viaan Faulkner",' +
            '"sfutilityaccount":"000023410","sfproduction":504.2,"sfcredits":83.03,"sfcreditvalue":0.1848,' +
            '"trutilityaccount":"000023410","trproduction":0,"trcredits":116.73,"trcreditvalue":0,' +
            '"isCreditMismatch":true,"Resolution":"UseSalesforce"}');
        mockTransferSheetScreenData.add('Conner","sfutilityaccount":"00002346","sfproduction":657.65,' +
            '"sfcredits":108.3,"sfcreditvalue":0.1848,"trutilityaccount":"00002346","trproduction":0,' +
            '"trcredits":116.73,"trcreditvalue":0,"isCreditMismatch":true,"Resolution":"UseSalesforce"}');

        TransferSheetService.postUASBInsertProcessing(transferOne, mockTransferSheetScreenData);

        Transfer__c transfer = [
            SELECT Id, Bills_Generated__c, Bill_Period__c
            FROM Transfer__c
            WHERE Id = : transferOne.Id
            LIMIT 1
        ];
        System.assert(transfer.Bills_Generated__c);

        Bill_Period__c bp = [
            SELECT Id, Bill_Status__c
            FROM Bill_Period__c
            WHERE Id = : transferOne.Bill_Period__c
            LIMIT 1
        ];
        System.assertEquals('Generated',bp.Bill_Status__c);

        List<ContentDocumentLink> filesUploaded = [
            SELECT Id
            FROM ContentDocumentLink
            WHERE LinkedEntityId = : transferOne.Id
        ];
        System.assertEquals(1,filesUploaded.size());
    }

    @IsTest
    private static void testPreventBillingTransfersOutOfOrder() {
        TransferSheetService.transferSelector = (TransferSelector) Test.createStub(TransferSelector.class, new MockTransferSelector());
        System.assertEquals(1, TransferSheetService.transferSelector.getUnbilledTransfersBySSS(null).size(),
            'Mock should return one unbilled transfer');
        System.assertEquals(Date.newInstance(2020,02,06), TransferSheetService.transferSelector.getUnbilledTransfersBySSS(null)[0].Date_of_Transfer__c,
            'Mocked unbilled transfer should have a date of 2/6/2020');
        Transfer__c transferBeingQCed = new Transfer__c(
            Date_of_Transfer__c = Date.newInstance(2020,3,1)
        );
        try {
            TransferSheetService.preventBillingTransferOutOfOrder(transferBeingQCed);
            System.assert(false, 'Should have thrown an exception because transfer being QCed is later than other unbilled transfers ');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('There is another transfer'), 'Error should indicate another transfer');
        }
        transferBeingQCed.Date_of_Transfer__c = Date.newInstance(2020,02,06);
        try {
            TransferSheetService.preventBillingTransferOutOfOrder(transferBeingQCed);
            System.assert(true, 'Should not have prevented this transfer since it has the same date as the other unbilled transfer (maybe itself)');
        } catch (Exception e) {
            System.assert(false, 'Should not have prevented this transfer since it has the same date as the other unbilled transfer (maybe itself): ' + e.getMessage() + '\n' + e.getStackTraceString());
        }
        transferBeingQCed.Date_of_Transfer__c = Date.newInstance(2020,01,06);
        try {
            TransferSheetService.preventBillingTransferOutOfOrder(transferBeingQCed);
            System.assert(true, 'Should not have prevented this transfer since it has an earlier date as the other unbilled transfer');
        } catch (Exception e) {
            System.assert(false, 'Should not have prevented this transfer since it has an earlier date as the other unbilled transfer: ' + e.getMessage() + '\n' + e.getStackTraceString());
        }
    }

    @IsTest
    private static void testUCBTransferWithUtilityCSV() {
        // Test Setup
        useUCBMocks();

        // Run test
        Test.startTest();
        List<TransferSheetService.UASBWithStatus> uasbs = TransferSheetService.getTransferFromId('a90050000004CZgAAM');
        System.assertEquals(2, uasbs.size(), '2 UCB UASBs should have been handled');
        Test.stopTest();

        // Assertions global to all UASBs
        for (TransferSheetService.UASBWithStatus uasb : uasbs) {
            System.assertEquals('UCB', uasb.sfUASB.Billing_Method__c, 'Incorrect billing method for UCB UASBs');
            System.assertNotEquals(null, uasb.sfUASB);
            System.assertNotEquals(null, uasb.utilUASB);
            System.assertNotEquals('MISSING_TRANSFER', uasb.status, 'UCB UASB should not have a match status of MISSING_TRANSFER');
        }

        // Assertions on UASB for mock SZS with ID 'szsOne_ID' -- see Mock impl for raw data
        System.assertEquals('001519510481', uasbs[0].sfUASB.PreGen_Utility_Acct__c, 'Incorrect utility account # on UASB');
        System.assertEquals(100, uasbs[0].sfUASB.Starting_Banked_Credits__c, 'Incorrect Starting_Banked_Credits__c value');
        System.assertEquals(uasbs[0].sfUASB.Credits_Allocated__c, uasbs[0].sfUASB.New_available_credits__c, 'Incorrect New Available Credits');
        Decimal expectedTotalAvailCredits = 100 + uasbs[0].sfUASB.New_available_credits__c;
        System.assertEquals(expectedTotalAvailCredits, uasbs[0].sfUASB.Total_Available_Credits__c, 'Incorrect Total Available Credits');
        System.assertEquals(65, uasbs[0].sfUASB.Satellite_Charges__c, 'Incorrect Satelite Charges value from transfer .csv');
        System.assertEquals(
            Math.min(uasbs[0].sfUASB.Total_Available_Credits__c, uasbs[0].sfUASB.Satellite_Charges__c),
            uasbs[0].sfUASB.Calculated_Credits__c,
            'Incorrect calculated credits'
        );
        System.assertEquals(Date.valueOf('2021-03-09'),uasbs[0].sfUASB.Satellite_Bill_Date__c, 'Incorrect Satellite Bill Date');
        System.assertEquals(Date.valueOf('2021-03-09'),uasbs[0].utilUASB.Satellite_Bill_Date__c, 'Incorrect Satellite Bill Date');

        Decimal expectedNetMemberCredits = uasbs[0].sfUASB.Calculated_Credits__c * .12; // .12 comes from Mock SZS impl
        Decimal expectedEndingBankedCredits = expectedTotalAvailCredits - uasbs[0].sfUASB.Calculated_Credits__c;
        Decimal expectedDiscountedBill = uasbs[0].sfUASB.Satellite_Charges__c - uasbs[0].sfUASB.Net_Member_Credits__c;
        Decimal expectedCDGSubFee = uasbs[0].sfUASB.Calculated_Credits__c - uasbs[0].sfUASB.Net_Member_Credits__c;
        Decimal expectedAdminFee = (0.01 * uasbs[0].sfUASB.CDG_Subscription_Fee__c).setScale(2,UASB.DEFAULT_ROUND);
        Decimal expectedCDGSponsorPayment =  expectedCDGSubFee - expectedAdminFee;

        System.assertEquals(expectedNetMemberCredits, uasbs[0].sfUASB.Net_Member_Credits__c, 'Incorrect Net Member Credits');
        System.assertEquals(expectedDiscountedBill, uasbs[0].sfUASB.Discounted_Utility_Bill__c, 'Incorrect Ending Banked Credits');
        System.assertEquals(expectedEndingBankedCredits, uasbs[0].sfUASB.Ending_Banked_Credits__c, 'Incorrect Ending Banked Credits');
        System.assertEquals(expectedCDGSubFee, uasbs[0].sfUASB.CDG_Subscription_Fee__c, 'Incorrect CDG Subscription Fee');
        System.assertEquals(expectedAdminFee, uasbs[0].sfUASB.Utility_Admin_Fee__c, 'Incorrect Utility Admin Fee');
        System.assertEquals(expectedCDGSponsorPayment, uasbs[0].sfUASB.CDG_Sponsor_Payment__c, 'Incorrect CDG Sponsor Payment');
    }

    private static void useMocks() {
        BillGenerationService.szsSelector = (ScheduleZSubscriptionSelector) Test.createStub(ScheduleZSubscriptionSelector.class, new MockSZSSelector());
        BillGenerationService.escalatorSelector = (ProductEscalatorSelector) Test.createStub(ProductEscalatorSelector.class, new MockPESelector());
        TransferSheetService.accountsSelector = (AccountsSelector) Test.createStub(AccountsSelector.class, new MockAccountSelector());
    }

    private static void useUCBMocks() {
        BillGenerationService.szsSelector = (ScheduleZSubscriptionSelector) Test.createStub(ScheduleZSubscriptionSelector.class, new MockUCBSZSSelector());
        BillGenerationService.escalatorSelector = (ProductEscalatorSelector) Test.createStub(ProductEscalatorSelector.class, new MockPESelector());
        BillGenerationService.feeSelector = (DefaultUtilityFeeSelector) Test.createStub(DefaultUtilityFeeSelector.class, new MockDefaultUtilityFeeSelector());
        BillGenerationService.uasbSelector = (UASBSelector) Test.createStub(UASBSelector.class, new MockUASBSelector());
        TransferSheetService.accountsSelector = (AccountsSelector) Test.createStub(AccountsSelector.class, new MockAccountSelector());
        TransferSheetService.transferSelector = (TransferSelector) Test.createStub(TransferSelector.class, new MockUCBTransferSelector());
        TransferSheetService.docSelector = (ContentDocumentSelector) Test.createStub(ContentDocumentSelector.class, new MockUCBContentDocumentSelector());
    }

    public class MockUASBSelector extends MockProvider {
        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'getLatestUcbUasbBySzs' {
                    Map<String,UASB__c> priorUASBMapMock = new Map<String,UASB__c> {
                        'szsOne_ID' => new UASB__c(Ending_Banked_Credits__c = 100.00)
                    };
                    return priorUASBMapMock;
                }
            }
            return null;
        }
    }

    public class MockDefaultUtilityFeeSelector extends MockProvider {
        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'getActiveUCBRecordForUtility' {
                    return new Default_Utility_Fee__c(
                        Type__c = 'UCB',
                        Utility_Admin_Fee__c = 0.01, // Percent field
                        Method_for_UCB_Utility_Admin__c = 'CDG Subscription Fee'
                    );
                }
            }
            return null;
        }
    }

    public class MockSZSSelector extends MockProvider {
        public override Object handleMethodCall(MethodCall methodCall) {
            String szsOne = '{"Id":"szsOne_ID","Customer_Subscription_kW_DC__c": 26.00,"Percent_Share__c" : 1.7982,' +
                '"System_Size_kW_DC__c" : 1445.86,' +
                '"Schedule_Z__c" : "a3z190000009UUvAAM",' +
                '"Schedule_Z__r" : {"Name" : "SZ_NYSEG", ' +
                '"Shared_Solar_System__r" : { "Utility__r" : {"UASB_Number_of_Decimals__c" : 2, "Transfer_Mismatch_Tolerance__c":1.00}}},' +
                '"Utility_Account_Subscription__r" : {"Name" : "UAS_One", ' +
                '"Utility_Account_Log__r" : {"Name" : "07777", "Premise_Number__c" : "12-34-56-789"},' +
                '"Opportunity__r" : {"Id":"0000000AAA","Name":"Oppty A",' +
                '"Product__r" : {"NMC_Discount__c" : 12.00 ,"NM_Rate_Floor__c" : 0.0,"Solar_Electricity_Rate__c" : 0.13,' +
                '"Pricing_Structure__c" : "Use Solar Electric Rate","Percent_Share_Decimal_Places__c" : 6.00},' +
                '"Shared_Solar_System__r" : {"Id": "a1J19000001MFvAEAW", "Number_of_Billed_Production_Periods__c" : 2, "Billing_Method__c" : "kWh"}, ' +
                '"Account" : {"Name" : "Account One", "Account_Number__c" : "BW-00001"},' +
                '"AccountId" : "0015400000SajzCAAA"}}}';
            String szsTwo = '{"Id":"szsTwo_ID","Customer_Subscription_kW_DC__c": 12.00,"Percent_Share__c" : 0.8300,' +
                '"System_Size_kW_DC__c" : 1445.86,' +
                '"Schedule_Z__c" : "a3z190000009UUvAAM",' +
                '"Schedule_Z__r" : {"Name" : "SZ_NYSEG", ' +
                '"Shared_Solar_System__r" : { "Utility__r" : {"UASB_Number_of_Decimals__c" : 2, "Transfer_Mismatch_Tolerance__c":1.00}}},' +
                '"Utility_Account_Subscription__r" : {"Name" : "UAS_Two", ' +
                '"Utility_Account_Log__r" : {"Name" : "23 23 224"},' +
                '"Opportunity__r" : {"Id":"0000000BBB","Name":"Oppty B", "Product_Escalation_Schedule__c" : "a6o19000000CsuGAAS",' +
                '"Product__r" : {"NMC_Discount__c" : 10.00 ,"NM_Rate_Floor__c" : 0.0,"Solar_Electricity_Rate__c" : 0.13,' +
                '"Pricing_Structure__c" : "Fixed % Discount","Percent_Share_Decimal_Places__c" : 6.00},' +
                '"Shared_Solar_System__r" : {"Id": "a1J19000001MFvAEAW", "Number_of_Billed_Production_Periods__c" : 2, "Billing_Method__c" : "NMC"}, ' +
                '"Account" : {"Name" : "Account One", "Account_Number__c" : "BW-00001"},' +
                '"AccountId" : "0015400000SajzCAAA"}}}';
            String szsThree = '{"Id":"szsThree_ID","Customer_Subscription_kW_DC__c": 17.00,"Percent_Share__c" : 1.1758,' +
                '"System_Size_kW_DC__c" : 1445.86,' +
                '"Schedule_Z__c" : "a3z190000009UUvAAM",' +
                '"Schedule_Z__r" : {"Name" : "SZ_NYSEG", ' +
                '"Shared_Solar_System__r" : { "Utility__r" : {"UASB_Number_of_Decimals__c" : 0}}},' +
                '"Utility_Account_Subscription__r" : {"Name" : "UAS_Three", ' +
                '"Utility_Account_Log__r" : {"Name" : "777222", "Premise_Number__c" : "223232"},' +
                '"Opportunity__r" : {"Id":"0000000CCC","Name":"Oppty C",' +
                '"Product__r" : {"NMC_Discount__c" : 10.00 ,"NM_Rate_Floor__c" : 0.0,"Solar_Electricity_Rate__c" : 0.13,' +
                '"Pricing_Structure__c" : "Fixed % Discount","Percent_Share_Decimal_Places__c" : 6.00},' +
                '"Shared_Solar_System__r" : {"Id": "a1J19000001MFvAEAW", "Number_of_Billed_Production_Periods__c" : 2, "Billing_Method__c" : "NMC"}, ' +
                '"Account" : {"Name" : "Account One", "Account_Number__c" : "BW-00001"},' +
                '"AccountId" : "0015400000SajzCAAA"}}}';
            String szsFour = '{"Id":"szsFour_ID","Customer_Subscription_kW_DC__c": 17.00,"Percent_Share__c" : 1.1758,' +
                '"System_Size_kW_DC__c" : 1445.86,' +
                '"Schedule_Z__c" : "a3z190000009UUvAAM",' +
                '"Schedule_Z__r" : {"Name" : "SZ_NYSEG", ' +
                '"Shared_Solar_System__r" : { "Utility__r" : {"UASB_Number_of_Decimals__c" : 2, "Transfer_Mismatch_Tolerance__c":1.00}}},' +
                '"Utility_Account_Subscription__r" : {"Name" : "UAS_Four", ' +
                '"Utility_Account_Log__r" : {"Name" : " 00 12 34 56789"},' +
                '"Opportunity__r" : {"Id":"0000000DDD","Name":"Oppty D",' +
                '"Product__r" : {"NMC_Discount__c" : 10.00 ,"NM_Rate_Floor__c" : 0.0,"Solar_Electricity_Rate__c" : 0.13,' +
                '"Pricing_Structure__c" : "Use Solar Electric Rate","Percent_Share_Decimal_Places__c" : 6.00},' +
                '"Shared_Solar_System__r" : {"Id": "a1J19000001MFvAEAW", "Number_of_Billed_Production_Periods__c" : 2, "Billing_Method__c" : "kWh"}, ' +
                '"Account" : {"Name" : "Account One", "Account_Number__c" : "BW-00001"},' +
                '"AccountId" : "0015400000SajzCAAA"}}}';
            String szsFive = '{"Id":"szsFive_ID","Customer_Subscription_kW_DC__c": 7.00,"Percent_Share__c" : 0.4841,' +
                '"System_Size_kW_DC__c" : 1445.86,' +
                '"Schedule_Z__c" : "a3z190000009UUvAAM",' +
                '"Schedule_Z__r" : {"Name" : "SZ_NYSEG", ' +
                '"Shared_Solar_System__r" : { "Utility__r" : {"UASB_Number_of_Decimals__c" : 2, "Transfer_Mismatch_Tolerance__c":1.00}}},' +
                '"Utility_Account_Subscription__r" : {"Name" : "UAS_Five", ' +
                '"Utility_Account_Log__r" : {"Name" : "777888"},' +
                '"Opportunity__r" : {"Id":"0000000EEE","Name":"Oppty E",' +
                '"Product__r" : {"NMC_Discount__c" : 25.00 ,"NM_Rate_Floor__c" : 0.0,"Solar_Electricity_Rate__c" : 0.13,' +
                '"Pricing_Structure__c" : "Fixed % Discount","Percent_Share_Decimal_Places__c" : 6.00},' +
                '"Shared_Solar_System__r" : {"Id": "a1J19000001MFvAEAW", "Number_of_Billed_Production_Periods__c" : 2, "Billing_Method__c" : "NMC"}, ' +
                '"Account" : {"Name" : "Account One", "Account_Number__c" : "BW-00001"},' +
                '"AccountId" : "0015400000SajzCBBB"}}}';
            String szsSix = '{"Id":"szsSix_ID","Schedule_Z__c" : "a3z190000009UUvCCC",' +
                '"Utility_Account_Subscription__r" : {"Name" : "UAS_Six", ' +
                '"Utility_Account_Log__r" : {"Name" : "666333222"},' +
                '"Opportunity__r" : {"Id":"0000000FFF","Name":"Oppty F",' +
                '"Shared_Solar_System__r" : {"Id": "a1J19000001MFvAEAW", "Number_of_Billed_Production_Periods__c" : 2, "Billing_Method__c" : "NMC"}, ' +
                '"Account" : {"Name" : "Account One", "Account_Number__c" : "BW-00001"},' +
                '"AccountId" : "0015400000SajzCBBB"}}}';
            String onTimeSZS = '[' + szsOne + ',' + szsTwo + ',' + szsThree + ',' + szsFour + ',' + szsFive +  ']';
            String cancelledSZS = '[' + szsSix + ']';
            switch on methodCall.stubbedMethodName {
                when 'getOnTimeListForBillingOffTransfer' {
                    return (List<Schedule_Z_Subscription__c>) JSON.deserialize(onTimeSZS, List<Schedule_Z_Subscription__c>.class);
                }
                when 'getOverdueSZSForBillingOffTransfer' {
                    return (List<Schedule_Z_Subscription__c>) JSON.deserialize(cancelledSZS, List<Schedule_Z_Subscription__c>.class);
                }
            }
            return null;
        }
    }

    public class MockUCBSZSSelector extends MockProvider {
        public override Object handleMethodCall(MethodCall methodCall) {
            String szsOne = '{"Id":"szsOne_ID","Customer_Subscription_kW_DC__c": 26.00,"Percent_Share__c" : 1.7982,' +
                '"System_Size_kW_DC__c" : 1445.86,' +
                '"Schedule_Z__c" : "a3z190000009UUvAAM",' +
                '"Schedule_Z__r" : {"Name" : "SZ_NYSEG", ' +
                '"Shared_Solar_System__r" : { "Utility__r" : {"UASB_Number_of_Decimals__c" : 2, "Transfer_Mismatch_Tolerance__c":1.00}}},' +
                '"Utility_Account_Subscription__r" : {"Name" : "UAS_One", ' +
                '"Utility_Account_Log__r" : {"Name" : "001519510481"},' +
                '"Opportunity__r" : {"Id":"0000000AAA","Name":"Oppty A",' +
                '"Product__r" : {"NMC_Discount__c" : 12.00 ,"NM_Rate_Floor__c" : 0.0,"Solar_Electricity_Rate__c" : 0.13,' +
                '"Pricing_Structure__c" : "Use Solar Electric Rate","Percent_Share_Decimal_Places__c" : 6.00},' +
                '"Shared_Solar_System__r" : {"Id": "a1J19000001MFvAEAW", "Number_of_Billed_Production_Periods__c" : 2, "Billing_Method__c" : "kWh"}, ' +
                '"Account" : {"Name" : "Account One", "Account_Number__c" : "BW-00001"},' +
                '"AccountId" : "0015400000SajzCAAA"}}}';
            String szsTwo = '{"Id":"szsTwo_ID","Customer_Subscription_kW_DC__c": 12.00,"Percent_Share__c" : 0.8300,' +
                '"System_Size_kW_DC__c" : 1445.86,' +
                '"Schedule_Z__c" : "a3z190000009UUvAAM",' +
                '"Schedule_Z__r" : {"Name" : "SZ_NYSEG", ' +
                '"Shared_Solar_System__r" : { "Utility__r" : {"UASB_Number_of_Decimals__c" : 2, "Transfer_Mismatch_Tolerance__c":1.00}}},' +
                '"Utility_Account_Subscription__r" : {"Name" : "UAS_Two", ' +
                '"Utility_Account_Log__r" : {"Name" : "001519510482"},' +
                '"Opportunity__r" : {"Id":"0000000BBB","Name":"Oppty B", "Product_Escalation_Schedule__c" : "a6o19000000CsuGAAS",' +
                '"Product__r" : {"NMC_Discount__c" : 10.00 ,"NM_Rate_Floor__c" : 0.0,"Solar_Electricity_Rate__c" : 0.13,' +
                '"Pricing_Structure__c" : "Fixed % Discount","Percent_Share_Decimal_Places__c" : 6.00},' +
                '"Shared_Solar_System__r" : {"Id": "a1J19000001MFvAEAW", "Number_of_Billed_Production_Periods__c" : 2, "Billing_Method__c" : "NMC"}, ' +
                '"Account" : {"Name" : "Account One", "Account_Number__c" : "BW-00001"},' +
                '"AccountId" : "0015400000SajzCAAA"}}}';
            String ucbSzsList = '[' + szsOne + ',' + szsTwo + ']';
            switch on methodCall.stubbedMethodName {
                when 'getOnTimeListForBillingOffTransfer' {
                    return (List<Schedule_Z_Subscription__c>) JSON.deserialize(ucbSzsList, List<Schedule_Z_Subscription__c>.class);
                }
            }
            return null;
        }
    }

    public class MockPESelector extends MockProvider {
        public override Object handleMethodCall(MethodCall methodCall) {
            Map<Id, List<Product_Escalator__c>> escalatorMap = new Map<Id, List<Product_Escalator__c>>();
            Product_Escalator__c firstPeriod = new Product_Escalator__c (
                Product_Escalation_Schedule__c = 'a6o19000000CsuGAAS',
                Starting_Credit_Transfer__c = 5,
                New_Solar_Electricity_Rate__c = 0.15
            );
            Product_Escalator__c secondPeriod = new Product_Escalator__c (
                Product_Escalation_Schedule__c = 'a6o19000000CsuGAAS',
                Starting_Credit_Transfer__c = 2,
                New_Solar_Electricity_Rate__c = 0.18
            );
            Product_Escalator__c thirdPeriod = new Product_Escalator__c (
                Product_Escalation_Schedule__c = 'a6o19000000CsuGAAS',
                Starting_Credit_Transfer__c = 0,
                New_Solar_Electricity_Rate__c = 0.13
            );

            Product_Escalator__c schedTwo = new Product_Escalator__c (
                Product_Escalation_Schedule__c = 'a6o19000000CsuGBBS',
                Starting_Credit_Transfer__c = 0,
                New_Solar_Electricity_Rate__c = 0.23
            );

            escalatorMap.put('a6o19000000CsuGAAS', new List<Product_Escalator__c>{firstPeriod, secondPeriod, thirdPeriod});
            escalatorMap.put('a6o19000000CsuGBBS', new List<Product_Escalator__c>{schedTwo});

            switch on methodCall.stubbedMethodName {
                when 'getProductEscalations' {
                    return escalatorMap;
                }
            }
            return null;
        }
    }

    public class MockAccountSelector extends MockProvider {
        public override Object handleMethodCall(MethodCall methodCall) {
            Map<Id,Account> accountMap = new Map<Id,Account>();
            Date todayDate = System.today();
            Account accountOne = new Account(
                Id = '0015400000SajzCAAA',
                Last_Bill_Send_Date_New_Charges_Zuora__c = todayDate.addDays(-30),
                Total_Outstanding_Balance_Zuora__c = 100
            );
            Account accountTwo = new Account(
                Id = '0015400000SajzCBBB',
                Last_Bill_Send_Date_New_Charges_Zuora__c = null,
                Total_Outstanding_Balance_Zuora__c = 0
            );
            accountMap.put(accountOne.Id,accountOne);
            accountMap.put(accountTwo.Id,accountTwo);

            switch on methodCall.stubbedMethodName {
                when 'selectById' {
                    return accountMap;
                }
            }
            return null;
        }
    }

    public class MockTransferSelector extends MockProvider {
        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'getUnbilledTransfersBySSS' {
                    String unbilledTransfers = '[{"Id":"a900v0000000KjjAAE",' +
                        '"Name":"Main Transfer - Project A","Shared_Solar_System__c":"a1J0v000000t6CcEAI",' +
                        '"Allocation_Schedule__c":"a3z0v000000EFs4AAG","Attempted_Transfer__c":12033.730,' +
                        '"Bill_Period__c":"a8x0v0000000ONdAAM","Default_Credit_Value__c":0.18480000,' +
                        '"Bills_Generated__c":false,"Attempted_kWh_Transfer__c":81869.0000,' +
                        '"Total_Transferred__c":12033.73,"Transfer_Amount__c":12033.73,' +
                        '"Transfer_Type__c":"Main","Date_of_Transfer__c":"2020-02-06",' +
                        '"Bill_Period__r":{"Id":"a8x0v0000000ONdAAM","Bill_Date__c":"2020-02-12","Name":"Feb Period"},' +
                        '"Allocation_Schedule__r":{"Id":"a3z0v000000EFs4AAG","Name":"2016 - sssA"}}]';
                    return (List<Transfer__c>) JSON.deserialize(unbilledTransfers, List<Transfer__c>.class);
                }
            }
            return null;
        }
    }

    public class MockUCBTransferSelector extends MockProvider {
        public override Object handleMethodCall(MethodCall methodCall) {
            String ucbTransferRecord = '{' +
                '  "Id": "a90050000004CZgAAM",' +
                '  "Name":"Main Transfer - Project A",' +
                '  "Allocation_Schedule__c":"a3z190000009UUvAAM",' +
                '  "Attempted_Transfer__c":12033.730,' +
                '  "Bill_Period__c":"a8x0v0000000ONdAAM",' +
                '  "Default_Credit_Value__c":0.18480000,' +
                '  "Bills_Generated__c": false,' +
                '  "Attempted_kWh_Transfer__c":81869.0000,' +
                '  "Total_Transferred__c":12033.73,' +
                '  "Transfer_Amount__c":12033.73,' +
                '  "Transfer_Type__c":"Main",' +
                '  "Date_of_Transfer__c":"2020-02-06",' +
                '  "Bill_Period__r":{' +
                '       "Id":"a8x0v0000000ONdAAM",' +
                '       "Bill_Date__c":"2020-02-12",' +
                '       "Name":"Feb Period"' +
                '   },' +
                '  "Allocation_Schedule__r":{' +
                '       "Id":"a3z0v000000EFs4AAG",' +
                '       "Name":"2016 - sssA"' +
                '   },' +
                '  "Shared_Solar_System__r": {' +
                '       "UCB__c": true' + // UCB flag
                '   },' +
                '  "Shared_Solar_System__c": "a1J0v000000t6CcEAI",' +
                '  "Bills_Generated__c": false' +
            '}';
            switch on methodCall.stubbedMethodName {
                when 'getTransferById' {
                    return (Transfer__c) JSON.deserialize(ucbTransferRecord,Transfer__c.class);
                }
                when 'getUnbilledTransfersBySSS' {
                    return new List<Transfer__c>();
                }
            }
            return null;
        }
    }

    public class MockUCBContentDocumentSelector extends MockProvider {
        public String transferSheetCsvHeaders = String.join(new List<String>(TransferSheetService.UCB_UASB_FIELDS.keySet()),',');
        public Integer ucbColCount = TransferSheetService.UCB_UASB_FIELDS.size();
        public List<String> csvRow1 = new List<String>{
            '001519510481', // Utility Account Number
            '1117.09', // Credits
            '14194.4', // Production
            '0.078599', // CreditValue
            '0.0', // StartingBankedCredits
            '0.0', // NewAvailableCredits
            '0.0', // TotalAvailableCredits
            '65.00', // SateliteCharges
            '0.0', // CalculatedCredits
            '0.0', // NetMemberCredits
            '0.0', // EndingBankedCredits
            '0.0', // CDGSubscriptionFee
            '0.0', // UtilityAdminFee
            '0.0', // CDGSponsorPayment
            '2021-03-09' // Satellite Bill Date
        };
        public List<String> csvRow2 = new List<String>{
            '001519510482', // Utility Account Number
            '1117.09', // Credits
            '14194.4', // Production
            '0.078599', // CreditValue
            '0.0', // StartingBankedCredits
            '0.0', // NewAvailableCredits
            '0.0', // TotalAvailableCredits
            '75.00', // SateliteCharges
            '0.0', // CalculatedCredits
            '0.0', // NetMemberCredits
            '0.0', // EndingBankedCredits
            '0.0', // CDGSubscriptionFee
            '0.0', // UtilityAdminFee
            '0.0', // CDGSponsorPayment
            '2021-03-09' // Satellite Bill Date
        };
        public String transferCsv =
            transferSheetCsvHeaders + '\n' + String.join(csvRow1,',') + '\n' + String.join(csvRow2,',') + '\n';

        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'getMostRecentTransferSheet' {
                    System.assertEquals(ucbColCount, csvRow1.size(), 'csvRow1 contains incorrect number of data columns');
                    System.assertEquals(ucbColCount, csvRow2.size(), 'csvRow2 contains incorrect number of data columns');
                    ContentVersion contentVersion = new ContentVersion(
                        Title = 'Test',
                        PathOnClient = 'TransferTest.csv',
                        VersionData = Blob.valueOf(transferCsv),
                        IsMajorVersion = true
                    );
                    insert contentVersion;
                    ContentDocument document = [
                        SELECT Id, LatestPublishedVersion.Title, LatestPublishedVersion.VersionData, ContentSize
                        FROM ContentDocument LIMIT 1
                    ];
                    return document;
                }
            }
            return null;
        }
    }
    
    private static String mockGetApexDataFromLWC() {
        String apexData = '[';
        apexData += '{"Overdue":false,' +
            '"SfUASB":{"Customer_Subscription_KW_DC__c":15,"Date__c":"2020-01-06",' +
            '"Transfer__c":"a9054000000Cm7oAAC","Utility_Account_Subscription__c":"a1d54000000x4KuAAI",' +
            '"PreGen_Utility_Acct__c":"00002344","PreGen_Name_on_Account__c":"Albert Price",' +
            '"Account__c":"0015400000Sajz6AAB","Opportunity__c":"0065400000BG7CsAAL",' +
            '"Shared_Solar_System__c":"a1J54000000lUe3EAE","Billing_Period_Start_Date__c":"2020-02-06",' +
            '"Billing_Period_End_Date__c":"2020-03-06","Externally_Serviced__c":false,"NMC_Discount__c":10,' +
            '"Total_System_Size_kW_DC__c":1445.86,"NM_Rate_Floor__c":0,"NMC_Rate__c":0.1848,"Share_of_System__c":1.04,' +
            '"Credits_Allocated__c":125.15,"Total_System_NMCs__c":12033.73,"Total_System_Production_kWh__c":81869,' +
            '"Subscription_Production_kWh_Static__c":851.44,"Schedule_Z_Subscription__c":"a54540000001oN7AAI","Size_off_NMCs__c":true},' +
            '"Status":"MATCH",' +
            '"UtilUASB":{' +
            '"PreGen_Utility_Acct__c":"00002344",' +
            '"Credits_Allocated__c":125.15,' +
            '"Subscription_Production_kWh_Static__c":0,"NMC_Rate__c":0.1848}},';
        apexData += '{"SfUASB":{},' +
            '"Status":"MISSING_BILL",' +
            '"UtilUASB":{"PreGen_Utility_Acct__c":"000033344",' +
            '"Credits_Allocated__c":100,"Subscription_Production_kWh_Static__c":0,"NMC_Rate__c":0.1453}},';
        apexData += '{"Overdue":false,' +
            '"SfUASB":{"Customer_Subscription_KW_DC__c":19,"Date__c":"2020-01-06",' +
            '"Transfer__c":"a9054000000Cm7oAAC","Utility_Account_Subscription__c":"a1d54000000x4KrAAI",' +
            '"PreGen_Utility_Acct__c":"00002341","PreGen_Name_on_Account__c":"Donna Simmons",' +
            '"Account__c":"0015400000Sajz3AAB","Opportunity__c":"0065400000BG7CpAAL",' +
            '"Shared_Solar_System__c":"a1J54000000lUe3EAE","Billing_Period_Start_Date__c":"2020-02-06",' +
            '"Billing_Period_End_Date__c":"2020-03-06","Externally_Serviced__c":false,"NMC_Discount__c":10,' +
            '"Total_System_Size_kW_DC__c":1445.86,"NM_Rate_Floor__c":0,"NMC_Rate__c":0.1848,"Share_of_System__c":1.31,' +
            '"Credits_Allocated__c":157.64,"Total_System_NMCs__c":12033.73,"Total_System_Production_kWh__c":81869,' +
            '"Subscription_Production_kWh_Static__c":1072.48,"Schedule_Z_Subscription__c":"a54540000001oN4AAI","Size_off_NMCs__c":true},' +
            '"Status":"MISSING_TRANSFER",' +
            '"UtilUASB":{}},';
        apexData += '{"MatchMessage":"Credits Allocated Mismatch",' +
            '"Overdue":false,' +
            '"SfUASB":{"Customer_Subscription_KW_DC__c":18,"Date__c":"2020-01-06",' +
            '"Transfer__c":"a9054000000Cm7oAAC","Utility_Account_Subscription__c":"a1d54000000x4KpAAI",' +
            '"PreGen_Utility_Acct__c":"0000234","PreGen_Name_on_Account__c":"Joshua Phillips",' +
            '"Account__c":"0015400000Sajz1AAB","Opportunity__c":"0065400000BG7CnAAL",' +
            '"Shared_Solar_System__c":"a1J54000000lUe3EAE","Billing_Period_Start_Date__c":"2020-02-06",' +
            '"Billing_Period_End_Date__c":"2020-03-06","Externally_Serviced__c":false,"NMC_Discount__c":10,' +
            '"Total_System_Size_kW_DC__c":1445.86,"NM_Rate_Floor__c":0,"NMC_Rate__c":0.1848,"Share_of_System__c":1.24,' +
            '"Credits_Allocated__c":149.22,"Total_System_NMCs__c":12033.73,"Total_System_Production_kWh__c":81869,' +
            '"Subscription_Production_kWh_Static__c":1015.18,"Schedule_Z_Subscription__c":"a54540000001oN2AAI","Size_off_NMCs__c":true},' +
            '"Status":"CREDIT_MISMATCH",' +
            '"UtilUASB":{' +
                '"PreGen_Utility_Acct__c":"0000234",' +
                '"Credits_Allocated__c":251.33,' +
                '"Subscription_Production_kWh_Static__c":null,' +
                '"NMC_Rate__c":0.1848}' +
            '}';
        apexData += ']';
        return apexData;
    }

    private static List<String> mockGetResolutionDataFromLWC() {
        String lineOne = '{"Uniqueid":"a54540000001oN7AAI","customername":"Albert Price","trcreditvalue":0.1848,' +
            '"isMatch":true,"Resolution":"UseSalesforce"}';
        String lineTwo = '{"Uniqueid":"a54540000001oN4AAI","customername":"Joe Smo","trcreditvalue":0.1848,' +
            '"isMatch":true,"Resolution":"UseUtility"}';
        String lineThree = '{"Uniqueid":"a54540000001oN2AAI","customername":"Stacy Shaw","trcreditvalue":0.1848,' +
            '"isMatch":true,"Resolution":"UseUtility"}';
        String lineFour = '{"Uniqueid":"missingBill04","trcreditvalue":0.1848,' +
            '"isMatch":true,"Resolution":"UseSalesforce"}';
        return new List<String>{lineOne, lineTwo, lineThree, lineFour};
    }

    private static Transfer__c mockTransferServiceInitObjectNonUCB() {
        String jsonString = '{"id":"a54540000001oN7AAI","Shared_Solar_System__r":{"UCB__c":"false"}}';
        return (Transfer__c) JSON.deserialize(jsonString, Transfer__c.class);
    }
}