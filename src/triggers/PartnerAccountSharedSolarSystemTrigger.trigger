trigger PartnerAccountSharedSolarSystemTrigger on Partner_Account_Shared_Solar_System__c (after insert, after delete) {
    if (Trigger.isAFter) {
        if (Trigger.isInsert) {
            PartnerAccountSSSTriggerHandler.afterInsert(Trigger.new);
        } else if (Trigger.isDelete) {
            PartnerAccountSSSTriggerHandler.afterDelete(Trigger.oldMap);
        }
    }
}