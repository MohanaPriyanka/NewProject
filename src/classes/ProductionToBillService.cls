// Tested By: ProductionToBillServiceTest
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class ProductionToBillService implements ZuoraDataQueryService.Processor{
    public static ZuoraUsageSelector usageSelector = new ZuoraUsageSelector();
    public static JournalEntrySelector glSelector = new JournalEntrySelector();
    public static ProductionDetailSelector transferPartsSelector = new ProductionDetailSelector();
    public static UASBSelector uasbSelector = new UASBSelector();
    public static AdjustmentSelector adjustmentSelector = new AdjustmentSelector();

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

        private Boolean matches(UsageRecord keyToCheck) {
            Boolean isMatch = false;
            Date billDate = this.BillDatetime.date();
            if (keyToCheck.CustomerNumber == this.CustomerNumber
                && keyToCheck.BillMonth == billDate.month()
                && keyToCheck.BillYear == billDate.year()
                && keyToCheck.Project == this.Project
                && keyToCheck.Client == this.Client) {
                isMatch = true;
            }
            return isMatch;
        }
    }

    // Need to figure out if we want to fire this on a schedule or trigger, etc:
    public void queueCreateProductionDetailFromInvoiceItems() {
        List<Journal_Entry__c> invoiceItems = glSelector.getInvoiceItemWithoutProductionDetail();
        createProductionDetailFromInvoiceItems(invoiceItems);
    }

    public void createProductionDetailFromInvoiceItems(List<Journal_Entry__c> invoiceItems) {
        Set<String> invoiceItemIds = new Set<String>();
        List<String> accountNumbers = new List<String>();
        Date minDate;
        Date maxDate;

        for (Journal_Entry__c entry : invoiceItems){
            if (minDate == null || entry.Date__c < minDate){
                minDate = entry.Date__c;
            }
            if (maxDate == null || entry.Date__c > maxDate){
                maxDate = entry.Date__c;
            }
            invoiceItemIds.add(entry.External_Id__c);
            accountNumbers.add(entry.Customer_Account__c);
        }

        ZuoraDataQueryService.ProcessingParameter param = new ZuoraDataQueryService.ProcessingParameter();
        param.className = 'ProductionToBillService';
        param.methodName = 'postUsageQueryProcessing';
        param.optionalStrings = invoiceItemIds;

        String queryString = usageSelector.getUsageQueryStringFilterByAccountAndDate(accountNumbers,minDate,maxDate);
        ZuoraDataQueryService.callFromApex(queryString,param);
    }

    public void executePostQueryJob(ZuoraDataQueryService.ProcessingParameter method, String response) {
        fromInvoicesGetUsage(method.optionalStrings, response);
        fromUsageGetUASBsAndProductionAdjustments();
        distributeInvoiceItemAmongTransferParts();
        insert partsToInsert;
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
                    Logger.logLater(
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
            createProductionDetail(bill.UASB.Transfer__c, bill.Amount, 'Bill', journalRecordId);
            createProductionDetail(bill.UASB.Transfer__c, bill.UASB.Savings__c, 'Customer Savings', journalRecordId);
        } else if (bill.Adjustment != null){
            createProductionDetail(bill.Adjustment.Transfer__c, bill.Amount, 'Bill', journalRecordId);
            createProductionDetail(bill.Adjustment.Transfer__c, bill.Adjustment.Discount__c, 'Customer Savings', journalRecordId);
        }
    }

    private void createProductionDetail(Id transferId, Decimal billAmount, String type, Id journalRecordId){
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
            Decimal applicationAmount = staticBillAmount * (transferPart.Amount__c / transferPart.Transfer__r.Transfer_Amount__c);
            applicationAmount = Util.roundValue(applicationAmount,2, 'HALF_UP');
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

    @TestVisible
    private Map<String, GLInvoiceItem> groupUsageByInvoice(List<UsageRecord> allUsage, List<Journal_Entry__c> invoiceItems) {
        Map<String, GLInvoiceItem> invoiceToUsageMap = new Map<String, GLInvoiceItem>();
        for (UsageRecord usageKey : allUsage){
            for (Journal_Entry__c invoiceItem : invoiceItems){
                UsageRecord invoiceKey = new UsageRecord(invoiceItem);
                if (usageKey.matches(invoiceKey)){
                    invoiceToUsageMap = addToUsageMap(invoiceToUsageMap, invoiceKey, usageKey);
                    addToUASBOrAdjustList(usageKey.InternalId);
                    break;
                }
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
}