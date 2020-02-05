/**
 * Created by JordanPentaleri on 1/30/2020.
 * Tested By : ClientBrandingServiceTest
 */

public with sharing class ClientBrandingService implements Queueable {
    @TestVisible
    private AccountsSelector acctSelector = new AccountsSelector();
    @TestVisible
    private UASSelector uasSelector = new UASSelector();
    @TestVisible
    private OpportunitiesSelector oppSelector = new OpportunitiesSelector();

    public Set<Id> sssIdWithChangedClientBrandKey;

    public void execute(QueueableContext context){
        Set<Id> parentAccountIds = new Set<Id>();
        if (sssIdWithChangedClientBrandKey != null){
            List<Opportunity> oppList = oppSelector.getOppsFromSSS(sssIdWithChangedClientBrandKey);
            for (Opportunity opp : oppList){
                parentAccountIds.add(opp.Account.Parent_Account__c);
            }
            updateClientBrandKey(parentAccountIds);
        }
    }

    public void handleEvent(List<Subscription_Change_Event__e> changeEvents){
        Set<Id> parentAccountIds = new Set<Id>();
        Set<Id> propertyAccountIds = new Set<Id>();

        for (Subscription_Change_Event__e changeEvent : changeEvents){
            propertyAccountIds.add(changeEvent.Property_Account_Id__c);
        }
        List<Account> propertyAccounts = acctSelector.getAccountsById(propertyAccountIds);
        for (Account prop: propertyAccounts){
            parentAccountIds.add(prop.Parent_Account__c);
        }
        updateClientBrandKey(parentAccountIds);
    }

    public void updateClientBrandKey (Set<Id> parentAccountIds) {
        List<AggregateResult> uasSummary = uasSelector.getBrandKeySummary(parentAccountIds);
        Map<Id, Account> allAccounts = getParentAccountBrandKey(getPropertyAccountBrandKey(uasSummary));
        List<Account> accountsNeedingUpdate = checkForDifferences(allAccounts);
        if (accountsNeedingUpdate.size() > 0){
            update accountsNeedingUpdate;
        }
    }

    public Map<Id, Account> getPropertyAccountBrandKey(List<AggregateResult> uasSummary){
        Map<Id, Account> accountMap = new Map<Id, Account>();

        for (AggregateResult aggregateResult : uasSummary)  {
            String sssBrandKey = (String)aggregateResult.get('sssBrandKey');
            String entityBrandKey = (String)aggregateResult.get('entityBrandKey');
            String propertyAccountId = (String)aggregateResult.get('propertyAccount');
            String parentAccountId = (String)aggregateResult.get('parentAccount');

            Account propertyAccount = new Account(
                Id = propertyAccountId,
                Parent_Account__c = parentAccountId
            );
            // If blank, set to BluewaveLogo
            if (sssBrandKey != null){
                propertyAccount.Client_Brand_Key__c = sssBrandKey;
            } else if (entityBrandKey != null) {
                propertyAccount.Client_Brand_Key__c = entityBrandKey;
            } else {
                propertyAccount.Client_Brand_Key__c = 'BluewaveLogo';
            }
            if (accountMap.containsKey(propertyAccount.Id)
                && accountMap.get(propertyAccount.Id).Client_Brand_Key__c != propertyAccount.Client_Brand_Key__c){
                propertyAccount.Client_Brand_Key__c = 'BluewaveLogo';
            }
            accountMap.put(propertyAccount.Id,propertyAccount);
        }
        return accountMap;
    }

    public Map<Id, Account> getParentAccountBrandKey(Map<Id, Account> accountMap){
        for (Account property : accountMap.values()){
            Account propertyAccount = accountMap.get(property.Id);
            Account parentAccount = new Account(
                Id = property.Parent_Account__c
            );
            if (accountMap.containsKey(parentAccount.Id)
                && accountMap.get(parentAccount.Id).Client_Brand_Key__c != propertyAccount.Client_Brand_Key__c){
                parentAccount.Client_Brand_Key__c = 'BluewaveLogo';
            } else {
                parentAccount.Client_Brand_Key__c = propertyAccount.Client_Brand_Key__c;
            }
            accountMap.put(parentAccount.Id, parentAccount);
        }
        return accountMap;
    }

    public List<Account> checkForDifferences(Map<Id, Account> accountMap){
        List<Account> accountsWithChangedValues = new List<Account>();
        List<Account> accountsBeforeUpdate = acctSelector.getAccountsById(accountMap.keySet());

        for (Account oldValue : accountsBeforeUpdate){
            if(oldValue.Client_Brand_Key__c != accountMap.get(oldValue.Id).Client_Brand_Key__c){
                accountsWithChangedValues.add(accountMap.get(oldValue.Id));
            }
        }
        return accountsWithChangedValues;
    }
}