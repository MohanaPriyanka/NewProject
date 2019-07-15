/**
 * Created by PeterYao on 4/30/2019.
 * Tested By: ZuoraAccountServiceTest
 */

public without sharing class ZuoraAccountService {
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

    private static void createAccounts(List<Account> propertyAccounts, Map<Id, Lead> accountIdToLeadMap) {
        Map<Id, String> accountIdToZuoraIdMap =
            createAccountShells(accountIdToLeadMap, propertyAccounts);

        Map<String, String> accountIdToZuoraContactIdMap =
            createContact(propertyAccounts, accountIdToZuoraIdMap);

        List<Zuora_Contact__c> zuoraContacts =
            finishAccountCreation(accountIdToZuoraIdMap, accountIdToZuoraContactIdMap, propertyAccounts);

        insert zuoraContacts;
        for (Account account : propertyAccounts) {
            account.Zuora_Id__c = accountIdToZuoraIdMap.get(account.Id);
        }
        update propertyAccounts;
        Logger.flushLogs();
    }

    private static Map<Id, String> createAccountShells(Map<Id, Lead> accountIdToConvertedLeadMap, List<Account> propertyAccounts) {
        // https://www.zuora.com/developer/api-reference/#operation/Action_POSTcreate
        if (propertyAccounts.size() > 50) {
            throw new Util.BWException('Only 50 accounts can be created in Zuora at a time through this method');
        }
        ZuoraAPI.ActionItems actionItems = new ZuoraAPI.ActionItems();
        actionItems.type = 'Account';
        for (Account propertyAccount : propertyAccounts) {
            ZuoraAPI.ZuoraAccount zuoraAccount = new ZuoraAPI.ZuoraAccount();
            actionItems.objects.add(zuoraAccount);
            zuoraAccount.AccountNumber = propertyAccount.Account_Number__c;
            zuoraAccount.AutoPay = false;
            zuoraAccount.Batch = 'Batch1';
            // Since we're setting the Usage End Date to be the first of the month, a Bill Cycle Day of 10 will include
            // it, and will also allow us to have invoice dates as early as the 13th (which we need to import history)
            zuoraAccount.BillCycleDay = 10;
            zuoraAccount.CrmId = propertyAccount.Id;
            zuoraAccount.Currency_Zreserved = 'USD';
            zuoraAccount.Name = propertyAccount.Name;
            zuoraAccount.PaymentTerm = 'Net 30';
            zuoraAccount.Status = 'Draft';
            // Assign the payment method if hasn't expired
            if (accountIdToConvertedLeadMap == null) {
                continue;
            }
            Lead convertedLead = accountIdToConvertedLeadMap.get(propertyAccount.Id);
            if (convertedLead.Zuora_Payment_Ref_Id_Expiration_Date__c != null &&
                convertedLead.Zuora_Payment_Ref_Id_Expiration_Date__c.getTime() > Datetime.now().getTime()) {
                zuoraAccount.DefaultPaymentMethodId = convertedLead.Zuora_Payment_Ref_Id__c;
                // As of June 2019, if a lead provides a payment method, it is for autopay, so we'll set autopay to true
                zuoraAccount.AutoPay = true;
            } else {
                Logger.logLater(
                    'ZuoraAccountService',
                    'createAccount',
                    'Found an expired payment method for Lead Id ' + convertedLead.Id + ' at ' + Datetime.now().getTime(),
                    Logger.ERROR
                );
            }
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

    @TestVisible
    private static Map<String, String>  createContact(List<Account> propertyAccounts, Map<Id, String> accountIdToZuoraIdMap) {
        ZuoraAPI.ActionItems actionItems = new ZuoraAPI.ActionItems();
        actionItems.type = 'Contact';
        for (Account account : propertyAccounts) {
            ZuoraAPI.ZuoraContact zuoraContact = new ZuoraAPI.ZuoraContact();
            actionItems.objects.add(zuoraContact);
            zuoraContact.AccountId = accountIdToZuoraIdMap.get(account.Id);
            if (account.Send_Bills_Contact__c == null) {
                zuoraContact.FirstName = 'Default';
                zuoraContact.LastName = 'Billing Contact';
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

    private static List<Zuora_Contact__c> finishAccountCreation(Map<Id, String> accountIdToZuoraAccountIdMap, Map<String, String> zuoraAccountIdToZuoraContactIdMap,
        List<Account> propertyAccounts) {
        List<Zuora_Contact__c> zuoraContacts = new List<Zuora_Contact__c>();
        ZuoraAPI.ActionItems actionItems = new ZuoraAPI.ActionItems();
        actionItems.type = 'Account';
        for (Account account : propertyAccounts) {
            ZuoraAPI.ZuoraAccount zuoraAccount = new ZuoraAPI.ZuoraAccount();
            actionItems.objects.add(zuoraAccount);
            String zuoraAccountId = accountIdToZuoraAccountIdMap.get(account.Id);
            zuoraAccount.Id = zuoraAccountId;
            zuoraAccount.BillToId = zuoraAccountIdToZuoraContactIdMap.get(zuoraAccountId);
            zuoraAccount.SoldToId = zuoraAccountIdToZuoraContactIdMap.get(zuoraAccountId);
            zuoraAccount.Status = 'Active';
            Zuora_Contact__c zuoraContact = new Zuora_Contact__c(
                Contact__c = account.Send_Bills_Contact__c,
                Zuora_Id__c = zuoraAccountIdToZuoraContactIdMap.get(zuoraAccountId)
            );
            zuoraContacts.add(zuoraContact);
        }
        HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('PUT', '/v1/action/update/', actionItems, false);
        if (response.getStatusCode() != 200) {
            throw new Util.BWException('Received status ' + response.getStatusCode() + ': ' + response.getBody());
        }
        List<ZuoraAPI.SaveResult> saveResults = (List<ZuoraAPI.SaveResult>) System.JSON.deserialize(response.getBody(), List<ZuoraAPI.SaveResult>.class);
        if (saveResults.size() != propertyAccounts.size()) {
            throw new Util.BWException('Received ' + saveResults.size() + ' when updating ' + propertyAccounts.size() + ' accounts');
        }
        return zuoraContacts;
    }
}