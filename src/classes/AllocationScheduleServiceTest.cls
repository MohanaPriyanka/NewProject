@IsTest
public with sharing class AllocationScheduleServiceTest {
    @IsTest
    public static void testPopulateALSOnTransfer() {
        AllocationScheduleService service = new AllocationScheduleService();
        useMocks();

        List<Transfer__c> transfers = getTransfersWithoutALSes();
        System.assertEquals(null,transfers[0].Allocation_Schedule__c);
        System.assertEquals(null,transfers[1].Allocation_Schedule__c);
        System.assertEquals(null,transfers[2].Allocation_Schedule__c);
        transfers[0].Date_of_Transfer__c = Date.newInstance(2019,10,30);
        transfers[1].Date_of_Transfer__c = Date.newInstance(2019,10,10);
        transfers[2].Date_of_Transfer__c = Date.newInstance(2019,09,30);

        service.populateAllocationScheduleOnTransfer(transfers);

        System.assertEquals('a3z0a0000008hO1BBB',transfers[0].Allocation_Schedule__c);
        System.assertEquals('a3z0a0000008hO1AAA',transfers[1].Allocation_Schedule__c);
        System.assertEquals('a3z0a0000008hO1DDD',transfers[2].Allocation_Schedule__c);

        for (Transfer__c transfer : transfers){
            transfer.Date_of_Transfer__c = Date.newInstance(2019,12,30);
            transfer.Allocation_Schedule__c = null;
        }

        service.populateAllocationScheduleOnTransfer(transfers);

        System.assertEquals('a3z0a0000008hO1CCC',transfers[0].Allocation_Schedule__c);
        System.assertEquals('a3z0a0000008hO1CCC',transfers[1].Allocation_Schedule__c);
        System.assertEquals('a3z0a0000008hO1FFF',transfers[2].Allocation_Schedule__c);
    }

    @IsTest
    public static void testUpdateALSStatuses() {
        AllocationScheduleService service = new AllocationScheduleService();
        useMocks();
        List<Transfer__c> transfers = getTransfersWithALSes();

        // SSS1 has two billing transfers, with enacted dates in Oct and Nov, so at the end Nov allocation
        // schedule should be 'Billing' and Oct should be 'Replaced'. SSS2 has 1 transfer, with enacted date in Sept
        // so the only one that should be modified is the Sept schedule to change to 'Billing'.

        System.assertEquals(Date.newInstance(2019,10,15),transfers[0].Allocation_Schedule__r.Date_Enacted_by_Utility__c);
        System.assertEquals(Date.newInstance(2019,11,15),transfers[1].Allocation_Schedule__r.Date_Enacted_by_Utility__c);
        System.assertEquals(Date.newInstance(2019,9,15),transfers[2].Allocation_Schedule__r.Date_Enacted_by_Utility__c);
        System.assertEquals('Enacted By Utility',transfers[0].Allocation_Schedule__r.Status__c);
        System.assertEquals('Enacted By Utility',transfers[1].Allocation_Schedule__r.Status__c);
        System.assertEquals('Enacted By Utility',transfers[2].Allocation_Schedule__r.Status__c);

        List<Schedule_Z__c> schedulesToUpdate = service.updateALSStatuses(transfers);
        System.assertEquals(4, schedulesToUpdate.size());
        for (Schedule_Z__c schedule : schedulesToUpdate){
            if (schedule.Name == 'November SSS1' || schedule.Name == 'September SSS2'){
                System.assertEquals('Billing',schedule.Status__c);
            } else if (schedule.Name == 'September SSS1' || schedule.Name == 'October SSS1') {
                System.assertEquals('Replaced',schedule.Status__c);
            } else {
                // Should be caught above
                System.assert(false);
            }
        }
    }

    @IsTest
    public static void testTriggers(){
        Utility__c eversource = new Utility__c(
            Name = 'Eversource',
            Number_of_Decimal_Places__c = 2
        );

        insert eversource;

        Shared_Solar_System__c sss1 = new Shared_Solar_System__c(Name = 'Oxford Barrett St. P1',
            Service_Territory__c = 'SEMA',
            Service_Territories__c = 'SEMA',
            Open__c = true,
            Billing_Method__c = 'NMC',
            Reserved_Capacity_kW_DC__c = '10',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 1445.86,
            Total_System_Size_kW_AC__c = 1000,
            Utility__c = eversource.Id,
            Credit_Score_Requirement__c = 300,
            Assignment_Order__c = '1',
            Expected_Yield_kWh_kW__c = 1300,
            Assemblage_Count__c = 1,
            Sales_Partners__c = 'All',
            Maximum_Subscription_Capacity_kWDC__c = 25);
        insert sss1;

        Schedule_Z__c scheduleZ1 = new Schedule_Z__c(
            Name = '18-0515 Oxford Barrett St. P1',
            Shared_Solar_System__c = sss1.Id,
            Date_Enacted_by_Utility__c = Date.newInstance(2018,1,1),
            Status__c = 'Enacted By Utility'
        );
        insert scheduleZ1;

        Transfer__c transfer1 = new Transfer__c(
            Name = 'Main May Transfer',
            Allocation_Schedule__c = scheduleZ1.Id,
            Transfer_Type__c = 'Main',
            Bills_Generated__c = false,
            Shared_Solar_System__c = sss1.Id,
            Attempted_Transfer__c = 9950,
            Attempted_kWh_Transfer__c = 19000,
            Transfer_Amount__c = 9950,
            Date_of_Transfer__c = Date.newInstance(2019, 6, 4)
        );
        insert transfer1;

        transfer1.Bills_Generated__c = true;

        Test.startTest();
            update transfer1;
        Test.stopTest();

        Schedule_Z__c updatedSZ = [
            SELECT Status__c
            FROM Schedule_Z__c
            WHERE Id = : scheduleZ1.Id
            LIMIT 1
        ];
        System.assertEquals('Billing',updatedSZ.Status__c);
    }

    private static List<Transfer__c> getTransfersWithoutALSes() {
        Transfer__c transferOne = new Transfer__c(
            Id = 'a900a000000GqqvAAA',
            Name = 'Transfer One - SSS 1',
            Shared_Solar_System__c = 'a1Jj0000001H2ftEAC',
            Attempted_Transfer__c = 13483.660,
            Default_Credit_Value__c = 0.18480,
            Bills_Generated__c = false,
            Attempted_kWh_Transfer__c = 81869.0000,
            Total_Transferred__c = 13483.66,
            Transfer_Amount__c = 13483.66,
            Transfer_Type__c = 'Main',
            Date_of_Transfer__c = Date.newInstance(2019,1,1)
        );
        Transfer__c transferTwo = new Transfer__c(
            Id = 'a900a000000GqqvAAB',
            Name = 'Transfer Two - SSS 1',
            Shared_Solar_System__c = 'a1Jj0000001H2ftEAC',
            Attempted_Transfer__c = 13483.660,
            Default_Credit_Value__c = 0.18480,
            Bills_Generated__c = false,
            Attempted_kWh_Transfer__c = 81869.0000,
            Total_Transferred__c = 13483.66,
            Transfer_Amount__c = 13483.66,
            Transfer_Type__c = 'Main',
            Date_of_Transfer__c = Date.newInstance(2019,1,1)
        );
        Transfer__c transferThree = new Transfer__c(
            Id = 'a900a000000GqqvAAC',
            Name = 'Transfer One - SSS 2',
            Shared_Solar_System__c = 'a1Jj0000001H2ftEDD',
            Attempted_Transfer__c = 13483.660,
            Default_Credit_Value__c = 0.18480,
            Bills_Generated__c = false,
            Attempted_kWh_Transfer__c = 81869.0000,
            Total_Transferred__c = 13483.66,
            Transfer_Amount__c = 13483.66,
            Transfer_Type__c = 'Main',
            Date_of_Transfer__c = Date.newInstance(2019,1,1)
        );
        return new List<Transfer__c>{transferOne, transferTwo, transferThree};
    }

    private static Map<Id,List<Schedule_Z__c>> getALSes() {
        Map<Id,List<Schedule_Z__c>> sssToALSMap = new Map<Id,List<Schedule_Z__c>>();

        Schedule_Z__c alsOne = new Schedule_Z__c(
            Id = 'a3z0a0000008hO1AAA',
            Name = 'September SSS1',
            Shared_Solar_System__c = 'a1Jj0000001H2ftEAC',
            Date_Enacted_by_Utility__c = Date.newInstance(2019,09,15),
            Status__c = 'Enacted By Utility'
        );

        Schedule_Z__c alsTwo = new Schedule_Z__c(
            Id = 'a3z0a0000008hO1BBB',
            Name = 'October SSS1',
            Shared_Solar_System__c = 'a1Jj0000001H2ftEAC',
            Date_Enacted_by_Utility__c = Date.newInstance(2019,10,15),
            Status__c = 'Enacted By Utility'
        );

        Schedule_Z__c alsThree = new Schedule_Z__c(
            Id = 'a3z0a0000008hO1CCC',
            Name = 'November SSS1',
            Shared_Solar_System__c = 'a1Jj0000001H2ftEAC',
            Date_Enacted_by_Utility__c = Date.newInstance(2019,11,15),
            Status__c = 'Enacted By Utility'
        );

        Schedule_Z__c alsFour = new Schedule_Z__c(
            Id = 'a3z0a0000008hO1DDD',
            Name = 'September SSS2',
            Shared_Solar_System__c = 'a1Jj0000001H2ftEDD',
            Date_Enacted_by_Utility__c = Date.newInstance(2019,09,15),
            Status__c = 'Enacted By Utility'
        );

        Schedule_Z__c alsFive = new Schedule_Z__c(
            Id = 'a3z0a0000008hO1EEE',
            Name = 'October SSS2',
            Shared_Solar_System__c = 'a1Jj0000001H2ftEDD',
            Date_Enacted_by_Utility__c = Date.newInstance(2019,10,15),
            Status__c = 'Enacted By Utility'
        );

        Schedule_Z__c alsSix = new Schedule_Z__c(
            Id = 'a3z0a0000008hO1FFF',
            Name = 'November SSS2',
            Shared_Solar_System__c = 'a1Jj0000001H2ftEDD',
            Date_Enacted_by_Utility__c = Date.newInstance(2019,11,15),
            Status__c = 'Enacted By Utility'
        );
        sssToALSMap.put('a1Jj0000001H2ftEAC',new List<Schedule_Z__c>{alsThree, alsTwo, alsOne});
        sssToALSMap.put('a1Jj0000001H2ftEDD',new List<Schedule_Z__c>{alsSix, alsFive, alsFour});
        return sssToALSMap;
    }

    private static List<Transfer__c> getTransfersWithALSes(){
        List<Transfer__c> transfers = getTransfersWithoutALSes();
        Map<Id,List<Schedule_Z__c>> sssToALSMap = getALSes();

        transfers[0].Allocation_Schedule__r = sssToALSMap.get(transfers[0].Shared_Solar_System__c)[1];
        transfers[0].Allocation_Schedule__c = sssToALSMap.get(transfers[0].Shared_Solar_System__c)[1].Id;
        transfers[1].Allocation_Schedule__r = sssToALSMap.get(transfers[0].Shared_Solar_System__c)[0];
        transfers[1].Allocation_Schedule__c = sssToALSMap.get(transfers[0].Shared_Solar_System__c)[0].Id;
        transfers[2].Allocation_Schedule__r = sssToALSMap.get(transfers[0].Shared_Solar_System__c)[2];
        transfers[2].Allocation_Schedule__c = sssToALSMap.get(transfers[0].Shared_Solar_System__c)[2].Id;
        return transfers;
    }

    private static void useMocks() {
        AllocationScheduleService.alsSelector = (AllocationScheduleSelector) Test.createStub(AllocationScheduleSelector.class, new MockALSelector());
        AllocationScheduleService.transferSelector = (TransferSelector) Test.createStub(TransferSelector.class, new MockTransferSelector());
    }

    public class MockTransferSelector extends MockProvider {
        public MockTransferSelector() {
        }

        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'getAllTransfersById' {
                    return getTransfersWithALSes();
                }
            }
            return null;
        }
    }

    public class MockALSelector extends MockProvider {
        public MockALSelector() {
        }

        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'getEnactedAndBillingALSFromSSS' {
                    return getALSes();
                }
            }
            return null;
        }
    }

}