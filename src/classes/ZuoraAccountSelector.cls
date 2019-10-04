/**
 * Tested By: ZuoraAccountSelectorTest, BillingAccountServiceTest
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
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

    public static String getZuoraAccountFromSFAccount (String sfAccountId) {
        Zuora__CustomerAccount__c salesforceAccount = [
            SELECT Id, Zuora__Zuora_Id__c
            FROM Zuora__CustomerAccount__c
            WHERE Id = : sfAccountId
            LIMIT 1
        ];
        return salesforceAccount.Zuora__Zuora_Id__c;
    }

    public static ZuoraAPI.PaymentGateway getGatewayIdFromGatewayName (String gatewayName) {
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
    public static AccountWithPaymentMethod getAccountWithDefaultPaymentMethod (String sfAccountId) {
        String zuoraAcctId = getZuoraAccountFromSFAccount(sfAccountId);
        ZuoraAPI.ZuoraAccount acct = getAccountFromZuora(zuoraAcctId);
        AccountWithPaymentMethod acctWithMethod = new AccountWithPaymentMethod();
        acctWithMethod.account = acct;
        acctWithMethod.account.PaymentGateway = getGatewayIdFromGatewayName(acct.PaymentGateway).id;
        if (acct.DefaultPaymentMethodId != null){
            acctWithMethod.paymentMethod = ZuoraPaymentPageController.getPaymentMethod(acct.DefaultPaymentMethodId);
        }
        return acctWithMethod;
    }

    @TestVisible
    private static ZuoraAPI.ZuoraAccount getAccountFromZuora(String zuoraAcctId) {
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

    private static ZuoraAPI.ZuoraAccount accountQuery(String zuoraAcctId, String fields) {
        return query(new List<String>{zuoraAcctId}, fields)[0];
    }

    public static List<ZuoraAPI.ZuoraAccount> query(List<String> zuoraAccountIds, String fields) {
        if (zuoraAccountIds == null || zuoraAccountIds.size() == 0) {
            throw new Util.BWException('Query zuora accounts with at least one Zuora Account Id');
        }
        if (zuoraAccountIds.size() > 200) {
            // ZOQL only allows 200 conditions, no parens either (we can't use the IN operator):
            // https://knowledgecenter.zuora.com/DC_Developers/BC_ZOQL
            throw new Util.BWException('ZOQL only allows 200 conditions; run this query with fewer account ids');
        }
        String whereClause = 'WHERE Id = \'' + zuoraAccountIds[0] + '\'';
        for (Integer i = 1; i < zuoraAccountIds.size(); i++) {
            whereClause += ' OR Id = \'' + zuoraAccountIds[i] + '\'';
        }
        String queryString = 'SELECT ' + fields + ' FROM Account ' + whereClause;
        String queryResponse = ZuoraAPIHelper.query(queryString, false);
        QueryResultAccount queryResultAccount = (QueryResultAccount)JSON.deserialize(queryResponse, QueryResultAccount.class);
        if (queryResultAccount.records.size() != zuoraAccountIds.size()) {
            Logger.logLater(
                'ZuoraAccountSelector',
                'query',
                'Not all accounts could be found: accountIds: ' + JSON.serialize(zuoraAccountIds) + '\n' +
                ' query response: ' + JSON.serialize(queryResultAccount.records),
                Logger.WARN);
        }
        return queryResultAccount.records;
    }

    public static List<Zuora__CustomerAccount__c> getBillingAccountsById (Set<Id> accountIds){
        if (!Schema.SObjectType.Zuora__CustomerAccount__c.isQueryable() ||
            !Schema.SObjectType.Zuora__CustomerAccount__c.fields.Zuora__AutoPay__c.isAccessible() ||
            !Schema.SObjectType.Zuora__CustomerAccount__c.fields.Zuora__Account__c.isAccessible()) {
            throw new Util.FatalBWException('Insufficient permissions');
        }
        return [
            SELECT Id, Name,
                Zuora__Zuora_Id__c,
                Zuora__AutoPay__c,
                Zuora__Account__r.Id,
                Zuora__Account__r.Recurring_Billing__c,
                Zuora__Account__r.Total_Outstanding_Balance_Zuora__c,
                Zuora__Account__r.Max_Overdue_Due_Date_Zuora__c
            FROM Zuora__CustomerAccount__c
            WHERE Id IN : accountIds
        ];
    }

    public static List<Zuora__CustomerAccount__c> getAllBillingAccounts (){
        return [
            SELECT Id, Name,
                Zuora__Zuora_Id__c,
                Zuora__AutoPay__c,
                Zuora__Account__r.Id,
                Zuora__Account__r.Recurring_Billing__c,
                Zuora__Account__r.Total_Outstanding_Balance_Zuora__c,
                Zuora__Account__r.Max_Overdue_Due_Date_Zuora__c
            FROM Zuora__CustomerAccount__c
        ];
    }
}