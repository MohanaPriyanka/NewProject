/**
 * Created by peteryao on 7/28/20.
 */
@IsTest
public with sharing class CapacitySnapshotServiceTest {
    @IsTest
    private static void capacitySnapshotSystemTest() {
        SharedSolarSystemsSelectorTest.setupTestData();
        Utility_NMC_Tariff__c everbillNMC = new Utility_NMC_Tariff__c(
            Name = 'Eversource SEMA Class 2',
            Utility__c = 'Eversource',
            Class__c = 'Class 2',
            Value_of_Net_Metering_Credit__c = 0.1848,
            Current_Billing_Rate__c = true
        );
        insert everbillNMC;
        Product2 csProduct = new Product2(
            Name = 'VDER',
            Family = 'Community Solar',
            Product_Type__c = 'Community Solar',
            Program__c = 'VDER - Community Solar',
            Sizing_Method__c = 'Project Ratio',
            State__c = 'NY',
            IsActive = true,
            Lender_of_Record__c = 'BlueWave',
            NMC_Discount__c = 10,
            Customer_Subscription_Type__c = 'kWh'
        );
        insert csProduct;

        List<Shared_Solar_System__c> systems = [SELECT Id FROM Shared_Solar_System__c];
        for (Shared_Solar_System__c sharedSolarSystem : systems) {
            sharedSolarSystem.Estimated_PTO_Date_MANUAL__c = System.today();
            sharedSolarSystem.Actual_PTO_Date_MANUAL__c = System.today();
            sharedSolarSystem.Estimated_COD_Date_Manual__c = System.today();
            sharedSolarSystem.Actual_COD_Date__c = System.today();
            sharedSolarSystem.Utility_NMC_Tariff__c = everbillNMC.Id;
            sharedSolarSystem.Product__c = csProduct.Id;
            sharedSolarSystem.Stage__c = 'Acquisition';
        }
        update systems;
        System.assertEquals(5, systems.size(), 'Expected to load 4 systems');
        CapacitySnapshotScheduler scheduler = new CapacitySnapshotScheduler();
        Test.startTest();
        System.schedule('TestCapacitySnapshotService', '0 0 0 ? * *', scheduler);
        Test.stopTest();
        List<Capacity_Snapshot__c> capacitySnapshots = [
            SELECT Id
            FROM Capacity_Snapshot__c
        ];
        System.assertEquals(5, capacitySnapshots.size(), 'Expected a capacity snapshot for each system');
    }

    @IsTest
    private static void testCapacitySnapshots() {
        CapacitySnapshotService capacitySnapshotService = new CapacitySnapshotService();
        Capacity_Snapshot__c snapshot;

        snapshot = capacitySnapshotService.getSnapshot(getSharedSolarSystem('Complete', false, 0, 100, 5055.0742));
        System.assertEquals(0, snapshot.Available_Capacity__c, '5055/(100/100)-5055 should equal 0 but got ' + snapshot.Available_Capacity__c);

        snapshot = capacitySnapshotService.getSnapshot(getSharedSolarSystem('Complete', false, 0, 99.97, 5827.7631));
        System.assertEquals(1.75, snapshot.Available_Capacity__c.setScale(2), '5827/(99.97/100)-5827 should equal 1.748853586 but got ' + snapshot.Available_Capacity__c);

        snapshot = capacitySnapshotService.getSnapshot(getSharedSolarSystem('Complete', false, 45, 99.97, 5827.7631));
        System.assertEquals(1.75, snapshot.Available_Capacity__c.setScale(2), 'A 45 days late customer should still be included in the available capacity calculation');
        System.assertEquals(5827.7631, snapshot.X45_60_Day_Past_Due_Active_kW__c, 'A 45 days late customer should get that capacity reported');

        snapshot = capacitySnapshotService.getSnapshot(getSharedSolarSystem('Complete', false, 89, 99.97, 5827.7631));
        System.assertEquals(1.75, snapshot.Available_Capacity__c.setScale(2), 'An 89 days late customer should still be included in the available capacity calculation');
        System.assertEquals(5827.7631, snapshot.X60_Day_Past_Due_Active_kW__c, 'An 89 days late customer should get that capacity reported');

        snapshot = capacitySnapshotService.getSnapshot(getSharedSolarSystem('QC In Process', false, 45, 99.97, 5827.7631));
        System.assertEquals(0, snapshot.Available_Capacity__c.setScale(2), 'A QC In Process customer should not be included in available capacity calcs');
        System.assertEquals(5827.7631, snapshot.QC_Capacity__c, 'A QC In Process customer should be included in the QC Capacity');

        snapshot = capacitySnapshotService.getSnapshot(getSharedSolarSystem('Complete', true, 0, 99.97, 5827.7631));
        System.assertEquals(0, snapshot.Available_Capacity__c.setScale(2), 'Waitlist capacity should not be included in the available capacity calc');
        System.assertEquals(5827.76, snapshot.Waitlist_Capacity__c.setScale(2), 'Waitlist capacity should be reported in waitlist capacity');

        snapshot = capacitySnapshotService.getSnapshot(getSharedSolarSystem('Pending Quality Control Signature', true, 0, 99.97, 5827.7631));
        System.assertEquals(0, snapshot.Available_Capacity__c.setScale(2), 'Waitlist capacity should not be included in the available capacity calc');
        System.assertEquals(0, snapshot.Waitlist_Capacity__c.setScale(2), 'Waitlist capacity should be reported in waitlist capacity for opps in QC');
        System.assertEquals(5827.76, snapshot.QC_Capacity__c.setScale(2), 'Waitlist capacity should be reported in qc capacity for opps in QC');
    }
    private static Shared_Solar_System__c getSharedSolarSystem(String stageName, Boolean waitlist, Integer daysPastDue,
        Decimal futureShareOfSystem, Decimal futureCustomerSubscription) {
        Map<SObjectField, Object> sssValues = new Map<SObjectField, Object>{
            Shared_Solar_System__c.Id => Util.getFakeId(Shared_Solar_System__c.SObjectType)
        };
        Map<SObjectField, Object> uasValues = new Map<SObjectField, Object>{
            Utility_Account_Subscription__c.Id => Util.getFakeId(Utility_Account_Subscription__c.SObjectType),
            Utility_Account_Subscription__c.Future_Customer_Subscription_KWDC_Rollup__c => futureCustomerSubscription,
            Utility_Account_Subscription__c.Future_Share_of_System_Rollup__c => futureShareOfSystem
        };
        Map<SObjectField, Object> uasOpportunityValues = new Map<SObjectField, Object>{
            Opportunity.StageName => stageName
        };
        Map<SObjectField, Object> uasSharedSolarSystemValues = new Map<SObjectField, Object>{
            Shared_Solar_System__c.Waitlist__c => waitlist
        };
        Map<SObjectField, Object> uasOpportunityAccountValues = new Map<SObjectField, Object>{
            Account.Days_Past_Due__c => daysPastDue
        };
        sfab_FabricatedSObject fabbedUASOppAccount = new sfab_FabricatedSObject(Account.class, uasOpportunityAccountValues);
        sfab_FabricatedSObject fabbedUASSSS = new sfab_FabricatedSObject(Shared_Solar_System__c.class, uasSharedSolarSystemValues);
        sfab_FabricatedSObject fabbedUASOpp = new sfab_FabricatedSObject(Opportunity.class, uasOpportunityValues);
        fabbedUASOpp.setParent('Account', fabbedUASOppAccount);
        sfab_FabricatedSObject fabbedUAS = new sfab_FabricatedSObject(Utility_Account_Subscription__c.class, uasValues);
        fabbedUAS.setParent('Opportunity__r', fabbedUASOpp);
        fabbedUAS.setParent('Shared_Solar_System__r', fabbedUASSSS);
        sfab_FabricatedSObject fabbedSSS = new sfab_FabricatedSObject(Shared_Solar_System__c.class, sssValues);
        fabbedSSS.setChildren('Utility_Account_Subscriptions__r', new List<sfab_FabricatedSObject>{fabbedUAS});
        return (Shared_Solar_System__c) fabbedSSS.toSObject();
    }
}