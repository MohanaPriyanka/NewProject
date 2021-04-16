/*************************************************************************************
 * Created By: peteryao on 1/12/19  
 * Description: Could be extend the fflib_SObjectDomain class
 * Tested By: CSCancellationServiceTest
 *************************************************************************************/

@SuppressWarnings('PMD.ApexCRUDViolation')
public inherited sharing class UtilityAccountSubscriptions {
    public List<Utility_Account_Subscription__c> records;
    @TestVisible
    private static SubscriptionManagementService subscriptionSerivce = new SubscriptionManagementService();
    @TestVisible
    private static FeatureService featureService = new FeatureService();

    public UtilityAccountSubscriptions(List<Utility_Account_Subscription__c> sObjectList) {
        records = sObjectList;
    }

    public void removeFromNextScheduleZ() {
        for (Utility_Account_Subscription__c uas : records) {
            uas.Next_Schedule_Z_Status__c = 'Inactive Subscription';
        }
        update records;
    }

    public void registerSubscriptionOrdersToZeroOutUAS(String zeroType, fflib_SObjectUnitOfWork uow) {
        for (Utility_Account_Subscription__c uas : records) {
            if (uas.Future_Customer_Subscription_KWDC_Rollup__c == 0) {
                // This is already zeroed, so it doesn't need another SO
                continue;
            }
            Subscription_Order__c zeroedSO = new Subscription_Order__c(
                Type__c = zeroType,
                Approval_Status__c = 'Approved',
                Effective_Date__c = System.now(),
                Utility_Account_Subscription__c = uas.Id,
                Comments__c = 'Subscription Order was created to zero out UAS'
            );
            if (uas.Subscription_Type__c == 'kWh') {
                zeroedSO.New_Annual_kWh__c = 0;
            } else {
                zeroedSO.New_Annual_Cost__c = 0;
            }
            uow.registerNew(zeroedSO);
        }
    }

    public void handleFinaledAccounts() {
        for (Utility_Account_Subscription__c uas : records) {
            uas.Next_Schedule_Z_Status__c = 'Inactive Subscription';
            uas.Date_Removed_from_Project__c = uas.Utility_Account_Log__r.Date_Utility_Account_Cancelled__c;
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

        uasesToMarkInactive = UASSelector.selectUASesByAccounts(new Set<Id>(accountsCancelled));
        return uasesToMarkInactive;
    }
}