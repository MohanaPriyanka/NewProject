/*************************************************************************************
 * Created By: peteryao on 2019-04-30  
 * Description: 
 * Test: LeadSelectorTest
 *************************************************************************************/

public without sharing class LeadSelector {
    public static List<Lead> selectConvertedByIds(List<Id> leadIds) {
        return [
            SELECT Id, ConvertedAccountId, Zuora_Payment_Ref_Id__c, Zuora_Payment_Ref_Id_Expiration_Date__c
            FROM Lead
            WHERE Id IN :leadIds
            AND ConvertedAccountId != NULL
        ];
    }
}