trigger ResidentialEquipmentTrigger on Residential_Equipment__c (before insert, before update, after insert, after update) {
        LoanHandler loanHandler = new LoanHandler(Trigger.isExecuting, Trigger.size);
        
        if (Trigger.isUpdate && Trigger.isAfter) {
            loanHandler.onAfterResidentialEquipmentUpdate(Trigger.new, Trigger.old);
        }
}