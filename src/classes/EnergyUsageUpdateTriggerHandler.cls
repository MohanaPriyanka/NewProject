/*
 * Created By: Cole Swain
 * Description: Creates CS Bills after a Production Update is created
 *
 * This class is only creating the admin details of the bills. Sets up the correct relationships and such.
 * Money Due, kWh, etc aren't calculated.
 *
 * Tested by: RecurringPaymentsHandlerTestClass
 */

public without sharing class EnergyUsageUpdateTriggerHandler implements Database.Batchable<sObject> { 
    public Map<Id, Energy_Usage_Update__c> sssIdToEUUMap = new Map<Id,Energy_Usage_Update__c>();        
    public Set<Id> scheduleZs = new Set<Id>();

    // Prep for batch, set list of Schedule Z Ids and Shared Solar System Map:
    public EnergyUsageUpdateTriggerHandler(List<Energy_Usage_Update__c> euuList) {
        for (Energy_Usage_Update__c euu : euuList) {
            sssIdToEUUMap.put(euu.Shared_Solar_System__c, euu);
            scheduleZs.add(euu.Schedule_Z__c);
        }
        if (!Test.isRunningTest()) {
            Database.executeBatch(this, 10);
        } else {
            List<Schedule_Z_Subscription__c> scheduleZSubscriptions = [
                SELECT Id, Utility_Account_Subscription__c
                FROM Schedule_Z_Subscription__c
                WHERE Schedule_Z__c IN : scheduleZs
            ];
            createBills(scheduleZSubscriptions);
        }
    }

    private static void printCPULimit(String prefix) {
        System.debug(LoggingLevel.ERROR, 'Limits: ' + prefix + ': ' + Limits.getCpuTime() + 'ms of ' 
                     + Limits.getLimitCpuTime() + 'ms used');
        System.debug(LoggingLevel.ERROR, 'SOQL Limites: ' + prefix + ': ' +  Limits.getQueries());
    }

    private static String getDate(Energy_Usage_Update__c euu) {
        return DateTime.newInstance(euu.Date__c.year(), euu.Date__c.month(),euu.Date__c.day()).format('yyyy-MM');
    }

    // Batch into groups of Schedule Z Subscriptions:
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query =  'SELECT Id, Utility_Account_Subscription__c ' +
                        ' FROM Schedule_Z_Subscription__c ' +
                        ' WHERE Schedule_Z__c IN : scheduleZs';
        return Database.getQueryLocator(query);
    }

    // Execute this code block in batches to avoid CPU Limit:
    public void execute(Database.BatchableContext bc, List<Schedule_Z_Subscription__c> scheduleZSubscriptions) {
        createBills(scheduleZSubscriptions);
    }

    public void createBills(List<Schedule_Z_Subscription__c> scheduleZSubscriptions ){
        Map<Id, Utility_Account_Subscription__c> uasMap = getUASFromSZS(scheduleZSubscriptions);

        //select the Opportunities that are related to the shared solar systems that have production updates being logged.
        List<Opportunity> oppList = [SELECT   Id, Name, Account.Name, Shared_Solar_System__r.Name, Shared_Solar_System__c, 
                                     AccountId, Account.Id, Account.Recurring_Billing__c, Product__r.Monthly_Late_Fee__c,
                                     Product__r.Days_in_Bill_Period__c
                                     FROM Opportunity 
                                     WHERE StageName = 'Complete' 
                                     AND Shared_Solar_System__c IN : sssIdToEUUMap.keySet() 
                                     ORDER BY Name];                                                                                  

        //Generate a list of all System Bill Numbers for each opportunity
        Map<String, Integer> maxSysBillByOppId = maxSysBillByOppId(sssIdToEUUMap.keySet());

        Map<String, Account_Bill__c> abKeyToAccountBillMap = new Map<String, Account_Bill__c>();

        printCPULimit('Before first uas loop');

        for (Schedule_Z_Subscription__c scheduleZSub : scheduleZSubscriptions) {
            Utility_Account_Subscription__c uas = uasMap.get(scheduleZSub.Utility_Account_Subscription__c);
            if (sssIdToEUUMap.containsKey(uas.Opportunity__r.Shared_Solar_System__c)) {
                Energy_Usage_Update__c euu = sssIdToEUUMap.get(uas.Opportunity__r.Shared_Solar_System__c);
                String abUniqueID = uas.Opportunity__r.Account.Id + ' ' + getDate(euu);
                if (!abKeyToAccountBillMap.containsKey(abUniqueID)) {
                    try {
                        Account_Bill__c ab = generateAccountBill(uas, abUniqueID, euu);
                        abKeyToAccountBillMap.put(ab.Unique_Id__c, ab);
                    } catch (DmlException e){
                        String message = 'Account Bill Creation Failed for UniqueID ' + abUniqueID;
                        Logger.logLater('EnergyUsageUpdateTriggerHandler', 'GenerateAccountBill', message);
                    }
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
            Energy_Usage_Update__c euu = sssIdToEUUMap.get(opp.Shared_Solar_System__c);
            String parentKey = opp.Account.Id + ' ' + getDate(euu);
            if (abKeyToAccountBillMap.containsKey(parentKey)) {
                Integer maxSysBill = maxSysBillByOppId.get(opp.Id);
                Account_Bill__c ab = abKeyToAccountBillMap.get(parentKey);
                try {
                    System_Bill__c sb = generateSystemBill(opp, euu, ab, maxSysBill);
                    systemBillSet.add(sb);
                } catch (DmlException e) {
                    String message = 'System Bill Creation Failed for Parent Id ' + parentKey ;
                    Logger.logLater('EnergyUsageUpdateTriggerHandler', 'GenerateSystemBill', message);
                }
            }
        }

        printCPULimit('Before System Bills upserted');

        if (!systemBillSet.isEmpty()) {
            upsert new List<System_Bill__c>(systemBillSet) Unique_Id__c;
        }

        printCPULimit('After System Bills upserted');

        Map<String, Utility_Account_Bill__c> uabSet = new Map<String, Utility_Account_Bill__c>();  
        for (Utility_Account_Subscription__c uas : uasMap.values()) {
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
                uabSet.put(uab.Name, uab);
            }
        }

        printCPULimit('Before Utility Account Bills upserted');

        upsert new List<Utility_Account_Bill__c>(uabSet.values()) Unique_Id__c;

        Map<Id, Utility_Account_Bill__c> utilityAccountLogIdToUABMap = new Map<Id, Utility_Account_Bill__c>();
        Map<String, System_Bill__c > systemBillMap = new Map<string, System_Bill__c >();

        for(Utility_Account_Bill__c uab : uabSet.values()){
            utilityAccountLogIdToUABMap.put(uab.Utility_Account_Log__c, uab);
        }

        for(System_Bill__c sysBill : systemBillSet){
            systemBillMap.put(sysBill.Unique_Id__c, sysBill);
        }

        UtilityAccountBillTriggerHandler handler = new UtilityAccountBillTriggerHandler();
        handler.createUASB(sssIdToEUUMap, systemBillMap, utilityAccountLogIdToUABMap, uasMap.values());

        printCPULimit('After Utility Account Bills upserted');    
    }     

    public void finish(Database.BatchableContext bc){
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, 
                            JobItemsProcessed,
                            TotalJobItems, CreatedBy.Email
                            FROM AsyncApexJob
                            WHERE Id = :bc.getJobId()];

        String emailBody = 'CS Bill Creation has Completed. Job Id: '+ job.Id;
            List<String> postJobEmailAddresses = new List<String>{'product@bluewavesolar.com' , 'communitysolar@bluewavesolar.com'};   
        if(!Test.isRunningTest()){
            MessagingService.createAndSendEmail(emailBody, 'customercare@bluewavesolar.com', 'CS Bill Creation Processing Complete', postJobEmailAddresses);
        } 
    }

    private Account_Bill__c generateAccountBill(Utility_Account_Subscription__c uas, String abUniqueID, Energy_Usage_Update__c euu) {
                Integer abCounter;
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
                return ab;
    }

    private Map<String, Integer> maxSysBillByOppId(Set<Id> sssIds) {
        Map<String, Integer> oppKeyMap = new Map<String, Integer>();
        for ( AggregateResult lineItem : [  SELECT Opportunity__r.Id oppID,
                                                MAX(Bill_Number__c) maxBillNumber
                                                FROM System_Bill__c
                                                WHERE Shared_Solar_System__c IN : sssIds
                                                GROUP BY Opportunity__r.Id]) {
            oppKeyMap.put((String)lineItem.get('oppID'), (Integer)lineItem.get('maxBillNumber'));
        }
        return oppKeyMap;
    }

    private Map<Id, Utility_Account_Subscription__c> getUASFromSZS(List<Schedule_Z_Subscription__c> scheduleZSubscriptions ) {
        Set<Id> scheduleZUASIds = new Set<Id>();

        for (Schedule_Z_Subscription__c scheduleZSub : scheduleZSubscriptions) {
            scheduleZUASIds.add(scheduleZSub.Utility_Account_Subscription__c);
        }

        //select the UAS related to the ScheduleZSubscriptions.
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
        WHERE Id IN : scheduleZUASIds
        ORDER BY Name];

        Map<Id, Utility_Account_Subscription__c> uasMap = new Map<Id, Utility_Account_Subscription__c>();
        for (Utility_Account_Subscription__c uas : uasList) {
            uasMap.put(uas.Id, uas);
        }
        return uasMap;
    }

    private System_Bill__c generateSystemBill(Opportunity opp, Energy_Usage_Update__c euu, Account_Bill__c ab, Integer maxSysBill ) {
        integer sbCounter;

        // Set Bill Number for each opportunity, if opportunity has previous bills increment by one, otherwise set to 1
        if(maxSysBill != null){
            sbCounter = maxSysBill + 1;
        } else {
            sbCounter = 1;
        }

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
            Opportunity__c = opp.Id,
            Unique_Id__c = opp.Name + ' ' + opp.Shared_Solar_System__r.Name + ' ' + getDate(euu));
        return sb;
    }
//    List<Utility_Account_Subscription__c> uasList = [SELECT   Id, Name,
//        Utility_Account_Log__c,
//        Opportunity__r.Name,
//        Opportunity__r.Account.Name,
//        Opportunity__r.Shared_Solar_System__r.Name,
//        Opportunity__r.Shared_Solar_System__c,
//        Opportunity__r.Shared_Solar_System__r.Id,
//        Opportunity__r.AccountId,
//        Max_Account_Bill_Number__c
//    FROM Utility_Account_Subscription__c
//    WHERE Id IN : scheduleZUASIds
//    ORDER BY Name];
//
//    Map<Id, Utility_Account_Subscription__c> uasMap = new Map<Id, Utility_Account_Subscription__c>();
//    for (Utility_Account_Subscription__c uas : uasList) {
//    uasMap.put(uas.Id, uas);
//}
}