/**
 * Tested By: ZuoraAccountSelectorTest, BillingAccountServiceTest
 */

public without sharing class ZuoraAccountSelector {
    public class QueryResultAccount{
        public List<ZuoraAPI.ZuoraAccount> records;
    }

    public class QueryResultGateways{
        public List<ZuoraAPI.PaymentGateway> paymentgateways;
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
    public static ZuoraAPI.PaymentGateway getGatewayIdFromGatewayName (String gatewayName){
        HttpResponse response = ZuoraAPIHelper.callJsonEndpoint( 'GET', '/v1/paymentgateways', null, false );
        QueryResultGateways gatewayList = (QueryResultGateways)JSON.deserialize(response.getBody(), QueryResultGateways.class);
        ZuoraAPI.PaymentGateway selectedGateway;
        for (ZuoraAPI.PaymentGateway gateway : gatewayList.paymentgateways){
            if (gatewayName == null && gateway.isDefault){
                selectedGateway = gateway;
            } else if (gateway.isActive && gateway.name == gatewayName){
                selectedGateway = gateway;
            }
        }
        return selectedGateway;
    }

    @AuraEnabled
    public static AccountWithPaymentMethod getAccountWithDefaultPaymentMethod (String sfAccountId){
        String zuoraAcctId = getZuoraAccountFromSFAccount(sfAccountId);
        ZuoraAPI.ZuoraAccount acct = getAccountFromZuora(zuoraAcctId);
        AccountWithPaymentMethod acctWithMethod = new AccountWithPaymentMethod();
        acctWithMethod.account = acct;
        acctWithMethod.account.PaymentGateway = getGatewayIdFromGatewayName(acct.PaymentGateway).Id;
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
            'PaymentGateway, ' +
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

    public static List<Zuora__CustomerAccount__c> getBillingAccountsById (Set<Id> accountIds){
        return [
            SELECT Id, Name,
                Zuora__AutoPay__c,
                Zuora__Account__r.Id,
                Zuora__Account__r.Recurring_Billing__c
            FROM Zuora__CustomerAccount__c
            WHERE Id IN : accountIds
        ];
    }
}