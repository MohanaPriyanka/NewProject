trigger SystemBillTrigger on System_Bill__c (before insert, after insert, before update, after update) {
    SystemBillAccountingLogicHandler systemBillAccountingLogicHandler = new SystemBillAccountingLogicHandler();
    if(Trigger.isInsert && Trigger.isBefore){
        systemBillAccountingLogicHandler.accountingRefresh(Trigger.new);
    } else if(Trigger.isUpdate && Trigger.isBefore){
        systemBillAccountingLogicHandler.accountingRefresh(Trigger.new);
    }
}