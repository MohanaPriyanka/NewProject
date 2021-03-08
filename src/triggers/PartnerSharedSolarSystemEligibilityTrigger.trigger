/**
 * Created by peteryao on 11/22/20.
 * Tested By: SharedSolarSystemSharingServiceTest
 */

trigger PartnerSharedSolarSystemEligibilityTrigger on Partner_Shared_Solar_System_Eligibility__c (before insert, before update, after insert, after update, before delete) {
    if (Util.isDisabled('Disable_PartnerSSSEligibilityTrigger__c')) {
        return;
    }
    SharedSolarSystemSharingService sssSharingService = new SharedSolarSystemSharingService();
    switch on Trigger.operationType {
        when BEFORE_INSERT, BEFORE_UPDATE {
            new PartnerSSSEligibilities(Trigger.new).validate();
        } when AFTER_INSERT {
            sssSharingService.shareSharedSolarSystems(Trigger.new);
        } when AFTER_UPDATE {
            sssSharingService.changeSharesAfterEligibilityUpdate(Trigger.oldMap, Trigger.newMap);
        } when BEFORE_DELETE {
            new PartnerSSSEligibilities(Trigger.old).preventDeleteForPreviouslyActiveRecords();
        }
    }
}