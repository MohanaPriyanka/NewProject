trigger SystemBillAccountingLogicTrigger on System_Bill__c (before insert, after insert, before update, after update) {
    SystemBillAccountingLogicHandler handler = new SystemBillAccountingLogicHandler(Trigger.isExecuting, Trigger.size);

         if(Trigger.isUpdate && Trigger.isBefore){
                handler.OnBeforeUpdate (Trigger.new);
            }
            
        if(Trigger.isInsert && Trigger.isBefore){
                handler.OnBeforeUpdate (Trigger.new);
            }
}