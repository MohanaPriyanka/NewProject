/**
 * Created by pyao on 2/1/2019.
 */
@IsTest
public with sharing class CSBillQualityCheckSchedulerTest {
    @IsTest static void testGetSetLastSuccessfulRun() {
        List<System_Properties__c> systemProperties = System_Properties__c.getAll().values();
        System.assertEquals(0, systemProperties.size());
        CSBillQualityCheckScheduler scheduler = new CSBillQualityCheckScheduler();
        System.assertEquals(System.now() - 1, scheduler.getLastSuccessfulRun());
        Datetime yesterday = System.now() - 1;

        scheduler.setLastSuccessfulRun(yesterday);
        systemProperties = System_Properties__c.getAll().values();
        System.assertEquals(1, systemProperties.size());
        System.assertEquals(yesterday, systemProperties[0].Last_Automated_Bill_QC_Check__c);

        System.assertEquals(yesterday, scheduler.getLastSuccessfulRun());
    }

    @IsTest static void testExecute() {
        CSBillQualityCheckScheduler scheduler = new CSBillQualityCheckScheduler();
        Datetime yesterday = System.now() - 1;
        scheduler.setLastSuccessfulRun(yesterday);
        scheduler.execute(null);
        System.assert(scheduler.getLastSuccessfulRun() > yesterday, 'Expected last successful run to be updated');
    }
}