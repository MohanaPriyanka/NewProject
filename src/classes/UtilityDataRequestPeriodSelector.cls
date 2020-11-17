/**
 * Created by: Kristin White on 9/28/2020
 * 
 * Tested by: UtilityDataRequestServiceTest
 */

@SuppressWarnings('PMD.ApexCRUDViolation')
public inherited sharing class UtilityDataRequestPeriodSelector {

    public Map<Id,List<Utility_Data_Request_Period__c>> selectByUDR(Set<Id> udrIdSet) {

        Map<Id,List<Utility_Data_Request_Period__c>> returnMap = new Map<Id,List<Utility_Data_Request_Period__c>>();

        List<Utility_Data_Request_Period__c> udrpList = [
            SELECT Id, Name, Utility_Data_Request__c, Rate_Class__c, Rate_Class_Lookup__c, Service_Start_Date__c, Rate_Class_Lookup__r.Id,
            Rate_Subclass__c, Utility_Data_Request__r.Utility__c, Utility_Data_Request__r.Utility_Account_Log__r.Utility_Rate_Class__c, 
            Quantity__c, Measurement_Unit__c, Load_Profile_Description__c, Measurement_Significance_Code__c, 
            Used_in_Annual_kWh_Calculation__c, Used_in_Average_Demand_Calculation__c
            FROM Utility_Data_Request_Period__c 
            WHERE Utility_Data_Request__c IN :udrIdSet
            ORDER BY Utility_Data_Request__c ASC, Service_Start_Date__c DESC
        ];

        for (Utility_Data_Request_Period__c udrp : udrpList) {
            List<Utility_Data_Request_Period__c> udrps;
            if (returnMap.containsKey(udrp.Utility_Data_Request__c)) {
                udrps = returnMap.get(udrp.Utility_Data_Request__c);
                udrps.add(udrp);
            } else {
                udrps = new List<Utility_Data_Request_Period__c>();
                udrps.add(udrp);
            }
            returnMap.put(udrp.Utility_Data_Request__c, udrps);
        }
        
        return returnMap;
    }
    
    public List<Utility_Data_Request_Period__c> selectWithKHByUDR(List<Utility_Data_Request__c> udrList) {
        
        List<Utility_Data_Request_Period__c> udrpList = [
            SELECT Id, Name, Utility_Data_Request__c, Rate_Class__c, Rate_Class_Lookup__c, Service_Start_Date__c, Rate_Class_Lookup__r.Id,
            Rate_Subclass__c, Utility_Data_Request__r.Utility__c, Utility_Data_Request__r.Utility_Account_Log__r.Utility_Rate_Class__c, 
            Quantity__c, Measurement_Unit__c, Load_Profile_Description__c, Measurement_Significance_Code__c, 
            Used_in_Annual_kWh_Calculation__c, Used_in_Average_Demand_Calculation__c
            FROM Utility_Data_Request_Period__c 
            WHERE Utility_Data_Request__c IN :(udrList)
            AND Measurement_Unit__c ='KH'
            AND Measurement_Significance_Code__c = '51'
            ORDER BY Utility_Data_Request__c ASC, Service_Start_Date__c DESC
        ];
        
        return udrpList;
    }
    
    public List<Utility_Data_Request_Period__c> selectWithK1ByUDR(List<Utility_Data_Request__c> udrList) {
        
        List<Utility_Data_Request_Period__c> udrpList = [
            SELECT Id, Name, Utility_Data_Request__c, Rate_Class__c, Rate_Class_Lookup__c, Service_Start_Date__c, Rate_Class_Lookup__r.Id,
            Rate_Subclass__c, Utility_Data_Request__r.Utility__c, Utility_Data_Request__r.Utility_Account_Log__r.Utility_Rate_Class__c, 
            Quantity__c, Measurement_Unit__c, Load_Profile_Description__c, Measurement_Significance_Code__c, 
            Used_in_Annual_kWh_Calculation__c, Used_in_Average_Demand_Calculation__c
            FROM Utility_Data_Request_Period__c 
            WHERE Utility_Data_Request__c IN :(udrList)
            AND Measurement_Unit__c ='K1'
            AND Measurement_Significance_Code__c = '51'
            ORDER BY Utility_Data_Request__c ASC, Service_Start_Date__c DESC
        ];
        
        return udrpList;
    }
     
}