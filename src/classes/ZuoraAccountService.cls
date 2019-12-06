/**
 * Created by PeterYao on 4/30/2019.
 * Tested By: ZuoraAccountServiceTest
 */

public without sharing class ZuoraAccountService {
    @TestVisible
    private static AccountsSelector accountSelector = new AccountsSelector();

    //Going to call this for Switch
    public static void createAccounts(List<Account> propertyAccounts) {
        if (propertyAccounts.size() == 0) {
            return;
        }
        createAccounts(propertyAccounts, null);
    }

    public static void createAccountsFromLeads(List<Id> convertedLeadIds) {
        List<Lead> convertedLeads = LeadSelector.selectConvertedByIds(convertedLeadIds);
        Map<Id, Lead> accountIdToLeadMap = new Map<Id, Lead>();
        for (Lead lead : convertedLeads) {
            accountIdToLeadMap.put(lead.ConvertedAccountId, lead);
        }
        List<Account> propertyAccounts = AccountsSelector.selectWithSendBillsContact(accountIdToLeadMap.keySet());
        if (propertyAccounts.size() == 0) {
            Logger.logNow(
                'ZuoraAccountService',
                'createAccount',
                'Found no property accounts to create for these lead Ids: ' + convertedLeadIds,
                Logger.ERROR
            );
            return;
        }
        createAccounts(propertyAccounts, accountIdToLeadMap);
    }

    // Since we want to insert Zuora Contacts and update the Account with a Zuora Id as system
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static void createAccounts(List<Account> propertyAccounts, Map<Id, Lead> accountIdToLeadMap) {
        Map<Id, String> accountIdToZuoraIdMap =
            createAccountShells(propertyAccounts);

        Map<String, String> accountIdToZuoraContactIdMap =
            createContact(propertyAccounts, accountIdToZuoraIdMap);

        Map<Id, ZuoraAPI.ZuoraAccount> propertyAccountIdToZuoraAccountMap = setContactsOnAccount(accountIdToZuoraIdMap,  accountIdToZuoraContactIdMap, propertyAccounts);

        assignPaymentMethodToAccount(propertyAccountIdToZuoraAccountMap, propertyAccounts, accountIdToLeadMap);
        updateZuoraAccounts(propertyAccountIdToZuoraAccountMap.values());
        createZuoraContacts(propertyAccounts, accountIdToZuoraIdMap, accountIdToZuoraContactIdMap);

        for (Account account : propertyAccounts) {
            account.Zuora_Id__c = accountIdToZuoraIdMap.get(account.Id);
        }
        update propertyAccounts;
        Logger.flushLogs();
    }

    private static Map<Id, String> createAccountShells(List<Account> propertyAccounts) {
        // https://www.zuora.com/developer/api-reference/#operation/Action_POSTcreate
        if (propertyAccounts.size() > 50) {
            throw new Util.BWException('Only 50 accounts can be created in Zuora at a time through this method');
        }
        ZuoraAPI.ActionItems actionItems = new ZuoraAPI.ActionItems();
        actionItems.type = 'Account';
        for (Account propertyAccount : propertyAccounts) {
            ZuoraAPI.ZuoraAccount zuoraAccount = new ZuoraAPI.ZuoraAccount(propertyAccount);
            actionItems.objects.add(zuoraAccount);
        }

        HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('POST', '/v1/action/create', actionItems, false);
        Map<Id, String> accountIdToZuoraIdMap = new Map<Id, String>();
        if (response.getStatusCode() != 200) {
            throw new Util.BWException('Received status ' + response.getStatusCode() + ': ' + response.getBody());
        }
        List<ZuoraAPI.SaveResult> saveResults =
            (List<ZuoraAPI.SaveResult>) System.JSON.deserialize(response.getBody(), List<ZuoraAPI.SaveResult>.class);
        if (saveResults.size() != propertyAccounts.size()) {
            throw new Util.BWException('Received ' + saveResults.size() + ' result when creating ' + propertyAccounts.size() + ' accounts');
        }
        for (Integer i = 0; i < saveResults.size(); i++) {
            accountIdToZuoraIdMap.put(propertyAccounts[i].Id, saveResults[i].Id);
        }
        return accountIdToZuoraIdMap;
    }

    private static void assignPaymentMethodToAccount(Map<Id, ZuoraAPI.ZuoraAccount> accountToZuoraAccountMap, List<Account> propertyAccountList, Map<Id, Lead> accountIdToLeadMap) {
        for (Account propertyAccount : propertyAccountList) {
            ZuoraAPI.ZuoraAccount zuoraAccount = accountToZuoraAccountMap.get(propertyAccount.Id);
            zuoraAccount.Status = 'Active';
            if (accountIdToLeadMap != null) {
                Lead convertedLead = accountIdToLeadMap.get(propertyAccount.Id);
                if (convertedLead.Zuora_Payment_Ref_Id_Expiration_Date__c != null &&
                    convertedLead.Zuora_Payment_Ref_Id_Expiration_Date__c.getTime() > Datetime.now().getTime()) {
                    zuoraAccount.DefaultPaymentMethodId = convertedLead.Zuora_Payment_Ref_Id__c;
                } else {
                    Logger.logLater(
                        'ZuoraAccountService',
                        'createAccount',
                        'Found an expired payment method for Lead Id ' + convertedLead.Id + ' at ' + Datetime.now().getTime(),
                        Logger.ERROR
                    );
                }
            } else if (accountIdToLeadMap == null && propertyAccount.Zuora_Payment_Ref_Id__c != null) {
                zuoraAccount.DefaultPaymentMethodId = propertyAccount.Zuora_Payment_Ref_Id__c;
            }

            if (zuoraAccount.DefaultPaymentMethodId != null ) {
                // As of June 2019, if a lead provides a payment method, it is for autopay, so we'll set autopay to true
                zuoraAccount.AutoPay = true;
            }
        }


    }

    @TestVisible
    private static Map<String, String> createContact(List<Account> propertyAccounts, Map<Id, String> accountIdToZuoraIdMap) {
        ZuoraAPI.ActionItems actionItems = new ZuoraAPI.ActionItems();
        actionItems.type = 'Contact';
        for (Account account : propertyAccounts) {
            ZuoraAPI.ZuoraContact zuoraContact = new ZuoraAPI.ZuoraContact();
            actionItems.objects.add(zuoraContact);
            zuoraContact.AccountId = accountIdToZuoraIdMap.get(account.Id);
            zuoraContact.Address1 = account.Address_Attn__c;
            zuoraContact.Address2 = account.BillingStreet;
            zuoraContact.City = account.BillingCity;
            zuoraContact.State = account.BillingState;
            zuoraContact.PostalCode = account.BillingPostalCode;
            zuoraContact.Country = account.BillingCountry;
            if (account.Send_Bills_Contact__c == null) {
                zuoraContact.FirstName = 'Default';
                zuoraContact.LastName = 'Billing Contact';
                zuoraContact.CRM_ID_Zcustom = account.Id;
            } else {
                zuoraContact.CRM_ID_Zcustom = account.Send_Bills_Contact__c;
                zuoraContact.FirstName = account.Send_Bills_Contact__r.FirstName;
                zuoraContact.LastName = account.Send_Bills_Contact__r.LastName;
                if (Util.getSystemPropertyCheckbox('Use_Actual_Email_For_Zuora_Upload__c')) {
                    zuoraContact.PersonalEmail = account.Send_Bills_Contact__r.Email;
                } else if (String.isEmpty(Util.getSystemPropertyString('Zuora_Contact_Substitution_Email__c'))) {
                    zuoraContact.PersonalEmail = account.Send_Bills_Contact__r.Email + '.disabled';
                } else {
                    zuoraContact.PersonalEmail = Util.getSystemPropertyString('Zuora_Contact_Substitution_Email__c');
                }
            }
        }
        HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('POST', '/v1/action/create', actionItems, false);
        // There might be multiple property accounts with the same contact - we'll create a duplicate contact
        // under each corresponding zuora account
        Map<String, String> zuoraAccountIdToZuoraContactIdMap = new Map<String, String>();
        if (response.getStatusCode() != 200) {
            throw new Util.BWException('Received status ' + response.getStatusCode() + ': ' + response.getBody());
        }
        List<ZuoraAPI.SaveResult> saveResults =
            (List<ZuoraAPI.SaveResult>) System.JSON.deserialize(response.getBody(), List<ZuoraAPI.SaveResult>.class);
        if (saveResults.size() != propertyAccounts.size()) {
            throw new Util.BWException('Received ' + saveResults.size() + ' result when creating ' + propertyAccounts.size() + ' contacts');
        }
        for (Integer i = 0; i < saveResults.size(); i++) {
            zuoraAccountIdToZuoraContactIdMap.put(accountIdToZuoraIdMap.get(propertyAccounts[i].Id), saveResults[i].Id);
        }
        return zuoraAccountIdToZuoraContactIdMap;
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private static Map<Id, ZuoraAPI.ZuoraAccount> setContactsOnAccount(Map<Id, String> accountIdToZuoraAccountIdMap,
        Map<String, String> zuoraAccountIdToZuoraContactIdMap,
        List<Account> propertyAccounts) {

        Map<Id, ZuoraAPI.ZuoraAccount> accountToZuoraAccountMap = new Map<Id, ZuoraAPI.ZuoraAccount>();

        for (Account account : propertyAccounts) {
            ZuoraAPI.ZuoraAccount zuoraAccount = new ZuoraAPI.ZuoraAccount();
            accountToZuoraAccountMap.put(account.Id, zuoraAccount);
            String zuoraAccountId = accountIdToZuoraAccountIdMap.get(account.Id);
            zuoraAccount.Id = zuoraAccountId;
            zuoraAccount.BillToId = zuoraAccountIdToZuoraContactIdMap.get(zuoraAccountId);
            zuoraAccount.SoldToId = zuoraAccountIdToZuoraContactIdMap.get(zuoraAccountId);
        }
        return accountToZuoraAccountMap;
    }

    private static void createZuoraContacts(List<Account> propertyAccounts, Map<Id, String> accountIdToZuoraAccountIdMap, Map<String, String> zuoraAccountIdToZuoraContactIdMap ) {
        List<Zuora_Contact__c> zuoraContacts = new List<Zuora_Contact__c>();
        for (Account account : propertyAccounts) {
            String zuoraAccountId = accountIdToZuoraAccountIdMap.get(account.Id);
            Zuora_Contact__c zuoraContact = new Zuora_Contact__c(
                Contact__c = account.Send_Bills_Contact__c,
                Zuora_Id__c = zuoraAccountIdToZuoraContactIdMap.get(zuoraAccountId)
            );
            zuoraContacts.add(zuoraContact);
        }

        //Cant do DML before callout (ZuoraAPIHelper.update)
        insert zuoraContacts;

    }

    public void handleAccountUpdates(ZuoraAccountUpdate zuoraAccountUpdates) {
        if (!zuoraAccountUpdates.accountsWithAddressChange.isEmpty()) {
            ZuoraAccountService.handleAccountAddressUpdatesFuture(zuoraAccountUpdates.getAccountWithAddressChangeIds());
        }
        if (!zuoraAccountUpdates.accountsWithNameChange.isEmpty()) {
            ZuoraAccountService.handleAccountNameUpdates(zuoraAccountUpdates.getAccountWithNameChangeIds());
        }
    }

    // Not future because it starts a batch (which can't be done from future)
    @TestVisible
    private static void handleAccountNameUpdates(Set<Id> accountIds) {
        try {
            ZuoraAPI.ActionItems actionItems = new ZuoraAPI.ActionItems();
            List<Account> accounts = accountSelector.selectAll(accountIds);
            actionItems.type = 'Account';
            for (Account account : accounts) {
                ZuoraAPI.ZuoraAccount zuoraAccount = new ZuoraAPI.ZuoraAccount();
                zuoraAccount.Id = account.Zuora_Id__c;
                zuoraAccount.Name = account.Name;
                actionItems.objects.add(zuoraAccount);
            }
            ZuoraGenericBatchOperation genericBatchOperation = new ZuoraGenericBatchOperation(actionItems, ZuoraAPIHelper.ActionDMLOperations.DMLUPDATE);
            Database.executeBatch(genericBatchOperation, 50);
        } catch (Exception e) {
            Logger.logLater(
                'ZuoraAccountService',
                'handleAccountNameUpdatesFuture',
                'Caught exception: ' + e.getMessage() + '\n' + e.getStackTraceString(),
                Logger.ERROR
            );
        } finally {
            Logger.flushLogs();
        }
    }

    // Future because callouts need to happen before DML. Future methods can't start batch, and these would need to be
    // chained (first create contacts then update accounts with them), so we'll limit to 50 updates at a time...
    @Future(Callout=true)
    // We should insert Zuora Contacts independent of user permissions
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public static void handleAccountAddressUpdatesFuture(Set<Id> accountIds) {
        try {
            if (accountIds.size() > ZuoraAPIHelper.maxActionUpdateRecords) {
                throw new Util.FatalBWException('Sorry, this does not yet support updating more than 50 addresses at a time. ' +
                    'These account addresses were not updated: ' + JSON.serialize(accountIds));
            }
            List<Account> accounts = accountSelector.selectAll(accountIds);
            Map<Id, String> accountIdToZuoraIdMap = new Map<Id, String>();
            for (Account account : accounts) {
                if (account.Zuora_Id__c == null) {
                    Logger.logLater('ZuoraAccountService', 'handleAccountAddressUpdatesFuture', 'Found account without a Zuora Id: ' + account.Id, Logger.ERROR);
                } else {
                    accountIdToZuoraIdMap.put(account.Id, account.Zuora_Id__c);
                }
            }
            // This doesn't support switching to an existing Send Bills Contact without creating a duplicate. For example, if
            // we start with Contact 1 as Send Bills Contact, change to Contact 2, and then back to Contact 1, we'll end up with
            // two Contact 1's in Zuora. The one referenced as Bill To will have the correct info. Because this use case
            // doesn't happen often, I don't think it's worth the added complexity.
            Map<String, String> accountIdToZuoraContactIdMap =
                createContact(accounts, accountIdToZuoraIdMap);

            Map<Id, ZuoraAPI.ZuoraAccount> propertyAccountIdToZuoraAccountMap = setContactsOnAccount(accountIdToZuoraIdMap,  accountIdToZuoraContactIdMap, accounts);
            updateZuoraAccounts(propertyAccountIdToZuoraAccountMap.values());
            createZuoraContacts(accounts, accountIdToZuoraIdMap, accountIdToZuoraContactIdMap);

        } catch (Exception e) {
            Logger.logLater(
                'ZuoraAccountService',
                'handleAccountAddressUpdatesFuture',
                'Caught exception: ' + e.getMessage() + '\n' + e.getStackTraceString(),
                Logger.ERROR
            );
        } finally {
            Logger.flushLogs();
        }
    }

    public static void updateZuoraAccounts(List<ZuoraAPI.ZuoraAccount> zuoraAccounts){
        ZuoraAPI.ActionItems actionItems = new ZuoraAPI.ActionItems();
        actionItems.type = 'Account';

        for (ZuoraAPI.ZuoraAccount account : zuoraAccounts) {
            actionItems.objects.add(account);
        }

        ZuoraAPIHelper.actionUpdate(actionItems);
    }

    public class ZuoraAccountUpdate {
        List<Account> accountsWithNameChange;
        List<Account> accountsWithAddressChange;
        public ZuoraAccountUpdate() {
            this.accountsWithNameChange = new List<Account>();
            this.accountsWithAddressChange = new List<Account>();
        }
        public Boolean hasChanges() {
            return (!accountsWithAddressChange.isEmpty() || !accountsWithNameChange.isEmpty());
        }
        public Set<Id> getAccountWithAddressChangeIds() {
            Set<Id> accountIds = new Set<Id>();
            for (Account account : accountsWithAddressChange) {
                accountIds.add(account.Id);
            }
            return accountIds;
        }
        public Set<Id> getAccountWithNameChangeIds() {
            Set<Id> accountIds = new Set<Id>();
            for (Account account : accountsWithNameChange) {
                accountIds.add(account.Id);
            }
            return accountIds;
        }
    }

    public ZuoraAccountUpdate accountsWithZuoraUpdates(Map<Id, Account> oldAccounts, Map<Id, Account> newAccounts) {
        ZuoraAccountUpdate zuoraAccountUpdate = new ZuoraAccountUpdate();
        for (Account account : newAccounts.values()) {
            if (account.Zuora_Id__c == null) {
                continue;
            }
            if (accountNeedsAddressUpdate(oldAccounts.get(account.Id), account)) {
                zuoraAccountUpdate.accountsWithAddressChange.add(account);
            }
            if (!account.Name.equals(oldAccounts.get(account.Id).Name)) {
                zuoraAccountUpdate.accountsWithNameChange.add(account);
            }
        }
        return zuoraAccountUpdate;
    }

    private static final List<String> zuoraFieldsToUpdate =
        new List<String>{'Address_Attn__c','BillingStreet','BillingCity','BillingState','BillingPostalCode','BillingCountry','Send_Bills_Contact__c'};

    @TestVisible
    private Boolean accountNeedsAddressUpdate(Account oldAccount, Account newAccount) {
        if (newAccount.Zuora_Id__c == null) {
            return false;
        }
        for (String fieldName : zuoraFieldsToUpdate) {
            if (oldAccount.get(fieldName) != newAccount.get(fieldName)) {
                return true;
            }
        }
        return false;
    }
}