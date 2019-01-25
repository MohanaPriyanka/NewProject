/**
 * Created by mstackhouse on 1/23/2019.
 * Description: Used to query shared solar systems
 * Test: SharedSolarSystemSelectorTest
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
}