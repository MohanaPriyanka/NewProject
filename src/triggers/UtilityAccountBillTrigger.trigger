trigger UtilityAccountBillTrigger on Utility_Account_Bill__c(after insert, after update) {
    /*
    Found an issue where we were looping through this trigger whenever an energy usage update was inserted. The
    UtilityAccountBillTriggerHandler upserts UtilityAccountSystemBills and those in turn update the Utility
    Account Bill on creation, which will trigger this again. The UtilityAccountBillTriggerHandler
    consumes ~15 SOQL queries whenever it is run, so if run twice it takes up about 30% of our SOQL limits in testing

     */
//    UtilityAccountBillTriggerHandler handler = new UtilityAccountBillTriggerHandler();
//    handler.createUASB(Trigger.new);
}