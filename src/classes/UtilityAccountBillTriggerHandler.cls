public with sharing class UtilityAccountBillTriggerHandler {
    private boolean m_isExecuting = false;
    private Integer BatchSize = 0;
    
    public UtilityAccountBillTriggerHandler(boolean isExecuting, Integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
    }
    public void OnAfterInsert(Utility_Account_Bill__c[] newUtilityAccountBillUpdates){
        createUASB(newUtilityAccountBillUpdates);
    }
   public void OnAfterUpdate(Utility_Account_Bill__c[] oldUtilityAccountBillUpdates, Utility_Account_Bill__c[] updatedUtilityAccountBillUpdates, Map<ID, Utility_Account_Bill__c> oldUtilityAccountBillUpdateMap, Map<ID, Utility_Account_Bill__c> newUtilityAccountBillUpdateMap){
        createUASB(updatedUtilityAccountBillUpdates);
    }
    private void createUASB(List<Utility_Account_Bill__c> utilityAccountBillList){
        
        //Get the set of utilityAccountLogSet to process
        Map<Id, Utility_Account_Bill__c> utilityAccountLogIdToUABMap = new Map<Id, Utility_Account_Bill__c>();
        Map<string, Utility_NMC_Tariff__c > nmcMap = new Map<string, Utility_NMC_Tariff__c >();
        Map<string, System_Bill__c > systemBillMap = new Map<string, System_Bill__c >();
        Map<string, Utility_Account_Subscription__c > uasMap = new Map<string, Utility_Account_Subscription__c >();
        String uasOppUalIdentifier;
        Integer counter = 0;
        //String systemBillKey;
        
        for(Utility_Account_Bill__c uab : utilityAccountBillList){
            utilityAccountLogIdToUABMap.put(uab.Utility_Account_Log__c, uab);
        }
        
        //Get the Utility NMC Tariff records
        for(Utility_NMC_Tariff__c nmcRate : [SELECT Value_of_Net_Metering_Credit__c, Name, Sizing_Rate__c, Current_Billing_Rate__c, Date__c  
                                             FROM Utility_NMC_Tariff__c
                                             WHERE Sizing_Rate__c = false
                                             AND Current_Billing_Rate__c = true
                                             ORDER BY Date__c DESC]){
            nmcMap.put(nmcRate.Name, nmcRate);
        }
        for(System_Bill__c systemBill : [SELECT Id, Name, Unique_Id__c, Date__c, Opportunity__r.Name, Opportunity__r.Shared_Solar_System__r.Name
                                            FROM System_Bill__c 
                                            WHERE Id != null]){
            systemBillMap.put(systemBill.Unique_Id__c, systemBill);
            system.debug(systemBill.Unique_Id__c);
        }        
        Set<UASB__c> uasbSet = new Set<UASB__c>();
        //Get all of the Utility_Account_Subscription__c that is linked to the Utility_Account_Log__c object
        for(Utility_Account_Subscription__c uas : [ SELECT Id, Name, Customer_Subscription_KW_DC_STATIC__c,
                                                            Customer_Subscription_KW_DC__c, 
                                                            Opportunity__c, 
                                                            Opportunity__r.Name,
                                                            Opportunity__r.Shared_Solar_System__r.Name,
                                                          //Subscription_Key__c, 
                                                            UAS_Number__c,
                                                            Share_of_System__c ,                                                            
                                                            Utility_Account_Log__c,
                                                            Opportunity__r.Shared_Solar_System__r.Total_System_Size_kwh_dc__c, 
                                                            Opportunity__r.NMC_Value__c, 
                                                            Opportunity__r.Shared_Solar_System__c
                                                    FROM Utility_Account_Subscription__c 
                                                    WHERE Utility_Account_Log__c != null 
                                                    AND Opportunity__c != null 
                                                    AND Customer_Group__c != 'Anchor'
                                                    AND Opportunity__r.StageName = 'Complete'                                                    
                                                    AND Utility_Account_Log__c IN : utilityAccountLogIdToUABMap.keySet()
                                                    ORDER BY UAS_Number__c]){
            if(utilityAccountLogIdToUABMap.containsKey(uas.Utility_Account_Log__c)){
                uasOppUalIdentifier = uas.Opportunity__r.Id + ' ' + uas.Utility_Account_Log__c;
                uasMap.put(uasOppUalIdentifier, uas);
                Utility_Account_Bill__c uab = utilityAccountLogIdToUABMap.get(uas.Utility_Account_Log__c);
                //for(System_Bill__c sbDate : systemBillMap.values()){
                //  if(sbDate.Opportunity__r.Name == uas.Opportunity__r.Name && sbDate.Opportunity__r.Shared_Solar_System__r.Name == uas.Opportunity__r.Shared_Solar_System__r.Name){
                //      systemBillKey = uas.Opportunity__r.Name + ' ' + uas.Opportunity__r.Shared_Solar_System__r.Name + ' ' + DateTime.newInstance(sbDate.Date__c.year(), sbDate.Date__c.month(),sbDate.Date__c.day()).format('yyyy-MM');
                //  }
                //}
                string systemBillKey = uas.Opportunity__r.Name + ' ' + uas.Opportunity__r.Shared_Solar_System__r.Name + ' ' + DateTime.newInstance(uab.Date__c.year(), uab.Date__c.month(),uab.Date__c.day()).format('yyyy-MM');
                System.debug(LoggingLevel.Info, 'The System Bill Key is ' + systemBillKey);
                //system.debug(LoggingLevel.Info, 'The SSS of the UAB is ' + uab.Shared_Solar_System__c );
                //system.debug(LoggingLevel.Info, 'The SSS of the UAS is ' + uas.Opportunity__r.Shared_Solar_System__c  );
                if(uab.Shared_Solar_System__c == uas.Opportunity__r.Shared_Solar_System__c 
                    && nmcMap.containsKey(uab.NMC_Rate_ID__c)){
                    counter = counter + 1;
                    UASB__c uasb = new UASB__c( Name = uab.Name + uas.Opportunity__r.Shared_Solar_System__r.Name,
                                            Customer_Subscription_KW_DC__c = uas.Customer_Subscription_KW_DC_STATIC__c,
                                            CS_Billing_Log__c = uab.Id, 
                                            Date__c = uab.Date__c,
                                            Production_Update__c = uab.Production_Update__c,
                                            Utility_Account_Subscription__c = uas.Id,  
                                            Opportunity__c = uas.Opportunity__c,
                                            System_Bill__c = systemBillMap.get(systemBillKey).Id,
                                            Shared_Solar_System__c = uas.Opportunity__r.Shared_Solar_System__c,
                                            Billing_Period_Start_Date__c = uab.Billing_Period_Start_Date__c,
                                            Billing_Period_End_Date__c = uab.Billing_Period_End_Date__c,
                                            Total_System_Size_kW_DC__c = uas.Opportunity__r.shared_solar_system__r.Total_System_Size_kWh_DC__c,
                                            NMC_Rate__c = nmcMap.get(uab.NMC_Rate_ID__c).Value_of_Net_Metering_Credit__c,
                                            Total_System_Production_kWh__c = uab.Production_kWh_DC__c,                                                                                       
                                            Total_System_NMCs__c = uab.Total_System_NMCs__c,
                                            Size_off_NMCs__c = uab.Size_off_NMCs__c,
                                            Share_of_System__c = uas.Share_of_System__c);

                    uasb.Unique_Id__c = uas.Opportunity__r.Shared_Solar_System__c + ' - ' + uas.Id + ' - ' + DateTime.newInstance(uab.Date__c.year(), uab.Date__c.month(),uab.Date__c.day()).format('yyyy-MM');
                    uasbSet.add(uasb);
                    system.debug(LoggingLevel.Info, uasb);                   
                }
                system.debug(LoggingLevel.Info,uas.Opportunity__r.Name + ' ' + uas.Opportunity__r.Shared_Solar_System__r.Name + ' ' + uas.Utility_Account_Log__c + DateTime.newInstance(uab.Date__c.year(), uab.Date__c.month(),uab.Date__c.day()).format('yyyy-MM'));
            }
        }
        System.debug(LoggingLevel.Info,'counter = ' + counter);
        system.debug(LoggingLevel.Info, uasbSet.size()); 
        if(uasbSet.size() > 0) upsert new List<UASB__c>(uasbSet) Unique_Id__c;
    }

    /*
        

    public void OnBeforeInsert(CS_Billing_Log__c[] newCSBillingLogUpdates){
    }
    
    
    @future public static void OnAfterInsertAsync(Set<Id> newCSBillingLogUpdateIDs){
    }
    
    public void OnBeforeUpdate(CS_Billing_Log__c[] oldCSBillingLogUpdates, CS_Billing_Log__c[] updatedCSBillingLogUpdates, Map<ID, CS_Billing_Log__c> oldCSBillingLogUpdateMap, Map<ID, CS_Billing_Log__c> newCSBillingLogUpdateMap){
    }
    
    
    @future public static void OnAfterUpdateAsync(Set<Id> updatedCSBillingLogUpdateIDs){
    }
    
    public void OnBeforeDelete(CS_Billing_Log__c[] CSBillingLogUpdatesToDelete, Map<ID, CS_Billing_Log__c> CSBillingLogUpdateMap){
        
    }
    
    public void OnAfterDelete(CS_Billing_Log__c[] deletedCSBillingLogUpdates, Map<ID, CS_Billing_Log__c> CSBillingLogUpdateMap){
        
    }
    
    @future public static void OnAfterDeleteAsync(Set<Id> deletedCSBillingLogUpdateIDs){
        
    }
    
    public void OnUndelete(CS_Billing_Log__c[] restoredCSBillingLogUpdates){
        
    }
    
    public boolean IsTriggerContext{
        get{ return m_isExecuting;}
    }
    
    public boolean IsVisualforcePageContext{
        get{ return !IsTriggerContext;}
    }
    
    public boolean IsWebServiceContext{
        get{ return !IsTriggerContext;}
    }
    
    public boolean IsExecuteAnonymousContext{
        get{ return !IsTriggerContext;}
    }
    */
}