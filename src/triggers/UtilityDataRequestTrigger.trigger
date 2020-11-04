/**
 * Created by: Kristin White on 9/28/2020
 * 
 * Tested by: UtilityDataRequestServiceTest
 */
trigger UtilityDataRequestTrigger on Utility_Data_Request__c (after update, before update) {
    if (Util.isDisabled('Disable_UtilityDataRequestTrigger__c')) {
        return;
    }
    
    UtilityDataRequestService udrService = new UtilityDataRequestService(Trigger.oldMap, Trigger.newMap);
    
    switch on Trigger.operationType {
        when BEFORE_UPDATE {
            udrService.beforeStatusUpdatedToComplete();
        }
        when AFTER_UPDATE {
            udrService.afterStatusUpdatedToComplete();
        }
    }

}