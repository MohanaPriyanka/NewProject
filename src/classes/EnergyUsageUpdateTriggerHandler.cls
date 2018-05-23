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
        Integer abCounter = 1;
        
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
                                                         Opportunity__r.AccountId,
                                                         Max_Account_Bill_Number__c
                                                         FROM Utility_Account_Subscription__c 
                                                         WHERE Utility_Account_Log__c != null
                                                         AND Opportunity__r.StageName = 'Complete' 
                                                         AND Opportunity__c != null 
                                                         AND Next_Schedule_Z_Status__c != 'Cancelled'
                                                         AND Next_Schedule_Z_Status__c != 'Not Enacted: Addition'
                                                         AND Opportunity__r.Shared_Solar_System__c IN : sssIdToEUUMap.keySet() 
                                                         ORDER BY Name];

        //select the UAS that are related to the shared solar systems that have production updates being logged.
        List<Opportunity> oppList = [SELECT   Id, Name, Account.Name, Shared_Solar_System__r.Name, Shared_Solar_System__c, 
                                     AccountId, Account.Id, Account.Recurring_Billing__c, Product__r.Monthly_Late_Fee__c,
                                     Product__r.Days_in_Bill_Period__c
                                     FROM Opportunity 
                                     WHERE StageName = 'Complete' 
                                     AND Shared_Solar_System__c IN : sssIdToEUUMap.keySet() 
                                     ORDER BY Name];                                                                                  

        //Generate a list of all System Bills   
        Map<String, Decimal> oppKeyMap = new Map<String, Decimal>();   
        for ( AggregateResult lineItem : [  SELECT Opportunity__r.Id oppID, 
                                                MAX(Bill_Number__c) maxBillNumber
                                                FROM System_Bill__c 
                                                WHERE Shared_Solar_System__c IN : sssIdToEUUMap.keySet()
                                                GROUP BY Opportunity__r.Id]) {
            oppKeyMap.put((String)lineItem.get('oppID'), (Decimal)lineItem.get('maxBillNumber'));
        }

        Map<String, Account_Bill__c> abKeyToAccountBillMap = new Map<String, Account_Bill__c>();

        printCPULimit('Before first uas loop');

        for (Utility_Account_Subscription__c uas : uasList) {
            if (sssIdToEUUMap.containsKey(uas.Opportunity__r.Shared_Solar_System__c)) {    
                Energy_Usage_Update__c euu = sssIdToEUUMap.get(uas.Opportunity__r.Shared_Solar_System__c);
                String abUniqueID = uas.Opportunity__r.Account.Id + ' ' + getDate(euu);

                /*  Joe Cadette Issue: Unique Id is used to match Account Bills from different 
                    production updates. Ie, all of Joe's bills are child records of his March Account 
                    Bill, which has a unique Id. However, we don't want to upsert an Account Bill 
                    twice from the same Production Update because the bill number will increase by 1 
                    (this shouldn't happen on others - should not be 2 opportunities for same project)
                */
                if (!abKeyToAccountBillMap.containsKey(abUniqueID)) {
                    if(uas.Max_Account_Bill_Number__c == 0) {            
                        abCounter = 1;
                    } else {
                        abCounter = (uas.Max_Account_Bill_Number__c).intValue() + 1;
                    }
                    Account_Bill__c ab = new Account_Bill__c(Name = uas.Opportunity__r.Account.Name + ' ' + 
                                                             euu.MonthDate__c + ' ' + euu.YearDate__c, 
                                                             Date__c =  euu.Date__c,
                                                             Parent_Account__c = uas.Opportunity__r.Account.Id,
                                                             Bill_Number__c = abCounter,
                                                             Last_Shared_Solar_System_ID__c = uas.Opportunity__r.Shared_Solar_System__r.Id);
                    ab.Unique_Id__c = abUniqueID;
                    abKeyToAccountBillMap.put(abUniqueID, ab);
                }
            }
        }

        printCPULimit('After first uas loop');

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

            if(oppKeyMap.containsKey(opp.Id)){
                sbCounter = (oppKeyMap.get(opp.Id)).intValue() + 1;
            } else {
                sbCounter = 1;
            }

            if (abKeyToAccountBillMap.containsKey(parentKey)) {
                System_Bill__c sb = new System_Bill__c(Name = opp.Name + ' ' + 
                                                       opp.Shared_Solar_System__r.Name + ' ' + euu.MonthDate__c + ' ' + euu.YearDate__c,
                                                       Shared_Solar_System_ID2__c = opp.Shared_Solar_System__r.Id,
                                                       Account_Bill__c = ab.Id,
                                                       Recurring_Billing__c = opp.Account.Recurring_Billing__c,
                                                       Date__c =  euu.Date__c,
                                                       Bill_Number__c = sbCounter,
                                                       Shared_Solar_System__c = opp.Shared_Solar_System__r.Id,
                                                       Monthly_Late_Fee_Interest__c = opp.Product__r.Monthly_Late_Fee__c,
                                                       Days_in_Bill_Period__c = opp.Product__r.Days_in_Bill_Period__c,
                                                       Property_Account__c = opp.Account.Id,
                                                       Opportunity__c = opp.Id);
                sb.Unique_Id__c = opp.Name + ' ' + opp.Shared_Solar_System__r.Name + ' ' + getDate(euu);
                systemBillIdentifier = opp.Name + ' ' + opp.Shared_Solar_System__r.Name + ' ' + getDate(euu);
                if (!sbSetCheck.contains(systemBillIdentifier)) {
                    systemBillSet.add(sb);
                    sbSetCheck.add(systemBillIdentifier);
                }
            }
        }

        printCPULimit('Before System Bills upserted');

        if (!systemBillSet.isEmpty()) {
            upsert new List<System_Bill__c>(systemBillSet) Unique_Id__c;
        }  

        printCPULimit('After System Bills upserted');

        Set<Utility_Account_Bill__c> uabSet = new Set<Utility_Account_Bill__c>();  
        for (Utility_Account_Subscription__c uas : uasList) {
            Energy_Usage_Update__c euu = sssIdToEUUMap.get(uas.Opportunity__r.Shared_Solar_System__c);
            String parentKey = uas.Opportunity__r.Account.Id + ' ' + getDate(euu);
            if (abKeyToAccountBillMap.containsKey(parentKey)) { 
                Account_Bill__c ab = abKeyToAccountBillMap.get(parentKey);
                Utility_Account_Bill__c uab = 
                    new Utility_Account_Bill__c(Name = uas.Opportunity__r.Name + ' ' + 
                                                euu.MonthDate__c + ' ' + euu.YearDate__c + ' ' + uas.Name,
                                                Production_Update__c = euu.Id,
                                                Shared_Solar_System__c = euu.Shared_Solar_System__c,
                                                Date__c =  euu.Date__c,
                                                Utility_Account_Log__c = uas.Utility_Account_Log__c,
                                                Account_Bill__c = ab.Id);
                uab.Unique_Id__c = uas.Utility_Account_Log__c + ' - ' + getDate(euu);
                uabSet.add(uab);
            }
        }

        printCPULimit('Before Utility Account Bills upserted');

        //Create the Utility Account Bills
        if (!Test.isRunningTest()) {
            // Upsert asynchronously to avoid CPU limit
            List<System_Properties__c> csBillSettings = System_Properties__c.getall().values();
            Integer batchSizeToExecute = Integer.valueOf(csBillSettings[0].CS_Bill_Batch_Size__c); 
            Database.executeBatch(new GenericBatchDMLOperation(new List<Utility_Account_Bill__c>(uabSet), 'Upsert'),batchSizeToExecute);
        } else {
            upsert new List<Utility_Account_Bill__c>(uabSet);
        }
    }                  
}