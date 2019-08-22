trigger ZuoraDataQueryTrigger on Zuora_Data_Query__c (after Insert) {
    if (trigger.isInsert && trigger.IsAfter) {
        ZuoraDataQueryService.callFromTrigger(Trigger.new);
    }
}