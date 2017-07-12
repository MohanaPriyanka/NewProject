trigger EnergyUsageUpdateTrigger on Energy_Usage_Update__c (after update) {
    EnergyUsageUpdateTriggerHandler handler = new EnergyUsageUpdateTriggerHandler();
    
    if(Trigger.isUpdate && Trigger.isAfter){    	
	    List <Energy_Usage_Update__c> trigProdUpdateList = new List <Energy_Usage_Update__c> ();
	    for(Energy_Usage_Update__c productionUpdate : Trigger.new) {  
	        if (productionUpdate.Generate_Bills__c) {
	            Id newvalueID = productionUpdate.Id;
	            Boolean newBox = productionUpdate.Generate_Bills__c;
	            Boolean oldBox = Trigger.OldMap.get(newvalueID).Generate_Bills__c;
	                if (newBox && !oldBox) { 
	                    trigProdUpdateList.add(productionUpdate);
	                } 
	        }
	    } 
		handler.createCSBillingLog(trigProdUpdateList);
    }
}