/**
 * Created by SarahRenfro on 9/13/2019.
 *
 * TestedBy: TransferPartServiceTest
 */

trigger TransferPartTrigger on Transfer_Part__c (after insert, after update, before delete, after delete) {
    if (Util.isDisabled('Disable_TransferTrigger__c')) {
        return;
    }

    TransferPartService transferPartService = new TransferPartService();
    switch on Trigger.operationType {
        when BEFORE_DELETE {
            transferPartService.onBeforeDelete(Trigger.oldMap);
        } when AFTER_INSERT, AFTER_UPDATE {
            transferPartService.onAfterTransferParts(Trigger.new);
        } when AFTER_DELETE {
            transferPartService.onAfterTransferParts(Trigger.old);
        }
    }
}