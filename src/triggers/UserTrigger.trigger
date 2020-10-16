trigger UserTrigger on User (after insert) {
    Boolean isAsync = (System.isFuture() || System.isQueueable() || System.isBatch());
    if (Trigger.isAfter) {
        if (Trigger.isInsert) {
            if (!isAsync) {
                UserTriggerHandler.afterInsert(Trigger.new);
            }
        }
    } 
}