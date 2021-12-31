/**
 * @description Created By Jordan Pentaleri 08/2019
 * Tested By: ZuoraGLServiceTest
 * Description: Scheduled job runs every day
 **/
@SuppressWarnings('PMD.ApexCRUDViolation')
public with sharing class ZuoraGLService implements Schedulable, ZuoraDataQueryService.Processor {
    private Map<String, String> depositAccountToClientMap;
    private List<Journal_Entry__c> entriesSafeToDelete;
    private List<Case> reconciliationItems;
    private List<Journal_Entry__c> entriesToUpsert;
    public void execute(SchedulableContext ctx) {
        Date today = System.today();
        // We look back into the closed period to see if transactions changed but shouldn't have. It used to be 60
        // days, but we started running into limit issues around June 2020.
        getAllDataFromZuora(today.addDays(-45), today);
    }

    public static void getAllDataFromZuora(Date startDate, Date endDate) {
        /*  Starts with Accounting Period, then then starts chain of Invoice Items, Credit Memos, Debit Memos
            and Payment Parts: Zuora does not perform well when multiple queries are running at the same time.
        */
        String queryString = 'SELECT Max(EndDate) as EndDate FROM AccountingPeriod WHERE Status = \'Closed\'';
        ZuoraDataQueryService.ProcessingParameter methodToRunAfter = new ZuoraDataQueryService.ProcessingParameter();
        methodToRunAfter.className = 'ZuoraGLService';
        methodToRunAfter.methodName = 'AccountingPeriod';
        methodToRunAfter.startDate = startDate;
        methodToRunAfter.endDate = endDate;
        methodToRunAfter.optionalDates = new Map<String, Date>();
        methodToRunAfter.optionalDates.put('Halfway', startDate.addDays(startDate.daysBetween(endDate) / 2));
        methodToRunAfter.enableContinueOnNoData();
        ZuoraDataQueryService.callFromApex(queryString, methodToRunAfter);
    }

    @SuppressWarnings('PMD.VariableNamingConventions,PMD.FieldNamingConventions,PMD.TooManyFields')
    private class GeneralLedgerItem {
        private String Project;
        private String Client;
        private String CustomerAccount;
        private String CRMId;
        private Date GLDate;
        private Datetime GLDatetime;
        private Decimal Amount;
        private String ReasonCode;
        private String ExternalId;
        private String Gateway;
        private String Lockbox;
        private String PaymentMethod;
        private String ArchivedChargentData;
        private String AppliedRecordId;
        private String Comments;
        private String ReferenceId;
    }

    public void executePostQueryJob(ZuoraDataQueryService.ProcessingParameter method, String response) {
        switch on method.methodName {
            // GL Methods: Insert one object's journal entries, then queue next object:
            when 'AccountingPeriod' {
                response = response.substring(1, response.length() - 1); // Removes Brackets since only returning 1, not a list:
                ZuoraAPI.AccountingPeriod lastAccountingPeriod = (ZuoraAPI.AccountingPeriod) System.JSON.deserialize(response, ZuoraAPI.AccountingPeriod.class);
                saveAccountingPeriodCloseDate(lastAccountingPeriod.EndDate);
                String queryString = ZuoraGLSelector.getInvoiceItems(method.startDate, method.optionalDates.get('Halfway'));
                method.methodName = 'InvoiceItem_First_Half';
                method.optionalDates.put('PeriodCloseDate', lastAccountingPeriod.EndDate);
                ZuoraDataQueryService.callFromApex(queryString, method);
            }
            when 'InvoiceItem_First_Half' {
                generalGLRecordInsert(response, method);
                String queryString = ZuoraGLSelector.getInvoiceItems(method.optionalDates.get('Halfway'), method.endDate);
                method.methodName = 'InvoiceItem_Last_Half';
                ZuoraDataQueryService.callFromApex(queryString, method);
            }
            when 'InvoiceItem_Last_Half' {
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
                method.methodName = 'PaymentPart_IV_First_Half';
                String queryString = ZuoraGLSelector.getPaymentPartsIV(method.startDate, method.optionalDates.get('Halfway'));
                ZuoraDataQueryService.callFromApex(queryString, method);
            }
            when 'PaymentPart_IV_First_Half' {
                generalGLRecordInsert(response, method);
                String queryString = ZuoraGLSelector.getPaymentPartsIV(method.optionalDates.get('Halfway'), method.endDate);
                method.methodName = 'PaymentPart_IV_Last_Half';
                ZuoraDataQueryService.callFromApex(queryString, method);
            }
            when 'PaymentPart_IV_Last_Half' {
                generalGLRecordInsert(response, method, 'PartnerCommissionHandler');
            }
        }
    }

    @TestVisible
    private void saveAccountingPeriodCloseDate(Date periodCloseDate) {
        Zuora_Custom_Setting__c zuoraSetting = Zuora_Custom_Setting__c.getOrgDefaults();
        zuoraSetting.Last_Accounting_Period_Close_Date__c = periodCloseDate;
        if (zuoraSetting == null || zuoraSetting.Id == null) {
            insert zuoraSetting;
        } else {
            update zuoraSetting;
        }
    }

    @TestVisible
    private void generalGLRecordInsert(String response, ZuoraDataQueryService.ProcessingParameter method) {
        generalGLRecordInsert(response, method, null);
    }

    @TestVisible
    private void generalGLRecordInsert(String response, ZuoraDataQueryService.ProcessingParameter method, String postBatchClass) {
        List<GeneralLedgerItem> ledgerItems = new List<GeneralLedgerItem>();
        Map<String, Journal_Entry__c> queriedJournalEntriesByExternalId = new Map<String, Journal_Entry__c>();

        ledgerItems = (List<GeneralLedgerItem>) JSON.deserialize(response, List<GeneralLedgerItem>.class);
        if (ledgerItems.isEmpty()) {
            return;
        }
        // Because some queries are broken into two to avoid limits, and we query Salesforce to compare what's there,
        // we need to use the right start and end dates. We also don't want to update the method.startDate or method.endDate
        // since that would change the start/end for any subsequent queries in the chain.
        Date startDate = method.startDate;
        Date endDate = method.endDate;
        if (method.methodName.contains('First_Half')) {
            endDate = method.optionalDates.get('Halfway');
        } else if (method.methodName.contains('Last_Half')) {
            startDate = method.optionalDates.get('Halfway');
        }
        method.methodName = method.methodName.removeEnd('_First_Half').removeEnd('_Last_Half');

        queriedJournalEntriesByExternalId = convertGeneralLedgerToJournalEntry(ledgerItems, method.methodName);

        JournalEntrySelector selector = new JournalEntrySelector();
        List<Journal_Entry__c> existingEntries = selector.getSFJournalEntries(startDate, endDate, method.methodName);
        // Sets entriesSafeToDelete, reconciliationItems and entriesToUpsert:
        Date periodCloseDate = method.optionalDates.get('PeriodCloseDate');
        upsertAndDeleteJournalEntries(queriedJournalEntriesByExternalId, existingEntries, periodCloseDate);

        delete entriesSafeToDelete;
        upsert reconciliationItems External_Id__c;

        if (entriesToUpsert.size() > 200) {
            GenericBatchDMLOperation batchDMLOperation = new GenericBatchDMLOperation(entriesToUpsert, 'Upsert');
            batchDMLOperation.setPostBatchOperation(postBatchClass);
            Database.executeBatch(batchDMLOperation);
        } else {
            upsert entriesToUpsert External_Id__c;
            GenericBatchDMLOperation.executePostBatchOperation(postBatchClass);
        }
        Logger.flushLogs();
    }

    private Map<String, String> getDepositAccountToClientMap() {
        Map<String, String> depositAccountToClientMap = new Map<String, String>();
        GatewaySelector gatewaySelector = new GatewaySelector();
        List<Zuora__PaymentGateway__c> zuoraGateways = gatewaySelector.getAllZuoraGateways();

        for (Zuora__PaymentGateway__c zuoraGateway : zuoraGateways) {
            depositAccountToClientMap.put(
                zuoraGateway.Name,
                zuoraGateway.Client_Owner__r.Account_Number__c
            );
        }
        return depositAccountToClientMap;
    }

    private Journal_Entry__c setArchivedPaymentFields(GeneralLedgerItem ledger, Journal_Entry__c entry) {
        ZuoraAPI.ArchivedChargentData chargentData;
        chargentData = (ZuoraAPI.ArchivedChargentData) System.JSON.deserialize(ledger.ArchivedChargentData, ZuoraAPI.ArchivedChargentData.class);
        entry.Paid_To_Client__c = chargentData.ClientNumber;
        entry.Deposit_Account__c = chargentData.GatewayName;
        entry.Payment_Method__c = chargentData.PaymentMethod;
        return entry;
    }

    private Journal_Entry__c setZuoraPaymentFields(GeneralLedgerItem ledger, Journal_Entry__c entry) {
        if (ledger.Gateway != null) {
            entry.Deposit_Account__c = ledger.Gateway;
            if (depositAccountToClientMap.containsKey(ledger.Gateway)) {
                entry.Paid_To_Client__c = depositAccountToClientMap.get(ledger.Gateway);
            } else {
                Logger.logLater('ZuoraGLService', 'Map Gateway to Client', 'Could not find client for gateway: ' + JSON.serialize(ledger));
            }
        } else if (ledger.Lockbox != null) {
            try {
                // Assumes Lockbox naming convention of (Lockbox Name)_(Client Number)
                entry.Deposit_Account__c = ledger.Lockbox.split('_')[0];
                entry.Paid_To_Client__c = ledger.Lockbox.split('_')[1];
            } catch (Exception excep) {
                Logger.logLater('ZuoraGLService', 'Map Lockbox to Client', 'Could not find client for lockbox: ' + JSON.serialize(ledger));
            }
        }
        if (ledger.PaymentMethod != null) {
            entry.Payment_Method__c = ledger.PaymentMethod;
        }
        return entry;
    }

    private Map<String, Journal_Entry__c> convertGeneralLedgerToJournalEntry(List<GeneralLedgerItem> ledgerItems, String methodName) {
        Map<String, Journal_Entry__c> journalEntriesMap = new Map<String, Journal_Entry__c>();

        String objectType = methodName;
        if (objectType == 'PaymentPart_DM' || objectType == 'PaymentPart_IV') {
            objectType = 'PaymentPart';
        }
        if (objectType == 'PaymentPart' || objectType == 'DebitMemo') {
            depositAccountToClientMap = getDepositAccountToClientMap();
        }
        for (GeneralLedgerItem ledger : ledgerItems) {
            Journal_Entry__c entry = new Journal_Entry__c();
            entry.Object_Type__c = objectType;
            entry.Query_Type__c = methodName;
            entry.Project__c = ledger.Project;
            entry.Client__c = ledger.Client;
            entry.Amount__c = ledger.Amount;
            entry.Reason_Code__c = ledger.ReasonCode;
            entry.External_Id__c = ledger.ExternalId;
            entry.Customer_Account__c = ledger.CustomerAccount;
            entry.Applied_Record_Id__c = ledger.AppliedRecordId;
            entry.Reference_Id__c = ledger.ReferenceId;

            populateJournalEntry(objectType, ledger, entry);
            journalEntriesMap.put(entry.External_Id__c, entry);
        }
        return journalEntriesMap;
    }

    private void populateJournalEntry(String objectType, GeneralLedgerItem ledger, Journal_Entry__c entry) {
        // Use CRMId as a switch for historical data v. new data in Zuora
        if (objectType == 'PaymentPart' && ledger.CRMId == null) {
            // Going forward, we will report on payments when they are applied:
            Datetime dateAsDateTime = ledger.GLDatetime;
            entry.Date__c = Date.newInstance(dateAsDateTime.year(), dateAsDateTime.month(), dateAsDateTime.day());
            entry = setZuoraPaymentFields(ledger, entry);
        } else {
            // Historical Migration, we reported on transactions when they were made.
            entry.Date__c = ledger.GLDate;
        }

        if ((objectType == 'DebitMemo' && (ledger.ReasonCode == 'Returned Payment' || ledger.ReasonCode == 'Refund')) || objectType == 'PaymentPart') {
            if (ledger.ReasonCode == 'Returned Payment') {
                //Comments example: Original Payment 2c92a00b71c96bdf0171dfcabc4e34c7, PaymentPartItem 2c92a00a71c95c4a0171dfcaf46f5343
                entry.Returned_PaymentPart_Id__c = ledger.Comments.substringAfter('PaymentPartItem ');
            }
            if (ledger.ArchivedChargentData == null) {
                entry = setZuoraPaymentFields(ledger, entry);
            } else {
                entry = setArchivedPaymentFields(ledger, entry);
            }
        }
    }

    private void upsertAndDeleteJournalEntries(Map<String, Journal_Entry__c> queriedJournalEntriesByExternalId, List<Journal_Entry__c> sfEntries, Date periodCloseDate) {
        entriesSafeToDelete = new List<Journal_Entry__c>();
        reconciliationItems = new List<Case>();
        entriesToUpsert = new List<Journal_Entry__c>();

        for (Journal_Entry__c sfEntry : sfEntries) {
            checkForUpdatesAndDeletions(queriedJournalEntriesByExternalId, sfEntry, periodCloseDate);
        }
        for (Journal_Entry__c zuoraEntry : queriedJournalEntriesByExternalId.values()) {
            checkForInsertions(zuoraEntry, periodCloseDate);
        }
    }

    private void checkForUpdatesAndDeletions(Map<String, Journal_Entry__c> queriedJournalEntriesByExternalId, Journal_Entry__c sfEntry, Date periodCloseDate) {
        Boolean inUpsertList = queriedJournalEntriesByExternalId.containsKey(sfEntry.External_Id__c);
        Boolean inClosedPeriod = sfEntry.Date__c <= periodCloseDate;

        if (inUpsertList && inClosedPeriod) {
            // Attempting to Update a SF Record in a Closed Period
            // Only log error if data in a closed period would be changing
            Journal_Entry__c zuoraRecord = queriedJournalEntriesByExternalId.get(sfEntry.External_Id__c);
            if (!entriesMatch(sfEntry, zuoraRecord)) {
                reconciliationItems.add(createRecItem('Update', JSON.serialize(sfEntry) + JSON.serialize(zuoraRecord), sfEntry.External_Id__c));
            }
            queriedJournalEntriesByExternalId.remove(sfEntry.External_Id__c);
        } else if (!inUpsertList && inClosedPeriod) {
            // We expected to see closed period SF records in Zuora, but they do not exist:
            reconciliationItems.add(createRecItem('Delete', JSON.serialize(sfEntry), sfEntry.External_Id__c));
        } else if (!inUpsertList) {
            // If SF record is still in an open period, but no longer exists in Zuora, delete it:
            entriesSafeToDelete.add(sfEntry);
        }
        // Records that are inUpsertList and !inClosedPeriod: safe to upsert, so continue
        Logger.flushLogs();
    }

    private void checkForInsertions(Journal_Entry__c zuoraEntry, Date periodCloseDate) {
        if (zuoraEntry.Date__c > periodCloseDate) {
            entriesToUpsert.add(zuoraEntry);
        } else {
            reconciliationItems.add(createRecItem('Insert', JSON.serialize(zuoraEntry), zuoraEntry.External_Id__c));
        }
    }

    @TestVisible
    private Case createRecItem(String actionType, String message, String externalId) {
        CaseFactory caseFactory = new CaseFactory();
        Case newCase = caseFactory.getCase('Data_Ops');
        newCase.Subject = 'Attempted Journal Entry ' + actionType + ' in Closed Period';
        newCase.Priority = 'High';
        newCase.Description = message;
        newCase.Origin = 'Other';
        newCase.Case_Type__c = 'BlueWave';
        newCase.Disable_Followup_Email__c = true;
        newCase.External_Id__c = externalId;
        return newCase;
    }

    private Boolean entriesMatch(Journal_Entry__c sfEntry, Journal_Entry__c zuoraEntry) {
        Boolean isMatch = true;
        if (sfEntry.Amount__c != zuoraEntry.Amount__c
            || sfEntry.Date__c != zuoraEntry.Date__c
            || sfEntry.Project__c != zuoraEntry.Project__c
            || sfEntry.Client__c != zuoraEntry.Client__c
            || sfEntry.Customer_Account__c != zuoraEntry.Customer_Account__c
            || sfEntry.Paid_To_Client__c != zuoraEntry.Paid_To_Client__c
            || sfEntry.Deposit_Account__c != zuoraEntry.Deposit_Account__c) {
            isMatch = false;
            String message = 'Amount:' + String.valueOf(sfEntry.Amount__c != zuoraEntry.Amount__c);
            message += '\nDate:' + String.valueOf(sfEntry.Date__c != zuoraEntry.Date__c);
            message += '\nDate Debugging: ' + sfEntry.Date__c.isSameDay(zuoraEntry.Date__c);
            message += '\nProject:' + String.valueOf(sfEntry.Project__c != zuoraEntry.Project__c);
            message += '\nClient:' + String.valueOf(sfEntry.Client__c != zuoraEntry.Client__c);
            message += '\nCustomer:' + String.valueOf(sfEntry.Customer_Account__c != zuoraEntry.Customer_Account__c);
            message += '\nPaid to Client:' + String.valueOf(sfEntry.Paid_To_Client__c != zuoraEntry.Paid_To_Client__c);
            message += '\nDepositAccount:' + String.valueOf(sfEntry.Deposit_Account__c != zuoraEntry.Deposit_Account__c);
            Logger.logLater('ZuoraGLService', 'entriesMatch', message + '\n' + JSON.serialize(sfEntry) + '\n' + JSON.serialize(zuoraEntry), Logger.INFO);
        }
        return isMatch;
    }
}