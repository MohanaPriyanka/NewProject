public with sharing class RecurringPaymentsHandler {
    private boolean m_isExecuting = false;
    private Integer BatchSize = 0;
    
    public RecurringPaymentsHandler(boolean isExecuting, Integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
    }
    public void OnAfterInsert(UASB__c[] newUtilityAccountBillSubscriptionUpdates){
        updateRecurringCharge(newUtilityAccountBillSubscriptionUpdates);
    }
    /*public void OnAfterUpdate(UASB__c[] oldUtilityAccountBillSubscriptionUpdates, UASB__c[] newUtilityAccountBillSubscriptionUpdates, Map<ID, UASB__c> oldUtilityAccountBillSubscriptionUpdateMap, Map<ID, UASB__c> newUtilityAccountBillSubscriptionUpdateMap){
        updateRecurringCharge(newUtilityAccountBillSubscriptionUpdates);
    }*/
    private void updateRecurringCharge(List<UASB__c> utilityAccountBillSubscriptionList){

        Set<System_Bill__C> newSystemBillSet = new Set<System_Bill__C>();
        Set<Id> propertyAccountSet = new Set<Id>();
        Map<String, ChargentOrders__ChargentOrder__c> chOrderMap = new Map<String, ChargentOrders__ChargentOrder__c>();
        string conditionalDebugCheck = 'No Execution';
        decimal totalDue;

        List<UASB__c> uasbList = [SELECT Id, Name, System_Bill__r.Property_Account__c, System_Bill__r.Discounted_Bill__c,  System_Bill__r.Property_Account__r.Id, System_Bill__r.Total_Due__c, System_Bill__r.Due_This_Month__c, 
                                 System_Bill__r.Property_Account__r.Name, System_Bill__r.Recurring_Payment_Id__c, System_Bill__r.Property_Account__r.Recurring_Billing__c
                                 FROM UASB__c WHERE Id IN : utilityAccountBillSubscriptionList];
        for(UASB__c uasb : uasbList){
            system.debug(uasb.Name);
            system.debug(uasb.System_Bill__c);
            system.debug(uasb.System_Bill__r.Property_Account__r.Name + ' ' + uasb.System_Bill__r.Property_Account__r.Recurring_Billing__c);
            if(uasb.System_Bill__r.Property_Account__r.Recurring_Billing__c == TRUE){
                conditionalDebugCheck = 'PR.ACC with Recurring Billing found';
                newSystemBillSet.add(uasb.System_Bill__r);
                propertyAccountSet.add(uasb.System_Bill__r.Property_Account__r.Id);
            }
        }
        system.Debug(newSystemBillSet.size());
        system.Debug(propertyAccountSet.size());
        system.Debug(conditionalDebugCheck);
        for(System_Bill__C oldSystemBillSet : [SELECT Id, Name, Recurring_Payment_Id__c, Property_Account__r.Id, Unique_Id__c,
                                                                (SELECT Id, Name, System_Bill__r.Property_Account__c, System_Bill__r.Recurring_Payment_Id__c, System_Bill__r.Bill_Number__c ,
                                                                    ChargentOrders__Charge_Amount__c, Unique_Id__c, ChargentOrders__Payment_Status__c, System_Bill__r.Unique_Id__c
                                                                FROM Chargent_Orders__r 
                                                                WHERE  ChargentOrders__Payment_Status__c = 'Recurring'
                                                                ORDER BY System_Bill__r.Bill_Number__c DESC)
                                                FROM System_Bill__C
                                                WHERE Recurring_Billing__c = TRUE
                                                AND Property_Account__r.Id IN : propertyAccountSet]){
            system.debug(oldSystemBillSet.Property_Account__r.Id);
            system.debug(propertyAccountSet);
            conditionalDebugCheck = 'No Execution';
            
            for(ChargentOrders__ChargentOrder__c chOrderValue : oldSystemBillSet.Chargent_Orders__r){
                system.debug(chOrderValue);
                if(chOrderValue.ChargentOrders__Payment_Status__c == 'Recurring'){
                    system.debug(chOrderMap.size());
                    if(chOrderMap.size() > 0 ){                   
                        for(ChargentOrders__ChargentOrder__c  chOrderCheck : chOrderMap.values()){
                            system.debug(chOrderCheck);
                            system.debug(chOrderCheck.System_Bill__r.Bill_Number__c);
                            system.debug(chOrderValue.System_Bill__r.Bill_Number__c);
                            if(chOrderCheck.System_Bill__r.Unique_ID__c == chOrderValue.System_Bill__r.Unique_ID__c){
                                if(chOrderValue.System_Bill__r.Bill_Number__c > chOrderCheck.System_Bill__r.Bill_Number__c){
                                    conditionalDebugCheck = 'Program entered into the removal of Ch.O from Map and entered a more recent Ch.O';
                                    chOrderMap.remove(chOrderCheck.System_Bill__r.Recurring_Payment_Id__c);
                                    chOrderMap.get(chOrderCheck.System_Bill__r.Recurring_Payment_Id__c).ChargentOrders__Payment_End_Date__c = date.today();                                    
                                    chOrderMap.put(chOrderValue.System_Bill__r.Recurring_Payment_Id__c, chOrderValue);
                                }                           
                                else{
                                    continue;
                                }
                                system.Debug(conditionalDebugCheck);
                            }
                            else{
                                chOrderMap.put(chOrderValue.System_Bill__r.Recurring_Payment_Id__c, chOrderValue);  
                            }
                        }
                    }
                    else{
                        conditionalDebugCheck = 'Program entered into placed the first Ch.O into the map';
                        chOrderMap.put(chOrderValue.System_Bill__r.Recurring_Payment_Id__c, chOrderValue);                     
                    }            
                    system.Debug(conditionalDebugCheck);
                }
            }
        }
        /*system.debug('The Chargent Order List value is ' + oldSystemBillSet.ChargentOrders__ChargentOrder__r);                                       
        for(ChargentOrders__ChargentOrder__r chOrder : oldSystemBillSet.ChargentOrders__ChargentOrder__r){
            chOrderMap.put(chOrder.Unique_Id__c, chOrder);
            system.debug('The Chargent Order ID is ' + chorder.Id)
        }*/
        try{
            if(newSystemBillSet.size() > 0 && chOrderMap.size() > 0){
                for(System_Bill__c newSb : newSystemBillSet){
                    totalDue = newSb.Total_Due__c + newSb.Discounted_bill__c;
                    system.debug(newSb.Total_Due__c);
                    system.debug(newSb.Discounted_bill__c);
                    //system.debug(chOrderMap.get(newSb.Recurring_Payment_Id__c).ChargentOrders__Charge_Amount__c);
                    chOrderMap.get(newSb.Recurring_Payment_Id__c).System_Bill__c = newSb.Id;
                    //chOrderMap.get(newSb.Recurring_Payment_Id__c).ChargentOrders__Charge_Amount__c = totalDue;
                    system.debug(newSb.Id);
                    system.debug('System Bill total due is ' + newSb.Total_Due__c);
                }
                update chOrderMap.values();
                system.debug(chOrderMap.values());
            }
        }    
        catch(System.nullPointerException e){
            system.debug('No values in System Bill list of Chargent Order list');
            return;
        }    
    }
}