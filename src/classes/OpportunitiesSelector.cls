/*************************************************************************************
 * Created By: peteryao on 1/19/19  
 * Description: Can extend fflib_SObjectSelector
 * Test: OpportunitiesSelectorTest
 *************************************************************************************/
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class OpportunitiesSelector {
    // To be used when cancelling opportunities, so we also exclude Anchors and Public Offtake
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public static List<Opportunity> selectAllCompleteCSWithUASesAndSystemBills() {
        return [
            SELECT Id, Name,
            (SELECT Id, Name, Next_Schedule_Z_Status__c, Total_Count_of_Schedule_Zs__c, Transferring_Subsc_to_Another_UAS__c FROM Utility_Account_Subscriptions__r),
            (SELECT Id, Name, Date__c FROM Utility_Account_Subscription_Bills__r ORDER BY Date__c DESC LIMIT 1)
            FROM Opportunity
            WHERE StageName = 'Complete'
            AND Product_Line__c = 'Community Solar'
            AND Customer_Group__c NOT IN ('Anchor', 'Public Offtake')
            ORDER BY Name
        ];
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    public static List<Opportunity> selectAllCompleteCSWithUASes(Set<Id> oppIds) {
        return [
            SELECT Id, Name, Date_Removed_from_Project__c,
            (
                SELECT Id, Name, Most_Recent_Enacted_ALSS__c, Next_Schedule_Z_Status__c, Total_Count_of_Schedule_Zs__c,
                    Transferring_Subsc_to_Another_UAS__c, Date_Removed_from_Project__c
                FROM Utility_Account_Subscriptions__r
            )
            FROM Opportunity
            WHERE StageName = 'Complete'
            AND Product_Line__c = 'Community Solar'
            AND Customer_Group__c NOT IN ('Anchor', 'Public Offtake')
            AND Id = :oppIds
        ];
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    public static Opportunity selectForContractSend(Id opportunityId) {
        return [
            SELECT Id, Name, Parent_Account_Name__c, Salesperson_Email__c, Sales_tag__c, Application_Type__c,
                Email__c, Co_Applicant_Email__c, Co_Applicant_Full_Name__c, Docusign_Template__c
            FROM Opportunity
            WHERE Id = : opportunityId
            LIMIT 1
        ];
    }

    public static Map<Id, Opportunity> selectOpportunityMap(Set<Id> oppIds) {
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([
            SELECT Id, Shared_Solar_System__c
            FROM Opportunity
            WHERE Id IN :oppIds
        ]);
        return oppMap;
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    public List<Opportunity> selectWithoutFirstInvoiceCommission(Set<Id> accountIds){
        return [
            SELECT Id, Name, AccountId, Account.Account_Number__c, Shared_Solar_System__r.Unique_ID__c,
                CS_Capacity_Allocated__c, Commission_Structure__r.Cents_kW_DC_First_Bill_Paid__c,
                Commission_Structure__r.Cents_kW_DC_First_Bill__c,
                Commission_Structure__c, Partner_tag_lookup__r.Id, Partner_tag_lookup__r.Name
            FROM Opportunity
            WHERE Commission_Structure__r.Cents_kW_DC_First_Bill__c != null
            AND Commission_Structure__r.Cents_kW_DC_First_Bill__c != 0
            AND ID NOT IN (SELECT Opportunity__c FROM Commission_Payment__c WHERE Type__c = 'First Bill Sent')
            AND Account.Zuora_Id__c != null
            AND Shared_Solar_System__r.Count_of_Transfers__c > 0
            AND AccountId IN : accountIds
        ];
    }
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public List<Opportunity> selectWithoutFirstPaymentCommission(Set<Id> accountIds){
        return [
            SELECT Id, Name, AccountId, Account.Account_Number__c, Shared_Solar_System__r.Unique_ID__c,
                CS_Capacity_Allocated__c, Commission_Structure__r.Cents_kW_DC_First_Bill_Paid__c,
                Commission_Structure__r.Cents_kW_DC_First_Bill__c,
                Commission_Structure__c, Partner_tag_lookup__r.Id, Partner_tag_lookup__r.Name
            FROM Opportunity
            WHERE Commission_Structure__r.Cents_kW_DC_First_Bill_Paid__c != null
            AND Commission_Structure__r.Cents_kW_DC_First_Bill_Paid__c != 0
            AND ID NOT IN (SELECT Opportunity__c FROM Commission_Payment__c WHERE Type__c = 'First Bill Paid')
            AND Account.Zuora_Id__c != null
            AND Shared_Solar_System__r.Count_of_Transfers__c > 0
            AND AccountId IN : accountIds
        ];
    }
}