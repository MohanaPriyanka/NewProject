/*************************************************************************************
 * Created By: peteryao on 2019-01-31  
 * Description: 
 * Test: CSBillQualityCheckSchedulerTest
 *************************************************************************************/

public without sharing class CSBillQualityCheckScheduler implements Schedulable {
    public void execute(SchedulableContext sc) {
        Datetime startingDatetime = System.now();
        Datetime lastTimeRun = getLastSuccessfulRun();
        List<System_Bill__c> systemBills = SystemBillsSelector.selectSystemBillsModifiedAfter(lastTimeRun);
        Set<Id> systemBillIds = (new Map<Id, System_Bill__c>(systemBills)).keySet();
        SystemBillQualityChecker.checkDecimalScale(new Set<Id>(systemBillIds));
        setLastSuccessfulRun(startingDatetime);
        Logger.logNow('CSBillQualityCheckScheduler', 'execute',
            'Checked ' + systemBillIds.size() + ' System Bills ' +
                'updated between ' + lastTimeRun + ' and ' + startingDatetime + '\n\n' +
                'Took ' +
                Limits.getCpuTime() + 'ms of CPU time (of ' + Limits.getLimitCpuTime() + 'ms), ' +
                Limits.getHeapSize()/1000000 + 'MB of heap (of ' + Limits.getLimitHeapSize()/1000000 + 'MB), and ' +
                Limits.getQueries() + ' queries (of ' + Limits.getLimitQueries() + ' queries)',
                'Info');
    }

    public Datetime getLastSuccessfulRun() {
        List<System_Properties__c> systemProperties = System_Properties__c.getAll().values();
        if (systemProperties.size() > 0 &&
            systemProperties[0].Last_Automated_Bill_QC_Check__c != null) {
            return systemProperties[0].Last_Automated_Bill_QC_Check__c;
        }
        // This must be the first run, just get the last 24 hours of system bills that were updated
        return System.now() - 1;
    }

    public void setLastSuccessfulRun(Datetime lastSuccessfulRun) {
        List<System_Properties__c> systemProperties = System_Properties__c.getAll().values();
        if (systemProperties.size() > 0) {
            systemProperties[0].Last_Automated_Bill_QC_Check__c = lastSuccessfulRun;
            update systemProperties[0];
        } else {
            // Set a new System Properties
            System_Properties__c systemProperty = new System_Properties__c(
                Name = 'System',
                Last_Automated_Bill_QC_Check__c = lastSuccessfulRun
            );
            insert systemProperty;
        }
    }
}