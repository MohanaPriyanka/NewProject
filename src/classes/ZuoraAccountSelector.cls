/**
 * Tested By: ZuoraAccountSelectorTest
 */

public without sharing class ZuoraAccountSelector {
    public class QueryResultAccount{
        public List<ZuoraAPI.ZuoraAccount> records;
    }

    public class AccountWithPaymentMethod{
        @AuraEnabled
        public ZuoraAPI.ZuoraAccount account;
        @AuraEnabled
        public ZuoraAPI.PaymentMethod paymentMethod;
    }

    @AuraEnabled
    public static String getZuoraAccountFromSFAccount (String sfAccountId){
        Zuora__CustomerAccount__c salesforceAccount = [
            SELECT Id, Zuora__Zuora_Id__c
            FROM Zuora__CustomerAccount__c
            WHERE Id = : sfAccountId
            LIMIT 1
        ];
        return salesforceAccount.Zuora__Zuora_Id__c;
    }

    @AuraEnabled
    public static AccountWithPaymentMethod getAccountWithDefaultPaymentMethod (String sfAccountId){
        String zuoraAcctId = getZuoraAccountFromSFAccount(sfAccountId);
        ZuoraAPI.ZuoraAccount acct = getAccountFromZuora(zuoraAcctId);
        AccountWithPaymentMethod acctWithMethod = new AccountWithPaymentMethod();
        acctWithMethod.account = acct;
        if (acct.DefaultPaymentMethodId != null){
            acctWithMethod.PaymentMethod = ZuoraPaymentPageController.getPaymentMethod(acct.DefaultPaymentMethodId);
        }
        return acctWithMethod;
    }

    @AuraEnabled
    public static ZuoraAPI.ZuoraAccount getAccountFromZuora(String zuoraAcctId){
        String fields = 'Id, ' +
            'AccountNumber, ' +
            'DefaultPaymentMethodId, ' +
            'AutoPay, ' +
            'InvoiceTemplateId, ' +
            'CreditBalance, ' +
            'BillCycleDay, ' +
            'PaymentTerm, ' +
            'Status, ' +
            'TotalInvoiceBalance, ' +
            'Batch, ' +
            'Name, ' +
            'CrmId, ' +
            'BillToId, ' +
            'CreatedDate, ' +
            'Balance';
        return accountQuery(zuoraAcctId, fields);
    }

    @AuraEnabled
    public static ZuoraAPI.ZuoraAccount accountQuery (String zuoraAcctId, String fields){
        String queryString = 'SELECT ' + fields + ' FROM Account WHERE Id = \'' + zuoraAcctId + '\'';
        String queryResponse = ZuoraAPIHelper.query(queryString, false);
        QueryResultAccount acctBalances = (QueryResultAccount)JSON.deserialize(queryResponse, QueryResultAccount.class);
        return acctBalances.records[0];
    }
}