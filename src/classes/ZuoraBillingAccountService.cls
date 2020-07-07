/*
   Tested By: ZuoraBillingAccountServiceTest
 */

@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class ZuoraBillingAccountService implements Schedulable, ZuoraDataQueryService.Processor {
    @TestVisible
    private static ZuoraAccountSelector zuoraAcctSelector = new ZuoraAccountSelector();
    private static CaseFactory caseFactory = new CaseFactory();
    @TestVisible
    private static fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
        new List<SObjectType> {
            Case.SObjectType
        }
    );
    public void checkPropertyAccountDiscrepancy(List<Zuora__CustomerAccount__c> billingAccounts) {
        checkPropertyAccountDiscrepancyFuture(CollectionUtil.toIds(CollectionUtil.getIds(billingAccounts)));
    }

    public void execute(SchedulableContext ctx){
        startDaysPastDueUpdate(null);
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
                        Recurring_Billing__c = zAccount.Zuora__AutoPay__c
                    );
                    if (zAccount.Zuora__AutoPay__c){
                        propAccount.Autopay_Date_Last_Enrolled__c = Date.today();
                    }
                    propAccountsToUpdate.add(propAccount);
                }
            }

            Util.updateSObjs(propAccountsToUpdate);
        } catch (Exception excep) {
            Logger.logNow('ZuoraBillingAccountService','checkPropertyAccountDiscrepancy',excep.getMessage() + '\n' + excep.getStackTraceString());
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
            Logger.logNow('ZuoraBillingAccountService','setBillingAccountOnPropertyAccountFuture',e.getMessage() + '\n' + e.getStackTraceString());
        }
    }

    @TestVisible
    private void startDaysPastDueUpdate(Set<Id> accountsToCheck) {
        try {
            ZuoraDataQueryService.ProcessingParameter finishMethod = new ZuoraDataQueryService.ProcessingParameter();
            finishMethod.className = 'ZuoraBillingAccountService';
            String queryString;
            if (accountsToCheck == null){
                queryString = ZuoraInvoiceSelector.getOutstandingBalanceByAccountQuery(null);
            } else {
                queryString = ZuoraInvoiceSelector.getOutstandingBalanceByAccountQuery(
                    zuoraAcctSelector.getBillingAccountsById(accountsToCheck)
                );
                finishMethod.recordIds = accountsToCheck;
            }
            ZuoraDataQueryService.callFromApex(queryString, finishMethod);
        } catch (Exception excep){
            Logger.logNow('ZuoraBillingAccountService','startDaysPastDueUpdate',excep.getMessage() + excep.getStackTraceString());
        }
    }

    public void executePostQueryJob(ZuoraDataQueryService.ProcessingParameter parameter, String response){
        updateDaysPastDue(response, parameter.recordIds);
    }

    @TestVisible
    private void updateDaysPastDue(String queryResponse, Set<Id> recordIds) {
        try {
            List<Account> accountsToUpdate = new List<Account>();
            Map<String, AccountSummary> zuoraIdToAccountSummary = summarizeBalanceQueryResult(queryResponse);
            List<Zuora__CustomerAccount__c> zuoraBillingAccounts;
            if (recordIds == null){
                zuoraBillingAccounts = zuoraAcctSelector.getAllBillingAccounts();
            } else {
                zuoraBillingAccounts = zuoraAcctSelector.getBillingAccountsById(recordIds);
            }
            for (Zuora__CustomerAccount__c zuoraAccount : zuoraBillingAccounts){
                String zuoraId = zuoraAccount.Zuora__Zuora_Id__c;
                Account zuoraAccountToUpdate = new Account();
                zuoraAccountToUpdate.Id = zuoraAccount.Zuora__Account__r.Id;
                if (zuoraIdToAccountSummary.containsKey(zuoraId)){
                    zuoraAccountToUpdate.Total_Outstanding_Balance_Zuora__c = zuoraIdToAccountSummary.get(zuoraId).TotalBalance;
                    zuoraAccountToUpdate.Max_Overdue_Due_Date_Zuora__c = zuoraIdToAccountSummary.get(zuoraId).MinDueDate;
                    zuoraAccountToUpdate.Last_Bill_Send_Date_New_Charges_Zuora__c = zuoraIdToAccountSummary.get(zuoraId).LastBillSendDate;
                } else {
                    // No invoices or debit memos with a balance were returned for that account, so set to null:
                    zuoraAccountToUpdate.Total_Outstanding_Balance_Zuora__c = 0;
                    zuoraAccountToUpdate.Max_Overdue_Due_Date_Zuora__c = null;
                    zuoraAccountToUpdate.Last_Bill_Send_Date_New_Charges_Zuora__c = null;
                }
                if (zuoraAccountToUpdate.Total_Outstanding_Balance_Zuora__c !=
                    zuoraAccount.Zuora__Account__r.Total_Outstanding_Balance_Zuora__c ||
                    zuoraAccountToUpdate.Max_Overdue_Due_Date_Zuora__c !=
                    zuoraAccount.Zuora__Account__r.Max_Overdue_Due_Date_Zuora__c ||
                    zuoraAccountToUpdate.Last_Bill_Send_Date_New_Charges_Zuora__c != zuoraAccount.Zuora__Account__r.Last_Bill_Send_Date_New_Charges_Zuora__c){
                    accountsToUpdate.add(zuoraAccountToUpdate);
                }
                if (zuoraAccount.Zuora__Account__r.Days_Past_Due__c >= CSCancellationScheduler.DAYS_PAST_DUE_DEACTIVATION_TRIGGER &&
                    zuoraAccount.Zuora__Account__r.Days_Past_Due__c < CSCancellationScheduler.DAYS_PAST_DUE_BAD_DEBT_TRIGGER &&
                    (zuoraAccountToUpdate.Max_Overdue_Due_Date_Zuora__c == null || zuoraAccountToUpdate.Max_Overdue_Due_Date_Zuora__c >= System.today())) {
                    uow.registerNew(getCaseToReactivateCustomer(zuoraAccount));
                }
            }
            if (accountsToUpdate.size() > 200){
                Database.executeBatch(new GenericBatchDMLOperation(accountsToUpdate, 'Update'));
            } else if (accountsToUpdate.size() > 0){
                Util.updateSObjs(accountsToUpdate);
            }
            uow.commitWork();
        } catch (Exception excep){
            Logger.logNow('ZuoraBillingAccountService','updateDaysPastDue',excep.getMessage() + excep.getStackTraceString());
        }
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
        collectionsCase.Case_Type__c = 'BlueWave';
        collectionsCase.Disable_Followup_Email__c = true;
        return collectionsCase;
    }

    private class AccountSummary{
        public Decimal TotalBalance;
        public Date MinDueDate;
        public Date LastBillSendDate;
    }
    @TestVisible
    private class BalanceQueryResult {
        public Decimal MemoBalance;
        public Date MemoDueDate;
        public Date LastBillSendDate;
        public Decimal InvoiceBalance;
        public Date InvoiceDueDate;
        public String AccountId;
    }

    private static Map<String, AccountSummary> summarizeBalanceQueryResult(String queryResponse){
        Map<String, AccountSummary> zuoraIdToAccountSummary = new Map<String, AccountSummary>();
        List<BalanceQueryResult> results;
        results = (List<BalanceQueryResult>)JSON.deserialize(queryResponse, List<BalanceQueryResult>.class);

        for (BalanceQueryResult result : results){
            AccountSummary summary = new AccountSummary();
            summary.TotalBalance = Util.nullToZero(result.MemoBalance) + Util.nullToZero(result.InvoiceBalance);
            summary.MinDueDate = DateUtil.min(result.MemoDueDate, result.InvoiceDueDate);
            summary.LastBillSendDate = result.LastBillSendDate;
            zuoraIdToAccountSummary.put(result.AccountId, summary);
        }
        return zuoraIdToAccountSummary;
    }
}