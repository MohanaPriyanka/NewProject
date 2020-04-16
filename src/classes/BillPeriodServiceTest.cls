/**
 * Created by SarahRenfro on 11/11/2019.
 */

@IsTest
private class BillPeriodServiceTest {
    @TestSetup
    public static void setupData() {

        Utility__c ngrid = new Utility__c(
            Name = 'National Grid',
            Number_of_Decimal_Places__c = 2
        );

        insert ngrid;

        Shared_Solar_System__c sss1 = new Shared_Solar_System__c(Name = 'Oxford Barrett St. P1',
            Service_Territory__c = 'SEMA',
            Service_Territories__c = 'SEMA',
            Open__c = true,
            Billing_Method__c = 'NMC',
            Reserved_Capacity_kW_DC__c = '10',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 1445.86,
            Total_System_Size_kW_AC__c = 1000,
            Utility__c = ngrid.Id,
            Credit_Score_Requirement__c = 300,
            Assignment_Order__c = '1',
            Expected_Yield_kWh_kW__c = 1300,
            Assemblage_Count__c = 1,
            Sales_Partners__c = 'All',
            Maximum_Subscription_Assemblage__c = 25);

        insert sss1;

        Schedule_Z__c scheduleZ1 = new Schedule_Z__c(
            Name = '18-0515 Oxford Barrett St. P1',
            Shared_Solar_System__c = sss1.Id,
            Date_Enacted_by_Utility__c = Date.newInstance(2018,1,1),
            Status__c = 'Billing'
        );

        insert scheduleZ1;

        Production__c prod1 = new Production__c(
            Name = 'SSS 1 Production - May 2019',
            Shared_Solar_System__c = sss1.Id,
            Production_kWh__c = 20000,
            Credits_Generated__c = 10000,
            Start_Date__c = Date.newInstance(2019, 5, 1),
            End_Date__c = Date.newInstance(2019, 5, 29)
        );

       insert prod1;

        //May Transfer has Date of Transfer in June - to be placed on July Bill Period
        Transfer__c onTime1 = new Transfer__c(
            Name = 'Main May Transfer',
            Transfer_Type__c = 'Main',
            Allocation_Schedule__c = scheduleZ1.Id,
            Shared_Solar_System__c = sss1.Id,
            Attempted_Transfer__c = 10000,
            Attempted_kWh_Transfer__c = 20000,
            Transfer_Amount__c = 10000,
            Date_of_Transfer__c = Date.newInstance(2019, 6, 4),
            Bills_Generated__c = FALSE
        );

        Transfer__c onTime2 = new Transfer__c(
            Name = 'Main June Transfer',
            Transfer_Type__c = 'Main',
            Allocation_Schedule__c = scheduleZ1.Id,
            Shared_Solar_System__c = sss1.Id,
            Attempted_Transfer__c = 8000,
            Attempted_kWh_Transfer__c = 15000,
            Transfer_Amount__c = 8000,
            Date_of_Transfer__c = Date.newInstance(2019, 7, 4)
        );

        Transfer__c onTime3 = new Transfer__c(
            Name = 'Main July Transfer',
            Transfer_Type__c = 'Main',
            Allocation_Schedule__c = scheduleZ1.Id,
            Shared_Solar_System__c = sss1.Id,
            Attempted_Transfer__c = 4980,
            Attempted_kWh_Transfer__c = 9000,
            Transfer_Amount__c = 4980,
            Date_of_Transfer__c = Date.newInstance(2019, 8, 4)
        );

        insert new List<Transfer__c> {onTime1, onTime2, onTime3};
    }

    @IsTest
    static void testVerifyProductions() {
        Shared_Solar_System__c sss = [
            SELECT Id
            FROM Shared_Solar_System__c
            LIMIT 1
        ];

        Bill_Period__c bp = new Bill_Period__c(
            Name = 'sssA - July Bill Period 2016',
            Shared_Solar_System__c = sss.Id,
            Bill_Date__c = Date.newInstance(2019, 7, 15)
        );

        insert bp;

        List<Transfer_Part__c> parts = [SELECT Id, Production__r.Name FROM Transfer_Part__c];
        System.assertEquals(1, parts.size());

        bp.Bill_Status__c = 'Host Account Bill Uploaded';
        update bp;

        Production__c production = [
            SELECT Id, Verification_Status__c
            FROM Production__c
            LIMIT 1
        ];

        System.assertEquals('Pending Verification', production.Verification_Status__c);

        bp.Bill_Status__c = 'Host Account Bill QCed';
        update bp;

        production = [
            SELECT Id, Verification_Status__c
            FROM Production__c
            LIMIT 1
        ];

        System.assertEquals('Verified', production.Verification_Status__c);
    }

