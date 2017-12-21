trigger UtilityAccountBillTrigger on Utility_Account_Bill__c(after insert, after update) {
    UtilityAccountBillTriggerHandler handler = new UtilityAccountBillTriggerHandler();
    handler.createUASB(Trigger.new);
}