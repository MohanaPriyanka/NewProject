trigger AccountTrigger on Account (before insert, before update) {
    if (Util.isDisabled('Disable_AccountTrigger__c')) {
        return;
    }
    AccountTriggerHandler accountTriggerHandler = new AccountTriggerHandler(Trigger.isExecuting, Trigger.size);
    
    if(Trigger.isInsert && Trigger.isBefore){
        accountTriggerHandler.OnBeforeInsert(Trigger.new);
    }
    else if(Trigger.isUpdate && Trigger.isBefore){
        accountTriggerHandler.OnBeforeUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
    }
}