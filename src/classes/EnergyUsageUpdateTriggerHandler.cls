/*
 * Created By: Cole Swain
 * Description: Creates CS Bills after a Production Update is created
 * Tested by: RecurringPaymentsHandlerTestClass
 */

public with sharing class EnergyUsageUpdateTriggerHandler {
    public EnergyUsageUpdateTriggerHandler() {
    }

    // March 2017: We run into CPU limits when creating new Production Updates - print CPU Limits
    // in case this creeps up again.
    private static void printCPULimit(String prefix) {
        System.debug(LoggingLevel.ERROR, 'Limits: ' + prefix + ': ' + Limits.getCpuTime() + 'ms of ' 
                     + Limits.getLimitCpuTime() + 'ms used');
    }

    private static String getDate(Energy_Usage_Update__c euu) {
        return DateTime.newInstance(euu.Date__c.year(), euu.Date__c.month(),euu.Date__c.day()).format('yyyy-MM');
    }

    // Called by EnergyUsageUpdateTrigger after insert
    public void createCSBillingLog(List<Energy_Usage_Update__c> euuList) {
        printCPULimit('Before createCSBillingLog');
        Map<Id, Energy_Usage_Update__c> sssIdToEUUMap = new Map<Id, Energy_Usage_Update__c>();
        Map<Id, Shared_Solar_System__c> sssIdMap = new Map<Id, Shared_Solar_System__c>();
        Integer abCounter = 1;
        Integer i;
        
        //load the triggered production updates into the instantiated map and set the SSS as the key value.
        for (Energy_Usage_Update__c euu : euuList) {
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
                                                         AND Next_Schedule_Z_Status__c != 'Cancelled'
                                                         AND Next_Schedule_Z_Status__c != 'Not Enacted: Addition'
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
        for (Shared_Solar_System__c sss : [  SELECT  Id, Name
                                             FROM Shared_Solar_System__c 
                                             WHERE Id IN : sssIdToEUUMap.keySet() 
                                             ORDER BY Name]) {
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
                                                 Property_Account__r.Id, Opportunity__c, Opportunity__r.Id,
                                                 Shared_Solar_System__r.Name, Property_Account__r.Name
                                                 FROM System_Bill__c
                                                 WHERE Id != null];
        Map<String, Account_Bill__c> abKeyToAccountBillMap = new Map<String, Account_Bill__c>();
        Map<String, Account_Bill__c> accountBillMapBillNumberFix = new Map<String, Account_Bill__c>();
        List<Account_Bill__c> myAccountBillList = new List<Account_Bill__c>();    

        printCPULimit('Before first uas loop');

        for (Utility_Account_Subscription__c uas : uasList) {
            if (sssIdToEUUMap.containsKey(uas.Opportunity__r.Shared_Solar_System__c)) {    
                Energy_Usage_Update__c euu = sssIdToEUUMap.get(uas.Opportunity__r.Shared_Solar_System__c);
                //count how many accountBills exist in the system for this specific Parent Account 
                for (i=0;i<accountBillList.size();i++) {
                    if (accountBillList.get(i).Parent_Account__r.Id == uas.Opportunity__r.Account.Id ) {
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
                ab.Unique_Id__c = uas.Opportunity__r.Account.Id + ' ' + getDate(euu);
                abKeyToAccountBillMap.put(ab.Unique_Id__c, ab);
            }
            abCounter = 1;
        }

        printCPULimit('After first uas loop');

        integer c;
        integer check = 0;
        for (c=0;c<accountBillList.size();c++) {
            check = 1;
            accountBillMapBillNumberFix.put(accountBillList.get(c).Unique_Id__c, accountBillList.get(c));
        }   
        for (Account_Bill__c abCounterFix : abKeyToAccountBillMap.values()) {
            if (accountBillMapBillNumberFix.containsKey(abCounterFix.Unique_Id__c)) {
                abCounterFix.Bill_Number__c = abCounterFix.Bill_Number__c - 1;
            }
        }        
        //Create the Account Bills
        if (!abKeyToAccountBillMap.isEmpty()) {
            upsert abKeyToAccountBillMap.values() Unique_Id__c;
        }
        
        printCPULimit('After Account Bills upserted');

        Set<System_Bill__c> systemBillSet = new Set<System_Bill__c>();
        for (Opportunity opp : oppList) {
            set<string> sbSetCheck = new set<string>();
            Energy_Usage_Update__c euu = sssIdToEUUMap.get(opp.Shared_Solar_System__c);
            String parentKey = opp.Account.Id + ' ' + getDate(euu);
            Account_Bill__c ab = abKeyToAccountBillMap.get(parentKey);
            integer sbCounter = 1;
            string systemBillIdentifier;
            for (i=0;i<systemBillList.size();i++) {
                if (systemBilllist.get(i).Opportunity__r.Id == opp.Id) {
                    sbCounter = sbCounter + 1;
                }
            } 
            System_Bill__c sb = new System_Bill__c(Name = opp.Name + ' ' + 
                                                   opp.Shared_Solar_System__r.Name + ' ' + euu.MonthDate__c + ' ' + euu.YearDate__c,
                                                   Shared_Solar_System_ID2__c = opp.Shared_Solar_System__r.Id,
                                                   Account_Bill__c = ab.Id,
                                                   Recurring_Billing__c = opp.Account.Recurring_Billing__c,
                                                   Date__c =  euu.Date__c,
                                                   Bill_Number__c = sbCounter,
                                                   Shared_Solar_System__c = opp.Shared_Solar_System__r.Id,
                                                   Property_Account__c = opp.Account.Id,
                                                   Opportunity__c = opp.Id);
            sb.Unique_Id__c = opp.Name + ' ' + opp.Shared_Solar_System__r.Name + ' ' + getDate(euu);
            systemBillIdentifier = opp.Name + ' ' + opp.Shared_Solar_System__r.Name + ' ' + getDate(euu);
            if (!sbSetCheck.contains(systemBillIdentifier)) {
                systemBillSet.add(sb);
                sbSetCheck.add(systemBillIdentifier);
            }
        }

        printCPULimit('Before System Bills upserted');

        //Create the Utility Account Bills
        if (!systemBillSet.isEmpty()) {
            upsert new List<System_Bill__c>(systemBillSet) Unique_Id__c;
        }        
          

        printCPULimit('After System Bills upserted');

        Set<Utility_Account_Bill__c> uabSet = new Set<Utility_Account_Bill__c>();  
        for (Utility_Account_Subscription__c uas : uasList) {
            integer uabCounter = 1;
            Energy_Usage_Update__c euu = sssIdToEUUMap.get(uas.Opportunity__r.Shared_Solar_System__c);
            String parentKey = uas.Opportunity__r.Account.Id + ' ' + getDate(euu);
            if (abKeyToAccountBillMap.containsKey(parentKey)) { 
                for (i=0;i<utilityAccountBillList.size();i++) {
                    if (utilityAccountBillList.get(i).Account_Bill__r.Parent_Account__r.Id == uas.Opportunity__r.Account.Id) {
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
                
                uab.Unique_Id__c = uas.Utility_Account_Log__c + ' - ' + getDate(euu);
                uabSet.add(uab);
            }
        }

        printCPULimit('Before Utility Account Bills upserted');

        //Create the Utility Account Bills
        if(uabSet.size() > 0){
            // Upsert asynchronously to avoid CPU limit
            Database.executeBatch(new GenericBatchDMLOperation(new List<Utility_Account_Bill__c>(uabSet), 'Upsert'));
        }
    }                  
}