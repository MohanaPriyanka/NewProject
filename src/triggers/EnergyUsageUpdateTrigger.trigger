trigger EnergyUsageUpdateTrigger on Energy_Usage_Update__c (after update) {
    if (Trigger.isUpdate && Trigger.isAfter){
        List <Energy_Usage_Update__c> trigProdUpdateList = new List <Energy_Usage_Update__c> ();
        for (Energy_Usage_Update__c productionUpdate : Trigger.new) {  
            if (productionUpdate.Generate_Bills__c) {
                Id newvalueID = productionUpdate.Id;
                Boolean newBox = productionUpdate.Generate_Bills__c;
                Boolean oldBox = Trigger.OldMap.get(newvalueID).Generate_Bills__c;
                if (newBox && !oldBox) { 
                    trigProdUpdateList.add(productionUpdate);
                }
            }
        } 
        if (trigProdUpdateList.size() > 0) {
            EnergyUsageUpdateTriggerHandler ee = new EnergyUsageUpdateTriggerHandler(trigProdUpdateList);
            ee.runBills();
        }
    }
    if (Trigger.isInsert && Trigger.isAfter) {
        List <Energy_Usage_Update__c> euuUpdateList = new List <Energy_Usage_Update__c> ();
        for (Energy_Usage_Update__c euu : Trigger.new) {
            if (euu.Shared_Solar_System__c.Size_off_NMCs__c) {
                euu.Size_off_NMCs__c = true;
                euuUpdateList.add(euu);
            }
        }
        if (euuUpdateList.size() > 0) {
            EnergyUsageUpdateTriggerHandler ee = new EnergyUsageUpdateTriggerHandler(euuUpdateList);
        }
    }
}