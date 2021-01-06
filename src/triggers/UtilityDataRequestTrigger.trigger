/**
 * Created by: Kristin White on 9/28/2020
 * 
 * Tested by: UtilityDataRequestServiceTest, GlyntUploadServiceTest
 */
trigger UtilityDataRequestTrigger on Utility_Data_Request__c (after insert, after update, before update) {
    if (Util.isDisabled('Disable_UtilityDataRequestTrigger__c')) {
        return;
    }
    
    UtilityDataRequestService udrService = new UtilityDataRequestService(Trigger.oldMap, Trigger.newMap);
    GlyntUploadService uploadService = new GlyntUploadService();

    switch on Trigger.operationType {
        when AFTER_INSERT {
            uploadService.associateContentToUDRs(Trigger.new);
            uploadService.queueGlyntUpload(Trigger.new);
        }
        when BEFORE_UPDATE {
            udrService.beforeStatusUpdatedToComplete();
        }
        when AFTER_UPDATE {
            udrService.afterStatusUpdatedToComplete();
        }
    }

}