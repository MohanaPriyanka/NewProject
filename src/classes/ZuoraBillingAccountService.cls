@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class ZuoraBillingAccountService implements Schedulable, ZuoraDataQueryService.Processor {
    private ZuoraAccountSelector zuoraAcctSelector = new ZuoraAccountSelector();
    public static void updatePropertyAccount(List<Zuora__CustomerAccount__c> billingAccounts) {
        Set<Id> zAccountIds = (new Map<Id,Zuora__CustomerAccount__c>(billingAccounts)).keySet();
        checkPropertyAccountDiscrepancy(zAccountIds);
    }

    public void execute(SchedulableContext ctx){
        startDaysPastDueUpdate(null);
    }

    @Future
    // Future methods must be declared as static
    public static void checkPropertyAccountDiscrepancy(Set<Id> accountsToCheck) {
        try {
            List<Account> propAccountsToUpdate = new List<Account>();
            ZuoraAccountSelector selector = new ZuoraAccountSelector();
            List<Zuora__CustomerAccount__c> zuoraAccounts = selector.getBillingAccountsById(accountsToCheck);

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

            if (propAccountsToUpdate.size() > 0) {
                update propAccountsToUpdate;
            }
        } catch (Exception excep){
            Logger.logNow('ZuoraBillingAccountService','checkPropertyAccountDiscrepancy',excep.getMessage() + excep.getStackTraceString());
        }
    }

    public void startDaysPastDueUpdate(Set<Id> accountsToCheck) {
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

    public void updateDaysPastDue(String queryResponse, Set<Id> recordIds) {
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
                Account property = new Account();
                property.Id = zuoraAccount.Zuora__Account__r.Id;
                if (zuoraIdToAccountSummary.containsKey(zuoraId)){
                    property.Total_Outstanding_Balance_Zuora__c = zuoraIdToAccountSummary.get(zuoraId).TotalBalance;
                    property.Max_Overdue_Due_Date_Zuora__c = zuoraIdToAccountSummary.get(zuoraId).MinDueDate;
                } else {
                    // No invoices or debit memos with a balance were returned for that account, so set to null:
                    property.Total_Outstanding_Balance_Zuora__c = 0;
                    property.Max_Overdue_Due_Date_Zuora__c = null;
                }
                if (property.Total_Outstanding_Balance_Zuora__c !=
                    zuoraAccount.Zuora__Account__r.Total_Outstanding_Balance_Zuora__c ||
                    property.Max_Overdue_Due_Date_Zuora__c !=
                    zuoraAccount.Zuora__Account__r.Max_Overdue_Due_Date_Zuora__c){
                    accountsToUpdate.add(property);
                }
            }
            if (accountsToUpdate.size() > 200){
                Database.executeBatch(new GenericBatchDMLOperation(accountsToUpdate, 'Update'));
            } else if (accountsToUpdate.size() > 0){
                update accountsToUpdate;
            }
        } catch (Exception excep){
            Logger.logNow('ZuoraBillingAccountService','updateDaysPastDue',excep.getMessage() + excep.getStackTraceString());
        }
    }

    public class AccountSummary{
        public Decimal TotalBalance;
        public Date MinDueDate;
    }

    public class BalanceQueryResult {
        Decimal MemoBalance;
        Date MemoDueDate;
        Decimal InvoiceBalance;
        Date InvoiceDueDate;
        String AccountId;
    }

    private static Map<String, AccountSummary> summarizeBalanceQueryResult(String queryResponse){
        Map<String, AccountSummary> zuoraIdToAccountSummary = new Map<String, AccountSummary>();
        List<BalanceQueryResult> results;
        results = (List<BalanceQueryResult>)JSON.deserialize(queryResponse, List<BalanceQueryResult>.class);

        for (BalanceQueryResult result : results){
            AccountSummary summary = new AccountSummary();
            summary.TotalBalance = Util.nullToZero(result.MemoBalance) + Util.nullToZero(result.InvoiceBalance);
            summary.MinDueDate = DateUtil.min(result.MemoDueDate, result.InvoiceDueDate);
            zuoraIdToAccountSummary.put(result.AccountId, summary);
        }
        return zuoraIdToAccountSummary;
    }
}