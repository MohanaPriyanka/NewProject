/**
 * Created by mstackhouse on 1/23/2019.
 * Description: 
 * Test: 
 */
@IsTest
public with sharing class SharedSolarSystemsSelectorTest {
    @testSetup public static void setupTestData(){
        Utility__c eversource = new Utility__c(
            Name = 'Eversource',
            Number_of_Decimal_Places__c = 2
        );
        Utility__c nationalGrid = new Utility__c(
            Name = 'National Grid',
            Number_of_Decimal_Places__c = 2
        );
        Utility__c noSSS = new Utility__c(
            Name = 'No SSS Utility',
            Number_of_Decimal_Places__c = 2
        );
        insert new List<Utility__c>{eversource, nationalGrid, noSSS};
        Shared_Solar_System__c sss1 = new Shared_Solar_System__c(   Name = 'Oxford Barrett St. P1',
            Service_Territory__c = 'SEMA',
            Service_Territories__c = 'SEMA',
            Open__c = true,
            Reserved_Capacity_kW_DC__c = '10',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 1445.86,
            Total_System_Size_kW_AC__c  = 996,
            Utility__c = eversource.Id,
            Credit_Score_Requirement__c = 300,
            Assignment_Order__c = '1',
            Expected_Yield_kWh_kW__c = 1300,
            Assemblage_Count__c = 1,
            Maximum_Subscription_Capacity_kWDC__c = 25);
        Shared_Solar_System__c sss2 = new Shared_Solar_System__c(   Name = 'Oxford Barrett St. P1',
            Service_Territory__c = 'NEMA',
            Service_Territories__c = 'NEMA',
            Open__c = true,
            Reserved_Capacity_kW_DC__c = '10',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 1445.86,
            Total_System_Size_kW_AC__c  = 996,
            Utility__c = eversource.Id,
            Credit_Score_Requirement__c = 300,
            Assignment_Order__c = '1',
            Expected_Yield_kWh_kW__c = 1300,
            Assemblage_Count__c = 1,
            Maximum_Subscription_Capacity_kWDC__c = 25);
        Shared_Solar_System__c sss3 = new Shared_Solar_System__c(   Name = 'Oxford Barrett St. P1',
            Service_Territory__c = 'NEMA',
            Service_Territories__c = 'NEMA',
            Open__c = true,
            Reserved_Capacity_kW_DC__c = '10',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 1445.86,
            Total_System_Size_kW_AC__c  = 996,
            Utility__c = eversource.Id,
            Credit_Score_Requirement__c = 300,
            Assignment_Order__c = '1',
            Expected_Yield_kWh_kW__c = 1300,
            Assemblage_Count__c = 1,
            Maximum_Subscription_Capacity_kWDC__c = 25);
        Shared_Solar_System__c sss4 = new Shared_Solar_System__c(   Name = 'Oxford Barrett St. P1',
            Service_Territory__c = 'NEMA',
            Service_Territories__c = 'NEMA',
            Open__c = true,
            Reserved_Capacity_kW_DC__c = '10',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 1445.86,
            Total_System_Size_kW_AC__c  = 996,
            Utility__c = nationalGrid.Id,
            Credit_Score_Requirement__c = 300,
            Assignment_Order__c = '1',
            Expected_Yield_kWh_kW__c = 1300,
            Assemblage_Count__c = 1,
            Maximum_Subscription_Capacity_kWDC__c = 25);
        Shared_Solar_System__c sss5 = new Shared_Solar_System__c(   Name = 'Closed SSS',
            Service_Territory__c = 'NEMA',
            Service_Territories__c = 'NEMA',
            Open__c = false,
            Reserved_Capacity_kW_DC__c = '10',
            Capacity_Committed_kW_DC__c = 0,
            Total_System_Size_kWh_DC__c = 1445.86,
            Total_System_Size_kW_AC__c  = 996,
            Utility__c = nationalGrid.Id,
            Credit_Score_Requirement__c = 300,
            Assignment_Order__c = '1',
            Expected_Yield_kWh_kW__c = 1300,
            Assemblage_Count__c = 1,
            Maximum_Subscription_Capacity_kWDC__c = 25);
        insert new List<Shared_Solar_System__c>{sss1, sss2, sss3, sss4, sss5};
    }


    @IsTest
    public static void testSelectOne() {
        List<Shared_Solar_System__c> sssIds = (new List<Shared_Solar_System__c>([SELECT Id FROM Shared_Solar_System__c]));
        SharedSolarSystemsSelector sssSelector = new SharedSolarSystemsSelector();
        System.assert(sssSelector.selectOne(sssIds.get(0).Id) != null, 'Expected a single SSS');
    }


    @IsTest
    public static void testSelectAll() {
        Set<Id> sssIds = (new Map<Id, Shared_Solar_System__c>([SELECT Id FROM Shared_Solar_System__c])).keySet();
        SharedSolarSystemsSelector sssSelector = new SharedSolarSystemsSelector();
        System.assert(sssSelector.selectAll(sssIds) != null, 'Expected a list of SSS');
    }


    @IsTest
    public static void testGetSSSMap() {
        Set<Id> sssIds = (new Map<Id, Shared_Solar_System__c>([SELECT Id FROM Shared_Solar_System__c])).keySet();
        SharedSolarSystemsSelector sssSelector = new SharedSolarSystemsSelector();
        System.assert(sssSelector.getSSSMap(sssIds) != null, 'Expected a map of SSS');
    }


    @IsTest
    public static void testGetSharedSolarSystemsWithCapacityByUtilityAndLoadZone() {
        Map<String, Id> utilityMap = new Map<String, Id>();
        for(Utility__c utility : [SELECT Id, Name FROM Utility__c]){
            utilityMap.put(utility.Name, utility.Id);
        }
        List<Shared_Solar_System__c> noSharedSolarSystems =
            SharedSolarSystemsSelector.selectSharedSolarSystemsWithCapacityByUtilityAndLoadZone(
                new Set<Id>{utilityMap.get('No SSS Utility')},
                new Set<String>{'No Load Zone'}
            );
        System.assertEquals(0, noSharedSolarSystems.size(), 'Method should have returned no Shared Solar Systems, as the input utility and load zone do not match any SSS records');
        noSharedSolarSystems =
            SharedSolarSystemsSelector.selectSharedSolarSystemsWithCapacityByUtilityAndLoadZone(
                new Set<Id>{utilityMap.get('Eversource')},
                new Set<String>{'No Load Zone'}
            );
        System.assertEquals(0, noSharedSolarSystems.size(), 'Method should have returned no Shared Solar Systems, as the input load zone does not match any SSS records');
        noSharedSolarSystems =
            SharedSolarSystemsSelector.selectSharedSolarSystemsWithCapacityByUtilityAndLoadZone(
                new Set<Id>(),
                new Set<String>()
            );
        System.assertEquals(0, noSharedSolarSystems.size(), 'Method should have returned no Shared Solar Systems, as the input utility and load zone are null');
        noSharedSolarSystems =
            SharedSolarSystemsSelector.selectSharedSolarSystemsWithCapacityByUtilityAndLoadZone(
                new Set<Id>{utilityMap.get('No SSS Utility')},
                new Set<String>{'SEMA'}
            );
        System.assertEquals(0, noSharedSolarSystems.size(), 'Method should have returned no Shared Solar Systems, as the input utility does not match any SSS records');
        List<Shared_Solar_System__c> eversourceSharedSolarSystems =
            SharedSolarSystemsSelector.selectSharedSolarSystemsWithCapacityByUtilityAndLoadZone(
                new Set<Id>{utilityMap.get('Eversource')},
                new Set<String>{'SEMA', 'NEMA'}
            );
        System.assertEquals(3, eversourceSharedSolarSystems.size(), 'Method should have returned 3 Shared Solar Systems, as 3 SSS records look up to the Eversource utility');
        List<Shared_Solar_System__c> nationalGridSharedSolarSystems =
            SharedSolarSystemsSelector.selectSharedSolarSystemsWithCapacityByUtilityAndLoadZone(
                new Set<Id>{utilityMap.get('National Grid')},
                new Set<String>{'SEMA', 'NEMA'}
            );
        System.assertEquals(1, nationalGridSharedSolarSystems.size(), 'Method should have returned 1 Shared Solar System, as 1 SSS record looks up to the National Grid utility');
        List<Shared_Solar_System__c> ngAndEversourceSharedSolarSystems =
            SharedSolarSystemsSelector.selectSharedSolarSystemsWithCapacityByUtilityAndLoadZone(
                new Set<Id>{utilityMap.get('National Grid'),utilityMap.get('Eversource')},
                new Set<String>{'SEMA', 'NEMA'}
            );
        System.assertEquals(4, ngAndEversourceSharedSolarSystems.size(), 'Method should have returned 4 Shared Solar Systems, as 4 SSS records look up to either the National Grid or Eversource utilities');
        

        Shared_Solar_System__c nationalGridSharedSolarSystem = [SELECT Id, Open__c FROM Shared_Solar_System__c WHERE Id = :nationalGridSharedSolarSystems[0].Id];
        nationalGridSharedSolarSystem.Open__c = false;
        update nationalGridSharedSolarSystem;
        noSharedSolarSystems = 
            SharedSolarSystemsSelector.selectSharedSolarSystemsWithCapacityByUtilityAndLoadZone(
                new Set<Id>{utilityMap.get('National Grid')},
                new Set<String>{'SEMA', 'NEMA'}
            );
        System.assertEquals(0, noSharedSolarSystems.size(), 'Method should have returned no Shared Solar Systems, as the only SSS matching the input utility and load zones is not open');
    }


    @IsTest
    static void testGetSSSWithoutTransfers(){
        Date todaysDate = Date.today();
        List<Id> transferIds;
        List<Transfer__c> transferList;
        transferList = TransferSelector.getTransfersByMonth(todaysDate.month(), todaysDate.year());
        for (Transfer__c transfer : transferList) {
            transferIds.add(transfer.Id);
        }
        List<Shared_Solar_System__c> sssList;
        sssList = SharedSolarSystemsSelector.getAllSSSWithTransfersNotInList(transferIds);
        System.assertEquals(0,sssList.size());
    }


    @IsTest
    static void testGetMyProject() {
        Shared_Solar_System__c myProject = [SELECT Id FROM Shared_Solar_System__c LIMIT 1];
        Shared_Solar_System__c checkProject = SharedSolarSystemsSelector.getMyProject(myProject.Id);
        System.assertNotEquals(null, checkProject);
    }


    @IsTest public static void testGetSSSByUniqueId() {
        Shared_Solar_System__c sssOne = new Shared_Solar_System__c(
            Name = 'Test SSS'
        );
        insert sssOne;
        Shared_Solar_System__c sss = [
            SELECT Id, Unique_Id__c
            FROM Shared_Solar_System__c
            WHERE Id = : sssOne.Id
            LIMIT 1
        ];
        SharedSolarSystemsSelector selector = new SharedSolarSystemsSelector();
        Map<String,Shared_Solar_System__c> sssMap = selector.getSSSByUniqueId(new Set<String>{sss.Unique_Id__c});
        System.assertEquals(sssOne.Id,sssMap.get(sss.Unique_Id__c).Id);
    }

    
    @IsTest public static void testGetAllSSSMap(){
        SharedSolarSystemsSelector selector = new SharedSolarSystemsSelector();
        Map<Id, Shared_Solar_System__c> sssMap = selector.getAllSSSMap();
        System.assert(sssMap.size() > 0);
    }

    @IsTest
    public static void testGetSharedSolarSystemsForEnrollment() {
        SharedSolarSystemsSelector selector = new SharedSolarSystemsSelector();
        List<Shared_Solar_System__c> sssList = selector.getSharedSolarSystemsForEnrollment();
        System.assertEquals(4, sssList.size());
    }

    @IsTest
    private static void testGetActiveSystemsWithSmallOfftakeUASes() {
        System.assertEquals(0, new SharedSolarSystemsSelector().getActiveSystemsWithSmallOfftakeUASes().size());
    }

    @IsTest
    private static void testGetSSSWithActiveUASes() {
        List<Shared_Solar_System__c> sssList = (new Map<Id, Shared_Solar_System__c>([SELECT Id FROM Shared_Solar_System__c])).values();
        System.assertEquals(5, new SharedSolarSystemsSelector().getSSSWithActiveUASes(sssList).size());
    }
}