    @IsTest
    static void testBillPeriodInsert() {
        Shared_Solar_System__c sss = [
            SELECT Id
            FROM Shared_Solar_System__c
            LIMIT 1
        ];

        //July Bill Period will grab May Transfer
        Bill_Period__c bp1 = new Bill_Period__c(
            Name = 'sssA - July Bill Period 2016',
            Shared_Solar_System__c = sss.Id,
            Bill_Date__c = Date.newInstance(2019, 7, 15)
        );

        insert bp1;

        List<Transfer__c> mayTransfers = [
            SELECT Id, Bill_Period__c
            FROM Transfer__c
            WHERE Bill_Period__c = :bp1.Id
        ];

        System.assertEquals(1, mayTransfers.size());

        //September Bill Period will grab June & July Transfer (2 months of production)
        Bill_Period__c bp2 = new Bill_Period__c(
            Name = 'sssA - September Bill Period 2016',
            Shared_Solar_System__c = sss.Id,
            Bill_Date__c = Date.newInstance(2019, 9, 15)
        );

        insert bp2;

        List<Transfer__c> multiTransfers = [
            SELECT Id, Bill_Period__c
            FROM Transfer__c
            WHERE Bill_Period__c = :bp2.Id
        ];

        System.assertEquals(2, multiTransfers.size());

    }


    @IsTest
    static void testBillPeriodStatusUpdates() {
        Test.startTest();
        Shared_Solar_System__c sss = [
            SELECT Id
            FROM Shared_Solar_System__c
            LIMIT 1
        ];

        Date today = Date.today();

        Bill_Period__c bp1 = new Bill_Period__c(
            Name = 'sssA - July Bill Period 2016',
            Shared_Solar_System__c = sss.Id,
            Bill_Date__c = Date.newInstance(2019, 7, 15)
        );

        Bill_Period__c bp2 = new Bill_Period__c(
            Name = 'sssA - August Bill Period 2016',
            Shared_Solar_System__c = sss.Id,
            Bill_Date__c = Date.newInstance(2019, 8, 15)
        );

        Bill_Period__c bp3 = new Bill_Period__c(
            Name = 'sssA - September Bill Period 2016',
            Shared_Solar_System__c = sss.Id,
            Bill_Date__c = Date.newInstance(2019, 9, 15)
        );

        Bill_Period__c bp4 = new Bill_Period__c(
            Name = 'sssA - October Bill Period 2016',
            Shared_Solar_System__c = sss.Id,
            Bill_Date__c = Date.newInstance(2019, 10, 15)
        );

        List<Bill_Period__c> bpList = new List<Bill_Period__c> {bp1, bp2, bp3, bp4};
        insert bpList;

        bp1.Bill_Status__c = 'Host Account Bill Uploaded';
        bp2.Bill_Status__c = 'Host Account Bill QCed';
        bp3.Bill_Status__c = 'Generated';
        bp4.Bill_Status__c = 'Credit Transfers QCed';

        update bpList;

        List<Bill_Period__c> bpStatuses = [
            SELECT Id, Bill_Status__c, Date_Host_Bill_Uploaded__c, Date_Host_Account_Bill_QCed__c,
                Date_Credit_Transfers_QCed__c, Date_Generated__c
            FROM Bill_Period__c
            ORDER BY Bill_Date__c ASC
        ];

        System.assertEquals(today, bpStatuses[0].Date_Host_Bill_Uploaded__c);
        System.assertEquals(today, bpStatuses[1].Date_Host_Account_Bill_QCed__c);
        System.assertEquals(today, bpStatuses[2].Date_Generated__c);
        System.assertEquals(today, bpStatuses[3].Date_Credit_Transfers_QCed__c);

        Test.stopTest();
    }

    @IsTest
    static void testMarkBillPeriodsAsBillRunComplete(){
        Shared_Solar_System__c sss = [
            SELECT Id
            FROM Shared_Solar_System__c
            LIMIT 1
        ];

        Bill_Period__c bp1 = new Bill_Period__c(
            Name = 'sssA - July Bill Period 2016',
            Shared_Solar_System__c = sss.Id,
            Bill_Status__c = 'Ready to Generate',
            Bill_Date__c = Date.newInstance(2019, 6, 15)
        );
        insert bp1;

        Bill_Period__c bp2 = new Bill_Period__c(
            Name = 'sssA - July Bill Period 2016',
            Shared_Solar_System__c = sss.Id,
            Bill_Status__c = 'Ready to Generate',
            Bill_Date__c = Date.newInstance(2019, 7, 15)
        );
        insert bp2;

        Bill_Period__c bp3 = new Bill_Period__c(
            Name = 'sssA - July Bill Period 2016',
            Shared_Solar_System__c = sss.Id,
            Bill_Status__c = 'Ready to Generate',
            Bill_Date__c = Date.newInstance(2020, 7, 15)
        );
        insert bp3;

        BillPeriodService.markBillPeriodsAsBillRunComplete(Date.newInstance(2019, 7, 20));

        List<Bill_Period__c> billPeriods = [
            SELECT Id
            FROM Bill_Period__c
            WHERE Bill_Status__c = 'Bill Run Complete'
        ];

        System.assertEquals(1,billPeriods.size());
    }
}