/**
 * Created by Jordan Pentaleri on 10/30/2019.
 * Tested By: BillGenerationServiceTest
*/

public class BillGenerationAsyncService implements Database.Batchable<Schedule_Z_Subscription__c>, Database.Stateful {
    public EnergyUsageUpdateTriggerHandler handler;
    public List<Energy_Usage_Update__c> productionUpdates;
    public List<Schedule_Z_Subscription__c> szsScope;

    public BillGenerationAsyncService(List<Energy_Usage_Update__c> productionUpdatesPassed) {
        // We will not need to instantiate EUUTH once we're ready to retire old architecture:
        handler = new EnergyUsageUpdateTriggerHandler(productionUpdatesPassed);

        // Should stay the same after we retire, will just need to create a list of Schedule Z Ids from PU.Schedule_Z__c
        productionUpdates = productionUpdatesPassed;
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

            //  When we are ready to retire old architecture, create new method:
            //  BillGenerationService.onlyCreateUASBs();
        } catch (Exception excep){
            Logger.logNow('BillGenerationAsyncService', 'execute', JSON.serialize(scope) + '\n' + excep.getMessage() + '\n' + excep.getStackTraceString(), Logger.ERROR);
        }
    }

    public void finish(Database.BatchableContext bc){
        try {
            for (Energy_Usage_Update__c productionUpdate : productionUpdates){
                productionUpdate.Generate_Bills__c = true;
            }
            update productionUpdates;
        } catch (Exception excep){
            Logger.logNow('BillGenerationAsyncService', 'finish', JSON.serialize(productionUpdates) + '\n' + excep.getMessage() + '\n' + excep.getStackTraceString(), Logger.ERROR);
        }
    }
}