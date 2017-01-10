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

        System.debug('The utilityAccountBillSubscriptionList size = ' + utilityAccountBillSubscriptionList.size());
        Set<System_Bill__C> newSystemBillSet = new Set<System_Bill__C>();
        Set<Id> propertyAccountSet = new Set<Id>();
        Map<String, ChargentOrders__ChargentOrder__c> chOrderMap = new Map<String, ChargentOrders__ChargentOrder__c>();
        string conditionalDebugCheck = 'No Execution';
        decimal totalDue;
        string chOrderValueSystemBillIdentifier;
        String chOrderCheckSystemBillIdentifier;


        List<UASB__c> uasbList = [SELECT Id, Name, System_Bill__r.Property_Account__c, System_Bill__r.Discounted_Bill__c,  System_Bill__r.Name,
                                    System_Bill__r.Property_Account__r.Id, System_Bill__r.Total_Due__c, System_Bill__r.Due_This_Month__c, 
                                    System_Bill__r.Property_Account__r.Name, System_Bill__r.Recurring_Payment_Id__c, 
                                    System_Bill__r.Property_Account__r.Recurring_Billing__c
                                 FROM UASB__c WHERE Id IN : utilityAccountBillSubscriptionList];
        System.debug('The uasbList size = ' + uasbList.size());
        for(UASB__c uasb : uasbList){            
            System.debug('UASB Recurring = ' + uasb.System_Bill__r.Property_Account__r.Recurring_Billing__c);
            System.debug(uasb.Name);
            System.debug(uasb.System_Bill__c);
            System.debug(uasb.System_Bill__r.Property_Account__r.Name + ' ' + uasb.System_Bill__r.Property_Account__r.Recurring_Billing__c);
            if(uasb.System_Bill__r.Property_Account__r.Recurring_Billing__c == TRUE){
                conditionalDebugCheck = 'PR.ACC with Recurring Billing found';
                System.debug('The Recurring Account Name is ' + uasb.System_Bill__r.Property_Account__r.Name);
                newSystemBillSet.add(uasb.System_Bill__r);
                propertyAccountSet.add(uasb.System_Bill__r.Property_Account__r.Id);
            }
        }
        system.Debug(newSystemBillSet.size());
        system.Debug(propertyAccountSet.size());
        system.Debug(conditionalDebugCheck);
        for(System_Bill__C oldSystemBillSet : [SELECT Id, Name, Recurring_Payment_Id__c, Property_Account__r.Id, Unique_Id__c, Opportunity__r.Id, 
                                                                (SELECT Id, Name, System_Bill__r.Name, System_Bill__r.Property_Account__c, System_Bill__r.Recurring_Payment_Id__c, System_Bill__r.Bill_Number__c ,
                                                                    ChargentOrders__Charge_Amount__c, Unique_Id__c, ChargentOrders__Payment_Status__c, System_Bill__r.Unique_Id__c, 
                                                                    System_Bill__r.Opportunity__r.Id, System_Bill__r.Shared_Solar_System__r.Id
                                                                FROM Chargent_Orders__r 
                                                                WHERE  ChargentOrders__Payment_Status__c = 'Recurring'
                                                                ORDER BY System_Bill__r.Bill_Number__c DESC)
                                                FROM System_Bill__C
                                                WHERE Recurring_Billing__c = TRUE
                                                AND Property_Account__r.Id IN : propertyAccountSet]){
            system.debug(oldSystemBillSet.Property_Account__r.Id);
            System.debug('The System bill Chargent Order List is ' + oldSystemBillSet.Chargent_Orders__r);
            system.debug(propertyAccountSet);
            conditionalDebugCheck = 'No Execution';
            
            for(ChargentOrders__ChargentOrder__c chOrderValue : oldSystemBillSet.Chargent_Orders__r){
                System.debug(chOrderValue);
                if(chOrderValue.ChargentOrders__Payment_Status__c == 'Recurring'){
                    chOrderValueSystemBillIdentifier = chOrderValue.System_Bill__r.Opportunity__r.Id + ' ' + chOrderValue.System_Bill__r.Shared_Solar_System__r.Id;                            
                    System.debug(chOrderMap.size());
                    if(chOrderMap.size() > 0 ){                   
                        for(ChargentOrders__ChargentOrder__c  chOrderCheck : chOrderMap.values()){
                            chOrderCheckSystemBillIdentifier = chOrderCheck.System_Bill__r.Opportunity__r.Id + ' ' + chOrderCheck.System_Bill__r.Shared_Solar_System__r.Id;
                            System.debug('chOrderValueSystemBillIdentifier' + ' ' + chOrderValueSystemBillIdentifier);
                            System.debug('chOrderCheckSystemBillIdentifier' + ' ' + chOrderCheckSystemBillIdentifier);
                            System.debug('chOrderCheck.System_Bill__r.Unique_ID__c = ' + ' ' +  chOrderCheck.System_Bill__r.Unique_ID__c);
                            System.debug('chOrderValue.System_Bill__r.Unique_ID__c = ' + ' ' +  chOrderValue.System_Bill__r.Unique_ID__c);                          
                            System.debug(chOrderCheck);
                            System.debug(chOrderCheck.System_Bill__r.Bill_Number__c);
                            System.debug(chOrderValue.System_Bill__r.Bill_Number__c);
                            if(chOrderCheck.System_Bill__r.Unique_ID__c == chOrderValue.System_Bill__r.Unique_ID__c){
                                if(chOrderValue.System_Bill__r.Bill_Number__c > chOrderCheck.System_Bill__r.Bill_Number__c){
                                    conditionalDebugCheck = 'Program entered into the removal of Ch.O from Map and entered a more recent Ch.O';
                                    chOrderMap.remove(chOrderCheck.System_Bill__r.Recurring_Payment_Id__c);
                                    chOrderMap.get(chOrderCheck.System_Bill__r.Recurring_Payment_Id__c).ChargentOrders__Payment_End_Date__c = date.today();                                    
                                    chOrderMap.put(chOrderValue.System_Bill__r.Recurring_Payment_Id__c, chOrderValue);
                                }                           
                                else{
                                    System.debug('Contine');
                                    continue;
                                }
                                system.Debug(conditionalDebugCheck);
                            }
                            else{
                                System.debug('Add map');
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
        try {
            if (newSystemBillSet.size() > 0 && chOrderMap.size() > 0){
                System.debug('The newSystemBillSet size = ' + newSystemBillSet.size());
                for (System_Bill__c newSb : newSystemBillSet){                    
                    totalDue = newSb.Total_Due__c;
                    System.debug('The newSystemBillSet size is equal to ' + newSystemBillSet.size() + ' ' + 
                        ' ' + 'The old system bill was ' + chOrderMap.get(newSb.Recurring_Payment_Id__c).System_Bill__c + ' ' + 'The new System Bill is ' + newSb.Name + ' ' + 'with an Id of ' + newSb.Id + ' ' + 'and is being assigned the Chargent Order ' + chOrderMap.get(newSb.Recurring_Payment_Id__c).Id + ' ' + 'and has a new value of ' + newSb.Total_due__c);
                    System.debug('newSb.Id = ' + newSb.Id);
                    System.debug('newSb = ' + newSb);
                    chOrderMap.get(newSb.Recurring_Payment_Id__c).System_Bill__c = newSb.Id;
                    chOrderMap.get(newSb.Recurring_Payment_Id__c).ChargentOrders__Charge_Amount__c = newSb.Total_Due__c;
                    System.debug(newSb.Id);
                    System.debug('System Bill total due is ' + newSb.Total_Due__c);
                }
                System.debug('chOrderMap.size = ' + chOrderMap.size());
                System.debug('chOrderMap.values = ' + chOrderMap.values());
                update chOrderMap.values();
            }
        }    
        catch(System.nullPointerException e){
            System.debug('No values in System Bill list of Chargent Order list');
            return;
        }    
    }
}