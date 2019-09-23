/**
 * Created by SarahRenfro on 9/5/2019.
 *
 * TestedBy: TransferPartServiceTest
 */

trigger TransferTrigger on Transfer__c (after update) {
    if (Util.isDisabled('Disable_TransferTrigger__c')) {
        return;
    }

    TransferPartService transferPartService = new TransferPartService();

    if(Trigger.isAfter && Trigger.isUpdate) {
        transferPartService.onAfterTransferUpdate(Trigger.new, Trigger.oldMap);
    }

}