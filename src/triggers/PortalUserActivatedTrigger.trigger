/**
 * Created by joeychan on 2020-02-05.
 */

trigger PortalUserActivatedTrigger on Portal_User_Activated__e (after insert) {
    List<Id> userIdList = new List<Id>();
    for (Portal_User_Activated__e portalUserActivatedEvent : Trigger.new) {
        if (portalUserActivatedEvent.User_Id__c != null) {
            userIdList.add(portalUserActivatedEvent.User_Id__c);
        }
    }
    SharedSolarSystemSharingService sssService = new SharedSolarSystemSharingService();
    sssService.evaluateSharingViaUsers(userIdList);
}