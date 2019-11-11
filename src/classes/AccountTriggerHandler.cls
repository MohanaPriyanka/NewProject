//Test: AccountTriggerHandlerTestClass, CSCancellationServiceTest

public without sharing class AccountTriggerHandler {

    public void onBeforeInsert(List<Account> newAccounts) {
        customIdSwapAccount(newAccounts);
    }
    public void onBeforeUpdate(List<Account> updatedAccounts) {
        customIdSwapAccount(updatedAccounts);
    }

    public void onAfterUpdate(Map<Id, Account> oldMap, Map<Id, Account> newMap) {
        List<Utility_Account_Subscription__c> uasesToCancel =
            UtilityAccountSubscriptions.getUASesForManuallyCancelledAccounts(newMap, oldMap);
        if (!uasesToCancel.isEmpty()) {
            CSCancellationService.processSubscriptionCancellations(uasesToCancel);
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
}