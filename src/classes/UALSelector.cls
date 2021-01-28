/**
 * Created by jlugo on 2019-07-10.
 * Tested by: UALSelectorTest, UtilityDataRequestServiceTest, and system tests in RESTRouterV2Test
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class UALSelector {
    
    public Utility_Account_Log__c selectOne(Id utilityAccountLogId) {
        List<Utility_Account_Log__c> uals = this.selectAll(new Set<Id>{utilityAccountLogId});
        if (uals.isEmpty()) {
            return null;
        }
        return uals[0];
    }
    
    public List<Utility_Account_Log__c> selectAll(Set<Id> utilityAccountLogIds) {
        return [
            SELECT Id, Name, Name_on_Account__c, Service_Address__c, Service_City__c, Service_State__c,
                Service_Zip_Code__c, Annual_kWh__c, Annual_Cost_of_Electricity__c, Account__c, Lead__c,
                Average_Demand__c, Utility_lookup__c, Utility_Rate_Class__c, Utility_Rate_Class__r.Name,
            	Num_UDRPs_Annual_kWh__c, Num_UDRPs_Avg_Demand__c, NYPA__c, RNY__c, Address_Update__c,
            	Username__c, Previous_Name_on_Utility_Account__c, Previous_Service_Address__c, QC_Status__c,
            	Previous_Service_City__c, Previous_Service_State__c, Previous_Service_Zip_Code__c, Premise_Number__c
            FROM Utility_Account_Log__c
            WHERE Id = :utilityAccountLogIds
        ];
    }
    
    public Map<Id,Utility_Account_Log__c> selectAllMap(Set<Id> utilityAccountLogIds) {
        return new Map<Id, Utility_Account_Log__c>([
            SELECT Id, Name, Name_on_Account__c, Service_Address__c, Service_City__c, Service_State__c,
                Service_Zip_Code__c, Annual_kWh__c, Annual_Cost_of_Electricity__c, Account__c, Lead__c,
                Average_Demand__c, Utility_lookup__c, Utility_Rate_Class__c, Utility_Rate_Class__r.Name,
            	Num_UDRPs_Annual_kWh__c, Num_UDRPs_Avg_Demand__c, NYPA__c, RNY__c, Address_Update__c,
            	Username__c, Previous_Name_on_Utility_Account__c, Previous_Service_Address__c, QC_Status__c,
            	Previous_Service_City__c, Previous_Service_State__c, Previous_Service_Zip_Code__c, Premise_Number__c
            FROM Utility_Account_Log__c
            WHERE Id = :utilityAccountLogIds
        ]);
    }
    
    public Map<Id, Utility_Account_Log__c> selectAllByLeadMap(Set<Id> leadIds) {
        return new Map<Id, Utility_Account_Log__c>([
            SELECT Id, Name, Name_on_Account__c, Service_Address__c, Service_City__c, Service_State__c,
                Service_Zip_Code__c, Annual_kWh__c, Annual_Cost_of_Electricity__c, Account__c, Lead__c,
                Average_Demand__c, Utility_lookup__c, Utility_Rate_Class__c, Utility_Rate_Class__r.Name,
            	Num_UDRPs_Annual_kWh__c, Num_UDRPs_Avg_Demand__c, NYPA__c, RNY__c, Address_Update__c,
            	Username__c, Previous_Name_on_Utility_Account__c, Previous_Service_Address__c, QC_Status__c,
            	Previous_Service_City__c, Previous_Service_State__c, Previous_Service_Zip_Code__c, Premise_Number__c
            FROM Utility_Account_Log__c
            WHERE Lead__c = :leadIds
        ]);
    }

    public List<Utility_Account_Log__c> selectUalsWithUdrs(List<Id> leadIds) {

        return [
            SELECT Id, Name, Utility_lookup__r.Utility_DUNS_Number__c, Utility_lookup__c, Utility_lookup__r.Name,
                Utility_lookup__r.Utility_Data_Collection_Mechanism__c, QC_Status__c, Premise_Number__c,
                Utility_lookup__r.Use_Glynt__c,
                (SELECT Id FROM Utility_Data_Requests__r)
            FROM Utility_Account_Log__c
            WHERE Lead__c IN :leadIds
            AND (Utility_lookup__r.Utility_Data_Collection_Mechanism__c = 'EDI'
            OR (Utility_lookup__r.Utility_Data_Collection_Mechanism__c = 'File Upload' AND Utility_lookup__r.Use_Glynt__c = TRUE))
        ];
    }

    public List<Utility_Account_Log__c> selectDuplicateUALs(String ualNumber) {
        return [
            SELECT
                Id,
                Name,
                Lead__r.Application_Complete_Date__c,
                Lead__r.Continue_Application_Link__c,
                Lead__r.IsConverted,
                Lead__r.Status,
                Opportunity__r.StageName,
                (SELECT Id, Opportunity__r.StageName
                    FROM Utility_Account_Subscriptions__r
                    WHERE Next_Schedule_Z_Status__c = 'Active Subscription'
                )
            FROM Utility_Account_Log__c
            WHERE Name = :ualNumber
            AND Lead__r.LastName != 'Testcase'
        ];
    }
}