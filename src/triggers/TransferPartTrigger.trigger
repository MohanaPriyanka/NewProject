/**
 * Created by SarahRenfro on 9/13/2019.
 *
 * TestedBy: TransferPartServiceTest
 */

trigger TransferPartTrigger on Transfer_Part__c (after insert, after update) {

    TransferPartService transferPartService = new TransferPartService();

    if (Trigger.isAfter){
        transferPartService.onAfterTransferParts(Trigger.new);
    }

}