@IsTest
public with sharing class AllocationScheduleSelectorTest {
    @TestSetup
    public static void testSetup() {
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
            Maximum_Subscription_Assemblage__c = 25);

        Shared_Solar_System__c sss2 = new Shared_Solar_System__c(Name = 'SSS 2',
            Service_Territory__c = 'NEMA',
            Service_Territories__c = 'NEMA',
            Open__c = true,
            Billing_Method__c = 'kWh',
            Reserved_Capacity_kW_DC__c = '10',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 1445.86,
            Total_System_Size_kW_AC__c = 996,
            Utility__c = eversource.Id,
            Credit_Score_Requirement__c = 300,
            Assignment_Order__c = '2',
            Expected_Yield_kWh_kW__c = 1300,
            Assemblage_Count__c = 1,
            Sales_Partners__c = 'All',
            Maximum_Subscription_Assemblage__c = 25);

        insert new List<Shared_Solar_System__c> {sss1, sss2};

        Schedule_Z__c scheduleZ1 = new Schedule_Z__c(
            Name = '18-0515 Oxford Barrett St. P1',
            Shared_Solar_System__c = sss1.Id,
            Date_Enacted_by_Utility__c = Date.newInstance(2018,1,1),
            Status__c = 'Billing'
        );

        Schedule_Z__c scheduleZ2 = new Schedule_Z__c(
            Name = '18-0515 Oxford Barrett St. P2',
            Shared_Solar_System__c = sss2.Id,
            Date_Enacted_by_Utility__c = Date.newInstance(2018,1,1),
            Status__c = 'Billing'
        );

        Schedule_Z__c scheduleZ3 = new Schedule_Z__c(
            Name = '18-0515 Oxford Barrett St. P1',
            Shared_Solar_System__c = sss1.Id,
            Date_Enacted_by_Utility__c = Date.newInstance(2019,1,1),
            Status__c = 'Enacted By Utility'
        );

        Schedule_Z__c scheduleZ4 = new Schedule_Z__c(
            Name = '18-0515 Oxford Barrett St. P2',
            Shared_Solar_System__c = sss2.Id,
            Date_Enacted_by_Utility__c = Date.newInstance(2019,1,1),
            Status__c = 'Replaced'
        );

        insert new List<Schedule_Z__c>{scheduleZ1, scheduleZ2, scheduleZ3, scheduleZ4};

    }

    @IsTest
    public static void testGetEnactedAndBillingALSFromSSS() {
        List<Shared_Solar_System__c> sssList = [SELECT Id FROM Shared_Solar_System__c ORDER BY Name];
        List<Schedule_Z__c> alsList = [SELECT Id FROM Schedule_Z__c];

        System.assertEquals(2,sssList.size());
        System.assertEquals(4,alsList.size());

        AllocationScheduleSelector selector = new AllocationScheduleSelector();
        Map<Id,List<Schedule_Z__c>> sssMap;
        sssMap = selector.getEnactedAndBillingALSFromSSS(new Set<Id>{sssList[0].Id, sssList[1].Id});

        System.assertEquals(2,sssMap.get(sssList[0].Id).size());
        System.assertEquals(1,sssMap.get(sssList[1].Id).size());
    }
}