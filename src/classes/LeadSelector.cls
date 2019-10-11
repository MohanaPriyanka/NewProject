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

    public Lead selectOne(Id leadId) {
        List<Lead> leads = this.selectAll(new Set<Id>{leadId});
        if (leads.isEmpty()) {
            return null;
        }
        return leads[0];
    }

    public List<Lead> selectAll(Set<Id> leadIds) {
        return [
            SELECT Id, Privacy_Policy_Acknowledged__c, Terms_Conditions__c, Zuora_Payment_Ref_Id__c,
                Zuora_Payment_Ref_Id_Expiration_Date__c, FirstName, LastName, Email, MobilePhone,
                Company, Application_Type__c, LASERCA__Home_Address__c, LASERCA__Home_City__c,
                LASERCA__Home_State__c, LASERCA__Home_Zip__c, Parcel_Zip__c, LoadZone__c,
                Partner_Lookup__c, Partner_Lookup__r.Id, bs_Sales_ID__c, Customer_Referral__c, Product__c, Phone,
                Business_Title__c, Utility_relationship__r.Name, Product__r.Name, Application_Complete_Date__c, Status,
                Utility_relationship__r.EIA_ID__c, Continue_Application_Link__c, Product_line__c, Manual_Campaign_ID__c,
                Utility_relationship__r.Id, Referral_Name__c, Referral_Email__c
            FROM Lead
            WHERE Id = :leadIds
        ];
    }
}