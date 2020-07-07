/**
 * Tested By: ZuoraAccountSelectorTest, BillingAccountServiceTest
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class ZuoraAccountSelector {
    private static ZuoraSubscriptionService zuoraSubscriptionService = new ZuoraSubscriptionService();
    private static QueryResultGateways gatewayList;

    public class QueryResultAccount {
        public List<ZuoraAPI.ZuoraAccount> records;
        public Integer size;
        public Boolean done;
    }

    public class QueryResultGateways {
        public List<ZuoraAPI.PaymentGateway> paymentgateways;
    }

    public class AccountWithPaymentMethod {
        @AuraEnabled
        public ZuoraAPI.ZuoraAccount account;
        @AuraEnabled
        public ZuoraAPI.PaymentMethod paymentMethod;
        @AuraEnabled
        public Integer numberOfGateways;
    }

    public String getZuoraAccountFromSFAccount (String sfAccountId) {
        Zuora__CustomerAccount__c salesforceAccount = [
            SELECT Id, Zuora__Zuora_Id__c
            FROM Zuora__CustomerAccount__c
            WHERE Id = : sfAccountId
            LIMIT 1
        ];
        return salesforceAccount.Zuora__Zuora_Id__c;
    }

    public ZuoraAPI.PaymentGateway getGatewayIdFromGatewayName (String gatewayName) {
        if (gatewayList == null) {
            HttpResponse response = ZuoraAPIHelper.callJsonEndpoint( 'GET', '/v1/paymentgateways', null, false );
            gatewayList = (QueryResultGateways) JSON.deserialize(response.getBody(), QueryResultGateways.class);
        }
        for (ZuoraAPI.PaymentGateway gateway : gatewayList.paymentgateways) {
            if (gatewayName == null && gateway.isDefault) {
                return gateway;
            } else if (gateway.isActive && gateway.name == gatewayName) {
                return gateway;
            }
        }
        return null;
    }

    public AccountWithPaymentMethod getAccountWithDefaultPaymentMethod (String sfAccountId) {
        String zuoraAcctId = getZuoraAccountFromSFAccount(sfAccountId);
        ZuoraAPI.ZuoraAccount acct = getAccountFromZuora(zuoraAcctId);
        AccountWithPaymentMethod acctWithMethod = new AccountWithPaymentMethod();
        acctWithMethod.account = acct;
        acctWithMethod.account.PaymentGateway = getGatewayIdFromGatewayName(acct.PaymentGateway).id;
        acctWithMethod.numberOfGateways = zuoraSubscriptionService.getSubscriptionsByAccount(zuoraAcctId).getNumberOfGateways();
        if (acct.DefaultPaymentMethodId != null){
            acctWithMethod.paymentMethod = ZuoraPaymentPageController.getPaymentMethod(acct.DefaultPaymentMethodId);
        }
        Logger.flushLogs();
        return acctWithMethod;
    }

    public ZuoraAPI.ZuoraAccount getAccountFromZuora(String zuoraAcctId) {
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

    private ZuoraAPI.ZuoraAccount accountQuery(String zuoraAcctId, String fields) {
        return query(new List<String>{zuoraAcctId}, fields)[0];
    }

    public List<ZuoraAPI.ZuoraAccount> query(List<String> zuoraAccountIds, String fields) {
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

    public List<Zuora__CustomerAccount__c> getBillingAccountsById (Set<Id> accountIds){
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
                Zuora__Account__r.Max_Overdue_Due_Date_Zuora__c,
                Zuora__Account__r.Last_Bill_Send_Date_New_Charges_Zuora__c,
                Zuora__Account__r.Days_Past_Due__c,
                Zuora__Account__r.Parent_Account__c
            FROM Zuora__CustomerAccount__c
            WHERE Id IN : accountIds
        ];
    }

    public List<Zuora__CustomerAccount__c> getAllBillingAccounts (){
        return [
            SELECT Id, Name,
                Zuora__Zuora_Id__c,
                Zuora__AutoPay__c,
                Zuora__Account__r.Id,
                Zuora__Account__r.Recurring_Billing__c,
                Zuora__Account__r.Total_Outstanding_Balance_Zuora__c,
                Zuora__Account__r.Max_Overdue_Due_Date_Zuora__c,
                Zuora__Account__r.Last_Bill_Send_Date_New_Charges_Zuora__c,
                Zuora__Batch__c,
                Zuora__Account__r.Days_Past_Due__c,
                Zuora__Account__r.Parent_Account__c
            FROM Zuora__CustomerAccount__c
        ];
    }

    public List<ZuoraAPI.ZuoraAccount> getAutopayAccountsWithBalance() {
        String query = 'SELECT Id, CRMId, Balance FROM Account WHERE Autopay = true AND Balance > 0';
        QueryResultAccount queryResultAccount = (QueryResultAccount)JSON.deserialize(ZuoraAPIHelper.query(query, false), QueryResultAccount.class);
        if (queryResultAccount.done = false) {
            Logger.logLater('ZuoraAccountSelector', 'getAutopayAccountsWithBalance', 'More than 2000 records found, but only 2000 supported. Implement queryMore.', Logger.ERROR);
        }
        return queryResultAccount.records;
    }
}