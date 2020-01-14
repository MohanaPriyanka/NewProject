/**
 * Created by mstackhouse on 1/23/2019.
 * Description: Used to query shared solar systems
 * Test: SharedSolarSystemSelectorTest, ProductionUpdateSelectorTest
 */

@SuppressWarnings('PMD.ApexCRUDViolation')
public inherited sharing class SharedSolarSystemsSelector {

    public Shared_Solar_System__c selectOne(Id sssId) {
        List<Shared_Solar_System__c> sssList = this.selectAll(new Set<Id>{sssId});
        if (sssList.isEmpty()) {
            return null;
        }
        return sssList[0];
    }

    public List<Shared_Solar_System__c> selectAll(Set<Id> sssIds) {
        return [
            SELECT Id, Apex_Context__c, Expected_Yield_kWh_kW__c, Total_System_Size_kWh_DC__c
            FROM Shared_Solar_System__c
            WHERE Id IN :sssIds
        ];
    }

    public Map<Id, Shared_Solar_System__c> getSSSMap(Set<Id> sssIds) {
        Map<Id, Shared_Solar_System__c> sssMap = new Map<Id, Shared_Solar_System__c>([
            SELECT Id, Client_Account__c
            FROM Shared_Solar_System__c
            WHERE Id IN :sssIds
        ]);

        return sssMap;
    }
    public static List<Shared_Solar_System__c> selectSharedSolarSystemsWithCapacityByUtilityAndLoadZone(
        Set<Id> utilityIds,
        Set<String> loadZones) {
        String query = 'SELECT Id, Name, Capacity_Available_to_be_Reserved__c, Product__r.Id, ' +
            'Product__r.Name, Product__r.Customer_Subscription_Type__c ' +
            'FROM Shared_Solar_System__c ' +
            'WHERE Capacity_Available_to_be_Reserved__c > 0 ' +
            'AND Utility__c IN : utilityIds ';

        String loadZoneString = '\'' + String.join(new List<String>(loadZones),'\',\'') + '\'';
        query += 'AND Service_Territories__c INCLUDES (' + loadZoneString + ')';

        return Database.query(query);
    }

    // Gets all SSS that have at least 1 transfer, but that transfer is not in list
    public static List<Shared_Solar_System__c> getAllSSSWithTransfersNotInList(List<Id> transfersToIgnore) {
        List<Shared_Solar_System__c> sssList;
        if(transfersToIgnore != null) {
            sssList = [
                SELECT Id, Name
                FROM Shared_Solar_System__c
                WHERE Id NOT IN (SELECT Shared_Solar_System__c FROM Transfer__c WHERE Id IN :transfersToIgnore)
                AND Id IN (SELECT Shared_Solar_System__c FROM Transfer__c)
            ];
        } else {
            sssList = [
                SELECT Id, Name
                FROM Shared_Solar_System__c
                WHERE Id IN (SELECT Shared_Solar_System__c FROM Transfer__c)
            ];
        }
        return sssList;
    }

    public static Shared_Solar_System__c getMyProject(String projectId) {
        Shared_Solar_System__c myProject = [
            SELECT Id, Name, Metric_Tons_of_CO2_Offset__c, Home_Electricity_Offset__c, Waitlist__c, Subscribers__c,  Project_Image__c
            FROM Shared_Solar_System__c
            WHERE Id = :projectId
            LIMIT 1
        ];
        return myProject;
    }


    //TODO: These are the queries required to go into Production BEFORE Production/Transfer Logic has been released
    // WILL BE DEPRECATED AFTER RELEASE

    // Gets all SSS that have at least 1 production update
    public static List<Shared_Solar_System__c> getAllSSSWithProductionUpdates() {
        return getAllSSSWithProdUpdatesNotInList(null);
    }

    // Gets all SSS that have at least 1 production update, but that production update is not in list
    public static List<Shared_Solar_System__c> getAllSSSWithProdUpdatesNotInList(List<Id> prodUpdatesToIgnore) {
        List<Shared_Solar_System__c> sssList;
        if(prodUpdatesToIgnore != null) {
            sssList = [
                SELECT Id, Name
                FROM Shared_Solar_System__c
                WHERE Id NOT IN (SELECT Shared_Solar_System__c FROM Energy_Usage_Update__c WHERE Id IN :prodUpdatesToIgnore)
                AND Id IN (SELECT Shared_Solar_System__c FROM Energy_Usage_Update__c)
            ];
        } else {
            sssList = [
                SELECT Id, Name
                FROM Shared_Solar_System__c
                WHERE Id IN (SELECT Shared_Solar_System__c FROM Energy_Usage_Update__c)
            ];
        }
        return sssList;
    }

}