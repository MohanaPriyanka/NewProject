/**
 * Created by jlugo on 2019-07-10.
 */

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
                Service_Zip_Code__c, Annual_kWh__c, Annual_Cost_of_Electricity__c
            FROM Utility_Account_Log__c
            WHERE Id = :utilityAccountLogIds
        ];
    }

}