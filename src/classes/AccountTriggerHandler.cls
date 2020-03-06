//Test: AccountTriggerHandlerTestClass, CSCancellationServiceTest

public without sharing class AccountTriggerHandler {
    private static ZuoraAccountService zuoraAccountService = new ZuoraAccountService();

    public void onBeforeInsert(List<Account> newAccounts) {
        customIdSwapAccount(newAccounts);
    }
    public void onBeforeUpdate(List<Account> updatedAccounts) {
        customIdSwapAccount(updatedAccounts);
    }
    public void onAfterInsert(Map<Id, Account> oldMap, Map<Id, Account> newMap) {
        createZuoraAccounts(newMap.values(), oldMap);
    }
    public void onAfterUpdate(Map<Id, Account> oldMap, Map<Id, Account> newMap) {
        createZuoraAccounts(newMap.values(), oldMap);

        List<Utility_Account_Subscription__c> uasesToCancel =
            UtilityAccountSubscriptions.getUASesForManuallyCancelledAccounts(newMap, oldMap);
        if (!uasesToCancel.isEmpty()) {
            CSCancellationService.processSubscriptionCancellations(uasesToCancel);
        }

        ZuoraAccountService.ZuoraAccountUpdate zuoraAccountsToUpdate =
            zuoraAccountService.accountsWithZuoraUpdates(oldMap, newMap);
        if (zuoraAccountsToUpdate.hasChanges()) {
            zuoraAccountService.handleAccountUpdates(zuoraAccountsToUpdate);
        }
    }

    private void customIdSwapAccount(List<Account> accountList){
        Set<String> customIds = new Set<String>( ); 
        for(Account acc : accountList) {
            if(acc.Custom_Id__c != null) {
                customIds.add(acc.Custom_Id__c);
            }
        }
        if(customIds.size() > 0){
            Map<String, BSST__c > salesIdMap = new Map<String, BSST__c >();
            for (BSST__c obj : [SELECT Id, Custom_Id__c, Partner__c FROM BSST__c WHERE Custom_Id__c IN : customIds]){
                salesIdMap.put(obj.Custom_Id__c, obj); 
            }
            for(Account acc : accountList) {
                if(salesIdMap.containsKey(acc.Custom_Id__c)){
                    acc.Sales_Representative__c = salesIdMap.get(acc.Custom_Id__c).Id;
                    acc.Partner__c = salesIdMap.get(acc.Custom_Id__c).Partner__c;
                }
            }
        }
    }

    public void preventZuoraAccountsFromDelete(List<Account> accounts) {
        for (Account account : accounts) {
            if (!String.isBlank(account.Zuora_Id__c)) {
                account.addError('This account has a Zuora Id. Delete it from Zuora first if there is no activity, ' +
                    'remove the Zuora Id, and attempt the delete again');
            }
        }
    }

    // Intended to be called from after insert or after update - can't be before insert since we need the account Id when
    // starting the batch
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private void createZuoraAccounts(List<Account> newAccounts, Map<Id, Account> oldMap) {
        Id propertyRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Property').getRecordTypeId();
        List<Account> accountsToUnsetCreateZuoraAccount = new List<Account>();
        Set<Id> accountsNeedingZuoraAccounts = new Set<Id>();
        for (Account accountInTrigger : newAccounts) {
            // We always want to unset Create_Zuora_Account__c, since it shouldn't be left on for more than a transaction
            if (accountInTrigger.Create_Zuora_Account__c) {
                Account accountNotInTrigger = new Account(
                    Id = accountInTrigger.Id,
                    Create_Zuora_Account__c = false
                );
                accountsToUnsetCreateZuoraAccount.add(accountNotInTrigger);
                // then, if it meets the conditions, we should create it.
                if ((oldMap == null || !oldMap.get(accountInTrigger.Id).Create_Zuora_Account__c) &&
                    accountInTrigger.RecordTypeId == propertyRecordTypeId &&
                    accountInTrigger.Zuora_Id__c == null) {
                    accountsNeedingZuoraAccounts.add(accountInTrigger.Id);
                }
            }
        }

        if (!accountsToUnsetCreateZuoraAccount.isEmpty()) {
            update accountsToUnsetCreateZuoraAccount;
        }

        if (!accountsNeedingZuoraAccounts.isEmpty()) {
            List<Account> propertyAccounts = AccountsSelector.selectWithSendBillsContact(accountsNeedingZuoraAccounts);
            ZuoraAccountAsyncService accountAsyncService = new ZuoraAccountAsyncService(propertyAccounts);
            Database.executeBatch(accountAsyncService, 50);
        }
    }
}