trigger ResidentialEquipmentTrigger on Residential_Equipment__c (before insert, before update, after insert, after update) {
        LoanHandler loanHandler = new LoanHandler(Trigger.isExecuting, Trigger.size);
        DisbursalHandler disbursalHandler = new DisbursalHandler ();

        if (Trigger.isUpdate && Trigger.isAfter) {
            loanHandler.onAfterResidentialEquipmentUpdate(Trigger.newMap, Trigger.oldMap);
            disbursalHandler.setEquipmentDisbursals(Trigger.new, Trigger.newMap, Trigger.oldMap);
        }
}