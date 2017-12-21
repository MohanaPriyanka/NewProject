 public with sharing class AccountTriggerHandler {
    private boolean m_isExecuting = false;
    private integer BatchSize = 0;
    
    public AccountTriggerHandler(boolean isExecuting, integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
    }
    public void OnBeforeInsert(List<Account> newAccounts){
        customIdSwapAccount(newAccounts);
    }
    public void OnBeforeUpdate(List<Account> oldAccounts, List<Account> updatedAccounts, Map<ID, Account> oldAccountMap, Map<ID, Account> newAccountMap){
        customIdSwapAccount(updatedAccounts);
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
}