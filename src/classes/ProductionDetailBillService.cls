// Tested By: ProductionToBillServiceTest
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class ProductionDetailBillService implements ZuoraDataQueryService.Processor{
    @TestVisible
    private static ZuoraUsageSelector usageSelector = new ZuoraUsageSelector();
    @TestVisible
    private static JournalEntrySelector journalEntrySelector = new JournalEntrySelector();
    @TestVisible
    private static ProductionDetailSelector productionDetailSelector = new ProductionDetailSelector();
    @TestVisible
    private static UASBSelector uasbSelector = new UASBSelector();
    @TestVisible
    private static AdjustmentSelector adjustmentSelector = new AdjustmentSelector();

    private Set<Id> transferIds = new Set<Id>();
    private Set<Id> uasbIds = new Set<Id>();
    private Set<Id> adjustmentIds = new Set<Id>();

    @TestVisible
    private Map<String, GLInvoiceItem> invoiceIdToUsageMap = new Map<String, GLInvoiceItem>();
    public Map<Id, List<Transfer_Part__c>> transferToDetailMap = new Map<Id, List<Transfer_Part__c>>();
    public List<Transfer_Part__c> productionDetailToInsert = new List<Transfer_Part__c>();

    public class GLInvoiceItem {
        public List<UsageRecord> Bills;
        public Decimal Amount;
        public Decimal SumOfAmount;
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

    public void createProductionDetailFromInvoiceItems(List<Journal_Entry__c> invoiceItems, Integer batchSize) {
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

        String queryString = usageSelector.getUsageQueryStringFilterByAccountAndDate(accountNumbers,minDate,maxDate);
        ZuoraDataQueryService.callFromApex(queryString,param);
    }

    public void executePostQueryJob(ZuoraDataQueryService.ProcessingParameter method, String response) {
        try {
            fromInvoicesGetUsage(method.optionalStrings, response);
            fromUsageGetUASBsAndProductionAdjustments();
            distributeInvoiceItemAmongTransferProductionDetail();
            insert productionDetailToInsert;

            if (method.optionalBooleans.get('MoreBillsToProcess')){
                queueJob(ProductionToBillService.OperationType.BILL);
            } else {
                queueJob(ProductionToBillService.OperationType.PAYMENT);
            }
        } catch (Exception excep) {
            String message = JSON.serialize(method)+ '_'+ excep.getMessage() + '_' + excep.getStackTraceString();
            Logger.logNow('ProductionToBillService', 'executePostQueryJob', message);
        }
    }

    public void queueJob(ProductionToBillService.OperationType operation){
        ProductionToBillService billJob = new ProductionToBillService();
        billJob.opType = operation;
        System.enqueueJob(billJob);
    }

    @TestVisible
    private void fromInvoicesGetUsage(Set<String> invoiceItemIds, String response) {
        List<UsageRecord> allUsage = (List<UsageRecord>)JSON.deserialize(response, List<UsageRecord>.class);
        List<Journal_Entry__c> invoiceItems = journalEntrySelector.getSFJournalEntriesFromExternalId(invoiceItemIds);
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
    private void distributeInvoiceItemAmongTransferProductionDetail() {
        transferToDetailMap = productionDetailSelector.getTransferPartMap(transferIds);
        for (String invoiceItemId : invoiceIdtoUsageMap.keySet()){
            GLInvoiceItem invItem = invoiceIdToUsageMap.get(invoiceItemId);
            for (UsageRecord bill : invItem.Bills){
                distributeAmongTransferProductionDetail(bill, invItem.JERecordId);
            }
        }
    }

    private void distributeAmongTransferProductionDetail(UsageRecord bill, Id journalRecordId){
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

    public void createBillProductionDetail(Id transferId, Decimal billAmount, String type, Id relatedRecordId){
        billAmount = Util.roundValue(billAmount,2, 'HALF_UP');
        Decimal staticBillAmount = billAmount;
        Decimal decliningBillAmount = billAmount;
        Integer loopCount = 0;

        List<Transfer_Part__c> transferProductionDetail = transferToDetailMap.get(transferId);

        for (Transfer_Part__c transferDetail : transferProductionDetail){
            loopCount += 1;
            Transfer_Part__c part = new Transfer_Part__c(
                Name = type,
                Production__c = transferDetail.Production__c,
                Transfer__c = transferId,
                Type__c = type
            );
            part = setRelatedRecordId(part, type, relatedRecordId);
            Decimal applicationAmount = getWeightedApplicationAmount(transferDetail, staticBillAmount);

            if (applicationAmount <= decliningBillAmount){
                part.Amount__c = applicationAmount;
                decliningBillAmount -= applicationAmount;
            } else {
                part.Amount__c = decliningBillAmount;
                decliningBillAmount = 0;
            }
            // In cases of rounding cutoff, put remainder (~0.01 or so on last transfer part):
            if (decliningBillAmount > 0 && loopCount == transferProductionDetail.size()){
                part.Amount__c = part.Amount__c + decliningBillAmount;
            }
            productionDetailToInsert.add(part);
        }
    }

    private Transfer_Part__c setRelatedRecordId(Transfer_Part__c transferProdDetail, String type, Id relatedRecordId){
        if (type == 'Externally Serviced'){
            transferProdDetail.Externally_Serviced_UASB__c = relatedRecordId;
        } else {
            transferProdDetail.Journal_Entry__c = relatedRecordId;
        }
        return transferProdDetail;
    }

    private Decimal getWeightedApplicationAmount(Transfer_Part__c transferProdDetail, Decimal staticBillAmount){
        Decimal applicationAmount = 0;
        if (transferProdDetail.Transfer__r.Billing_Method__c == 'kWh'){
            applicationAmount = staticBillAmount * (transferProdDetail.kWh_Amount__c / transferProdDetail.Transfer__r.Transfer_kWh__c);
        } else {
            applicationAmount = staticBillAmount * (transferProdDetail.Amount__c / transferProdDetail.Transfer__r.Transfer_Amount__c);
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

    public void createProductionDetailFromUnservicedUASB(List<UASB__c> unservicedUASBs){
        calculateProductionDetailFromUnservicedUASB(unservicedUASBs);
        insert productionDetailToInsert;
    }

    @TestVisible
    private void calculateProductionDetailFromUnservicedUASB(List<UASB__c> unservicedUASBs){
        for (UASB__c exBill : unservicedUASBs){
            transferIds.add(exBill.Transfer__c);
        }

        transferToDetailMap = productionDetailSelector.getTransferPartMap(transferIds);

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