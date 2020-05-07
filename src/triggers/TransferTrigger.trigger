/**
 * Created by SarahRenfro on 9/5/2019.
 *
 * TestedBy: TransferPartServiceTest, AllocationScheduleServiceTest, TransferServiceTest
 */

trigger TransferTrigger on Transfer__c (before update, before insert, after update, after insert) {
    if (Util.isDisabled('Disable_TransferTrigger__c')) {
        return;
    }

    TransferPartService transferPartService = new TransferPartService();
    AllocationScheduleService alsService = new AllocationScheduleService();
    ClientReportingService clientReportingService = new ClientReportingService();
    TransferService transferService = new TransferService();

    switch on Trigger.operationType {
        when BEFORE_UPDATE {
            alsService.populateAllocationScheduleOnTransfer(Trigger.new);
        }
        when BEFORE_INSERT {
            alsService.populateAllocationScheduleOnTransfer(Trigger.new);
            clientReportingService.stampClient(Trigger.new);
        }
        when AFTER_UPDATE {
            transferPartService.onAfterTransferUpdate(Trigger.new, Trigger.oldMap);
            alsService.queueUpdateALSStatuses(Trigger.new, Trigger.oldMap);
            transferService.changeInBillsGenerated(Trigger.new, Trigger.oldMap);
        }
        when AFTER_INSERT {
            transferPartService.createPartsFromTransfer(Trigger.new);
        }
    }
}