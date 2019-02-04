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

    public static List<Utility_Account_Subscription__c> getUASesForManuallyCancelledAccounts(Map<Id, Account> triggerNewMap, Map<Id, Account> triggerOldMap) {
        List<Id> accountsCancelled = new List<Id>();
        List<Utility_Account_Subscription__c> uasesToMarkInactive = new List<Utility_Account_Subscription__c>();
        for (Id newAccountId : triggerNewMap.keySet()) {
            if (triggerOldMap.get(newAccountId).Cancellation_Request_Date__c == null &&
                triggerNewMap.get(newAccountId).Cancellation_Request_Date__c != null) {
                accountsCancelled.add(newAccountId);
            }
        }

        if (accountsCancelled.isEmpty()) {
            return uasesToMarkInactive;
        }

        uasesToMarkInactive = UASSelector.selectByAccounts(new Set<Id>(accountsCancelled));
        return uasesToMarkInactive;
    }
}