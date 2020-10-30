/**
 * Created by jlugo on 2019-07-10.
 * Tested by: UtilityDataRequestServiceTest, and system tests in RESTRouterV2Test
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
                Utility_lookup__c, Utility_Rate_Class__c, Utility_Rate_Class__r.Name
            FROM Utility_Account_Log__c
            WHERE Id = :utilityAccountLogIds
        ];
    }

    public Map<Id, Utility_Account_Log__c> selectAllByLeadMap(Set<Id> leadIds) {
        return new Map<Id, Utility_Account_Log__c>([
            SELECT Id, Name, Name_on_Account__c, Service_Address__c, Service_City__c, Service_State__c,
                Service_Zip_Code__c, Annual_kWh__c, Annual_Cost_of_Electricity__c, Account__c, Lead__c,
                Utility_lookup__c, Utility_Rate_Class__c, Utility_Rate_Class__r.Name
            FROM Utility_Account_Log__c
            WHERE Lead__c = :leadIds
        ]);
    }
    
    public Utility_Account_Log__c selectByUDR(Utility_Data_Request__c udr) {
        Set<Id> udrUALId = new Set<Id>();
        udrUALId.add(udr.Utility_Account_Log__c);
        
        Utility_Account_Log__c ual = [
            SELECT Id, Name, Name_on_Account__c, Service_Address__c, Service_City__c, Service_State__c,
            Service_Zip_Code__c, Annual_kWh__c, Annual_Cost_of_Electricity__c, Account__c, Lead__c,
            Utility_lookup__c, Utility_Rate_Class__c, Utility_Rate_Class__r.Name, QC_Status__c
            FROM Utility_Account_Log__c
            WHERE Id IN :(udrUALId)
        ];
        
        return ual;
    }

    public List<Utility_Account_Log__c> selectUalsWithoutUdrs(List<Id> leadIds) {
        return [
            SELECT Id, Name, Utility_lookup__r.Utility_DUNS_Number__c, Utility_lookup__c, Utility_lookup__r.Name,
                Utility_lookup__r.Utility_Data_Collection_Mechanism__c, QC_Status__c,
                (SELECT Id FROM Utility_Data_Requests__r)
            FROM Utility_Account_Log__c
            WHERE Lead__c IN :leadIds
            AND Utility_lookup__r.Utility_Data_Collection_Mechanism__c = 'EDI'
        ];
    }


}