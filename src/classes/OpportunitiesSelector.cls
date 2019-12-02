/*************************************************************************************
 * Created By: peteryao on 1/19/19  
 * Description: Can extend fflib_SObjectSelector
 * Test: OpportunitiesSelectorTest
 *************************************************************************************/

public class OpportunitiesSelector {
    // To be used when cancelling opportunities, so we also exclude Anchors and Public Offtake
    public static List<Opportunity> selectAllCompleteCSWithUASesAndSystemBills() {
        return [
            SELECT Id, Name,
            (SELECT Id, Name, Next_Schedule_Z_Status__c, Total_Count_of_Schedule_Zs__c, Transferring_Subsc_to_Another_UAS__c FROM Utility_Account_Subscriptions__r),
            (SELECT Id, Name, Date__c FROM System_Bills__r ORDER BY Date__c DESC LIMIT 1)
            FROM Opportunity
            WHERE StageName = 'Complete'
            AND Product_Line__c = 'Community Solar'
            AND Customer_Group__c NOT IN ('Anchor', 'Public Offtake')
        ];
    }

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
}