/*************************************************************************************
Created By Jordan Pentaleri 08/2019
Tested By: ZuoraGLServiceTest
*************************************************************************************/
@SuppressWarnings('PMD.ApexCRUDViolation')
public with sharing class ZuoraGLService implements Schedulable, ZuoraDataQueryService.Processor {
    public Integer daysToLookBack;
    public Map<String, String> depositAccountToClientMap;
    public List<Journal_Entry__c> entriesSafeToDelete;
    public List<Case> reconciliationItems;
    public List<Journal_Entry__c> entriesToUpsert;

    public void execute(SchedulableContext ctx){
        Date today = System.today();
        if (daysToLookBack == null){
            daysToLookBack = 30;
        }
        getAllDataFromZuora(today.addDays(-1*daysToLookBack), today);
    }

    public static void getAllDataFromZuora(Date startDate, Date endDate){
        /*  Starts with Accounting Period, then then starts chain of Invoice Items, Credit Memos, Debit Memos
            and Payment Parts: Zuora does not perform well when multiple queries are running at the same time.
        */
        String queryString = 'SELECT Max(EndDate) as EndDate FROM AccountingPeriod WHERE Status = \'Closed\'';
        ZuoraDataQueryService.ProcessingParameter methodToRunAfter = new ZuoraDataQueryService.ProcessingParameter();
        methodToRunAfter.className = 'ZuoraGLService';
        methodToRunAfter.methodName = 'AccountingPeriod';
        methodToRunAfter.startDate = startDate;
        methodToRunAfter.endDate = endDate;
        ZuoraDataQueryService.callFromApex(queryString,methodToRunAfter);
    }

    public class GeneralLedgerItem {
        String Project;
        String Client;
        String CustomerAccount;
        String CRMId;
        Date GLDate;
        Datetime GLDatetime;
        Decimal Amount;
        String ReasonCode;
        String ExternalId;
        String Gateway;
        String Lockbox;
        String PaymentMethod;
        String ArchivedChargentData;
    }

    public void executePostQueryJob(ZuoraDataQueryService.ProcessingParameter method, String response) {
        switch on method.methodName {
            // GL Methods: Insert one object's journal entries, then queue next object:
            when 'AccountingPeriod' {
                response = response.substring(1,response.length()-1); // Removes Brackets since only returning 1, not a list:
                ZuoraAPI.AccountingPeriod lastAccountingPeriod = (ZuoraAPI.AccountingPeriod) System.JSON.deserialize(response, ZuoraAPI.AccountingPeriod.class);
                String queryString = ZuoraGLSelector.getInvoiceItems(method.startDate, method.endDate);
                method.methodName = 'InvoiceItem';
                Map<String,Date> optionalDates = new Map<String,Date>();
                optionalDates.put('PeriodCloseDate',lastAccountingPeriod.EndDate);
                method.optionalDates = optionalDates;
                ZuoraDataQueryService.callFromApex(queryString, method);
            }
            when 'InvoiceItem' {
                generalGLRecordInsert(response, method);
                String queryString = ZuoraGLSelector.getCreditMemos(method.startDate, method.endDate);
                method.methodName = 'CreditMemo';
                ZuoraDataQueryService.callFromApex(queryString, method);
            }
            when 'CreditMemo' {
                generalGLRecordInsert(response, method);
                String queryString = ZuoraGLSelector.getDebitMemos(method.startDate, method.endDate);
                method.methodName = 'DebitMemo';
                ZuoraDataQueryService.callFromApex(queryString, method);
            }
            when 'DebitMemo' {
                generalGLRecordInsert(response, method);
                String queryString = ZuoraGLSelector.getPaymentPartsDM(method.startDate, method.endDate);
                method.methodName = 'PaymentPart_DM';
                ZuoraDataQueryService.callFromApex(queryString, method);
            }
            when 'PaymentPart_DM' {
                generalGLRecordInsert(response, method);
                String queryString = ZuoraGLSelector.getPaymentPartsIV(method.startDate, method.endDate);
                method.methodName = 'PaymentPart_IV';
                ZuoraDataQueryService.callFromApex(queryString, method);
            }
            when 'PaymentPart_IV' {
                generalGLRecordInsert(response, method);
            }
        }
    }

    public void generalGLRecordInsert(String response, ZuoraDataQueryService.ProcessingParameter method){
        List<GeneralLedgerItem> ledgerItems = new List<GeneralLedgerItem>();
        Map<String, Journal_Entry__c> zuoraJournalEntries = new Map<String, Journal_Entry__c>();

        ledgerItems = (List<GeneralLedgerItem>)JSON.deserialize(response, List<GeneralLedgerItem>.class);
        zuoraJournalEntries = convertGeneralLedgerToJournalEntry(ledgerItems, method.methodName);

        List<Journal_Entry__c> sfEntries = ZuoraGLSelector.getSFJournalEntries(method.startDate,method.endDate,method.methodName);
        // Sets entriesSafeToDelete, reconciliationItems and entriesToUpsert:
        Date periodCloseDate = method.optionalDates.get('PeriodCloseDate');
        checkForClosedPeriodUpdates(zuoraJournalEntries,sfEntries,periodCloseDate);

        if (entriesSafeToDelete.size() > 0){
            delete entriesSafeToDelete;
        }
        if (reconciliationItems.size() > 0){
            insert reconciliationItems;
        }
        if (entriesToUpsert.size() > 10000){
            Database.executeBatch(new GenericBatchDMLOperation(entriesToUpsert, 'Upsert'));
        } else {
            upsert entriesToUpsert External_Id__c;
        }
        Logger.flushLogs();
    }

    public Map<String, String> getDepositAccountToClientMap(){
        Map<String, String> depositAccountToClientMap = new Map<String, String>();
        GatewaySelector gatewaySelector = new GatewaySelector();
        List<Zuora__PaymentGateway__c> zuoraGateways = gatewaySelector.getAllZuoraGateways();

        for (Zuora__PaymentGateway__c zuoraGateway : zuoraGateways){
            depositAccountToClientMap.put(
                zuoraGateway.Name,
                zuoraGateway.Client_Owner__r.Account_Number__c
            );
        }
        return depositAccountToClientMap;
    }

    public Journal_Entry__c setArchivedPaymentFields(GeneralLedgerItem ledger, Journal_Entry__c entry) {
        ZuoraAPI.ArchivedChargentData chargentData;
        chargentData = (ZuoraAPI.ArchivedChargentData)System.JSON.deserialize(ledger.ArchivedChargentData, ZuoraAPI.ArchivedChargentData.class);
        entry.Paid_To_Client__c = chargentData.ClientNumber;
        entry.Deposit_Account__c = chargentData.GatewayName;
        entry.Payment_Method__c = chargentData.PaymentMethod;
        return entry;
    }

    public Journal_Entry__c setZuoraPaymentFields(GeneralLedgerItem ledger, Journal_Entry__c entry){
        if (ledger.Gateway != null){
            entry.Deposit_Account__c = ledger.Gateway;
            if (depositAccountToClientMap.containsKey(ledger.Gateway)){
                entry.Paid_To_Client__c = depositAccountToClientMap.get(ledger.Gateway);
            } else {
                Logger.logLater('ZuoraGLService','Map Gateway to Client','Could not find client for gateway: ' + JSON.serialize(ledger));
            }
        } else if (ledger.Lockbox != null) {
            try {
                // Assumes Lockbox naming convention of (Lockbox Name)_(Client Number)
                entry.Deposit_Account__c = ledger.Lockbox.split('_')[0];
                entry.Paid_To_Client__c = ledger.Lockbox.split('_')[1];
            } catch (Exception excep){
                Logger.logLater('ZuoraGLService','Map Lockbox to Client','Could not find client for lockbox: ' + JSON.serialize(ledger));
            }
        }
        if (ledger.PaymentMethod != null){
            entry.Payment_Method__c = ledger.PaymentMethod;
        }
        return entry;
    }

    private Map<String, Journal_Entry__c> convertGeneralLedgerToJournalEntry(List<GeneralLedgerItem> ledgerItems, String methodName) {
        Map<String, Journal_Entry__c> journalEntriesMap = new Map<String, Journal_Entry__c>();

        String objectType = methodName;
        if (objectType == 'PaymentPart_DM' || objectType == 'PaymentPart_IV'){
            objectType = 'PaymentPart';
        }
        if (objectType == 'PaymentPart' || objectType == 'DebitMemo'){
            depositAccountToClientMap = getDepositAccountToClientMap();
        }
        for (GeneralLedgerItem ledger : ledgerItems){
            Journal_Entry__c entry = new Journal_Entry__c();
            entry.Object_Type__c = objectType;
            entry.Query_Type__c = methodName;
            entry.Project__c = ledger.Project;
            entry.Client__c = ledger.Client;
            entry.Amount__c = ledger.Amount;
            entry.Reason_Code__c = ledger.reasonCode;
            entry.External_Id__c = ledger.ExternalId;
            entry.Customer_Account__c = ledger.CustomerAccount;

            // Use CRMId as a switch for historical data v. new data in Zuora
            if (objectType == 'PaymentPart' && ledger.CRMId == null) {
                // Going forward, we will report on payments when they are applied:
                entry.Date__c = Date.valueOf(ledger.GLDatetime);
                entry = setZuoraPaymentFields(ledger, entry);
            } else {
                // Historical Migration, we reported on transactions when they were made.
                entry.Date__c = ledger.GLDate;
            }

            if ((objectType == 'DebitMemo' && (ledger.reasonCode == 'Returned Payment' || ledger.reasonCode == 'Refund')) || objectType == 'PaymentPart') {
                if (ledger.ArchivedChargentData == null){
                    entry = setZuoraPaymentFields(ledger, entry);
                } else {
                    entry = setArchivedPaymentFields(ledger, entry);
                }
            }
            journalEntriesMap.put(entry.External_Id__c, entry);
        }
        return journalEntriesMap;
    }

    private void checkForClosedPeriodUpdates(Map<String, Journal_Entry__c> zuoraEntriesToUpsert, List<Journal_Entry__c> sfEntries, Date periodCloseDate){
        entriesSafeToDelete = new List<Journal_Entry__c>();
        reconciliationItems = new List<Case>();
        entriesToUpsert  = new List<Journal_Entry__c>();

        if (sfEntries.size() > 0) {
            for (Journal_Entry__c sfEntry : sfEntries) {
                checkForUpdatesAndDeletions(zuoraEntriesToUpsert, sfEntry, periodCloseDate);
            }
        }
        // Final catch for records in Zuora that are not in SF, but are in a closed period:
        for (Journal_Entry__c zuoraEntry : zuoraEntriesToUpsert.values()) {
            checkForInsertions(zuoraEntry, periodCloseDate);
        }
    }

    private void checkForUpdatesAndDeletions(Map<String, Journal_Entry__c> zuoraEntriesToUpsert, Journal_Entry__c sfEntry, Date periodCloseDate){
        Boolean inUpsertList = zuoraEntriesToUpsert.containsKey(sfEntry.External_Id__c);
        Boolean inClosedPeriod = sfEntry.Date__c <= periodCloseDate;

        if (inUpsertList && inClosedPeriod) {
            // Attempting to Update a SF Record in a Closed Period
            // Only log error if data in a closed period would be changing
            Journal_Entry__c zuoraRecord = zuoraEntriesToUpsert.get(sfEntry.External_Id__c);
            if (!entriesMatch(sfEntry, zuoraRecord)) {
                reconciliationItems.add(createRecItem('Update', JSON.serialize(sfEntry) + JSON.serialize(zuoraRecord)));
            }
            zuoraEntriesToUpsert.remove(sfEntry.External_Id__c);
        } else if (!inUpsertList && inClosedPeriod) {
            // We expected to see closed period SF records in Zuora, but they do not exist:
            reconciliationItems.add(createRecItem('Delete', JSON.serialize(sfEntry)));
        } else if (!inUpsertList) {
            // If SF record is still in an open period, but no longer exists in Zuora, delete it:
            entriesSafeToDelete.add(sfEntry);
        } else {
            // Records that are inUpsertList and !inClosedPeriod: safe to upsert, so continue
        }
    }

    private void checkForInsertions(Journal_Entry__c zuoraEntry, Date periodCloseDate){
        if (zuoraEntry.Date__c > periodCloseDate) {
            entriesToUpsert.add(zuoraEntry);
        } else {
            reconciliationItems.add(createRecItem('Insert', JSON.serialize(zuoraEntry)));
        }
    }

    private Case createRecItem(String actionType, String message){
        CaseFactory caseFactory = new CaseFactory();
        Case newCase = caseFactory.getCase('Data_Ops');
        newCase.Subject = 'Attempted Journal Entry ' + actionType + ' in Closed Period';
        newCase.Priority = 'High';
        newCase.Description = message;
        newCase.Origin = 'Other';
        newCase.Case_Type__c = 'BlueWave';
        newCase.Disable_Followup_Email__c = true;
        return newCase;
    }

    private Boolean entriesMatch(Journal_Entry__c sfEntry, Journal_Entry__c zuoraEntry){
        Boolean isMatch = true;
        if (sfEntry.Amount__c != zuoraEntry.Amount__c
            || sfEntry.Date__c != zuoraEntry.Date__c
            || sfEntry.Project__c != zuoraEntry.Project__c
            || sfEntry.Client__c != zuoraEntry.Client__c
            || sfEntry.Customer_Account__c != zuoraEntry.Customer_Account__c
            || sfEntry.Paid_To_Client__c != zuoraEntry.Paid_To_Client__c
            || sfEntry.Deposit_Account__c != zuoraEntry.Deposit_Account__c){
            isMatch = false;
        }
        return isMatch;
    }
}