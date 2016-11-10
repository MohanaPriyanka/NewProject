trigger UtilityAccountBillTrigger on Utility_Account_Bill__c(after insert, after update) {

    UtilityAccountBillTriggerHandler handler = new UtilityAccountBillTriggerHandler(Trigger.isExecuting, Trigger.size);

    if(Trigger.isInsert && Trigger.isAfter){
        handler.OnAfterInsert(Trigger.new);
        //CSBillingLogTriggerHandler.OnAfterInsertAsync(Trigger.newMap.keySet());
    }
    else if(Trigger.isUpdate && Trigger.isAfter){
        handler.OnAfterUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
        //CSBillingLogTriggerHandler.OnAfterUpdateAsync(Trigger.newMap.keySet());
   }
    
    /*
    
    if(Trigger.isInsert && Trigger.isBefore){
        handler.OnBeforeInsert(Trigger.new);
    }
    
    else if(Trigger.isUpdate && Trigger.isBefore){
        handler.OnBeforeUpdate(Trigger.old, Trigger.new, Trigger.oldMap, Trigger.newMap);
    }
    
    else if(Trigger.isDelete && Trigger.isBefore){
        handler.OnBeforeDelete(Trigger.old, Trigger.oldMap);
    }
    else if(Trigger.isDelete && Trigger.isAfter){
        handler.OnAfterDelete(Trigger.old, Trigger.oldMap);
        //CSBillingLogTriggerHandler.OnAfterDeleteAsync(Trigger.oldMap.keySet());
    }
    
    else if(Trigger.isUnDelete){
        handler.OnUndelete(Trigger.new);    
    }
    */

                                                 
    //for(CS_Billing_Log__c o : Trigger.new){
    //    if(Trigger.isInsert || (Trigger.isUpdate && 
    //                            Trigger.oldMap.get(o.iD).Discounted_Bill__c == o.Discounted_Bill__c && 
    //                            Trigger.oldMap.get(o.iD).Customer_Subscription_KW_DC__c == o.Customer_Subscription_KW_DC__c && 
    //                            Trigger.oldMap.get(o.iD).Net_Metering_Credits_Allocated__c == o.Net_Metering_Credits_Allocated__c && 
    //                            Trigger.oldMap.get(o.iD).Savings__c == o.Savings__c && 
    //                            Trigger.oldMap.get(o.iD).Subscription_Production__c == o.Subscription_Production__c)){  
    //        createUASB.createUASB(Trigger.new);
    //    }
    //}
}