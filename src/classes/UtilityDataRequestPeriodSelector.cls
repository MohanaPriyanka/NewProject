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
            SELECT Id, Name, Utility_Data_Request__c, Rate_Class__c, Rate_Class_Lookup__c, Service_Start_Date__c, Service_End_Date__c,
            Rate_Subclass__c, Utility_Data_Request__r.Utility__c, Utility_Data_Request__r.Utility_Account_Log__r.Utility_Rate_Class__c, 
            Quantity__c, Measurement_Unit__c, Load_Profile_Description__c, Measurement_Significance_Code__c, Quantity_Qualifier__c, 
            Used_in_Annual_kWh_Calculation__c, Used_in_Average_Demand_Calculation__c, Num_Days__c, Rate_Class_Lookup__r.Id
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
    
    public List<Utility_Data_Request_Period__c> selectTypeByUDR(List<Utility_Data_Request__c> udrList, String mUnit, List<String> sCode) {
        List<Utility_Data_Request_Period__c> udrpList = [
            SELECT Id, Name, Utility_Data_Request__c, Rate_Class__c, Rate_Class_Lookup__c, Service_Start_Date__c, Service_End_Date__c,
            Rate_Subclass__c, Utility_Data_Request__r.Utility__c, Utility_Data_Request__r.Utility_Account_Log__r.Utility_Rate_Class__c, 
            Quantity__c, Measurement_Unit__c, Load_Profile_Description__c, Measurement_Significance_Code__c, Quantity_Qualifier__c, 
            Used_in_Annual_kWh_Calculation__c, Used_in_Average_Demand_Calculation__c, Num_Days__c, Rate_Class_Lookup__r.Id
            FROM Utility_Data_Request_Period__c 
            WHERE Utility_Data_Request__c IN :udrList
            AND Measurement_Significance_Code__c IN :sCode
            AND Measurement_Unit__c =:mUnit
            ORDER BY Utility_Data_Request__c ASC, Service_Start_Date__c DESC
        ];
        return udrpList;
    }

    public List<Utility_Data_Request_Period__c> selectAvgUsagePeriodsByUDR(Id utilityDataRequestId) {
        return [
            SELECT Id, Service_Start_Date__c, Measurement_Value__c
            FROM Utility_Data_Request_Period__c
            WHERE Glynt_Average_Daily_Usage__c = TRUE
            AND Utility_Data_Request__c =: utilityDataRequestId
            ORDER BY Service_Start_Date__c DESC
        ];
    }
}