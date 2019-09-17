/**
 * Created by mstackhouse on 1/23/2019.
 * Description: Used to query shared solar systems
 * Test: SharedSolarSystemSelectorTest, ProductionUpdateSelectorTest
 */


public class SharedSolarSystemsSelector {
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

    public static Shared_Solar_System__c getMyProject(String projectId) {
        Shared_Solar_System__c myProject = [
            SELECT Id, Name, Metric_Tons_of_CO2_Offset__c, Home_Electricity_Offset__c, Waitlist__c, Subscribers__c,  Project_Image__c
            FROM Shared_Solar_System__c
            WHERE Id = :projectId
            LIMIT 1
        ];
        return myProject;
    }

}