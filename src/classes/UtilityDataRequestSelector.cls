/**
 * Created by: Kristin White on 10/19/2020
 * 
 * Tested by: UtilityDataRequestServiceTest
 */

@SuppressWarnings('PMD.ApexCRUDViolation')
public class UtilityDataRequestSelector {
    
    public Map<Id, Utility_Data_Request__c> selectMapForKWHById(List<Utility_Data_Request__c> udrList) {
        Map<Id, Utility_Data_Request__c> selectedUDRs = new Map<Id, Utility_Data_Request__c>([
            SELECT Id, Name, Annual_kWh__c, Request_Status__c, State__c, Utility__c, Average_Demand__c, 
            Utility_Account_Log__c, Account_Number__c, Account_Type__c, Utility_Account_Log__r.Service_State__c, 
            Utility_Account_Log__r.Lead__r.Product__r.X4_month_sizing_method__c, Customer_Name__c, Zip_Code__c,
            Utility_Account_Log__r.Lead__r.Customer_type__c, Num_months_Average_Demand__c, City__c, 
            Old_Account_Number__c, Num_months_Annual_kWh__c, Address_Line_1__c, Address_Line_2__c,
            Government_Credit_Code__c, LDC_Customer_Eligibility__c
            FROM Utility_Data_Request__c 
            WHERE Id IN :(udrList)
        ]);
        return selectedUDRs;
    }
}