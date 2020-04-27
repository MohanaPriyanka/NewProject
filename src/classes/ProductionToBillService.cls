// Tested By: ProductionToBillServiceTest
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class ProductionToBillService implements ZuoraDataQueryService.Processor, Queueable, Database.AllowsCallouts{
    @TestVisible
    private static PtbSelectors selectors = new PtbSelectors();

    @TestVisible
    private class PtbSelectors {
        @TestVisible
        private ZuoraUsageSelector usage = new ZuoraUsageSelector();
        @TestVisible
        private JournalEntrySelector journalEntry = new JournalEntrySelector();
        @TestVisible
        private ProductionDetailSelector transferParts = new ProductionDetailSelector();
        @TestVisible
        private UASBSelector uasb = new UASBSelector();
        @TestVisible
        private AdjustmentSelector adjustment = new AdjustmentSelector();
    }

    public enum OperationType {BILL, PAYMENT, CREDITMEMO, UNSERVICED}
    public OperationType opType;
    public Integer batchSize;
    public Integer calloutCount;

    private Set<Id> transferIds = new Set<Id>();
    private Set<Id> uasbIds = new Set<Id>();
    private Set<Id> adjustmentIds = new Set<Id>();

    @TestVisible
    private Map<String, GLInvoiceItem> invoiceIdToUsageMap = new Map<String, GLInvoiceItem>();
    @TestVisible
    private Map<Id, List<Transfer_Part__c>> transferToPartsMap = new Map<Id, List<Transfer_Part__c>>();
    @TestVisible
    private List<Transfer_Part__c> partsToInsert = new List<Transfer_Part__c>();
    @TestVisible
    private List<Transfer_Part__c> partsToDelete = new List<Transfer_Part__c>();
    @TestVisible
    private Map<Id,Decimal> partToPaymentMap = new Map<Id,Decimal>();
    private List<Journal_Entry__c> incompleteEntries;

    @TestVisible
    public class GLInvoiceItem {
        @TestVisible
        public List<UsageRecord> Bills;
        @TestVisible
        public Decimal Amount;
        @TestVisible
        public Decimal SumOfAmount;
        @TestVisible
        public Id JERecordId;
    }

    @TestVisible
    private class UsageRecord {
        private String CustomerNumber;
        private Integer BillMonth;
        private Integer BillYear;
        private String Project;
        private String Client;
        private Id InternalId;
        @TestVisible
        private String ExternalId;
        private Decimal Amount;
        private Datetime BillDatetime;
        @TestVisible
        private UASB__c UASB;
        @TestVisible
        private Bill_Adjustment__c Adjustment;

        private UsageRecord(Journal_Entry__c entry) {
            this.Client = entry.Client__c;
            this.Project = entry.Project__c;
            this.CustomerNumber = entry.Customer_Account__c;
            this.BillMonth = entry.Date__c.month();
            this.BillYear = entry.Date__c.year();
            this.InternalId = entry.Id;
            this.ExternalId = entry.External_Id__c;
            this.Amount = entry.Amount__c;
        }

        private String generateKey() {
            if (this.BillMonth == null
                && this.BillYear == null
                && this.BillDatetime.date() != null){
                Date billDate = this.BillDatetime.date();
                this.BillMonth = billDate.month();
                this.BillYear = billDate.year();
            }
            String key = this.CustomerNumber
                + this.Project
                + this.Client
                + String.valueOf(this.BillMonth)
                + String.valueOf(this.BillYear);
            return key;
        }
    }

    /*
        This class creates Production Detail records for
        Bill (ie, InvoiceItem) and Collection (ie, Payments & Credit Memos) GL records:

        1.) All GL records are marked as "Ready_for_Production_Detail__c" when they are inserted
        2.) This class is kicked off by scheduled job to get invoice GL records marked as "Ready_for_Production_Detail__c"
        3.) Queues a Data Query for usage related to those invoices and unchecks "Ready_for_Production_Detail__c"
        4.) After Data Query finishes, creates bill production detail records
        5.) After bill Production detail records are inserted, queues payment production detail job
        6.) Production detail payment records are inserted and "Ready_for_Production_Detail__c" is unchecked

    */

    public void execute(QueueableContext context) {
        genericExecute();
    }

    public void genericExecute(){
        calloutCount = 0;
        partsToInsert = new List<Transfer_Part__c>();
        partsToDelete = new List<Transfer_Part__c>();
        transferIds = new Set<Id>();
        transferToPartsMap = new Map<Id, List<Transfer_Part__c>>();
        if (batchSize == null){
            batchSize = 1000;
        }
        if (incompleteEntries == null){
            incompleteEntries = new List<Journal_Entry__c>();
        }
        if (opType == OperationType.BILL){
            executeBillJob();
        } else if (opType == OperationType.PAYMENT){
            executePaymentJob();
        } else if (opType == OperationType.CREDITMEMO){
            executeCreditMemoJob();
        } else if (opType == OperationType.UNSERVICED){
            executeUnservicedJob();
        }

    }

    private void executeBillJob(){
        List<Journal_Entry__c> invoiceItems;
        try {
            invoiceItems = selectors.journalEntry.getEntriesWithoutProductionDetail(
                new List<String>{'InvoiceItem'}, batchSize
            );
            if (invoiceItems.size() > 0){
                createProductionDetailFromInvoiceItems(invoiceItems);
                markJournalEntriesAsComplete(invoiceItems);
            } else {
                queueJob(OperationType.PAYMENT);
            }
        } catch (Exception excep) {
            String message = excep.getMessage() + '_' + excep.getStackTraceString() + '_' + JSON.serialize(invoiceItems);
            Logger.logNow('ProductionToBillService', 'executeBillJob', message);
        }
    }

    private void executePaymentJob(){
        List<Journal_Entry__c> collectionItems;
        try {
            collectionItems = selectors.journalEntry.getEntriesWithoutProductionDetail(
                new List<String>{'PaymentPart'}, batchSize
            );
            if (collectionItems.size() > 0){
                createProductionDetailFromCollectionItem(collectionItems);
                insert partsToInsert;
                markJournalEntriesAsComplete(collectionItems);
            }
            if (collectionItems.size() == batchSize){
                queueJob(OperationType.PAYMENT);
            } else {
                queueJob(OperationType.CREDITMEMO);
            }
        } catch (Exception excep) {
            String message = excep.getMessage() + '_' + excep.getStackTraceString() + '_' + JSON.serialize(collectionItems);
            Logger.logNow('ProductionToBillService', 'executePaymentJob', message);
        }
    }

    private void executeCreditMemoJob(){
        List<Journal_Entry__c> creditMemosToAttempt;
        List<Journal_Entry__c> creditMemosExecuted;

        try {
            /*
                We will use at least 2 callouts per credit memo, but since we don't know how many part items there
                will be for any given CM, we can't know exactly how many callouts createProductionDetailFromCreditMemo
                will use. If we come close to the callout limit, we will stop processing credit memos and requeue
            */
            batchSize = Math.min(batchSize, 50);
            creditMemosToAttempt = selectors.journalEntry.getEntriesWithoutProductionDetail(
                new List<String>{'CreditMemo'}, batchSize
            );

            if (creditMemosToAttempt.size() > 0){
                creditMemosExecuted = createProductionDetailFromCreditMemo(creditMemosToAttempt);
                delete partsToDelete;
                insert partsToInsert;
                markJournalEntriesAsComplete(creditMemosExecuted);
            }
            if (creditMemosToAttempt.size() == batchSize || creditMemosExecuted.size() != creditMemosToAttempt.size()){
                queueJob(OperationType.CREDITMEMO);
            } else {
                updateJournalEntriesReadyStatus(incompleteEntries, true);
                queueJob(OperationType.UNSERVICED);
            }
        } catch (Exception excep) {
            String message = excep.getMessage() + '_' + excep.getStackTraceString() + '_' + JSON.serialize(creditMemosToAttempt);
            Logger.logNow('ProductionToBillService', 'executeCreditMemoJob', message);
        }
    }

    private void executeUnservicedJob(){
        List<UASB__c> externallyServicedUASBs = new List<UASB__c>();
        try {
            externallyServicedUASBs = selectors.uasb.getUnservicedWithoutProductionDetail(batchSize);
            if (externallyServicedUASBs.size() > 0){
                createProductionDetailFromUnservicedUASB(externallyServicedUASBs);
                insert partsToInsert;
                markUASBsAsComplete(externallyServicedUASBs);
            }
            if (externallyServicedUASBs.size() == batchSize){
                queueJob(OperationType.UNSERVICED);
            }
        } catch (Exception excep){
            String message = excep.getMessage() + '_' + excep.getStackTraceString() + '_' + JSON.serialize(externallyServicedUASBs);
            Logger.logNow('ProductionToBillService', 'executeUnservicedJob', message);
        }
    }

    @TestVisible
    private void queueJob(OperationType operation){
        ProductionToBillService billJob = new ProductionToBillService();
        billJob.opType = operation;
        billJob.incompleteEntries = incompleteEntries;
        System.enqueueJob(billJob);
    }

    public void createProductionDetailFromInvoiceItems(List<Journal_Entry__c> invoiceItems) {
        Set<String> invoiceItemIds = new Set<String>();
        Set<String> accountNumbers = new Set<String>();
        Date minDate;
        Date maxDate;

        for (Journal_Entry__c entry : invoiceItems){
            minDate = DateUtil.min(minDate, entry.Date__c);
            maxDate = DateUtil.max(maxDate, entry.Date__c);
            invoiceItemIds.add(entry.External_Id__c);
            accountNumbers.add(entry.Customer_Account__c);
        }

        ZuoraDataQueryService.ProcessingParameter param = new ZuoraDataQueryService.ProcessingParameter();
        param.className = 'ProductionToBillService';
        param.optionalStrings = invoiceItemIds;
        Map<String,Boolean> booleanMap = new Map<String,Boolean>();
        booleanMap.put('MoreBillsToProcess',invoiceItems.size() == batchSize);
        param.optionalBooleans = booleanMap;

        String queryString = selectors.usage.getUsageQueryStringFilterByAccountAndDate(accountNumbers,minDate,maxDate);
        ZuoraDataQueryService.callFromApex(queryString,param);
    }

    public void executePostQueryJob(ZuoraDataQueryService.ProcessingParameter method, String response) {
        try {
            fromInvoicesGetUsage(method.optionalStrings, response);
            fromUsageGetUASBsAndProductionAdjustments();
            distributeInvoiceItemAmongTransferParts();
            insert partsToInsert;

            if (method.optionalBooleans.get('MoreBillsToProcess')){
                queueJob(OperationType.BILL);
            } else {
                queueJob(OperationType.PAYMENT);
            }
        } catch (Exception excep) {
            String message = JSON.serialize(method)+ '_'+ excep.getMessage() + '_' + excep.getStackTraceString();
            Logger.logNow('ProductionToBillService', 'executePostQueryJob', message);
        }
    }

    @TestVisible
    private void fromInvoicesGetUsage(Set<String> invoiceItemIds, String response) {
        List<UsageRecord> allUsage = (List<UsageRecord>)JSON.deserialize(response, List<UsageRecord>.class);
        List<Journal_Entry__c> invoiceItems = selectors.journalEntry.getSFJournalEntriesFromExternalId(invoiceItemIds);
        invoiceIdToUsageMap = groupUsageByInvoice(allUsage,invoiceItems);
    }

    @TestVisible
    private void fromUsageGetUASBsAndProductionAdjustments() {
        Map<Id, UASB__c> uasbMap = selectors.uasb.getUASBsFromIds(uasbIds);
        Map<Id, Bill_Adjustment__c> adjustMap = selectors.adjustment.getAdjustmentsFromIds(adjustmentIds);

        for (String invoiceItemId : invoiceIdtoUsageMap.keySet()){
            List<UsageRecord> bills = invoiceIdToUsageMap.get(invoiceItemId).Bills;
            for (UsageRecord bill : bills){
                if (uasbMap.containsKey(bill.InternalId)){
                    bill.UASB = uasbMap.get(bill.InternalId);
                    transferIds.add(bill.UASB.Transfer__c);
                } else if (adjustMap.containsKey(bill.InternalId)){
                    bill.Adjustment = adjustMap.get(bill.InternalId);
                    transferIds.add(bill.Adjustment.Transfer__c);
                } else {
                    Logger.logNow(
                        'ProductionToBillService',
                        'fromUsageGetUASBsAndProductionAdjustments',
                        'Could not find UASB or Adjustment for: ' + JSON.serialize(bill)
                    );
                }
            }
        }
    }

    @TestVisible
    private void distributeInvoiceItemAmongTransferParts() {
        transferToPartsMap = selectors.transferParts.getTransferPartMap(transferIds);
        for (String invoiceItemId : invoiceIdtoUsageMap.keySet()){
            GLInvoiceItem invItem = invoiceIdToUsageMap.get(invoiceItemId);
            for (UsageRecord bill : invItem.Bills){
                distributeAmongTransferParts(bill, invItem.JERecordId);
            }
        }
    }

    private void distributeAmongTransferParts(UsageRecord bill, Id journalRecordId){
        if (bill.Amount == 0){
            return;
        } else if (bill.UASB != null){
            createBillProductionDetail(bill.UASB.Transfer__c, bill.Amount, 'Bill', journalRecordId);
            createBillProductionDetail(bill.UASB.Transfer__c, bill.UASB.Savings__c, 'Customer Savings', journalRecordId);
        } else if (bill.Adjustment != null){
            createBillProductionDetail(bill.Adjustment.Transfer__c, bill.Amount, 'Bill', journalRecordId);
            createBillProductionDetail(bill.Adjustment.Transfer__c, bill.Adjustment.Discount__c, 'Customer Savings', journalRecordId);
        }
    }

    private void createBillProductionDetail(Id transferId, Decimal billAmount, String type, Id relatedRecordId){
        billAmount = Util.roundValue(billAmount,2, 'HALF_UP');
        Decimal staticBillAmount = billAmount;
        Decimal decliningBillAmount = billAmount;
        Integer loopCount = 0;

        List<Transfer_Part__c> transferParts = transferToPartsMap.get(transferId);

        for (Transfer_Part__c transferPart : transferParts){
            loopCount += 1;
            Transfer_Part__c part = new Transfer_Part__c(
                Name = type,
                Production__c = transferPart.Production__c,
                Transfer__c = transferId,
                Type__c = type
            );
            part = setRelatedRecordId(part, type, relatedRecordId);
            Decimal applicationAmount = getWeightedApplicationAmount(transferPart, staticBillAmount);

            if (applicationAmount <= decliningBillAmount){
                part.Amount__c = applicationAmount;
                decliningBillAmount -= applicationAmount;
            } else {
                part.Amount__c = decliningBillAmount;
                decliningBillAmount = 0;
            }
            // In cases of rounding cutoff, put remainder (~0.01 or so on last transfer part):
            if (decliningBillAmount > 0 && loopCount == transferParts.size()){
                part.Amount__c = part.Amount__c + decliningBillAmount;
            }
            partsToInsert.add(part);
        }
    }

    private Transfer_Part__c setRelatedRecordId(Transfer_Part__c part, String type, Id relatedRecordId){
        if (type == 'Externally Serviced'){
            part.Externally_Serviced_UASB__c = relatedRecordId;
        } else {
            part.Journal_Entry__c = relatedRecordId;
        }
        return part;
    }

    private Decimal getWeightedApplicationAmount(Transfer_Part__c transferPart, Decimal staticBillAmount){
        Decimal applicationAmount = 0;
        if (transferPart.Transfer__r.Billing_Method__c == 'kWh'){
            applicationAmount = staticBillAmount * (transferPart.kWh_Amount__c / transferPart.Transfer__r.Transfer_kWh__c);
        } else {
            applicationAmount = staticBillAmount * (transferPart.Amount__c / transferPart.Transfer__r.Transfer_Amount__c);
        }
        applicationAmount = Util.roundValue(applicationAmount,2, 'HALF_UP');
        return applicationAmount;
    }

    @TestVisible
    private Map<String, GLInvoiceItem> groupUsageByInvoice(List<UsageRecord> allUsage, List<Journal_Entry__c> invoiceItems) {
        Map<String, GLInvoiceItem> invoiceToUsageMap = new Map<String, GLInvoiceItem>();
        Map<String,UsageRecord> keyToJournalEntryMap = new Map<String,UsageRecord>();

        for (Journal_Entry__c invoiceItem : invoiceItems){
            UsageRecord invoiceKey = new UsageRecord(invoiceItem);
            keyToJournalEntryMap.put(invoiceKey.generateKey(), invoiceKey);
        }
        for (UsageRecord usageKey : allUsage){
            String matchKey = usageKey.generateKey();
            if (keyToJournalEntryMap.containsKey(matchKey)){
                UsageRecord record = keyToJournalEntryMap.get(matchKey);
                invoiceToUsageMap = addToUsageMap(invoiceToUsageMap, record, usageKey);
                addToUASBOrAdjustList(usageKey.InternalId);
            }
        }
        return invoiceToUsageMap;
    }

    private Map<String, GLInvoiceItem> addToUsageMap(Map<String, GLInvoiceItem> usageMap, UsageRecord invoiceKey, UsageRecord usageKey) {
        String externalId = invoiceKey.ExternalId;
        GLInvoiceItem invoiceItem;

        if (usageMap.containsKey(externalId)){
            invoiceItem = usageMap.get(externalId);
            invoiceItem.Bills.add(usageKey);
            invoiceItem.SumOfAmount += usageKey.Amount;
        } else {
            invoiceItem = new GLInvoiceItem();
            invoiceItem.Bills = new List<UsageRecord>{usageKey};
            invoiceItem.Amount = invoiceKey.Amount;
            invoiceItem.SumOfAmount = usageKey.Amount;
            invoiceItem.JERecordId = invoiceKey.InternalId;
        }
        if (invoiceItem.SumOfAmount > invoiceItem.Amount){
            Logger.logNow('ProductionToBillService','addToUsageMap','Sum of Parts is greater than Invoice Amount ' + JSON.serialize(invoiceItem));
        } else {
            usageMap.put(externalId,invoiceItem);
        }
        return usageMap;
    }

    private void addToUASBOrAdjustList(Id recordId) {
        if (recordId.getSObjectType() == UASB__c.sObjectType){
            uasbIds.add(recordId);
        } else if (recordId.getSObjectType() == Bill_Adjustment__c.sObjectType){
            adjustmentIds.add(recordId);
        }
    }

    @TestVisible
    private void createProductionDetailFromCollectionItem(List<Journal_Entry__c> paymentEntries) {
        Set<String> invoiceIds = new Set<String>();
        for (Journal_Entry__c entry : paymentEntries){
            invoiceIds.add(entry.Applied_Record_Id__c);
        }

        Map<String, List<Transfer_Part__c>> billPartsMap = selectors.transferParts.getInvoicePartMap(invoiceIds);
        partToPaymentMap =  selectors.transferParts.getPaymentSum(invoiceIds);

        for (Journal_Entry__c paymentEntry : paymentEntries){
            List<Transfer_Part__c> invoiceParts = billPartsMap.get(paymentEntry.Applied_Record_Id__c);
            if (invoiceParts != null){
                distributePaymentAmongInvoices(paymentEntry,invoiceParts);
            }
        }
    }

    private void distributePaymentAmongInvoices(Journal_Entry__c paymentEntry, List<Transfer_Part__c> invoiceParts){
        Decimal paymentAmount = paymentEntry.Amount__c;

        for (Transfer_Part__c invoicePart : invoiceParts){
            if (paymentAmount <= 0){
                continue;
            }
            Decimal invoicePartPayments = Util.nullToZero(partToPaymentMap.get(invoicePart.Id));
            Decimal invoicePartBalance = invoicePart.Amount__c - invoicePartPayments;
            if (invoicePartBalance <= 0){
                continue;
            }
            Decimal applicationAmount = Math.min(invoicePartBalance, paymentAmount);
            partsToInsert.add(createCollectionProductionDetail(paymentEntry,invoicePart,applicationAmount));
            paymentAmount -= applicationAmount;
            invoicePartPayments += applicationAmount;
            partToPaymentMap.put(invoicePart.Id, invoicePartPayments);
        }
    }

    private Transfer_Part__c createCollectionProductionDetail(Journal_Entry__c paymentEntry, Transfer_Part__c invoicePart, Decimal applicationAmount){
        Transfer_Part__c payPart = new Transfer_Part__c(
            Name = 'Collection Item',
            Production__c = invoicePart.Production__c,
            Transfer__c = invoicePart.Transfer__c,
            Bill_Part__c = invoicePart.Id,
            Journal_Entry__c = paymentEntry.Id,
            Type__c = 'Payment',
            Amount__c = applicationAmount
        );
        return payPart;
    }

    @TestVisible
    private List<Journal_Entry__c> createProductionDetailFromCreditMemo(List<Journal_Entry__c> creditMemoEntries) {
        List<Journal_Entry__c> billItems = new List<Journal_Entry__c>();
        List<Journal_Entry__c> collectionItems = new List<Journal_Entry__c>();
        List<Journal_Entry__c> allItems = new List<Journal_Entry__c>();

        for (Journal_Entry__c creditMemo : creditMemoEntries) {
            // If a Credit Memo Journal Entry is marked as "Ready_for_Production_Detail__c" but already
            // has transfer parts, that means it could have been reallocated and we need to re-distribute:
            if (creditMemo.Transfer_Parts__r.size() > 0){
                partsToDelete.addAll(creditMemo.Transfer_Parts__r);
            }
            if (creditMemo.Reason_Code__c == 'Production'){
                billItems.add(creditMemo);
            } else if (calloutCount < 90) {
                // There is only 1 Journal Entry per credit memo, so we need to get the parts (ie, records it is
                // applied to) before reusing the same method that is used for Payment Journal Entries
                collectionItems.addAll(splitCreditMemoIntoParts(creditMemo));
            }
        }
        createBillItemForCreditMemo(billItems);
        createProductionDetailFromCollectionItem(collectionItems);
        allItems.addAll(billItems);
        allItems.addAll(collectionItems);
        return allItems;
    }

    private void createBillItemForCreditMemo(List<Journal_Entry__c> billItems){
        Set<String> adjustmentExternalIds = new Set<String>();
        Set<Id> transferRecordIds = new Set<Id>();

        for (Journal_Entry__c entry : billItems){
            adjustmentExternalIds.add(entry.External_Id__c);
        }

        Map<String, Bill_Adjustment__c> zuoraIdToAdjustMap = new Map<String, Bill_Adjustment__c>();
        List<Bill_Adjustment__c> adjustmentList = selectors.adjustment.getAdjustmentsFromExternalIds(adjustmentExternalIds);

        for (Bill_Adjustment__c adjust : adjustmentList){
            zuoraIdToAdjustMap.put(adjust.Zuora_Id__c, adjust);
            transferRecordIds.add(adjust.Transfer__c);
        }

        transferToPartsMap =  selectors.transferParts.getTransferPartMap(transferRecordIds);

        for (Journal_Entry__c entry : billItems){
            Bill_Adjustment__c sfAdjustment = zuoraIdToAdjustMap.get(entry.External_Id__c);
            createBillProductionDetail(sfAdjustment.Transfer__c, -1 * entry.Amount__c, 'Bill', entry.Id);
            createBillProductionDetail(sfAdjustment.Transfer__c, sfAdjustment.Discount__c, 'Customer Savings', entry.Id);
        }
    }

    private List<Journal_Entry__c> splitCreditMemoIntoParts(Journal_Entry__c creditMemo){
        HttpResponse response;
        ZuoraAPI.CreditMemoWithParts memoParts;
        ZuoraAPI.CreditMemoWithItems memoPartItems;
        List<Journal_Entry__c> journalEntriesByPart = new List<Journal_Entry__c>();

        response = ZuoraAPIHelper.callJsonEndpoint('GET', '/v1/creditmemos/'+ creditMemo.External_Id__c +'/parts', null, false);
        memoParts = (ZuoraAPI.CreditMemoWithParts) JSON.deserialize(response.getBody(), ZuoraAPI.CreditMemoWithParts.class);
        calloutCount += 1;

        for (ZuoraAPI.CreditMemoPart memoPart : memoParts.parts){
            if (memoPart.DebitMemoId != null){
                continue;
            }
            if (memoPart.InvoiceId != null){
                String urlString = '/v1/creditmemos/'+ creditMemo.External_Id__c +'/parts/';
                urlString += memoPart.Id + '/itemparts';
                response = ZuoraAPIHelper.callJsonEndpoint('GET', urlString, null, false);
                memoPartItems = (ZuoraAPI.CreditMemoWithItems) JSON.deserialize(response.getBody(), ZuoraAPI.CreditMemoWithItems.class);
                calloutCount += 1;
            } else {
                // If credit memo part doesn't have InvoiceId or DebitMemoId, it has an unapplied amount that
                // will need to be allocated to production later. Keep the credit memo marked with
                // 'Ready For Production Detail' until everything has been allocated
                incompleteEntries.add(creditMemo);
            }
        }

        for (ZuoraAPI.CreditMemoPartItem partItems : memoPartItems.itemParts){
            Journal_Entry__c creditMemoPartEntry = new Journal_Entry__c(
                Id = creditMemo.Id,
                Applied_Record_Id__c = partItems.InvoiceItemId,
                Amount__c = partItems.Amount
            );
            journalEntriesByPart.add(creditMemoPartEntry);
        }
        return journalEntriesByPart;
    }

    private void markJournalEntriesAsComplete(List<Journal_Entry__c> entries){
        updateJournalEntriesReadyStatus(entries, false);
    }

    private void updateJournalEntriesReadyStatus(List<Journal_Entry__c> entries, Boolean readyForDetail){
        for (Journal_Entry__c entry : entries){
            if (entry.Object_Type__c == 'CreditMemo'){
                entry.Applied_Record_Id__c = null;
            }
            entry.Ready_for_Production_Detail__c = readyForDetail;
        }
        update entries;
    }

    private void markUASBsAsComplete(List<UASB__c> unservicedBills){
        for (UASB__c uasb : unservicedBills){
            uasb.Ready_for_Production_Detail__c = false;
        }
        update unservicedBills;
    }

    @TestVisible
    private void createProductionDetailFromUnservicedUASB(List<UASB__c> unservicedUASBs){
        for (UASB__c exBill : unservicedUASBs){
            transferIds.add(exBill.Transfer__c);
        }

        transferToPartsMap = selectors.transferParts.getTransferPartMap(transferIds);

        for (UASB__c externalBill : unservicedUASBs){
            createBillProductionDetail(externalBill.Transfer__c, externalBill.Credits_Allocated__c, 'Externally Serviced', externalBill.Id);
        }
    }

    public static void setUnservicedUASBReadyForProdDetail(List<UASB__c> uasbs){
        for (UASB__c uasb : uasbs) {
            if (uasb.Externally_Serviced__c){
                uasb.Ready_For_Production_Detail__c = true;
            }
        }
    }
}