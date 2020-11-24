/**
 * Created by peteryao on 11/22/20.
 */

trigger PartnerSharedSolarSystemEligibilityTrigger on Partner_Shared_Solar_System_Eligibility__c (after insert, after update, after delete) {
    if (Util.isDisabled('Disable_PartnerSSSEligibilityTrigger__c')) {
        return;
    }
    SharedSolarSystemSharingService sssSharingService = new SharedSolarSystemSharingService();
    switch on Trigger.operationType {
        when AFTER_INSERT {
            sssSharingService.shareSharedSolarSystems(Trigger.new);
        } when AFTER_UPDATE {
            sssSharingService.changeSharesAfterEligibilityUpdate(Trigger.oldMap, Trigger.newMap);
        } when AFTER_DELETE {
            sssSharingService.unshareSharedSolarSystemsAfterDelete(Trigger.oldMap);
        }
    }
}