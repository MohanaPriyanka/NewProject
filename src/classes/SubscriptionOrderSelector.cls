/**
 * Created by SarahRenfro on 2/11/2020.
 *
 * Tested By: SubscriptionManagementServiceTestclass, SubscriptionOrderSelectorTest
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public inherited sharing class SubscriptionOrderSelector {
    public List<Subscription_Order__c> selectByIds(Set<Id> soIds) {
        return [
            SELECT Id,
                Name,
                System_Change_Percent_Share_of_System__c,
                System_Change_kW_DC_Subscription__c,
                System_Change_kW_DC_Rounded__c,
                Previous_Percent_Share_of_System__c,
                Previous_kw_DC_Subscription__c,
                Calculated_Change_in_Percent_Share_of_Sy__c,
                Calculated_Change_in_Subscription_KW_DC__c,
                Calculated_Change_in_kW_DC_Rounded__c,
                RecordType.Name,
                Total_System_Size_kW_DC__c,
                Utility_Number_of_Decimal_Places__c,
                Utility_Account_Subscription__r.Opportunity__r.Customer_Group__c,
                Utility_Account_Subscription__r.Opportunity__r.Partner_tag_lookup__r.Account__r.RecordType.Name,
                Approved_Change_in_Subscription__c,
                Contract_Fee_Detail__c,
                Effective_Date__c,
                Utility_Account_Subscription__r.Shared_Solar_System__c,
                Utility_Account_Subscription__r.Shared_Solar_System__r.Client_Acquisition_Contract__c,
                Utility_Account_Subscription__r.Shared_Solar_System__r.Client_Management_Contract__c,
                Utility_Account_Subscription__r.Shared_Solar_System__r.Reacquisition_Start_Date__c
            FROM Subscription_Order__c
            WHERE Id IN :soIds
        ];
    }

    public List<Subscription_Order__c> selectUnenactedByUASId(Set<Id> uasIds) {
        return [
            SELECT Id, Name,
                Utility_Account_Subscription__c,
                Allocation_Schedule_Subscription__c
            FROM Subscription_Order__c
            WHERE Utility_Account_Subscription__c IN : uasIds
            AND Date_Enacted_By_Utility__c = null
        ];
    }
}