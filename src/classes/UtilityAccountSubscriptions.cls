/*************************************************************************************
 * Created By: peteryao on 1/12/19  
 * Description: Could be extend the fflib_SObjectDomain class
 * Tested By: CSCancellationServiceTest
 *************************************************************************************/

public class UtilityAccountSubscriptions {
    public List<Utility_Account_Subscription__c> records;

    public UtilityAccountSubscriptions(List<Utility_Account_Subscription__c> sObjectList) {
        records = sObjectList;
    }

    public void removeFromNextScheduleZ() {
        for (Utility_Account_Subscription__c uas : records) {
            uas.Next_Schedule_Z_Status__c = 'Inactive Subscription';
        }
        update records;
    }

    public void removeFromProject() {
        for (Utility_Account_Subscription__c uas : records) {
            uas.Next_Schedule_Z_Status__c = 'Inactive Subscription';
            uas.Date_Removed_from_Project__c = Date.today();
        }
        update records;
    }
}