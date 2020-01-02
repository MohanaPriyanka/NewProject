/**
 * Created by Jordan Pentaleri on 10/30/2019.
 * Tested By: BillGenerationServiceTest
*/

public class BillGenerationAsyncService implements Database.Batchable<Schedule_Z_Subscription__c>, Database.Stateful {
    public EnergyUsageUpdateTriggerHandler handler;
    public List<Bill_Period__c> billPeriods;
    public List<Transfer__c> transfers;
    public List<Schedule_Z_Subscription__c> szsScope;

    public BillGenerationAsyncService(List<Bill_Period__c> billPeriodsPassed) {
        handler = new EnergyUsageUpdateTriggerHandler(billPeriodsPassed);
        billPeriods = billPeriodsPassed;
        transfers = handler.transferList;
        szsScope = BillGenerationService.getScheduleZSubscriptionList(handler.scheduleZs);
    }

    public void executeBatchJob() {
        System_Properties__c sysProp = System_Properties__c.getAll().values()[0];
        Decimal csBillBatchSize = sysProp.CS_Bill_Batch_Size__c;
        System.debug(sysProp);
        Database.executeBatch(this, Integer.valueOf(csBillBatchSize));
    }

    public Iterable<Schedule_Z_Subscription__c> start(Database.BatchableContext bc) {
        return szsScope;
    }

    public void execute(Database.BatchableContext bc, List<Schedule_Z_Subscription__c> scope) {
        try {
            // Until we can stop creating account bills/system bills use EUUTH method:
            handler.createBills(scope);

            //  When we are ready to retire old architecture, create new method:u
            //  BillGenerationService.onlyCreateUASBs();
        } catch (Exception excep){
            Logger.logNow('BillGenerationAsyncService', 'execute', JSON.serialize(scope) + '\n' + excep.getMessage() + '\n' + excep.getStackTraceString(), Logger.ERROR);
        }
    }

    public void finish(Database.BatchableContext bc){
        try {
            for (Transfer__c transfer : transfers){
               transfer.Bills_Generated__c = true;
            }
            update transfers;
        } catch (Exception excep){
            Logger.logNow('BillGenerationAsyncService', 'finish', JSON.serialize(transfers) + '\n' + excep.getMessage() + '\n' + excep.getStackTraceString(), Logger.ERROR);
        }
    }
}