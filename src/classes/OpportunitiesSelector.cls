/*************************************************************************************
 * Created By: peteryao on 1/19/19  
 * Description: Can extend fflib_SObjectSelector
 * Test: OpportunitiesSelectorTest
 *************************************************************************************/

public class OpportunitiesSelector {
    public static List<Opportunity> selectAllCompleteCSWithUASesAndSystemBills() {
        return [
            SELECT Id,
            (SELECT Id, Next_Schedule_Z_Status__c, Total_Count_of_Schedule_Zs__c FROM Utility_Account_Subscriptions__r),
            (SELECT Id, Date__c FROM System_Bills__r ORDER BY Date__c DESC LIMIT 1)
            FROM Opportunity
            WHERE StageName = 'Complete'
            AND Product_Line__c = 'Community Solar'
        ];
    }
}