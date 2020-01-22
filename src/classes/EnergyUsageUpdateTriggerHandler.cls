/*
 * Created By: Cole Swain
 * Description: Creates CS Bills after a Production Update is created
 *
 * This class is only creating the admin details of the bills. Sets up the correct relationships and such.
 * Money Due, kWh, etc aren't calculated.
 *
 * Tested by: TestBillCreationandPayment, RecurringPaymentsHandlerTestClass, TestBillCreationForCancelledCustomers
 */

public without sharing class EnergyUsageUpdateTriggerHandler implements Database.Batchable<Schedule_Z_Subscription__c> {
    public Map<Id, Bill_Period__c> sssToBillPeriod = new Map<Id, Bill_Period__c>();
    public List<Transfer__c> transferList = new List<Transfer__c>();
    public Map<Id, List<Transfer__c>> sssToTransfersMap = new Map<Id, List<Transfer__c>>();
    public Set<Id> bpIds = new Set<Id>();
    public Set<Id> scheduleZs = new Set<Id>();
    public Set<Integer> bpMonths = new Set<Integer>();
    public Set<String> bpYears = new Set<String>();
    public Map<String, Account_Bill__c> abKeyToAccountBillMap = new Map<String, Account_Bill__c>();
    public Map<Id, List<Product_Escalator__c>> productScheduleToEscalationMap = new Map<Id, List<Product_Escalator__c>>();

    // Prep for batch, set list of Schedule Z Ids and Shared Solar System Map:
    public EnergyUsageUpdateTriggerHandler(List<Bill_Period__c> billPeriodsList) {
        for (Bill_Period__c bp : billPeriodsList) {
            bpIds.add(bp.Id);
            sssToBillPeriod.put(bp.Shared_Solar_System__c, bp);
            bpMonths.add(bp.Bill_Date__c.month());
            bpYears.add(String.valueOf(bp.Bill_Date__c.year()));
        }

        //Get all the Transfers from BP Ids:
        transferList = TransferSelector.getAllTransfersByBillPeriod(bpIds);

        // Get schedule Zs from Transfers
        for (Transfer__c transfer : transferList) {
            scheduleZs.add(transfer.Allocation_Schedule__c);
            if (sssToTransfersMap.containsKey(transfer.Shared_Solar_System__c)) {
                List<Transfer__c> transferList = sssToTransfersMap.get(transfer.Shared_Solar_System__c);
                transferList.add(transfer);
                sssToTransfersMap.put(transfer.Shared_Solar_System__c, transferList);
            } else {
                sssToTransfersMap.put(transfer.Shared_Solar_System__c, new List<Transfer__c>{transfer});
            }
        }

        productScheduleToEscalationMap = ProductEscalatorSelector.getProductEscalationMap();

        for (Account_Bill__c accountBill : [
            SELECT Id, Unique_ID__c
            FROM Account_Bill__c
            WHERE Month__c IN : bpMonths
            AND Year__c IN : bpYears
        ]) {
            abKeyToAccountBillMap.put(accountBill.Unique_ID__c, accountBill);
        }
    }

    public void runBills() {
        System_Properties__c sysProp = System_Properties__c.getAll().values()[0];
        Decimal csBillBatchSize = sysProp.CS_Bill_Batch_Size__c;

        if (Test.isRunningTest()) {
            // Mock running the batch so that we can trigger multiple batches in a test
            List<Schedule_Z_Subscription__c> scheduleZSubscriptions = (List<Schedule_Z_Subscription__c>) start(null);
            execute(null, scheduleZSubscriptions);
            finish(null);
        } else {
            Database.executeBatch(this, Integer.valueOf(csBillBatchSize));
        }
    }

    public List<Schedule_Z_Subscription__c> getOverdueScheduleZSubscriptions(Set<Id> uasIdsAlreadyBilling) {
        System_Properties__c sysProp = System_Properties__c.getAll().values()[0];
        Decimal minimumBalance = Util.nullToZero(sysProp.Minimum_Balance_Bills_for_Cancelled__c);
        Date today = Date.today();
        Date maxPastDueDate = today.addDays(-(Integer.valueOf(Util.nullToZero(sysProp.Days_Generate_Bills_For_Cancelled__c))));
        Set<Id> overdueUASIds = new Set<Id>();
        List<UASB__c> overdueUASBs = [
            SELECT Id, System_Bill__r.Unique_ID__c, System_Bill__r.Opportunity__r.Id, Utility_Account_Subscription__c,
                System_Bill__r.Account_Bill__r.Parent_Account__r.Last_Bill_Send_Date_New_Charges__c
            FROM UASB__c
            WHERE System_Bill__r.Shared_Solar_System__c IN : sssToBillPeriod.keySet()
            AND System_Bill__r.Balance_Net_Late_Payments__c > : minimumBalance
            AND System_Bill__r.Account_Bill__r.Parent_Account__r.Last_Bill_Send_Date_New_Charges__c >= : maxPastDueDate
            AND System_Bill__r.Account_Bill__r.Parent_Account__r.Last_Bill_Send_Date_New_Charges__c <= :today
        ];

        for (UASB__c uasb : overdueUASBs) {
            overdueUASIds.add(uasb.Utility_Account_Subscription__c);
        }

        List<Utility_Account_Subscription__c> uasesWithAnOverdueUASB = [
            SELECT Id, (
                // We want to get a SZS for this overdue UAS, with which we can generate a bill
                SELECT Id, Utility_Account_Subscription__c, Utility_Account_Subscription__r.Opportunity__c
                FROM Schedule_Z_Subscriptions__r
                ORDER BY CreatedDate DESC
                LIMIT 1
            )
            FROM Utility_Account_Subscription__c
            WHERE Id IN :overdueUASIds
        ];

        List<Schedule_Z_Subscription__c> szsList = new List<Schedule_Z_Subscription__c>();
        for (Utility_Account_Subscription__c uas : uasesWithAnOverdueUASB) {
            if (!uasIdsAlreadyBilling.contains(uas.Id)) {
                szsList.addAll(uas.Schedule_Z_Subscriptions__r);
            }
        }
        return szsList;
    }

    private static String getDate(Bill_Period__c bp) {
        return Datetime.newInstance(bp.Bill_Date__c.year(), bp.Bill_Date__c.month(), bp.Bill_Date__c.day()).format('yyyy-MM');
    }

    // Batch into groups of Schedule Z Subscriptions:
    public Iterable<Schedule_Z_Subscription__c> start(Database.BatchableContext bc) {
        List<Schedule_Z_Subscription__c> szsList = ScheduleZSubscriptionSelector.getListForBilling(scheduleZs);
        Set<Id> uasIdsAlreadyBilling = new Set<Id>();
        for (Schedule_Z_Subscription__c szs : szsList) {
            uasIdsAlreadyBilling.add(szs.Utility_Account_Subscription__c);
        }
        szsList.addAll(getOverdueScheduleZSubscriptions(uasIdsAlreadyBilling));

        return szsList;
    }

    // Execute this code block in batches to avoid CPU Limit:
    public void execute(Database.BatchableContext bc, List<Schedule_Z_Subscription__c> scheduleZSubscriptions) {
        try {
            createBills(scheduleZSubscriptions);
        } catch (Exception e) {
            Logger.logNow('EnergyUsageUpdateTriggerHandler', 'createBills', e.getMessage() + '\n' + e.getStackTraceString(), Logger.ERROR);
        }
    }

    public void createBills(List<Schedule_Z_Subscription__c> scheduleZSubscriptions ){
        Set<Id> scheduleZUASIds = new Set<Id>();
        Set<Id> oppIds = new Set<Id>();
        Map<String, Account_Bill__c> abToUpsertMap = new Map<String, Account_Bill__c>();
        Map<Id, Utility_Account_Subscription__c> uasMap = new Map<Id, Utility_Account_Subscription__c>();

        if (scheduleZSubscriptions.size() > 0) {
            for (Schedule_Z_Subscription__c scheduleZSub : scheduleZSubscriptions) {
                scheduleZUASIds.add(scheduleZSub.Utility_Account_Subscription__c);
                oppIds.add(scheduleZSub.Utility_Account_Subscription__r.Opportunity__c);
            }
            uasMap = getUASFromSZS(scheduleZUASIds, oppIds);
        }
        //select the Opportunities that are related to the shared solar systems that have transfers being logged.
        List<Opportunity> oppList = [
            SELECT Id, Name, Account.Name, Shared_Solar_System__r.Name, Shared_Solar_System__r.Billing_Anchors__c,
                Shared_Solar_System__c, AccountId, Account.Id,  Account.Account_Number__c, Account.Recurring_Billing__c, Product__r.Monthly_Late_Fee__c,
                Product__r.Days_in_Bill_Period__c, Account.Max_Account_Bill_Number__c, StageName
            FROM Opportunity
            WHERE Shared_Solar_System__c IN : sssToBillPeriod.keySet()
            AND Id IN : oppIds
            ORDER BY Name
        ];

        //Generate a list of all System Bill Numbers for each opportunity
        Map<String, Integer> maxSysBillByOppId = maxSysBillByOppId(sssToBillPeriod.keySet(), oppIds);

        Map<String, System_Bill__c> previousBillsSet = new Map<String, System_Bill__c>();
        for (System_Bill__c systemBill : [
            SELECT Id, Unique_ID__c
            FROM System_Bill__c
            WHERE Month__c IN : bpMonths
            AND Shared_Solar_System__c IN : sssToBillPeriod.keySet()
        ]) {
            previousBillsSet.put(systemBill.Unique_ID__c, systemBill);
        }

        for (Opportunity opp : oppList) {
            if (sssToBillPeriod.containsKey(opp.Shared_Solar_System__c)) {
                Bill_Period__c bp = sssToBillPeriod.get(opp.Shared_Solar_System__c);
                String abUniqueID = opp.Account.Id + ' ' + getDate(bp);
                if (!abKeyToAccountBillMap.containsKey(abUniqueID)) {
                    try {
                        Account_Bill__c ab = generateAccountBill(opp, abUniqueID, bp);
                        abKeyToAccountBillMap.put(ab.Unique_ID__c, ab);
                        abToUpsertMap.put(ab.Unique_ID__c, ab);
                    } catch (Exception e){
                        String message = 'Account Bill Creation Failed for UniqueID ' + abUniqueID + 'Error: ' + String.valueOf(e);
                        Logger.logLater('EnergyUsageUpdateTriggerHandler', 'GenerateAccountBill', message);
                    }
                }
            }
        }

        //Create the Account Bills
        if (!abToUpsertMap.isEmpty()) {
            upsert abToUpsertMap.values() Unique_ID__c;
        }

        Map<String, System_Bill__c > systemBillMap = new Map<String, System_Bill__c >();
        for (Opportunity opp : oppList) {
            Bill_Period__c bp = sssToBillPeriod.get(opp.Shared_Solar_System__c);
            String parentKey = opp.Account.Id + ' ' + getDate(bp);
            String sysBillUniqueId = opp.Id + ' ' + opp.Shared_Solar_System__r.Name + ' ' + getDate(bp);
            if (abKeyToAccountBillMap.containsKey(parentKey) && !previousBillsSet.containsKey(sysBillUniqueId)) {
                Integer maxSysBill = maxSysBillByOppId.get(opp.Id);
                Account_Bill__c ab = abKeyToAccountBillMap.get(parentKey);
                try {
                    System_Bill__c sb = generateSystemBill(opp, bp, ab, maxSysBill, sysBillUniqueId);
                    systemBillMap.put(sb.Unique_ID__c, sb);
                } catch (Exception e) {
                    String message = 'System Bill Creation Failed for Parent Id ' + parentKey  + 'Error: ' + String.valueOf(e);
                    Logger.logLater('EnergyUsageUpdateTriggerHandler', 'GenerateSystemBill', message);
                }
            } else if (previousBillsSet.containsKey(sysBillUniqueId)) {
                System_Bill__c systemBill = previousBillsSet.get(sysBillUniqueId);
                systemBillMap.put(systemBill.Unique_ID__c, systemBill);
            }
        }

        if (!systemBillMap.isEmpty()) {
            upsert systemBillMap.values() Unique_ID__c;
        }

        Map<Id, Utility_Account_Bill__c> utilityAccountLogIdToUABMap = new Map<Id, Utility_Account_Bill__c>();
        for (Utility_Account_Subscription__c uas : uasMap.values()) {
            Bill_Period__c bp = sssToBillPeriod.get(uas.Opportunity__r.Shared_Solar_System__c);
            String parentKey = uas.Opportunity__r.Account.Id + ' ' + getDate(bp);
            if (abKeyToAccountBillMap.containsKey(parentKey)) {
                Account_Bill__c ab = abKeyToAccountBillMap.get(parentKey);
                try {
                    Utility_Account_Bill__c uab = generateUtilityAccountBill(uas, bp, ab);
                    utilityAccountLogIdToUABMap.put(uab.Utility_Account_Log__c, uab);
                } catch (Exception e) {
                    String message = 'Utility Account Bill Creation Failed for Account Id ' + ab.Unique_ID__c  + 'Error: ' + String.valueOf(e);
                    Logger.logLater('EnergyUsageUpdateTriggerHandler', 'GenerateSystemBill', message);
                }
            }
        }
        if (!utilityAccountLogIdToUABMap.isEmpty()) {
            upsert utilityAccountLogIdToUABMap.values() Unique_Id__c;
        }

        Logger.flushLogs();
        UtilityAccountBillTriggerHandler handler = new UtilityAccountBillTriggerHandler();
        handler.createUASB(sssToTransfersMap, systemBillMap, utilityAccountLogIdToUABMap, uasMap.values(), productScheduleToEscalationMap);
    }

    public void finish(Database.BatchableContext bc){
        for (Transfer__c transfer : transferList){
            transfer.Bills_Generated__c = true;
        }
        update transferList;
    }

    private Account_Bill__c generateAccountBill(Opportunity opp, String abUniqueID, Bill_Period__c bp) {
        Integer abCounter;
        if(opp.Account.Max_Account_Bill_Number__c == null) {
            abCounter = 1;
        } else {
            abCounter = (opp.Account.Max_Account_Bill_Number__c).intValue() + 1;
        }
        Account_Bill__c ab = new Account_Bill__c(
            Name = opp.Account.Account_Number__c + ' ' + bp.Bill_Date__c.month() + ' ' + String.valueOf(bp.Bill_Date__c.year()),
            Date__c =  bp.Bill_Date__c,
            Parent_Account__c = opp.Account.Id,
            Bill_Number__c = abCounter,
            Last_Shared_Solar_System_ID__c = opp.Shared_Solar_System__r.Id
        );
        ab.Unique_Id__c = abUniqueID;
        return ab;
    }

    private Map<String, Integer> maxSysBillByOppId(Set<Id> sssIds, Set<Id> oppIds) {
        Map<String, Integer> oppKeyMap = new Map<String, Integer>();
        for ( AggregateResult lineItem : [
            SELECT Opportunity__r.Id oppID, MAX(Bill_Number__c) maxBillNumber
            FROM System_Bill__c
            WHERE Shared_Solar_System__c IN : sssIds
            AND Opportunity__c IN : oppIds
            GROUP BY Opportunity__r.Id
        ]) {
            String oppId = (String)lineItem.get('oppID');
            Decimal maxBillNumber = (Decimal)lineItem.get('maxBillNumber');
            oppKeyMap.put(oppId, maxBillNumber.intValue());
        }
        return oppKeyMap;
    }

    private Map<Id, Utility_Account_Subscription__c> getUASFromSZS(Set<Id> scheduleZUASIds, Set<Id> oppIds) {
        //select the UAS related to the ScheduleZSubscriptions.
        List<Utility_Account_Subscription__c> uasList = [
            SELECT   Id, Name,
                Utility_Account_Log__c,
                Opportunity__r.Name,
                Opportunity__r.Account.Name,
                Opportunity__r.Shared_Solar_System__r.Count_of_Transfers__c,
                Opportunity__r.Shared_Solar_System__r.Name,
                Opportunity__r.Shared_Solar_System__c,
                Opportunity__r.Shared_Solar_System__r.Id,
                Opportunity__r.AccountId,
                Opportunity__r.Account.Account_Number__c,
                Opportunity__r.StageName,
                Opportunity__r.Product_Escalation_Schedule__c,
                Externally_Serviced__c,
                Max_Account_Bill_Number__c
            FROM Utility_Account_Subscription__c
            WHERE Id IN : scheduleZUASIds
            AND Opportunity__c IN : oppIds
            ORDER BY Name
        ];

        Map<Id, Utility_Account_Subscription__c> uasMap = new Map<Id, Utility_Account_Subscription__c>();
        for (Utility_Account_Subscription__c uas : uasList) {
            uasMap.put(uas.Id, uas);
        }
        return uasMap;
    }

    @SuppressWarnings('PMD.ExcessiveParameterList')
    private System_Bill__c generateSystemBill(Opportunity opp, Bill_Period__c bp, Account_Bill__c ab, Integer maxSysBill, String uniqueId ) {
        integer sbCounter;
        // Set Bill Number for each opportunity, if opportunity has previous bills increment by one, otherwise set to 1
        if(maxSysBill != null){
            sbCounter = maxSysBill + 1;
        } else {
            sbCounter = 1;
        }

        System_Bill__c sb = new System_Bill__c(
            Name = opp.Account.Account_Number__c + ' ' + (opp.Shared_Solar_System__r.Name).abbreviate(40) + ' ' + bp.Bill_Date__c.month() + ' ' + String.valueOf(bp.Bill_Date__c.year()),
            Shared_Solar_System_ID2__c = opp.Shared_Solar_System__r.Id,
            Account_Bill__c = ab.Id,
            Recurring_Billing__c = opp.Account.Recurring_Billing__c,
            Date__c =  bp.Bill_Date__c,
            Bill_Number__c = sbCounter,
            Shared_Solar_System__c = opp.Shared_Solar_System__r.Id,
            Monthly_Late_Fee_Interest__c = opp.Product__r.Monthly_Late_Fee__c,
            Days_in_Bill_Period__c = opp.Product__r.Days_in_Bill_Period__c,
            Property_Account__c = opp.Account.Id,
            Opportunity__c = opp.Id,
            Unique_Id__c = uniqueId
        );
        return sb;
    }

    private Utility_Account_Bill__c generateUtilityAccountBill(Utility_Account_Subscription__c uas, Bill_Period__c bp, Account_Bill__c ab) {
        Utility_Account_Bill__c uab = new Utility_Account_Bill__c(
            Name = uas.Opportunity__r.Account.Account_Number__c + ' ' + bp.Bill_Date__c.month() + ' ' + String.valueOf(bp.Bill_Date__c.year()) + ' ' + uas.Name,
            Shared_Solar_System__c = bp.Shared_Solar_System__c,
            Date__c =  bp.Bill_Date__c,
            Utility_Account_Log__c = uas.Utility_Account_Log__c,
            Account_Bill__c = ab.Id
        );
        uab.Unique_Id__c = uas.Utility_Account_Log__c + ' - ' + getDate(bp);
        return uab;
    }
}