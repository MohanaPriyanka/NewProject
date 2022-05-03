trigger UserTrigger on User (after insert, after update) {
    Boolean isAsync = (System.isFuture() || System.isQueueable() || System.isBatch());
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            if (!isAsync) {
                UserTriggerHandler.afterInsert(Trigger.new);                
            }            
        }
        if (Trigger.isUpdate && Trigger.isAfter ) {
            if (!isAsync) {              
                UserTriggerHandler.afterUpdate(Trigger.new,Trigger.oldMap);
            }            
        }
    } 
}