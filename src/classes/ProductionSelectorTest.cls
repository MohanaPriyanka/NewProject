/**
 * Created by SarahRenfro on 4/13/2020.
 */

@IsTest
private class ProductionSelectorTest {
    @testSetup
    static void setupData() {
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
            Verification_Status__c = 'Pending Verification',
            Production_kWh__c = 20000,
            Credits_Generated__c = 10000,
            Start_Date__c = Date.newInstance(2019, 5, 1),
            End_Date__c = Date.newInstance(2019, 5, 29)
        );

        insert prod1;

        Bill_Period__c bp = new Bill_Period__c(
            Name = 'sssA - January 2016',
            Shared_Solar_System__c = sss1.Id,
            Bill_Date__c = System.today()
        );

        insert bp;

        Transfer__c transfer = new Transfer__c(
            Name = 'Main Transfer - sssA September',
            Bill_Period__c = bp.Id,
            Date_of_Transfer__c = System.today(),
            Shared_Solar_System__c = sss1.Id,
            Transfer_Type__c = 'Main',
            Transferred_To__c = 'Customer',
            Bill_By__c = 'UASB',
            Attempted_Transfer__c = 45000,
            Attempted_kWh_Transfer__c = 364667,
            Transfer_kWh__c = 364667,
            Transfer_Amount__c = 45000,
            Default_Credit_Value__c = 0.1234
        );

        insert transfer;

    }

    @IsTest
    public static void testSelectPendingVerificationProductions() {
        Bill_Period__c bp = [
            SELECT Id
            FROM Bill_Period__c
            LIMIT 1
        ];

        ProductionSelector selector = new ProductionSelector();
        System.assert(selector.selectPendingVerificationProductions(new Set<Id>{bp.Id}).size() == 1, 'Expected 1 Production');
    }
}