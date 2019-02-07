trigger SystemBillTrigger on System_Bill__c (before insert, before update, after insert, after update) {
    List<System_Properties__c> systemProperties = System_Properties__c.getall().values();
    if (systemProperties.size() > 0 &&
        systemProperties[0].Disable_System_Bill_Trigger__c) {
        // Don't run trigger
    } else {
        if ((Trigger.isInsert && Trigger.isBefore) ||
            (Trigger.isUpdate && Trigger.isBefore)) {
            SystemBillAccountingLogicHandler.accountingRefresh(Trigger.new, Trigger.oldMap);
        }
    }
}