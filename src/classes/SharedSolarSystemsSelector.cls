/**
 * Created by mstackhouse on 1/23/2019.
 * Description: Used to query shared solar systems
 * Test: SharedSolarSystemSelectorTest
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
            SELECT Id, Apex_Context__c, Expected_Yield_kWh_kW__c, Total_System_Size_kWh_DC__c,
                CS_Services_Type__c, Client_Management_Contract__c, Client_Acquisition_Contract__c
            FROM Shared_Solar_System__c
            WHERE Id IN :sssIds
        ];
    }
    public Map<Id, Shared_Solar_System__c> getSSSMap(Set<Id> sssIds) {
        Map<Id, Shared_Solar_System__c> sssMap = new Map<Id, Shared_Solar_System__c>([
            SELECT Id, Client_Account__c, Number_of_Billed_Production_Periods__c
            FROM Shared_Solar_System__c
            WHERE Id IN :sssIds
        ]);
        return sssMap;
    }
    @SuppressWarnings('PMD.ApexSOQLInjection')
    public static List<Shared_Solar_System__c> selectSharedSolarSystemsWithCapacityByUtilityAndLoadZone(
        Set<Id> utilityIds,
        Set<String> loadZones) {
        String loadZoneString = '';
        for (String loadZone : loadZones) {
            loadZoneString += '\'' + String.escapeSingleQuotes(loadZone) +  '\',';
        }
        loadZoneString = loadZoneString.left(loadZoneString.length() - 1); // strip off extra comma
        String query = 'SELECT Id, Name, Capacity_Available_to_be_Reserved__c, Product__r.Id, ' +
            'Product__r.Name, Product__r.Customer_Subscription_Type__c, Sales_Partners__c ' +
            'FROM Shared_Solar_System__c ' +
            'WHERE Capacity_Available_to_be_Reserved__c > 0 ' +
            'AND Open__c = true ' +
            'AND Utility__c IN : utilityIds ';
        if (loadZoneString != '') {
            query +=
                'AND Service_Territories__c INCLUDES (' + loadZoneString + ')';
        }
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
    public Map<String,Shared_Solar_System__c> getSSSByUniqueId(Set<String> blueWaveIds){
        Map<String,Shared_Solar_System__c> bwIdToSSSMap = new Map<String,Shared_Solar_System__c>();
        for (Shared_Solar_System__c sss : [ SELECT Id, Unique_ID__c
        FROM Shared_Solar_System__c
        WHERE Unique_ID__c IN : blueWaveIds]){
            bwIdToSSSMap.put(sss.Unique_ID__c, sss);
        }
        return bwIdToSSSMap;
    }
    public List<Shared_Solar_System__c> getAllSSSes() {
        return [
            SELECT Id, Anchor_Capacity_Reserved__c, Capacity_Committed_kW_DC__c,
                Reserved_Capacity_kW_DC__c, Total_CS_Capacity__c, Maximum_Subscription_Capacity_kWDC__c,
                Total_Capacity_Committed_Reserved__c,
                Reserved_Anchor_Capacity__c, Name, Stage__c,
                CS_Services_Type__c, Client_Management_Contract__c, Client_Acquisition_Contract__c,
                Management_Revenue_Start_Date__c, Customer_Assignment_Date__c, First_Bill_Date__c
            FROM Shared_Solar_System__c
        ];
    }

    public List<Shared_Solar_System__c> getSharedSolarSystemsForEnrollment() {
        return [
            SELECT Id, Name, Sales_Partners__c, Maximum_Subscription_Cost__c, Billing_Method__c, Product__r.Name,
                Product__c, Product__r.Sizing_Method__c, Product__r.Customer_Subscription_Type__c,
                Project_Capacity_Available_kW_DC__c, Estimated_COD_Date_Manual__c, Service_Territories__c,
                Reserved_Capacity_kW_DC__c, Service_Territory__c, Utility__c, Utility__r.Number_of_Decimal_Places__c,
                Expected_Yield_kWh_kW__c, Utility_NMC_Tariff__c, Utility_NMC_Tariff__r.Size_Ratio__c, NMC_Value__c,
                Credit_Score_Requirement__c, Assignment_Order__c, Maximum_Subscription_Capacity_kWDC__c,
                BWC_Project_Entity_Manual__c, BWC_Project_Entity_Manual__r.Gateway__c, Total_System_Size_kWh_DC__c
            FROM Shared_Solar_System__c
            WHERE Open__c = TRUE
            AND Capacity_Available_to_be_Reserved__c > 0
        ];
    }

    public List<Shared_Solar_System__c> selectSharedSolarSystemsForQualificationCheck(String productId, List<Id> utilityIds) {
        return [
                SELECT Id, Name, Open__c, Capacity_Available_to_be_Reserved__c, Service_Territories__c,
                        Sales_Partners__c, Credit_Score_Requirement__c, Product__r.Name, Utility__r.Name
                FROM Shared_Solar_System__c
                WHERE Product__c = :productId
                AND Utility__c IN :utilityIds
                AND Stage__c = 'Acquisition'
                AND Sales_Partners__c != null
                ORDER BY Assignment_Order__c
        ];
    }

    public List<Shared_Solar_System__c> getActiveSystemsWithSmallOfftakeUASes() {
        return [
            SELECT Id, (
                SELECT Id, Opportunity__r.StageName, Opportunity__r.Account.Days_Past_Due__c, Future_Customer_Subscription_KWDC_Rollup__c,
                    Future_Share_of_System_Rollup__c, Shared_Solar_System__r.Waitlist__c, Opportunity__r.Customer_Group__c
                FROM Utility_Account_Subscriptions__r
                WHERE Next_Schedule_Z_Status__c = 'Active Subscription'
                AND (NOT Opportunity__r.Name LIKE '%test%')
            )
            FROM Shared_Solar_System__c
            WHERE Stage__c IN ('Acquisition', 'Management')
        ];
    }
}