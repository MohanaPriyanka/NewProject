/**
 * Created by PeterYao on 9/13/2021.
 */
@IsTest
private with sharing class ZuoraAccountingPeriodServiceTest {
    @IsTest
    private static void systemTest() {
        ZuoraAPIMock.addEndpointResult(
            '/v1/accounting-periods',
            '{\n' +
                '  "accountingPeriods" : [ {\n' +
                '    "id" : "2c92c0f86a583eb9016a6af37fbb0355",\n' +
                '    "name" : "Jan-16",\n' +
                '    "startDate" : "2016-01-01",\n' +
                '    "endDate" : "2016-01-31",\n' +
                '    "status" : "Closed"\n' +
                '  }, {\n' +
                '    "id" : "2c92c0f86a583eb9016a6af37fca0357",\n' +
                '    "name" : "Feb-16",\n' +
                '    "startDate" : "2016-02-01",\n' +
                '    "endDate" : "2016-02-29",\n' +
                '    "status" : "Open"\n' +
                '  } ],\n' +
                '  "success" : true\n' +
                '}');
        System.assert(new ZuoraAccountingPeriodService().isInOpenPeriod(Date.newInstance(2016,2,29)),
            '2/29/2016 should be in the open period from the mock');

        try {
            new ZuoraAccountingPeriodService().isInOpenPeriod(Date.newInstance(2050,2,1));
            System.assert(false, 'Should have caught an exception because there is no open period for 2050');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('Accounting period not found'), e.getMessage());
        }
    }

    @IsTest
    private static void testPeriodAppliesToDate() {
        ZuoraAccountingPeriodService accountingPeriodService = new ZuoraAccountingPeriodService();

        ZuoraAPI.AccountingPeriod accountingPeriod = new ZuoraAPI.AccountingPeriod();
        accountingPeriod.StartDate = Date.newInstance(2021, 1, 1);
        accountingPeriod.EndDate = Date.newInstance(2021, 1, 31);
        System.assert(accountingPeriodService.periodAppliesToDate(accountingPeriod, Date.newInstance(2021, 1, 1)),
            '1/1/2021 should apply to period that begins 1/1/2021 and ends 2021/1/31');
        System.assert(accountingPeriodService.periodAppliesToDate(accountingPeriod, Date.newInstance(2021, 1, 31)),
            '1/31/2021 should apply to period that begins 1/1/2021 and ends 2021/1/31');
        System.assert(!accountingPeriodService.periodAppliesToDate(accountingPeriod, Date.newInstance(2021, 2, 1)),
            '2/1/2021 should not apply to period that begins 1/1/2021 and ends 2021/1/31');
        System.assert(!accountingPeriodService.periodAppliesToDate(accountingPeriod, Date.newInstance(2020, 12, 31)),
            '12/31/2020 should not apply to period that begins 1/1/2021 and ends 2021/1/31');
        accountingPeriod.EndDate = null;
        System.assert(!accountingPeriodService.periodAppliesToDate(accountingPeriod, Date.newInstance(2020, 12, 31)),
            '12/31/2020 should not apply to period that begins 1/1/2021 and has to end date');
        System.assert(accountingPeriodService.periodAppliesToDate(accountingPeriod, Date.newInstance(2021, 2, 1)),
            '2/1/2021 should not apply to period that begins 1/1/2021 and has to end date');
    }
}