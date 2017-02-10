public with sharing class EnergyUsageUpdateTriggerHandler {
    private boolean m_isExecuting = false;
    private Integer BatchSize = 0;
    


    public EnergyUsageUpdateTriggerHandler(boolean isExecuting, Integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
    }
    public void OnAfterInsert(Energy_Usage_Update__c[] newEnergyUsageUpdates){
        createCSBillingLog(newEnergyUsageUpdates);
    }

    private void createCSBillingLog(List<Energy_Usage_Update__c> euuList){
        Map<Id, Energy_Usage_Update__c> sssIdToEUUMap = new Map<Id, Energy_Usage_Update__c>();
        Map<string, product_profile__c> productProfileMap = new Map<string, product_profile__c>();
        Map<Id, Shared_Solar_System__c> sssIdMap = new Map<Id, Shared_Solar_System__c>();
        integer abCounter = 1;
        integer tsbCounter = 1;
        integer i; 

        
        
        //load the triggered production updates into the instantiated map and set the SSS as the key value.
        for(Energy_Usage_Update__c euu : euuList){
            sssIdToEUUMap.put(euu.Shared_Solar_System__c, euu);
        }

        //select the UAS that are related to the shared solar systems that have production updates being logged.
        List<Utility_Account_Subscription__c> uasList = [SELECT   Id, Name, 
                                                                    Utility_Account_Log__c, 
                                                                    Opportunity__r.Name,
                                                                    Opportunity__r.Account.Name,
                                                                    Opportunity__r.Shared_Solar_System__r.Name,
                                                                    Opportunity__r.Shared_Solar_System__c,
                                                                    Opportunity__r.Shared_Solar_System__r.Id,
                                                                    Opportunity__r.AccountId
                                                           FROM Utility_Account_Subscription__c 
                                                           WHERE Utility_Account_Log__c != null
                                                           //AND Opportunity__r.StageName = 'Complete' 
                                                           AND Opportunity__c != null 
                                                           AND Customer_Group__c != 'Anchor'
                                                           AND Opportunity__r.Shared_Solar_System__c IN : sssIdToEUUMap.keySet() 
                                                           ORDER BY Name];

        //select the UAS that are related to the shared solar systems that have production updates being logged.
        List<Opportunity> oppList = [SELECT   Id, Name, Account.Name, Shared_Solar_System__r.Name, Shared_Solar_System__c, 
                                                AccountId, Account.Id, Account.Recurring_Billing__c
                                    FROM Opportunity 
                                    WHERE StageName = 'Complete' 
                                    AND Customer_Group__c != 'Anchor'
                                    AND Shared_Solar_System__c IN : sssIdToEUUMap.keySet() 
                                    ORDER BY Name];                                                           
        for(Shared_Solar_System__c sss : [  SELECT  Id, Name
                                            FROM Shared_Solar_System__c 
                                            WHERE Id IN : sssIdToEUUMap.keySet() 
                                            ORDER BY Name]){
            sssIdMap.put(sss.Id, sss);
        }
        //Generate a list of all account bills                                                   
        List<Account_Bill__c> accountBillList =  [ SELECT ID,Parent_Account__c, Unique_Id__c, Bill_Number__c, Parent_Account__r.Id, Last_Shared_Solar_System_ID__c, Name, Bill_Number_Guard__c
                                                    FROM Account_Bill__c
                                                    WHERE Id != null];                                       
      

        //Generate a list of all Totalized System Bills                                                  
     //   List<Totalized_System_Bill__c> totalizedSystemBillList =  [ SELECT ID,Shared_Solar_System__c
     //                                      FROM Totalized_System_Bill__c
     //                                      WHERE Id != null];



        List<Utility_Account_Bill__c> utilityAccountBillList =  [ SELECT ID, Account_Bill__r.Parent_Account__c, Account_Bill__r.Parent_Account__r.Id
                                           FROM Utility_Account_Bill__c
                                           WHERE Id != null];

        //Generate a list of all System Bills                                                  
        List<System_Bill__c> systemBillList =  [ SELECT ID, Shared_Solar_System__c,Shared_Solar_System_ID__c, Property_Account__r.Id, Opportunity__c, 
                                                    Shared_Solar_System__r.Name, Property_Account__r.Name
                                           FROM System_Bill__c
                                           WHERE Id != null];                                                                                                                                            
        system.debug(accountBillList.size());                                     
        Map<String, Account_Bill__c> abKeyToAccountBillMap = new Map<String, Account_Bill__c>();
        Map<String, Account_Bill__c> accountBillMapBillNumberFix = new Map<String, Account_Bill__c>();
        List<Account_Bill__c> myAccountBillList = new List<Account_Bill__c>();    
        for(Utility_Account_Subscription__c uas : uasList){
            if(sssIdToEUUMap.containsKey(uas.Opportunity__r.Shared_Solar_System__c)){    
                system.debug('Check sssIdToEUUMap If Clause');      
                system.debug(loggingLevel.info, uas.Opportunity__r.Shared_Solar_System__c);
                system.debug(logginglevel.info, uas.Name);         
                Energy_Usage_Update__c euu = sssIdToEUUMap.get(uas.Opportunity__r.Shared_Solar_System__c);
                //count how many accountBills exist in the system for this specific Parent Account 
                for(i=0;i<accountBillList.size();i++){
                    if(accountBillList.get(i).Parent_Account__r.Id == uas.Opportunity__r.Account.Id ){
                        myAccountBillList.add(accountBillList.get(i));
                        abCounter = abCounter + 1;      
                    }                                                  
                }
                Account_Bill__c ab = new Account_Bill__c(Name = uas.Opportunity__r.Account.Name + ' ' + euu.MonthDate__c + ' ' + euu.YearDate__c, 
                                                         Date__c =  euu.Date__c,
                                                         Parent_Account__c = uas.Opportunity__r.Account.Id,
                                                         //Product_Profile__c = productProfileMap.get(uas.Opportunity__r.Account.Id).Id,
                                                         Bill_Number__c = abCounter,
                                                         Last_Shared_Solar_System_ID__c = uas.Opportunity__r.Shared_Solar_System__r.Id);                                                         
                ab.Unique_Id__c = uas.Opportunity__r.Account.Id + ' ' + DateTime.newInstance(euu.Date__c.year(), euu.Date__c.month(),euu.Date__c.day()).format('yyyy-MM');
                abKeyToAccountBillMap.put(ab.Unique_Id__c, ab);
                system.debug('The Account Bill is ' + ab);
                system.debug('The Account Bill Map is ' + abKeyToAccountBillMap);
            }
            abCounter = 1;
        }
        integer c;
        system.debug(LoggingLevel.info, accountBillList.size());
        integer check = 0;
        for(c=0;c<accountBillList.size();c++){
            check = 1;
            accountBillMapBillNumberFix.put(accountBillList.get(c).Unique_Id__c, accountBillList.get(c));
            system.debug(LoggingLevel.info, accountBillList.get(c).Unique_Id__c);           
        }   
        system.debug(LoggingLevel.info, check);         
        system.debug(LoggingLevel.info, accountBillMapBillNumberFix.size());     
        for(Account_Bill__c abCounterFix : abKeyToAccountBillMap.values()){
            system.debug(LoggingLevel.info, abCounterFix.Unique_Id__c);
            if(accountBillMapBillNumberFix.containsKey(abCounterFix.Unique_Id__c)){
                system.debug(LoggingLevel.info, abCounterFix.Bill_Number__c);                
                abCounterFix.Bill_Number__c = abCounterFix.Bill_Number__c - 1;
                system.debug(LoggingLevel.info, abCounterFix.Bill_Number__c);
            }
        }        
        //Create the Account Bills
        system.debug('The abKeyToAccountBillMap is ' + abKeyToAccountBillMap);
        if(abKeyToAccountBillMap.size() > 0){
            upsert abKeyToAccountBillMap.values() Unique_Id__c;
        }
        system.debug('The UAS List is ' + uasList);
        for(Utility_Account_Subscription__c uas : uasList){
            if(sssIdMap.containsKey(uas.Opportunity__r.Shared_Solar_System__c)){
                Energy_Usage_Update__c euu = sssIdToEUUMap.get(uas.Opportunity__r.Shared_Solar_System__c);
                Shared_Solar_System__c sss = sssIdMap.get(uas.Opportunity__r.Shared_Solar_System__c);
                system.debug(sss);
            }
        }
        
        Set<System_Bill__c> systemBillSet = new Set<System_Bill__c>();
        for(Opportunity opp : oppList){
            System.debug('The Pr.Acc List is ' + opp.Account.Id);
            set<string> sbSetCheck = new set<string>();
            System.debug('The euu is ' + sssIdToEUUMap.get(opp.Shared_Solar_System__c));
            Energy_Usage_Update__c euu = sssIdToEUUMap.get(opp.Shared_Solar_System__c);
            String systemKey = opp.Shared_Solar_System__c + ' ' + DateTime.newInstance(euu.Date__c.year(), euu.Date__c.month(),euu.Date__c.day()).format('yyyy-MM');
            String parentKey = opp.Account.Id + ' ' + DateTime.newInstance(euu.Date__c.year(), euu.Date__c.month(),euu.Date__c.day()).format('yyyy-MM');            
            System.debug('The systemKey is ' + systemKey);
            System.debug('The parentKey is ' + parentKey);
            Account_Bill__c ab = abKeyToAccountBillMap.get(parentKey);
            integer sbCounter = 1;
            // Totalized_System_Bill__c tsb = sbKeyToTSBMap.get(systemKey);            
            string systemBillIdentifier;
            system.debug(LoggingLevel.info, systemBillList.size());
            for(i=0;i<systemBillList.size();i++){
                integer ifCheck = 0;
                system.debug('systemBillList / sssId ' + systemBillList.get(i).Shared_Solar_System__r.Name +' ' + systemBillList.get(i).Shared_Solar_System__r.Id + ' ' + opp.Shared_Solar_System__r.Id + ' ' + opp.Shared_Solar_System__r.Name);
                system.debug('propertyAccountId ' + systemBilllist.get(i).Property_Account__r.Name + ' ' + opp.Account.Name + opp.Name);
                if(systemBillList.get(i).Shared_Solar_System__r.Id == opp.Shared_Solar_System__r.Id
                    && systemBilllist.get(i).Property_Account__r.Id == opp.Account.Id){
                        ifCheck = 1;
                        sbCounter = sbCounter + 1;
                }
                //system.debug(LoggingLevel.info, 'The systemBill SSS ID is ' + systemBillList.get(i).Shared_Solar_System_ID__c);
                //system.debug(LoggingLevel.info, 'The opp SSS ID is ' + opp.Shared_Solar_System__r.Id);
                //system.debug(LoggingLevel.info, 'The systemBill PR.ACC ID is ' + systemBillList.get(i).Property_Account__r.Id);
                //system.debug(LoggingLevel.info, 'The opp PR.ACC ID is ' + string.ValueOf(opp.Account.Id));
                system.debug(LoggingLevel.info,ifCheck);
                system.debug(LoggingLevel.info,sbCounter);
            } 
            if(opp.Account.Recurring_Billing__c == true){          
                System_Bill__c sb = new System_Bill__c(Name = opp.Name + ' ' + opp.Shared_Solar_System__r.Name + ' ' + euu.MonthDate__c + ' ' + euu.YearDate__c,                                                           
                                                            Shared_Solar_System_ID2__c = opp.Shared_Solar_System__r.Id,
                                                            Account_Bill__c = ab.Id,
                                                            Recurring_Billing__c = true,
                                                            Date__c =  euu.Date__c,
                                                            Bill_Number__c = sbCounter,
                                                            Shared_Solar_System__c = opp.Shared_Solar_System__r.Id,
                                                            Property_Account__c = opp.Account.Id,
                                                            Opportunity__c = opp.Id);                                                                                 
                    sb.Unique_Id__c = opp.Name + ' ' + opp.Shared_Solar_System__r.Name + ' ' + DateTime.newInstance(euu.Date__c.year(), euu.Date__c.month(),euu.Date__c.day()).format('yyyy-MM');            
                    systemBillIdentifier = opp.Name + ' ' + opp.Shared_Solar_System__r.Name + ' ' + DateTime.newInstance(euu.Date__c.year(), euu.Date__c.month(),euu.Date__c.day()).format('yyyy-MM');
                    system.debug(LoggingLevel.info, systemBillIdentifier);
                    if(!sbSetCheck.contains(systemBillIdentifier)){
                            systemBillSet.add(sb);
                            sbSetCheck.add(systemBillIdentifier);
                    }
                    sbCounter = sbcounter + 1;                   
                }
                else{
                    System_Bill__c sb = new System_Bill__c(Name = opp.Name + ' ' + opp.Shared_Solar_System__r.Name + ' ' + euu.MonthDate__c + ' ' + euu.YearDate__c,                                                           
                                                                 Shared_Solar_System_ID2__c = opp.Shared_Solar_System__r.Id,
                                                                 Account_Bill__c = ab.Id,
                                                                 Date__c =  euu.Date__c,
                                                                 Bill_Number__c = sbCounter,
                                                                 Shared_Solar_System__c = opp.Shared_Solar_System__r.Id,
                                                                 Property_Account__c = opp.Account.Id,
                                                                 Opportunity__c = opp.Id);                    
                    sb.Unique_Id__c = opp.Name + ' ' + opp.Shared_Solar_System__r.Name + ' ' + DateTime.newInstance(euu.Date__c.year(), euu.Date__c.month(),euu.Date__c.day()).format('yyyy-MM');                
                    systemBillIdentifier = opp.Name + ' ' + opp.Shared_Solar_System__r.Name + ' ' + DateTime.newInstance(euu.Date__c.year(), euu.Date__c.month(),euu.Date__c.day()).format('yyyy-MM');
                    system.debug(LoggingLevel.info, systemBillIdentifier);
                    if(!sbSetCheck.contains(systemBillIdentifier)){
                            systemBillSet.add(sb);
                            sbSetCheck.add(systemBillIdentifier);
                    } 
                    sbcounter = sbcounter + 1;     
                }                                                             
            sbCounter = 1;               
        }
        //Create the Utility Account Bills
        system.debug(LoggingLevel.info, systemBillSet.size());
        System.debug(LoggingLevel.info, 'The System Bill Set Records are ' + systembillSet);
        if(systemBillSet.size() > 0){
            upsert new List<System_Bill__c>(systemBillSet) Unique_Id__c;
        }        
          
        Set<Utility_Account_Bill__c> uabSet = new Set<Utility_Account_Bill__c>();  
        for(Utility_Account_Subscription__c uas : uasList){
            integer uabCounter = 1;
            Energy_Usage_Update__c euu = sssIdToEUUMap.get(uas.Opportunity__r.Shared_Solar_System__c);
            String parentKey = uas.Opportunity__r.Account.Id + ' ' + DateTime.newInstance(euu.Date__c.year(), euu.Date__c.month(),euu.Date__c.day()).format('yyyy-MM');
            if(abKeyToAccountBillMap.containsKey(parentKey)){ 
                for(i=0;i<utilityAccountBillList.size();i++){
                    if(utilityAccountBillList.get(i).Account_Bill__r.Parent_Account__r.Id == uas.Opportunity__r.Account.Id){
                        uabCounter = uabCounter + 1;
                    }
                }                           
                Account_Bill__c ab = abKeyToAccountBillMap.get(parentKey);
                Utility_Account_Bill__c uab = new Utility_Account_Bill__c(Name = uas.Opportunity__r.Name + ' ' + euu.MonthDate__c + ' ' + euu.YearDate__c + ' ' + uas.Name,
                                                             Production_Update__c = euu.Id,
                                                             Shared_Solar_System__c = euu.Shared_Solar_System__c,
                                                             Date__c =  euu.Date__c,
                                                             Utility_Account_Log__c = uas.Utility_Account_Log__c,
                                                             Bill_Number__c = uabCounter,
                                                             Account_Bill__c = ab.Id);
                
                uab.Unique_Id__c = uas.Utility_Account_Log__c + ' - ' + DateTime.newInstance(euu.Date__c.year(), euu.Date__c.month(),euu.Date__c.day()).format('yyyy-MM');
                uabSet.add(uab);
            }
            uabCounter = 1;            
        }
        //Create the Utility Account Bills
        if(uabSet.size() > 0){
            upsert new List<Utility_Account_Bill__c>(uabSet) Unique_Id__c;
        }
    }                  

    /*
        
    public void OnBeforeInsert(Energy_Usage_Update__c[] newEnergyUsageUpdates){
    }
    
    
    @future public static void OnAfterInsertAsync(Set<Id> newEnergyUsageUpdateIDs){
    }
    
    public void OnBeforeUpdate(Energy_Usage_Update__c[] oldEnergyUsageUpdates, Energy_Usage_Update__c[] updatedEnergyUsageUpdates, Map<ID, Energy_Usage_Update__c> oldEnergyUsageUpdateMap, Map<ID, Energy_Usage_Update__c> newEnergyUsageUpdateMap){
    }
    
    public void OnAfterUpdate(Energy_Usage_Update__c[] oldEnergyUsageUpdates, Energy_Usage_Update__c[] updatedEnergyUsageUpdates, Map<ID, Energy_Usage_Update__c> oldEnergyUsageUpdateMap, Map<ID, Energy_Usage_Update__c> newEnergyUsageUpdateMap){
        
    }
    
    @future public static void OnAfterUpdateAsync(Set<Id> updatedEnergyUsageUpdateIDs){
    }
    
    public void OnBeforeDelete(Energy_Usage_Update__c[] EnergyUsageUpdatesToDelete, Map<ID, Energy_Usage_Update__c> EnergyUsageUpdateMap){
        
    }
    
    public void OnAfterDelete(Energy_Usage_Update__c[] deletedEnergyUsageUpdates, Map<ID, Energy_Usage_Update__c> EnergyUsageUpdateMap){
        
    }
    
    @future public static void OnAfterDeleteAsync(Set<Id> deletedEnergyUsageUpdateIDs){
        
    }
    
    public void OnUndelete(Energy_Usage_Update__c[] restoredEnergyUsageUpdates){
        
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