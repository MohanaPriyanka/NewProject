/**
 * Created by: Kristin White on 10/19/2020
 * 
 * Tested by: UtilityDataRequestServiceTest
 */

@SuppressWarnings('PMD.ApexCRUDViolation')
public class UtilityDataRequestSelector {
    
    public Map<Id, Utility_Data_Request__c> selectMapForKWHById(List<Utility_Data_Request__c> udrList) {
        Map<Id, Utility_Data_Request__c> selectedUDRs = new Map<Id, Utility_Data_Request__c>([
            SELECT Id, Name, Annual_kWh__c, Request_Status__c, State__c, Utility__c, 
            Utility_Account_Log__c, Account_Number__c, Account_Type__c, Utility_Account_Log__r.Service_State__c, Customer_Name__c,
            Utility_Account_Log__r.Lead__r.Product__r.X4_month_sizing_method__c, Utility_Account_Log__r.Lead__r.Customer_type__c
            FROM Utility_Data_Request__c 
            WHERE Id IN :(udrList)
        ]);
        return selectedUDRs;
    }
}