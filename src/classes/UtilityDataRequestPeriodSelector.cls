/**
 * Created by: Kristin White on 9/28/2020
 * 
 * Tested by: UtilityDataRequestServiceTest
 */

@SuppressWarnings('PMD.ApexCRUDViolation')
public inherited sharing class UtilityDataRequestPeriodSelector {
    public List<Utility_Data_Request_Period__c> getRelatedUDRP(Set<Id> udrIdSet) {
        
        List<Utility_Data_Request_Period__c> udrpList = [
            SELECT Id, Name, Utility_Data_Request__c, Rate_Class__c, Rate_Class_Lookup__c, Utility_Data_Request__r.Utility__c
            FROM Utility_Data_Request_Period__c 
            WHERE Utility_Data_Request__c IN :udrIdSet
        ];
        
        return udrpList;
    }
    
}