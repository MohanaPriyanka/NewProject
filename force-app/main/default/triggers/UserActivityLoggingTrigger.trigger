/**
 * Tested By: UserHandlerTest
 */

trigger UserActivityLoggingTrigger on Portal_User_Activated__e (after insert) {
    Set<Id> userIdSet = new Set<Id>();

    for (Portal_User_Activated__e portalUserActivatedEvent : Trigger.new) {
        if (portalUserActivatedEvent.User_Id__c != null) {
            userIdSet.add(portalUserActivatedEvent.User_Id__c);
        }
    }
    UserHandler userService = new UserHandler();
    userService.createPortalActivationEmailLog(userIdSet);
}