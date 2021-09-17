/**
 * @description Used by the ReturnedPaymentService to figure out whether a payment is in an open period
 * (in which case it can be cancelled if it's found to be returned), or in a closed period (in which case
 * we need to leave the payment applied, and create debit memos).
 * Tested By: ZuoraAccountingPeriodServiceTest
 */
public without sharing class ZuoraAccountingPeriodService {
    /**
     * @description Takes a date (for instance, a payment effective or submitted date), queries Zuora for
     * accounting periods, and returns true if the date is in an open period.
     * @param theDate A date to check
     * @return True if the date is in an open period
     */
    public Boolean isInOpenPeriod(Date theDate) {
        for (ZuoraAPI.AccountingPeriod accountingPeriod : getAllPeriods()) {
            if (periodAppliesToDate(accountingPeriod, theDate)) {
                return accountingPeriod.Status != 'Closed';
            }
        }
        throw new Util.BWException('Accounting period not found for ' + theDate);
    }

    @TestVisible
    private Boolean periodAppliesToDate(ZuoraAPI.AccountingPeriod accountingPeriod, Date theDate) {
        return accountingPeriod.StartDate <= theDate &&
            (accountingPeriod.EndDate >= theDate || accountingPeriod.EndDate == null);
    }

    private List<ZuoraAPI.AccountingPeriod> getAllPeriods() {
        HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('GET', '/v1/accounting-periods', null, false);
        ZuoraAPI.AccountingPeriods allPeriods =
            (ZuoraAPI.AccountingPeriods) JSON.deserialize(response.getBody(), ZuoraAPI.AccountingPeriods.class);
        return allPeriods.accountingPeriods;
    }
}