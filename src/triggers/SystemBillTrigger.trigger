trigger SystemBillTrigger on System_Bill__c (before insert, before update) {
    SystemBillAccountingLogicHandler systemBillAccountingLogicHandler = new SystemBillAccountingLogicHandler();
    systemBillAccountingLogicHandler.accountingRefresh(Trigger.new);
}