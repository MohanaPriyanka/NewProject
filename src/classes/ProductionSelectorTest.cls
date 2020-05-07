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

    public static void addMoreTestRecords(){
        Util.disableAllTriggers();
        Shared_Solar_System__c sss1 = new Shared_Solar_System__c(
            Name = 'Project 1A',
            Billing_Method__c = 'NMC',
            Reserved_Capacity_kW_DC__c = '10',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 1445.86,
            Total_System_Size_kW_AC__c = 1000,
            Maximum_Subscription_Assemblage__c = 25);
        insert sss1;

        Shared_Solar_System__c sss2 = new Shared_Solar_System__c(
            Name = 'Project 2B',
            Billing_Method__c = 'NMC',
            Reserved_Capacity_kW_DC__c = '10',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 1445.86,
            Total_System_Size_kW_AC__c = 1000,
            Maximum_Subscription_Assemblage__c = 25);
        insert sss2;

        Production__c prod1 = new Production__c(
            Name = 'SSS 1 Production - May 2019',
            Shared_Solar_System__c = sss1.Id,
            Production_kWh__c = 20000,
            Credits_Generated__c = 10000,
            Start_Date__c = Date.newInstance(2019, 5, 1),
            End_Date__c = Date.newInstance(2019, 5, 29)
        );
        Production__c prod2 = new Production__c(
            Name = 'SSS 1 Production - June 2020',
            Shared_Solar_System__c = sss1.Id,
            Production_kWh__c = 20000,
            Credits_Generated__c = 10000,
            Start_Date__c = Date.newInstance(2020, 6, 1),
            End_Date__c = Date.newInstance(2020, 6, 29)
        );
        Production__c prod3 = new Production__c(
            Name = 'SSS 2 Production - May 2019',
            Shared_Solar_System__c = sss2.Id,
            Production_kWh__c = 20000,
            Credits_Generated__c = 10000,
            Start_Date__c = Date.newInstance(2019, 5, 1),
            End_Date__c = Date.newInstance(2019, 5, 29)
        );
        Production__c prod4 = new Production__c(
            Name = 'SSS 2 Production - June 2020',
            Shared_Solar_System__c = sss2.Id,
            Production_kWh__c = 20000,
            Credits_Generated__c = 10000,
            Start_Date__c = Date.newInstance(2020, 6, 1),
            End_Date__c = Date.newInstance(2020, 6, 29)
        );
        insert new List<Production__c>{
            prod1, prod2, prod3, prod4
        };

        Transfer__c transfer1SSS1 = new Transfer__c(
            Name = 'Main May Transfer',
            Transfer_Type__c = 'Main',
            Shared_Solar_System__c = sss1.Id,
            Attempted_Transfer__c = 10000,
            Attempted_kWh_Transfer__c = 20000,
            Transfer_Amount__c = 10000,
            Date_of_Transfer__c = Date.newInstance(2019, 6, 4),
            Bills_Generated__c = TRUE
        );
        Transfer__c transfer2SSS1 = new Transfer__c(
            Name = 'Main June Transfer',
            Transfer_Type__c = 'Main',
            Shared_Solar_System__c = sss1.Id,
            Attempted_Transfer__c = 8000,
            Attempted_kWh_Transfer__c = 15000,
            Transfer_Amount__c = 8000,
            Date_of_Transfer__c = Date.newInstance(2019, 7, 4),
            Bills_Generated__c = TRUE
        );
        Transfer__c transfer1SSS2 = new Transfer__c(
            Name = 'Main July Transfer',
            Transfer_Type__c = 'Main',
            Shared_Solar_System__c = sss1.Id,
            Attempted_Transfer__c = 4980,
            Attempted_kWh_Transfer__c = 9000,
            Transfer_Amount__c = 4980,
            Date_of_Transfer__c = Date.newInstance(2019, 8, 4),
            Bills_Generated__c = TRUE
        );
        Transfer__c transfer2SSS2 = new Transfer__c(
            Name = 'Main July Transfer',
            Transfer_Type__c = 'Main',
            Shared_Solar_System__c = sss2.Id,
            Attempted_Transfer__c = 4980,
            Attempted_kWh_Transfer__c = 9000,
            Transfer_Amount__c = 4980,
            Date_of_Transfer__c = Date.newInstance(2019, 8, 4),
            Bills_Generated__c = FALSE
        );
        insert new List<Transfer__c>{
            transfer1SSS1, transfer2SSS1, transfer1SSS2, transfer2SSS2
        };

        Transfer_Part__c part1 = new Transfer_Part__c(
            Transfer__c = transfer1SSS1.Id,
            Production__c = prod1.Id
        );
        Transfer_Part__c part2 = new Transfer_Part__c(
            Transfer__c = transfer2SSS1.Id,
            Production__c = prod2.Id
        );
        Transfer_Part__c part3 = new Transfer_Part__c(
            Transfer__c = transfer1SSS2.Id,
            Production__c = prod3.Id
        );
        Transfer_Part__c part4 = new Transfer_Part__c(
            Transfer__c = transfer2SSS2.Id,
            Production__c = prod4.Id
        );
        insert new List<Transfer_Part__c>{
            part1, part2, part3, part4
        };
        Util.enableAllTriggers();
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

    @IsTest
    public static void testSelectProductionsByBillPeriod() {
        Map<Id, Bill_Period__c> bpMap = new Map<Id, Bill_Period__c>([
            SELECT Id
            FROM Bill_Period__c
            LIMIT 1
        ]);
        ProductionSelector selector = new ProductionSelector();
        Map<Production__c, Bill_Period__c> productionsByBPMap = selector.selectProductionByBillPeriod(bpMap);
        System.assertNotEquals(null, productionsByBPMap, 'Expected a Map to be returned');
    }

    @IsTest
    public static void testGetBilledProductionBySSS(){
        addMoreTestRecords();
        List<Shared_Solar_System__c> sssList = [
            SELECT Id
            FROM Shared_Solar_System__c
            WHERE (Name = 'Project 1A' OR Name = 'Project 2B')
            ORDER BY Name
        ];

        ProductionSelector selector = new ProductionSelector();
        Map<Id,Integer> sssMap = selector.getBilledProductionBySSS(new Set<Id>{sssList[0].Id, sssList[1].Id});

        System.assertEquals(2,sssMap.get(sssList[0].Id));
        System.assertEquals(1,sssMap.get(sssList[1].Id));
    }
}