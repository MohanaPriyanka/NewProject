/*
 * Tested by: RecurringPaymentsHandlerTestClass
 */

public with sharing class EnergyUsageUpdateTriggerHandler {
    private boolean m_isExecuting = false;
    private Integer BatchSize = 0;
    
    public EnergyUsageUpdateTriggerHandler(boolean isExecuting, Integer size){
        m_isExecuting = isExecuting;
        BatchSize = size;
    }
    public void OnAfterInsert(Energy_Usage_Update__c[] newEnergyUsageUpdates){
        printCPULimit('Before createCSBillingLog');

        createCSBillingLog(newEnergyUsageUpdates);

        printCPULimit('After createCSBillingLog');
    }

    public static void printCPULimit(String prefix) {
        System.debug(LoggingLevel.ERROR, 'Limits: ' + prefix + ': ' + Limits.getCpuTime() + 'ms of ' 
                     + Limits.getLimitCpuTime() + 'ms used');
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
        List<Account_Bill__c> accountBillList =  [ SELECT ID,Parent_Account__c, Unique_Id__c, Bill_Number__c, 
                                                   Parent_Account__r.Id, Last_Shared_Solar_System_ID__c, Name, 
                                                   Bill_Number_Guard__c
                                                   FROM Account_Bill__c
                                                   WHERE Id != null];                                       
      
        List<Utility_Account_Bill__c> utilityAccountBillList =  [ SELECT ID, Account_Bill__r.Parent_Account__c, 
                                                                  Account_Bill__r.Parent_Account__r.Id
                                                                  FROM Utility_Account_Bill__c
                                                                  WHERE Id != null];

        //Generate a list of all System Bills                                                  
        List<System_Bill__c> systemBillList =  [ SELECT ID, Shared_Solar_System__c,Shared_Solar_System_ID__c, 
                                                 Property_Account__r.Id, Opportunity__c, 
                                                 Shared_Solar_System__r.Name, Property_Account__r.Name
                                                 FROM System_Bill__c
                                                 WHERE Id != null];                                                                                                                                            
        System.debug(LoggingLevel.ERROR, 'Energy Usage Update Account Bill Size: ' + accountBillList.size());                                     
        Map<String, Account_Bill__c> abKeyToAccountBillMap = new Map<String, Account_Bill__c>();
        Map<String, Account_Bill__c> accountBillMapBillNumberFix = new Map<String, Account_Bill__c>();
        List<Account_Bill__c> myAccountBillList = new List<Account_Bill__c>();    

        printCPULimit('Before first uas loop');

        for(Utility_Account_Subscription__c uas : uasList){
            if(sssIdToEUUMap.containsKey(uas.Opportunity__r.Shared_Solar_System__c)){    
                Energy_Usage_Update__c euu = sssIdToEUUMap.get(uas.Opportunity__r.Shared_Solar_System__c);
                //count how many accountBills exist in the system for this specific Parent Account 
                for(i=0;i<accountBillList.size();i++){
                    if(accountBillList.get(i).Parent_Account__r.Id == uas.Opportunity__r.Account.Id ){
                        myAccountBillList.add(accountBillList.get(i));
                        abCounter = abCounter + 1;      
                    }                                                  
                }
                Account_Bill__c ab = new Account_Bill__c(Name = uas.Opportunity__r.Account.Name + ' ' + 
                                                         euu.MonthDate__c + ' ' + euu.YearDate__c, 
                                                         Date__c =  euu.Date__c,
                                                         Parent_Account__c = uas.Opportunity__r.Account.Id,
                                                         Bill_Number__c = abCounter,
                                                         Last_Shared_Solar_System_ID__c = uas.Opportunity__r.Shared_Solar_System__r.Id);                                                         
                ab.Unique_Id__c = uas.Opportunity__r.Account.Id + ' ' + 
                    DateTime.newInstance(euu.Date__c.year(), euu.Date__c.month(),euu.Date__c.day()).format('yyyy-MM');
                abKeyToAccountBillMap.put(ab.Unique_Id__c, ab);
            }
            abCounter = 1;
        }

        printCPULimit('After first uas loop');

        integer c;
        integer check = 0;
        for(c=0;c<accountBillList.size();c++){
            check = 1;
            accountBillMapBillNumberFix.put(accountBillList.get(c).Unique_Id__c, accountBillList.get(c));
        }   
        for(Account_Bill__c abCounterFix : abKeyToAccountBillMap.values()){
            if(accountBillMapBillNumberFix.containsKey(abCounterFix.Unique_Id__c)){
                abCounterFix.Bill_Number__c = abCounterFix.Bill_Number__c - 1;
            }
        }        
        //Create the Account Bills
        if(abKeyToAccountBillMap.size() > 0){
            upsert abKeyToAccountBillMap.values() Unique_Id__c;
        }
        for(Utility_Account_Subscription__c uas : uasList){
            if(sssIdMap.containsKey(uas.Opportunity__r.Shared_Solar_System__c)){
                Energy_Usage_Update__c euu = sssIdToEUUMap.get(uas.Opportunity__r.Shared_Solar_System__c);
                Shared_Solar_System__c sss = sssIdMap.get(uas.Opportunity__r.Shared_Solar_System__c);
            }
        }
        
        printCPULimit('After Account Bills upserted');

        Set<System_Bill__c> systemBillSet = new Set<System_Bill__c>();
        for(Opportunity opp : oppList){
            set<string> sbSetCheck = new set<string>();
            Energy_Usage_Update__c euu = sssIdToEUUMap.get(opp.Shared_Solar_System__c);
            String systemKey = 
                opp.Shared_Solar_System__c + ' ' + 
                DateTime.newInstance(euu.Date__c.year(), euu.Date__c.month(),euu.Date__c.day()).format('yyyy-MM');
            String parentKey = opp.Account.Id + ' ' + 
                DateTime.newInstance(euu.Date__c.year(), euu.Date__c.month(),euu.Date__c.day()).format('yyyy-MM');            
            Account_Bill__c ab = abKeyToAccountBillMap.get(parentKey);
            integer sbCounter = 1;
            // Totalized_System_Bill__c tsb = sbKeyToTSBMap.get(systemKey);            
            string systemBillIdentifier;
            for(i=0;i<systemBillList.size();i++){
                integer ifCheck = 0;
                if(systemBillList.get(i).Shared_Solar_System__r.Id == opp.Shared_Solar_System__r.Id
                   && systemBilllist.get(i).Property_Account__r.Id == opp.Account.Id){
                    ifCheck = 1;
                    sbCounter = sbCounter + 1;
                }
            } 
            if(opp.Account.Recurring_Billing__c == true){          
                System_Bill__c sb = new System_Bill__c(Name = opp.Name + ' ' + 
                                                       opp.Shared_Solar_System__r.Name + ' ' + euu.MonthDate__c + ' ' + euu.YearDate__c,
                                                       Shared_Solar_System_ID2__c = opp.Shared_Solar_System__r.Id,
                                                       Account_Bill__c = ab.Id,
                                                       Recurring_Billing__c = true,
                                                       Date__c =  euu.Date__c,
                                                       Bill_Number__c = sbCounter,
                                                       Shared_Solar_System__c = opp.Shared_Solar_System__r.Id,
                                                       Property_Account__c = opp.Account.Id,
                                                       Opportunity__c = opp.Id);                                                                                 
                sb.Unique_Id__c = opp.Name + ' ' + opp.Shared_Solar_System__r.Name + ' ' + 
                    DateTime.newInstance(euu.Date__c.year(), euu.Date__c.month(),euu.Date__c.day()).format('yyyy-MM');
                systemBillIdentifier = opp.Name + ' ' + opp.Shared_Solar_System__r.Name + ' ' + 
                    DateTime.newInstance(euu.Date__c.year(), euu.Date__c.month(),euu.Date__c.day()).format('yyyy-MM');
                if(!sbSetCheck.contains(systemBillIdentifier)){
                    systemBillSet.add(sb);
                    sbSetCheck.add(systemBillIdentifier);
                }
                sbCounter = sbcounter + 1;                   
            }
            else{
                System_Bill__c sb = new System_Bill__c(Name = opp.Name + ' ' + 
                                                       opp.Shared_Solar_System__r.Name + ' ' + euu.MonthDate__c + ' ' + euu.YearDate__c,
                                                       Shared_Solar_System_ID2__c = opp.Shared_Solar_System__r.Id,
                                                       Account_Bill__c = ab.Id,
                                                       Date__c =  euu.Date__c,
                                                       Bill_Number__c = sbCounter,
                                                       Shared_Solar_System__c = opp.Shared_Solar_System__r.Id,
                                                       Property_Account__c = opp.Account.Id,
                                                       Opportunity__c = opp.Id);                    
                sb.Unique_Id__c = opp.Name + ' ' + opp.Shared_Solar_System__r.Name + ' ' + 
                    DateTime.newInstance(euu.Date__c.year(), euu.Date__c.month(),euu.Date__c.day()).format('yyyy-MM');                
                systemBillIdentifier = opp.Name + ' ' + opp.Shared_Solar_System__r.Name + ' ' + 
                    DateTime.newInstance(euu.Date__c.year(), euu.Date__c.month(),euu.Date__c.day()).format('yyyy-MM');
                if(!sbSetCheck.contains(systemBillIdentifier)){
                    systemBillSet.add(sb);
                    sbSetCheck.add(systemBillIdentifier);
                } 
                sbcounter = sbcounter + 1;     
            }                                                             
            sbCounter = 1;               
        }

        printCPULimit('Before System Bills upserted');

        //Create the Utility Account Bills
        if(systemBillSet.size() > 0){
            upsert new List<System_Bill__c>(systemBillSet) Unique_Id__c;
        }        
          

        printCPULimit('After System Bills upserted');

        Set<Utility_Account_Bill__c> uabSet = new Set<Utility_Account_Bill__c>();  
        for(Utility_Account_Subscription__c uas : uasList){
            integer uabCounter = 1;
            Energy_Usage_Update__c euu = sssIdToEUUMap.get(uas.Opportunity__r.Shared_Solar_System__c);
            String parentKey = uas.Opportunity__r.Account.Id + ' ' + 
                DateTime.newInstance(euu.Date__c.year(), euu.Date__c.month(),euu.Date__c.day()).format('yyyy-MM');
            if(abKeyToAccountBillMap.containsKey(parentKey)){ 
                for(i=0;i<utilityAccountBillList.size();i++){
                    if(utilityAccountBillList.get(i).Account_Bill__r.Parent_Account__r.Id == uas.Opportunity__r.Account.Id){
                        uabCounter = uabCounter + 1;
                    }
                }                           
                Account_Bill__c ab = abKeyToAccountBillMap.get(parentKey);
                Utility_Account_Bill__c uab = 
                    new Utility_Account_Bill__c(Name = uas.Opportunity__r.Name + ' ' + 
                                                euu.MonthDate__c + ' ' + euu.YearDate__c + ' ' + uas.Name,
                                                Production_Update__c = euu.Id,
                                                Shared_Solar_System__c = euu.Shared_Solar_System__c,
                                                Date__c =  euu.Date__c,
                                                Utility_Account_Log__c = uas.Utility_Account_Log__c,
                                                Bill_Number__c = uabCounter,
                                                Account_Bill__c = ab.Id);
                
                uab.Unique_Id__c = uas.Utility_Account_Log__c + ' - ' + 
                    DateTime.newInstance(euu.Date__c.year(), euu.Date__c.month(),euu.Date__c.day()).format('yyyy-MM');
                uabSet.add(uab);
            }
            uabCounter = 1;            
        }

        printCPULimit('Before Utility Account Bills upserted');

        //Create the Utility Account Bills
        if(uabSet.size() > 0){
            Database.executeBatch(new GenericBatchDMLOperation(new List<Utility_Account_Bill__c>(uabSet), 'Upsert'));
        }
    }                  

}