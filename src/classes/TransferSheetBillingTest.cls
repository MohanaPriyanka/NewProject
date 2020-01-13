// JP 1/10/20 : Rename this "BillGenerationServiceTest" after migration away from SB / AB and delete existing

@isTest
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

    @isTest
    public static void testGetScheduleZSubscriptionMock() {
        useMocks();
        Transfer__c transfer = getTestTransfer();
        BillGenerationService billGenService = new BillGenerationService();

        // (Mocked) 6 Allocation Schedule Subscriptions to Generate Bills For:
        List<Schedule_Z_Subscription__c> szsList = billGenService.getScheduleZSubscriptionList(transfer);
        System.assertEquals(6,szsList.size());

        // Should match Percent_Share__c on SZS in Mock:
        System.assertEquals(1.7982,szsList[0].Percent_Share__c);
        System.assertEquals(0.8300,szsList[1].Percent_Share__c);
        System.assertEquals(1.1758,szsList[2].Percent_Share__c);
        System.assertEquals(1.1758,szsList[3].Percent_Share__c);
        System.assertEquals(0.4841,szsList[4].Percent_Share__c);
    }

    @isTest
    public static void testUASBsWithDifferentProducts() {
        useMocks();
        Transfer__c transfer = getTestTransfer();
        List<UASB__c> uasbs = BillGenerationService.calculateUASBsFromTransfer(transfer);

        System.assertEquals(6,uasbs.size());

        // Discounts are set by Product linked to a SZS:
        System.assertEquals(12,uasbs[0].NMC_Discount__c);
        System.assertEquals(25,uasbs[4].NMC_Discount__c);

        // Even though 2 SZS have the same size, because they are either using the NMC or kWH
        // billing method, they have different credits allocated:
        System.assert(uasbs[2].Size_off_NMCs__c);
        System.assertEquals(1.1758,uasbs[2].Share_of_System__c);
        System.assertEquals(859.18,uasbs[2].Subscription_Production_kWh_Static__c);
        System.assertEquals(141.49,uasbs[2].Credits_Allocated__c);

        System.assert(!uasbs[3].Size_off_NMCs__c);
        System.assertEquals(1.1758,uasbs[3].Share_of_System__c);
        System.assertEquals(859.18,uasbs[3].Subscription_Production_kWh_Static__c);
        System.assertEquals(158.77,uasbs[3].Credits_Allocated__c);
    }

    @isTest
    public static void testProductEscalactors() {
        useMocks();
        Transfer__c transfer = getTestTransfer();
        BillGenerationService billGenService = new BillGenerationService();
        List<Schedule_Z_Subscription__c> szsList = billGenService.getScheduleZSubscriptionList(transfer);
        System.assertEquals('a6o19000000CsuGAAS',szsList[1].Utility_Account_Subscription__r.Opportunity__r.Product_Escalation_Schedule__c);

        // For different periods, use different solar electric rates:
        Product_Escalator__c escOne = billGenService.getProductEscalator(szsList[1], 0);
        Product_Escalator__c escTwo = billGenService.getProductEscalator(szsList[1], 2);
        Product_Escalator__c escThree = billGenService.getProductEscalator(szsList[1], 4);

        System.assertEquals(0.13,escOne.New_Solar_Electricity_Rate__c);
        System.assertEquals(0.18,escTwo.New_Solar_Electricity_Rate__c);
        System.assertEquals(0.18,escThree.New_Solar_Electricity_Rate__c);

        // Mock sets count of transfer = 2, so should use 0.18 rate
        System.assertEquals(2,szsList[1].Utility_Account_Subscription__r.Opportunity__r.Shared_Solar_System__r.Count_of_Transfers__c);
        List<UASB__c> uasbs = BillGenerationService.calculateUASBsFromTransfer(transfer);
        System.assertEquals(0.18,uasbs[1].Solar_Electricity_Rate__c);
    }

    @isTest
    public static void testDifferentTransferAmount(){
        useMocks();
        Transfer__c transfer = getTestTransfer();
        transfer.Attempted_Transfer__c =  120000.25;
        transfer.Attempted_kWh_Transfer__c = 50000.00;

        List<UASB__c> firstBillGroup = BillGenerationService.calculateUASBsFromTransfer(transfer);

        System.assertEquals(242.05,firstBillGroup[4].Subscription_Production_kWh_Static__c);
        System.assertEquals(580.92,firstBillGroup[4].Credits_Allocated__c);

        // Credit value is doubled, kWH is the same:
        transfer.Attempted_Transfer__c =  240000.50;
        transfer.Attempted_kWh_Transfer__c = 50000.00;

        List<UASB__c> secondBillGroup = BillGenerationService.calculateUASBsFromTransfer(transfer);

        System.assertEquals(242.05,secondBillGroup[4].Subscription_Production_kWh_Static__c);
        System.assertEquals(1161.84,secondBillGroup[4].Credits_Allocated__c);
    }

    @isTest
    public static void testCancelledCustomer(){
        useMocks();
        Transfer__c transfer = getTestTransfer();
        List<UASB__c> uasbs = BillGenerationService.calculateUASBsFromTransfer(transfer);

        // Normal Bills:
        System.assertEquals(859.18,uasbs[2].Subscription_Production_kWh_Static__c);
        System.assertEquals(141.49,uasbs[2].Credits_Allocated__c);
        System.assertEquals(859.18,uasbs[3].Subscription_Production_kWh_Static__c);
        System.assertEquals(158.77,uasbs[3].Credits_Allocated__c);

        // Cancelled:
        System.assertEquals(0,uasbs[5].Subscription_Production_kWh_Static__c);
        System.assertEquals(0,uasbs[5].Credits_Allocated__c);
    }

    private static void useMocks() {
        BillGenerationService.szsSelector = (ScheduleZSubscriptionSelector) Test.createStub(ScheduleZSubscriptionSelector.class, new MockSZSSelector());
        BillGenerationService.escalatorSelector = (ProductEscalatorSelector) Test.createStub(ProductEscalatorSelector.class, new MockPESelector());
    }

    public class MockSZSSelector extends MockProvider {
        public MockSZSSelector() {
        }

        public override Object handleMethodCall(MethodCall methodCall) {
            String szsOne = '{"Id":"szsOne_ID","Customer_Subscription_kW_DC__c": 26.00,"Percent_Share__c" : 1.7982,' +
                '"System_Size_kW_DC__c" : 1445.86,"Schedule_Z__c" : "a3z190000009UUvAAM",' +
                '"Utility_Account_Subscription__r" : {"Name" : "UAS_One", ' +
                '"Opportunity__r" : {"Id":"0000000AAA","Name":"Oppty A",' +
                '"Product__r" : {"NMC_Discount__c" : 12.00 ,"NM_Rate_Floor__c" : 0.0,"Solar_Electricity_Rate__c" : 0.13,' +
                '"Pricing_Structure__c" : "Use Solar Electric Rate","Percent_Share_Decimal_Places__c" : 6.00},' +
                '"Shared_Solar_System__r" : {"Id": "a1J19000001MFvAEAW", "Count_of_Transfers__c" : 2, "Billing_Method__c" : "kWh"}, ' +
                '"Account" : {"Name" : "Account One", "Account_Number__c" : "BW-00001"}}}}';
            String szsTwo = '{"Id":"szsTwo_ID","Customer_Subscription_kW_DC__c": 12.00,"Percent_Share__c" : 0.8300,' +
                '"System_Size_kW_DC__c" : 1445.86,"Schedule_Z__c" : "a3z190000009UUvAAM",' +
                '"Utility_Account_Subscription__r" : {"Name" : "UAS_Two", ' +
                '"Opportunity__r" : {"Id":"0000000BBB","Name":"Oppty B", "Product_Escalation_Schedule__c" : "a6o19000000CsuGAAS",' +
                '"Product__r" : {"NMC_Discount__c" : 10.00 ,"NM_Rate_Floor__c" : 0.0,"Solar_Electricity_Rate__c" : 0.13,' +
                '"Pricing_Structure__c" : "Fixed % Discount","Percent_Share_Decimal_Places__c" : 6.00},' +
                '"Shared_Solar_System__r" : {"Id": "a1J19000001MFvAEAW", "Count_of_Transfers__c" : 2, "Billing_Method__c" : "NMC"}, ' +
                '"Account" : {"Name" : "Account One", "Account_Number__c" : "BW-00001"}}}}';
            String szsThree = '{"Id":"szsThree_ID","Customer_Subscription_kW_DC__c": 17.00,"Percent_Share__c" : 1.1758,' +
                '"System_Size_kW_DC__c" : 1445.86,"Schedule_Z__c" : "a3z190000009UUvAAM",' +
                '"Utility_Account_Subscription__r" : {"Name" : "UAS_Three", ' +
                '"Opportunity__r" : {"Id":"0000000CCC","Name":"Oppty C",' +
                '"Product__r" : {"NMC_Discount__c" : 10.00 ,"NM_Rate_Floor__c" : 0.0,"Solar_Electricity_Rate__c" : 0.13,' +
                '"Pricing_Structure__c" : "Fixed % Discount","Percent_Share_Decimal_Places__c" : 6.00},' +
                '"Shared_Solar_System__r" : {"Id": "a1J19000001MFvAEAW", "Count_of_Transfers__c" : 2, "Billing_Method__c" : "NMC"}, ' +
                '"Account" : {"Name" : "Account One", "Account_Number__c" : "BW-00001"}}}}';
            String szsFour = '{"Id":"szsFour_ID","Customer_Subscription_kW_DC__c": 17.00,"Percent_Share__c" : 1.1758,' +
                '"System_Size_kW_DC__c" : 1445.86,"Schedule_Z__c" : "a3z190000009UUvAAM",' +
                '"Utility_Account_Subscription__r" : {"Name" : "UAS_Four", ' +
                '"Opportunity__r" : {"Id":"0000000DDD","Name":"Oppty D",' +
                '"Product__r" : {"NMC_Discount__c" : 10.00 ,"NM_Rate_Floor__c" : 0.0,"Solar_Electricity_Rate__c" : 0.13,' +
                '"Pricing_Structure__c" : "Use Solar Electric Rate","Percent_Share_Decimal_Places__c" : 6.00},' +
                '"Shared_Solar_System__r" : {"Id": "a1J19000001MFvAEAW", "Count_of_Transfers__c" : 2, "Billing_Method__c" : "kWh"}, ' +
                '"Account" : {"Name" : "Account One", "Account_Number__c" : "BW-00001"}}}}';
            String szsFive = '{"Id":"szsFive_ID","Customer_Subscription_kW_DC__c": 7.00,"Percent_Share__c" : 0.4841,' +
                '"System_Size_kW_DC__c" : 1445.86,"Schedule_Z__c" : "a3z190000009UUvAAM",' +
                '"Utility_Account_Subscription__r" : {"Name" : "UAS_Five", ' +
                '"Opportunity__r" : {"Id":"0000000EEE","Name":"Oppty E",' +
                '"Product__r" : {"NMC_Discount__c" : 25.00 ,"NM_Rate_Floor__c" : 0.0,"Solar_Electricity_Rate__c" : 0.13,' +
                '"Pricing_Structure__c" : "Fixed % Discount","Percent_Share_Decimal_Places__c" : 6.00},' +
                '"Shared_Solar_System__r" : {"Id": "a1J19000001MFvAEAW", "Count_of_Transfers__c" : 2, "Billing_Method__c" : "NMC"}, ' +
                '"Account" : {"Name" : "Account One", "Account_Number__c" : "BW-00001"}}}}';
            String szsSix = '{"Id":"szsSix_ID","Schedule_Z__c" : "a3z190000009UUvCCC",' +
                '"Utility_Account_Subscription__r" : {"Name" : "UAS_Six", ' +
                '"Opportunity__r" : {"Id":"0000000FFF","Name":"Oppty F",' +
                '"Shared_Solar_System__r" : {"Id": "a1J19000001MFvAEAW", "Count_of_Transfers__c" : 2, "Billing_Method__c" : "NMC"}}}}';
            String onTimeSZS = '[' + szsOne + ',' + szsTwo + ',' + szsThree + ',' + szsFour + ',' + szsFive + ']';
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

    public class MockPESelector extends MockProvider {
        public MockPESelector() {
        }

        public override Object handleMethodCall(MethodCall methodCall) {
            Map<Id, List<Product_Escalator__c>> escalatorMap = new Map<Id, List<Product_Escalator__c>>();

            Product_Escalation_Schedule__c escalatorSchedule = new Product_Escalation_Schedule__c (
                Id = 'a6o19000000CsuGAAS',
                Name = 'Product Escalator'
            );
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

            Product_Escalation_Schedule__c escalatorScheduleTwo = new Product_Escalation_Schedule__c (
                Id = 'a6o19000000CsuGBBS',
                Name = 'Product Escalator'
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
}