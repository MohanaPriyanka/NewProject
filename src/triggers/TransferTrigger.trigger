/**
 * Created by SarahRenfro on 9/5/2019.
 *
 * TestedBy: TransferPartServiceTest
 */

trigger TransferTrigger on Transfer__c (after update, after insert) {
    if (Util.isDisabled('Disable_TransferTrigger__c')) {
        return;
    }

    TransferPartService transferPartService = new TransferPartService();

    switch on Trigger.operationType {
        when AFTER_UPDATE {
            transferPartService.onAfterTransferUpdate(Trigger.new, Trigger.oldMap);
        }
        when AFTER_INSERT {
            transferPartService.createPartsFromTransfer(Trigger.new);
        }
    }



}