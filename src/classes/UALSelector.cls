/**
 * Created by jlugo on 2019-07-10.
 * Tested by: System tests in RESTRouterV2Test
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
                Service_Zip_Code__c, Annual_kWh__c, Annual_Cost_of_Electricity__c, Account__c
            FROM Utility_Account_Log__c
            WHERE Id = :utilityAccountLogIds
        ];
    }

    public Map<Id, Utility_Account_Log__c> selectAllMap(Set<Id> utilityAccountLogIds) {
        return new Map<Id, Utility_Account_Log__c>([
            SELECT Id, Name, Name_on_Account__c, Service_Address__c, Service_City__c, Service_State__c,
                Service_Zip_Code__c, Annual_kWh__c, Annual_Cost_of_Electricity__c, Account__c
            FROM Utility_Account_Log__c
            WHERE Id = :utilityAccountLogIds
        ]);
    }

    public List<Utility_Account_Log__c> selectByLeads(List<Id> leadIds) {
        return [
            SELECT Id, Name, Annual_Cost_of_Electricity__c, Name_on_Account__c, Lead__c, Utility__c,Annual_kWh__c, Proposed_kWh__c,
                Lead__r.Product__r.Customer_Subscription_Type__c,Utility_NMC_Tariff__c, Utility_Rate_Class__c,
                Utility_Rate_Class__r.Utility_NMC_Tariff__c, Utility_Rate_Class__r.Utility_NMC_Tariff__r.Size_Ratio__c,
                Subsc_Annual_Cost_of_Electricity_Rollup__c, Subscribed_Annual_kWhs_Rollup__c
            FROM Utility_Account_Log__c
            WHERE Lead__c IN :leadIds
            ORDER BY Annual_Cost_of_Electricity__c DESC
        ];
    }
}