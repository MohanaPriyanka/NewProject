/**
 * Created by: Kristin White on 9/28/2020
 * 
 * Tested by: UtilityDataRequestServiceTest
 */

trigger UtilityDataRequestTrigger on Utility_Data_Request__c (after update) {
    if (Util.isDisabled('Disable_UtilityDataRequestTrigger__c')) {
        return;
    }
    
    UtilityDataRequestService udrService = new UtilityDataRequestService();
    
    switch on Trigger.operationType {
        when AFTER_UPDATE {
            udrService.updateUDRP(Trigger.oldMap, Trigger.new);
        }
    }

}