/**
 * Created by peteryao on 7/27/20.
 * Tested By: MergeHelperTest
 */

public without sharing class MergeHelper {
    @TestVisible
    private static ZuoraSubscriptionService subscriptionService = new ZuoraSubscriptionService();
    @TestVisible
    private static AccountsSelector accountsSelector = new AccountsSelector();
    @TestVisible
    private static ZuoraContactSelector zuoraContactSelector = new ZuoraContactSelector();
    @TestVisible
    private static fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{
        Account.SObjectType,
        Zuora_Contact__c.SObjectType
    });

    public void prepForMerge(Id propertyAccountId) {
        uow.registerWork(new Logger());
        Account propertyAccount = accountsSelector.selectOne(propertyAccountId);
        if (propertyAccount.Zuora_Id__c != null) {
            validateAccountHasNoSubscriptions(propertyAccount);

            List<Zuora_Contact__c> zuoraContacts = getZuoraContactsToDelete(propertyAccount);
            uow.registerDeleted(zuoraContacts);
            Logger.logLater('MergeHelper', 'prepForZuoraMerge', 'Zuora_Contacts being deleted: ' + zuoraContacts, Logger.INFO);

            deleteAccountAndContactsInZuora(propertyAccount);
            Logger.logLater('MergeHelper', 'prepForZuoraMerge', 'Zuora Accounts being deleted: ' + propertyAccount.Zuora_Id__c, Logger.INFO);
        }

        propertyAccount.Zuora_Id__c = null;
        propertyAccount.Name = propertyAccount.Name + ' dupe';
        uow.registerDirty(propertyAccount);
        uow.commitWork();
    }

    private static void validateAccountHasNoSubscriptions(Account propertyAccount) {
        ZuoraAPI.SubscriptionsByAccount subscriptionsByAccount =
            subscriptionService.getSubscriptionsByAccount(propertyAccount.Account_Number__c);
        if (subscriptionsByAccount.subscriptions.size() > 0) {
            throw new Util.BWException('\nDid not delete the Zuora account because there are existing subscriptions!\n' +
                JSON.serialize(subscriptionsByAccount));
        }
    }

    private static void deleteAccountAndContactsInZuora(Account propertyAccount) {
        ZuoraAPI.ActionItems actionItems = new ZuoraAPI.ActionItems();
        actionItems.type = 'Account';
        actionItems.ids.add(propertyAccount.Zuora_Id__c);
        ZuoraAPIHelper.genericAction(actionItems, ZuoraAPIHelper.ActionDMLOperations.DMLDELETE);
    }

    private static List<Zuora_Contact__c> getZuoraContactsToDelete(Account propertyAccount) {
        String contacts = ZuoraAPIHelper.query('SELECT Id FROM Contact WHERE AccountId = \'' + propertyAccount.Zuora_Id__c + '\'', false);
        ZuoraAPI.ZuoraQueryResult queryResult = (ZuoraAPI.ZuoraQueryResult) JSON.deserialize(contacts, ZuoraAPI.ZuoraQueryResult.class);
        Set<String> contactIds = new Set<String>();
        for (ZuoraAPI.ZuoraQueryResultRecord record : queryResult.records) {
            contactIds.add(record.Id);
        }
        return zuoraContactSelector.selectAll(contactIds);
    }
}