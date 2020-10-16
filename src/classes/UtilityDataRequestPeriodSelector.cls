/**
 * Created by: Kristin White on 9/28/2020
 * 
 * Tested by: UtilityDataRequestServiceTest and UtilityDataRequestPeriodSelectorTest
 */

@SuppressWarnings('PMD.ApexCRUDViolation')
public inherited sharing class UtilityDataRequestPeriodSelector {
    public List<Utility_Data_Request_Period__c> selectByUDR(Set<Id> udrIdSet) {
        
        List<Utility_Data_Request_Period__c> udrpList = [
            SELECT Id, Name, Utility_Data_Request__c, Rate_Class__c, Rate_Class_Lookup__c, Service_Start_Date__c, Rate_Class_Lookup__r.Id,
            Utility_Data_Request__r.Utility__c, Utility_Data_Request__r.Utility_Account_Log__r.Utility_Rate_Class__c
            FROM Utility_Data_Request_Period__c 
            WHERE Utility_Data_Request__c IN :udrIdSet
            ORDER BY Utility_Data_Request__c ASC, Service_Start_Date__c DESC
        ];
        
        return udrpList;
    }
    
}