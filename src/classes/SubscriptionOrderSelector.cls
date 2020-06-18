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
                New_Annual_Cost__c,
                New_Annual_kWh__c,
                Previous_Annual_Cost__c,
                Previous_Annual_kwh__c,
                Previous_Percent_Share_of_System__c,
                Previous_kw_DC_Subscription__c,
                Product__r.Customer_Subscription_Type__c,
                System_Change_Percent_Share_of_System__c,
                System_Change_kW_DC_Subscription__c,
                System_Change_kW_DC_Rounded__c,
                Total_System_Size_kW_DC__c,
                Utility_Number_of_Decimal_Places__c
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

    public List<Subscription_Order__c> selectApprovedByOppIds(Set<Id> oppIds) {
        return [
            SELECT Id, Client_Assignment_Agreement__c, Utility_Account_Subscription__r.Opportunity__c
            FROM Subscription_Order__c
            WHERE Utility_Account_Subscription__r.Opportunity__c IN :oppIds
            AND Approval_Status__c = 'Approved'
        ];
    }

    public List<Subscription_Order__c> selectApprovedByContractIds(Set<Id> contractIds) {
        return [
            SELECT Id, Client_Assignment_Agreement__c, Utility_Account_Subscription__r.Opportunity__r.ContractId
            FROM Subscription_Order__c
            WHERE Utility_Account_Subscription__r.Opportunity__r.ContractId IN :contractIds
            AND Approval_Status__c = 'Approved'
        ];
    }
}