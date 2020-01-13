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
            Sales_Partners__c = 'All',
            Maximum_Subscription_Assemblage__c = 25);

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
            Sales_Partners__c = 'All',
            Maximum_Subscription_Assemblage__c = 25);

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
            Sales_Partners__c = 'All',
            Maximum_Subscription_Assemblage__c = 25);

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
            Sales_Partners__c = 'All',
            Maximum_Subscription_Assemblage__c = 25);

        insert new List<Shared_Solar_System__c>{sss1, sss2, sss3, sss4};
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

        System.assertEquals(0, noSharedSolarSystems.size());

        noSharedSolarSystems =
            SharedSolarSystemsSelector.selectSharedSolarSystemsWithCapacityByUtilityAndLoadZone(
                new Set<Id>{utilityMap.get('Eversource')},
                new Set<String>{'No Load Zone'}
            );

        System.assertEquals(0, noSharedSolarSystems.size());

        noSharedSolarSystems =
            SharedSolarSystemsSelector.selectSharedSolarSystemsWithCapacityByUtilityAndLoadZone(
                new Set<Id>(),
                new Set<String>()
            );

        System.assertEquals(0, noSharedSolarSystems.size());

        noSharedSolarSystems =
            SharedSolarSystemsSelector.selectSharedSolarSystemsWithCapacityByUtilityAndLoadZone(
                new Set<Id>{utilityMap.get('No SSS Utility')},
                new Set<String>{'SEMA'}
            );

        System.assertEquals(0, noSharedSolarSystems.size());

        List<Shared_Solar_System__c> eversourceSharedSolarSystems =
            SharedSolarSystemsSelector.selectSharedSolarSystemsWithCapacityByUtilityAndLoadZone(
                new Set<Id>{utilityMap.get('Eversource')},
                new Set<String>{'SEMA', 'NEMA'}
            );

        System.assertEquals(3, eversourceSharedSolarSystems.size());

        List<Shared_Solar_System__c> nationalGridSharedSolarSystems =
            SharedSolarSystemsSelector.selectSharedSolarSystemsWithCapacityByUtilityAndLoadZone(
                new Set<Id>{utilityMap.get('National Grid')},
                new Set<String>{'SEMA', 'NEMA'}
            );

        System.assertEquals(1, nationalGridSharedSolarSystems.size());

        List<Shared_Solar_System__c> ngAndEversourceSharedSolarSystems =
            SharedSolarSystemsSelector.selectSharedSolarSystemsWithCapacityByUtilityAndLoadZone(
                new Set<Id>{utilityMap.get('National Grid'),utilityMap.get('Eversource')},
                new Set<String>{'SEMA', 'NEMA'}
            );

        System.assertEquals(4, ngAndEversourceSharedSolarSystems.size());
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

    //TODO: These are Test methods for queries required to go into Production BEFORE Production/Transfer Logic has been released
    // WILL BE DEPRECATED AFTER RELEASE

    @IsTest
    static void testGetSSSWithoutProdUpdates(){
        Date todaysDate = Date.today();
        List<Id> prodIdList;

        List<Energy_Usage_Update__c> prodList;
        prodList = ProductionUpdateSelector.getProductionUpdatesByMonth(todaysDate.month(),String.valueOf(todaysDate.year()));

        for (Energy_Usage_Update__c prod : prodList){
            prodIdList.add(prod.Id);
        }

        List<Shared_Solar_System__c> sssList;
        List<Shared_Solar_System__c> sss2List;
        sssList = SharedSolarSystemsSelector.getAllSSSWithProductionUpdates();
        sss2List = SharedSolarSystemsSelector.getAllSSSWithProdUpdatesNotInList(prodIdList);

        System.assertEquals(0,sssList.size());
        System.assertEquals(0,sss2List.size());
    }

}