public without sharing class BillingAccountService{
    public static void updatePropertyAccount(List<Zuora__CustomerAccount__c> billingAccounts) {
        Set<Id> zAccountIds = (new Map<Id,Zuora__CustomerAccount__c>(billingAccounts)).keySet();
        checkPropertyAccountDiscrepancy(zAccountIds);
    }

    @Future
    public static void checkPropertyAccountDiscrepancy(Set<Id> accountsToCheck) {
        try {
            List<Account> propAccountsToUpdate = new List<Account>();

            List<Zuora__CustomerAccount__c> zuoraAccounts = ZuoraAccountSelector.getBillingAccountsById(accountsToCheck);

            for (Zuora__CustomerAccount__c zAccount : zuoraAccounts) {
                if (zAccount.Zuora__AutoPay__c != zAccount.Zuora__Account__r.Recurring_Billing__c) {
                    Account propAccount = new Account(
                        Id = zAccount.Zuora__Account__r.Id,
                        Recurring_Billing__c = zAccount.Zuora__AutoPay__c
                    );
                    propAccountsToUpdate.add(propAccount);
                }
            }

            if (propAccountsToUpdate.size() > 0) {
                update propAccountsToUpdate;
            }
        } catch (Exception excep){
            Logger.logNow('BillingAccountService','checkPropertyAccountDiscrepancy',excep.getMessage() + excep.getStackTraceString());
        }
    }
}