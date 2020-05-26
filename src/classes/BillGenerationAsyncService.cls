/**
 * Created by Jordan Pentaleri on 10/30/2019.
 * Tested By: BillGenerationServiceTest
*/

public class BillGenerationAsyncService implements Database.Batchable<Transfer__c>, Database.Stateful {
    public List<Bill_Period__c> billPeriods;
    public List<Transfer__c> transfers;

    public BillGenerationAsyncService(List<Bill_Period__c> billPeriodsPassed) {
        billPeriods = billPeriodsPassed;
        Set<Id> bpIds = new Set<Id>();
        for (Bill_Period__c bp : billPeriodsPassed) {
            bpIds.add(bp.Id);
        }
        transfers = TransferSelector.getAllTransfersByBillPeriod(bpIds);
    }

    public void executeBatchJob() {
        if (Test.isRunningTest()){
            // Can't call more than 1 batch when running a test
            for (Transfer__c transfer : transfers){
                createBillsUpdateTransfer(transfer);
            }
        } else {
            // Each transfer is its own batch, so a size of 1:
            Database.executeBatch(this, 1);
        }
    }

    public Iterable<Transfer__c> start(Database.BatchableContext bc) {
        return transfers;
    }

    public void execute(Database.BatchableContext bc, List<Transfer__c> transfers) {
        try {
            if (transfers.size() > 1){
                throw new Util.BWException('Queue transfers with batch size of 1');
            }
            createBillsUpdateTransfer(transfers[0]);
        } catch (Exception excep){
            Logger.logNow('BillGenerationAsyncService', 'execute', JSON.serialize(transfers) + '\n' + excep.getMessage() + '\n' + excep.getStackTraceString(), Logger.ERROR);
        }
    }

    private void createBillsUpdateTransfer(Transfer__c transfer){
        List<UASB__c> uasbsToInsert = new List<UASB__c>();
        BillGenerationService.BillType operationType = BillGenerationService.BillType.BOTH;
        uasbsToInsert.addAll(BillGenerationService.calculateUASBsFromTransfer(transfer, operationType, false));
        insert uasbsToInsert;
        // Checking this box could increase the Number of Billed Production Periods by 1
        // so it is important to do at the end of each batch instead of in the finish
        transfer.Bills_Generated__c = true;
        update transfer;
    }

    public void finish(Database.BatchableContext bc){
        Logger.logNow('BillGenerationAsyncService', 'finish','Job Finished', Logger.INFO);
    }
}