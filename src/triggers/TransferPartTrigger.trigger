/**
 * Created by SarahRenfro on 9/13/2019.
 *
 * TestedBy: TransferPartServiceTest
 */

trigger TransferPartTrigger on Transfer_Part__c (after insert, after update, before delete) {
    if (Util.isDisabled('Disable_TransferTrigger__c')) {
        return;
    }

    TransferPartService transferPartService = new TransferPartService();

    if (Trigger.isAfter){
        transferPartService.onAfterTransferParts(Trigger.new);
    }
    if (Trigger.isBefore && Trigger.isDelete) {
        transferPartService.onBeforeDelete(Trigger.new);
    }

}