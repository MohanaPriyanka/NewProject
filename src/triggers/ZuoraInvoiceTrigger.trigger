/**
 * Created by PeterYao on 11/18/2019.
 * TEsted By: ZuoraInvoiceSericeTest
 */

trigger ZuoraInvoiceTrigger on Zuora__ZInvoice__c (after insert) {
    if (Util.isDisabled('Disable_ZInvoiceTrigger__c')) {
        return;
    }

    switch on Trigger.operationType {
        when AFTER_INSERT {
            ZuoraInvoiceAsyncService.findFirstInvoiceAndSetInsertsFuture(Trigger.newMap.keySet());
        }
    }
}