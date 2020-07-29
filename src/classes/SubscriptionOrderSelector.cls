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
                Utility_Number_of_Decimal_Places__c,
                Approved_Change_in_Subscription__c,
                Effective_Date__c,
                Utility_Account_Subscription__r.Opportunity__r.Customer_Group__c,
                Utility_Account_Subscription__r.Opportunity__r.Customer_Sub_Group__c,
                Utility_Account_Subscription__r.Opportunity__r.Underwriting_Criteria__c,
                Utility_Account_Subscription__r.Opportunity__r.Acquired_By_Client_Closed_By_BlueWave__c,
                Utility_Account_Subscription__r.Opportunity__r.Partner_tag_lookup__r.Account__r.RecordType.Name,
                Utility_Account_Subscription__r.Opportunity__r.Assignment_Agreement__r.CustomerSignedDate,
                Utility_Account_Subscription__r.Shared_Solar_System__c,
                Utility_Account_Subscription__r.Shared_Solar_System__r.Client_Acquisition_Contract__c,
                Utility_Account_Subscription__r.Shared_Solar_System__r.Client_Management_Contract__c,
                Utility_Account_Subscription__r.Shared_Solar_System__r.Reacquisition_Start_Date__c,
                Utility_Account_Subscription__r.Shared_Solar_System__r.Actual_COD_Date__c,
                Utility_Account_Subscription__r.Shared_Solar_System__r.Actual_PTO_Date_MANUAL__c,
                Utility_Account_Subscription__r.Shared_Solar_System__r.First_Bill_Date__c,
                Contract_Fee_Detail__c,
                Contract_Fee_Detail__r.Acquisition_Type_Reacquisition__c,
                Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Max_Project__c,
                Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Number_Months__c,
                Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Project_Date__c,
                Contract_Fee_Detail__r.Fee__c,
                Contract_Fee_Detail__r.Contract__r.StartDate
            FROM Subscription_Order__c
            WHERE Id IN :soIds
            ORDER BY Effective_Date__c
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
    public Map<Id, Subscription_Order__c> getAcquisitionOrdersBySSS(Id sssId, Date newReacqStartDate) {
        return new Map<Id, Subscription_Order__c> ([
            SELECT Id, Name
            FROM Subscription_Order__c
            WHERE Utility_Account_Subscription__r.Shared_Solar_System__c = : sssId
            AND Effective_Date__c >= : newReacqStartDate
            AND Contract_Fee_Detail__r.Acquisition_Type_Reacquisition__c = false
        ]);
    }
    public Map<Id,Decimal> getSubscriptionOrdersAssignedToClient(Set<Id> uasIds){
        Map<Id,Decimal> uasIdToSumSoMap = new Map<Id,Decimal>();
        List<AggregateResult> aggResults = [
            SELECT SUM(Approved_Change_in_Subscription__c) sumApprovedKW,
                Utility_Account_Subscription__c uasId
            FROM Subscription_Order__c
            WHERE Utility_Account_Subscription__c IN : uasIds
            AND Client_Assignment_Agreement__c != null
            AND Client_Assignment_Agreement__r.Status != 'Draft'
            AND Client_Assignment_Agreement__r.Status != 'Rejected'
            GROUP BY Utility_Account_Subscription__c
        ];
        for (AggregateResult aggregateResult : aggResults) {
            uasIdToSumSoMap.put((Id)aggregateResult.get('uasId'),(Decimal)aggregateResult.get('sumApprovedKW'));
        }
        return uasIdToSumSoMap;
    }
}