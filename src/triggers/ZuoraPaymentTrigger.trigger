/**
 * Tested By: PartnerCommissionServiceTest
 */

trigger ZuoraPaymentTrigger on Zuora__Payment__c (after insert) {
    if (Util.isDisabled('Disable_ZPaymentTrigger__c')) {
        return;
    }

    switch on Trigger.operationType {
        when AFTER_INSERT {
            PartnerCommissionService.onAfterPaymentInsert(Trigger.new);
        }
    }
}