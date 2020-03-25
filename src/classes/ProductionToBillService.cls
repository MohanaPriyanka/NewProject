// Tested By: ProductionToBillServiceTest
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class ProductionToBillService implements ZuoraDataQueryService.Processor, Queueable{
    @TestVisible
    private static ZuoraUsageSelector usageSelector = new ZuoraUsageSelector();
    @TestVisible
    private static JournalEntrySelector glSelector = new JournalEntrySelector();
    @TestVisible
    private static ProductionDetailSelector transferPartsSelector = new ProductionDetailSelector();
    @TestVisible
    private static UASBSelector uasbSelector = new UASBSelector();
    @TestVisible
    private static AdjustmentSelector adjustmentSelector = new AdjustmentSelector();

    public enum OperationType {BILL, COLLECTION}
    public OperationType opType;
    public Integer batchSize;

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
    private Map<Id,Decimal> partToPaymentMap = new Map<Id,Decimal>();

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
        3.) Queues a Data Query for usage related to those invoices
        4.) After Data Query finishes, creates bill production detail records
        5.) After bill Production detail records are inserted, queues payment production detail job
        6.) Unchecks "Ready_for_Production_Detail__c" on processed records
    */

    public void execute(QueueableContext context) {
        genericExecute();
    }

    public void genericExecute(){
        partsToInsert = new List<Transfer_Part__c>();
        if (batchSize == null){
            batchSize = 1000;
        }
        if (opType == OperationType.BILL){
            executeBillJob();
        } else if (opType == OperationType.COLLECTION){
            executeCollectionsJob();
        }
    }

    private void executeBillJob(){
        List<Journal_Entry__c> invoiceItems;
        try {
            invoiceItems = glSelector.getEntriesWithoutProductionDetail(
                new List<String>{'InvoiceItem'}, batchSize
            );
            if (invoiceItems.size() > 0){
                createProductionDetailFromInvoiceItems(invoiceItems);
                markJournalEntriesAsComplete(invoiceItems);
            } else {
                queueJob(OperationType.COLLECTION);
            }
        } catch (Exception excep) {
            String message = excep.getMessage() + '_' + excep.getStackTraceString() + '_' + JSON.serialize(invoiceItems);
            Logger.logNow('ProductionToBillService', 'executeBillJob', message);
        }
    }

    private void executeCollectionsJob(){
        List<Journal_Entry__c> collectionItems;
        try {
            collectionItems = glSelector.getEntriesWithoutProductionDetail(
                new List<String>{'PaymentPart', 'CreditMemo'}, batchSize
            );
            if (collectionItems.size() > 0){
                createProductionDetailFromCollectionItem(collectionItems);
                insert partsToInsert;
                markJournalEntriesAsComplete(collectionItems);
            }
            if (collectionItems.size() == batchSize){
                queueJob(OperationType.COLLECTION);
            }
        } catch (Exception excep) {
            String message = excep.getMessage() + '_' + excep.getStackTraceString() + '_' + JSON.serialize(collectionItems);
            Logger.logNow('ProductionToBillService', 'executeCollectionsJob', message);
        }
    }

    @TestVisible
    private void queueJob(OperationType operation){
        ProductionToBillService billJob = new ProductionToBillService();
        billJob.opType = operation;
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
        param.methodName = 'postUsageQueryProcessing';
        param.optionalStrings = invoiceItemIds;
        param.optionalBoolean = invoiceItems.size() == batchSize;

        String queryString = usageSelector.getUsageQueryStringFilterByAccountAndDate(accountNumbers,minDate,maxDate);
        ZuoraDataQueryService.callFromApex(queryString,param);
    }

    public void executePostQueryJob(ZuoraDataQueryService.ProcessingParameter method, String response) {
        try {
            fromInvoicesGetUsage(method.optionalStrings, response);
            fromUsageGetUASBsAndProductionAdjustments();
            distributeInvoiceItemAmongTransferParts();
            insert partsToInsert;

            // If there are more bills to process, re-queue bill job, otherwise move on to payments:
            if (method.optionalBoolean){
                queueJob(OperationType.BILL);
            } else {
                queueJob(OperationType.COLLECTION);
            }
        } catch (Exception excep) {
            String message = JSON.serialize(method)+ '_'+ excep.getMessage() + '_' + excep.getStackTraceString();
            Logger.logNow('ProductionToBillService', 'executePostQueryJob', message);
        }
    }

    @TestVisible
    private void fromInvoicesGetUsage(Set<String> invoiceItemIds, String response) {
        List<UsageRecord> allUsage = (List<UsageRecord>)JSON.deserialize(response, List<UsageRecord>.class);
        List<Journal_Entry__c> invoiceItems = glSelector.getSFJournalEntriesFromExternalId(invoiceItemIds);
        invoiceIdToUsageMap = groupUsageByInvoice(allUsage,invoiceItems);
    }

    @TestVisible
    private void fromUsageGetUASBsAndProductionAdjustments() {
        Map<Id, UASB__c> uasbMap = uasbSelector.getUASBsFromIds(uasbIds);
        Map<Id, Bill_Adjustment__c> adjustMap = adjustmentSelector.getAdjustmentsFromIds(adjustmentIds);

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
        transferToPartsMap = transferPartsSelector.getTransferPartMap(transferIds);
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

    private void createBillProductionDetail(Id transferId, Decimal billAmount, String type, Id journalRecordId){
        billAmount = Util.roundValue(billAmount,2, 'HALF_UP');
        Decimal staticBillAmount = billAmount;
        Decimal decliningBillAmount = billAmount;
        Integer loopCount = 0;

        List<Transfer_Part__c> transferParts = transferToPartsMap.get(transferId);

        for (Transfer_Part__c transferPart : transferParts){
            loopCount += 1;
            Transfer_Part__c part = new Transfer_Part__c(
                Name = type + '_' + transferPart.Production__r.Name,
                Production__c = transferPart.Production__c,
                Transfer__c = transferId,
                Journal_Entry__c = journalRecordId,
                Type__c = type
            );

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

    // Payment or Credit Memo:
    public void createProductionDetailFromCollectionItem(List<Journal_Entry__c> paymentEntries) {
        Set<String> invoiceIds = new Set<String>();
        for (Journal_Entry__c entry : paymentEntries){
            invoiceIds.add(entry.Applied_Record_Id__c);
        }

        Map<String, List<Transfer_Part__c>> billPartsMap = transferPartsSelector.getInvoicePartMap(invoiceIds);
        partToPaymentMap = transferPartsSelector.getPaymentSum(invoiceIds);

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

    private void markJournalEntriesAsComplete(List<Journal_Entry__c> entries){
        for (Journal_Entry__c  entry : entries){
            entry.Ready_for_Production_Detail__c = false;
        }
        update entries;
    }
}