trigger DisbursalTrigger on Disbursal__c (before insert, after insert, before update, after update) {
    DisbursalHandler disbursalHandler = new DisbursalHandler ();
    if(Trigger.isUpdate && Trigger.isBefore){
        disbursalHandler.setStatusAndFBODateonFBOFunding(Trigger.new, Trigger.newMap, Trigger.oldMap);
        disbursalHandler.setStatusToDisbursed(Trigger.new, Trigger.newMap, Trigger.oldMap);
        disbursalHandler.setStatusToHold(Trigger.new, Trigger.newMap, Trigger.oldMap);
    }
}
