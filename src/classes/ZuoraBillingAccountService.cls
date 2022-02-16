/*
   Tested By: ZuoraBillingAccountServiceTest
 */

@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class ZuoraBillingAccountService implements Schedulable, ZuoraDataQueryService.Processor {
    @TestVisible private static ZuoraAccountSelector zuoraAcctSelector = new ZuoraAccountSelector();
    @TestVisible private static CaseFactory caseFactory = new CaseFactory();
    private static AccountsSelector accountsSelector = new AccountsSelector();
    @TestVisible private static CaseSelector caseSelector = new CaseSelector();
    @TestVisible private static fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
        new List<SObjectType>{
            Case.SObjectType
        }
    );
    @TestVisible private static final String SUPPRESS_COLLECTIONS_TEMPORARILY = 'Suppress collections until no longer past due';
    @TestVisible private static final String SUPPRESS_COLLECTIONS_PERMANENTLY = 'Suppress collections forever';

    public void checkPropertyAccountDiscrepancy(List<Zuora__CustomerAccount__c> billingAccounts) {
        checkPropertyAccountDiscrepancyFuture(CollectionUtil.toIds(CollectionUtil.getIds(billingAccounts)));
    }

    public void execute(SchedulableContext ctx) {
        startDaysPastDueUpdate();
    }

    @Future
    // Future methods must be declared as static, and can't have sobject parameters (like List<Zuora__CustomerAccount__c>)
    private static void checkPropertyAccountDiscrepancyFuture(Set<Id> accountsToCheck) {
        try {
            List<Account> propAccountsToUpdate = new List<Account>();
            List<Zuora__CustomerAccount__c> zuoraAccounts = zuoraAcctSelector.getBillingAccountsById(accountsToCheck);

            for (Zuora__CustomerAccount__c zAccount : zuoraAccounts) {
                if (zAccount.Zuora__AutoPay__c != zAccount.Zuora__Account__r.Recurring_Billing__c) {
                    Account propAccount = new Account(
                        Id = zAccount.Zuora__Account__r.Id,
                        Recurring_Billing__c = zAccount.Zuora__AutoPay__c,
                        Autopay_Date_Last_Enrolled__c = zAccount.Zuora__AutoPay__c ? Date.today() : null
                    );
                    propAccountsToUpdate.add(propAccount);
                }
            }

            Util.updateSObjs(propAccountsToUpdate);
        } catch (Exception excep) {
            Logger.logNow('ZuoraBillingAccountService', 'checkPropertyAccountDiscrepancy', excep.getMessage() + '\n' + excep.getStackTraceString());
        }
    }

    public void setBillingAccountOnPropertyAccount(List<Zuora__CustomerAccount__c> billingAccounts) {
        setBillingAccountOnPropertyAccountFuture(CollectionUtil.toIds(CollectionUtil.getIds(billingAccounts)));
    }

    @Future
    private static void setBillingAccountOnPropertyAccountFuture(Set<Id> billingAccountsInserted) {
        try {
            List<Account> propAccountsToUpdate = new List<Account>();
            List<Zuora__CustomerAccount__c> zuoraAccounts = zuoraAcctSelector.getBillingAccountsById(billingAccountsInserted);

            for (Zuora__CustomerAccount__c zAccount : zuoraAccounts) {
                propAccountsToUpdate.add(new Account(
                    Id = zAccount.Zuora__Account__r.Id,
                    Billing_Account__c = zAccount.Id
                ));
            }
            update propAccountsToUpdate;
        } catch (Exception e) {
            Logger.logNow('ZuoraBillingAccountService', 'setBillingAccountOnPropertyAccountFuture', e.getMessage() + '\n' + e.getStackTraceString());
        }
    }

    @TestVisible
    private void startDaysPastDueUpdate() {
        try {
            ZuoraDataQueryService.ProcessingParameter finishMethod = new ZuoraDataQueryService.ProcessingParameter();
            finishMethod.className = 'ZuoraBillingAccountService';
            String queryString;
            queryString = ZuoraInvoiceSelector.getOutstandingBalanceByAccountQuery();
            ZuoraDataQueryService.callFromApex(queryString, finishMethod);
        } catch (Exception excep) {
            Logger.logNow('ZuoraBillingAccountService', 'startDaysPastDueUpdate', excep.getMessage() + excep.getStackTraceString());
        }
    }

    public void executePostQueryJob(ZuoraDataQueryService.ProcessingParameter parameter, String response) {
        updateDaysPastDue(response);
    }

    @TestVisible
    private void updateDaysPastDue(String queryResponse) {
        List<Account> accountsToUpdate = new List<Account>();
        Map<String, AccountSummary> zuoraIdToAccountSummary = summarizeBalanceQueryResult(queryResponse);
        Set<Id> currentParentAccountIds = new Set<Id>();
        List<Zuora__CustomerAccount__c> zuoraBillingAccounts = zuoraAcctSelector.getAllBillingAccounts();
        for (Zuora__CustomerAccount__c zuoraAccount : zuoraBillingAccounts) {
            String zuoraId = zuoraAccount.Zuora__Zuora_Id__c;
            Account propertyToUpdate = new Account(
                Id = zuoraAccount.Zuora__Account__r.Id,
                Suppress_Collections__c = zuoraAccount.Zuora__Account__r.Suppress_Collections__c
            );

            AccountSummary accountSummary = zuoraIdToAccountSummary.get(zuoraId);
            setAccountPastDueFields(accountSummary, propertyToUpdate);
            registerPropertyForUpdate(propertyToUpdate, zuoraAccount, accountsToUpdate);
            unsetSuppressCollections(propertyToUpdate);

            if(pastDueFieldChanged(propertyToUpdate, zuoraAccount) && noLongerPastDue(propertyToUpdate)) {
                currentParentAccountIds.add(zuoraAccount.Zuora__Account__r.Parent_Account__c);
            }

            if (inBadDebtGracePeriod(zuoraAccount) &&
                noLongerPastDue(propertyToUpdate)) {
                uow.registerNew(getCaseToReactivateCustomer(zuoraAccount));
            }
        }

        if (accountsToUpdate.size() > 200) {
            Database.executeBatch(new GenericBatchDMLOperation(accountsToUpdate, 'Update'));
        } else {
            Util.updateSObjs(accountsToUpdate);
        }

        closeOpenCollectionCasesForCurrentAccounts(currentParentAccountIds); // Close out open cases before creating new cases to Reactivate certain customers
        uow.commitWork();
    }

    @TestVisible
    private Account unsetSuppressCollections(Account propertyToUpdate) {
        if (propertyToUpdate.Suppress_Collections__c == SUPPRESS_COLLECTIONS_TEMPORARILY &&
            noLongerPastDue(propertyToUpdate)) {
            propertyToUpdate.Suppress_Collections__c = null;
        }
        return propertyToUpdate;
    }

    private void registerPropertyForUpdate(Account propertyToUpdate, Zuora__CustomerAccount__c zuoraAccount, List<Account> accountsToUpdate) {
        if (pastDueFieldChanged(propertyToUpdate, zuoraAccount)) {
            accountsToUpdate.add(propertyToUpdate);
        }
    }

    private Boolean inBadDebtGracePeriod(Zuora__CustomerAccount__c zuoraAccount) {
        return zuoraAccount.Zuora__Account__r.Days_Past_Due__c >= CSCancellationScheduler.DAYS_PAST_DUE_DEACTIVATION_TRIGGER &&
            zuoraAccount.Zuora__Account__r.Days_Past_Due__c < CSCancellationScheduler.DAYS_PAST_DUE_BAD_DEBT_TRIGGER;
    }

    private Boolean pastDueFieldChanged(Account propertyToUpdate, Zuora__CustomerAccount__c zuoraAccount) {
        return propertyToUpdate.Max_Overdue_Due_Date_Zuora__c != zuoraAccount.Zuora__Account__r.Max_Overdue_Due_Date_Zuora__c ||
            propertyToUpdate.Last_Bill_Send_Date_New_Charges_Zuora__c != zuoraAccount.Zuora__Account__r.Last_Bill_Send_Date_New_Charges_Zuora__c;
    }

    private void setAccountPastDueFields(AccountSummary accountSummary, Account propertyToUpdate) {
        if (accountSummary != null) {
            propertyToUpdate.Max_Overdue_Due_Date_Zuora__c = accountSummary.MinDueDate;
            propertyToUpdate.Last_Bill_Send_Date_New_Charges_Zuora__c = accountSummary.LastBillSendDate;
        } else {
            // No invoices or debit memos with a balance were returned for that account, so set to null:
            propertyToUpdate.Max_Overdue_Due_Date_Zuora__c = null;
            propertyToUpdate.Last_Bill_Send_Date_New_Charges_Zuora__c = null;
        }
    }

    private Boolean allPropertyAccountsAreCurrent(List<Account> childPropertyAccounts) {
        Boolean allCurrent = true;
        for (Account acc : childPropertyAccounts) {
            if (acc.Max_Overdue_Due_Date_Zuora__c != null) {
                allCurrent = false;
            }
        }
        return allCurrent;
    }

    private void closeOpenCollectionCasesForCurrentAccounts(Set<Id> parentAccountIds) {
        Set<Id> currentParentAccountIds = new Set<Id>();
        List<Account> parentAccWithAllChildAcc = accountsSelector.selectParentAccountWithPropertyAccounts(parentAccountIds);

        for (Account parent : parentAccWithAllChildAcc) {
            if (allPropertyAccountsAreCurrent(parent.Accounts__r)) {
                currentParentAccountIds.add(parent.Id);
            }
        }

        List<Case> relatedCollectionsCases = caseSelector.openCollectionCasesForAccounts(currentParentAccountIds);

        for (Case collectionsCase : relatedCollectionsCases) {
            collectionsCase.Resolution__c = 'No Longer Past Due';
            collectionsCase.Status = 'Closed';
        }
        update relatedCollectionsCases;
    }

    private Boolean noLongerPastDue(Account propertyToUpdate) {
        return propertyToUpdate.Max_Overdue_Due_Date_Zuora__c == null || propertyToUpdate.Max_Overdue_Due_Date_Zuora__c >= System.today();
    }

    private Case getCaseToReactivateCustomer(Zuora__CustomerAccount__c zuoraAccount) {
        Case collectionsCase = caseFactory.getCase('Collections');
        collectionsCase.Subject = '67-90 days past due customer fully paid their balance';
        collectionsCase.Description = zuoraAccount.Name + ' (' + zuoraAccount.Zuora__Account__r.Id + ') was at ' +
            zuoraAccount.Zuora__Account__r.Days_Past_Due__c + ' days past due and fully paid their balance. ' +
            'Please review their subscriptions status to see if they should be reactivated';
        collectionsCase.AccountId = zuoraAccount.Zuora__Account__r.Parent_Account__c;
        collectionsCase.Category__c = 'Billing-Payment';
        collectionsCase.Priority = 'Medium';
        collectionsCase.Product_Line__c = 'Community Solar';
        collectionsCase.Origin = 'Other';
        collectionsCase.Case_Type__c = 'Perch';
        collectionsCase.Disable_Followup_Email__c = true;
        return collectionsCase;
    }

    @SuppressWarnings('PMD.FieldNamingConventions')
    private class AccountSummary {
        public Decimal TotalBalance;
        public Date MinDueDate;
        public Date LastBillSendDate;
    }
    @TestVisible
    @SuppressWarnings('PMD.FieldNamingConventions')
    private class BalanceQueryResult {
        public Decimal MemoBalance;
        public Date MemoDueDate;
        public Date LastBillSendDate;
        public Decimal InvoiceBalance;
        public Date InvoiceDueDate;
        public String AccountId;
    }

    private static Map<String, AccountSummary> summarizeBalanceQueryResult(String queryResponse) {
        Map<String, AccountSummary> zuoraIdToAccountSummary = new Map<String, AccountSummary>();
        List<BalanceQueryResult> results;
        results = (List<BalanceQueryResult>) JSON.deserialize(queryResponse, List<BalanceQueryResult>.class);

        for (BalanceQueryResult result : results) {
            AccountSummary summary = new AccountSummary();
            summary.TotalBalance = Util.nullToZero(result.MemoBalance) + Util.nullToZero(result.InvoiceBalance);
            summary.MinDueDate = DateUtil.min(result.MemoDueDate, result.InvoiceDueDate);
            summary.LastBillSendDate = result.LastBillSendDate;
            zuoraIdToAccountSummary.put(result.AccountId, summary);
        }
        return zuoraIdToAccountSummary;
    }
}
