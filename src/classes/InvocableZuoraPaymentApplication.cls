/*
Tested By: InvocableZuoraActionsTest
*/

public class InvocableZuoraPaymentApplication {
    @InvocableMethod(Label='ZuoraPaymentApplication')
    public static void paymentApplication() {
        ZuoraDataQueryService.ProcessingParameter parameter = new ZuoraDataQueryService.ProcessingParameter('ZuoraPaymentService');
        parameter.methodName = 'PaymentsWithUnappliedBalance';
        String queryString = 'SELECT p.Id, p.accountid, p.unappliedamount, p.paymentmethodid, p.status, p.gateway gatewayName ' +
            'FROM Payment p ' +
            'INNER JOIN Account a ON p.accountid = a.Id ' +
            'WHERE (p.unappliedamount > 0 AND p.status = \'Processed\') ' +
            'AND (a.totalinvoicebalance > 0 OR a.totaldebitmemobalance > 0 )';
        ZuoraDataQueryService.callFromApex(queryString, parameter);
    }
}