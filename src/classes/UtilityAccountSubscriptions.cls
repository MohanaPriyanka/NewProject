/*************************************************************************************
 * Created By: peteryao on 1/12/19  
 * Description: Could be extend the fflib_SObjectDomain class
 * Tested By: CSCancellationServiceTest
 *************************************************************************************/

@SuppressWarnings('PMD.ApexCRUDViolation')
public inherited sharing class UtilityAccountSubscriptions {
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

    public void handleFinaledAccounts() {
        for (Utility_Account_Subscription__c uas : records) {
            uas.Next_Schedule_Z_Status__c = 'Inactive Subscription';
            uas.Date_Removed_from_Project__c = Date.today();
            // When we mark a utility account as finaled, we set it to transferring by default to pause the cancellation
            // process. Otherwise, this may trigger the opportunity to go to Cancelled and the Account CS Status to go to Closed.
            uas.Transferring_Subsc_to_Another_UAS__c = true;
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