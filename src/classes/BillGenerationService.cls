/** Description: Used to generate and validate UASBs
 *
 * Tested By: BillGenerationServiceTest, TransferSheetBillingTest
 */

@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class BillGenerationService {

    public enum BillType { ONTIME, OVERDUE, BOTH }
    @TestVisible private static DefaultUtilityFeeSelector feeSelector = new DefaultUtilityFeeSelector();
    @TestVisible private static ProductEscalatorSelector escalatorSelector = new ProductEscalatorSelector();
    @TestVisible private static ScheduleZSubscriptionSelector szsSelector = new ScheduleZSubscriptionSelector();
    @TestVisible private static UASBSelector uasbSelector = new UASBSelector();
    @TestVisible private static Quiddity testQuiddityOverride;
    @TestVisible private Map<Id,List<Product_Escalator__c>> productEscalatorMap;
    private BillType operationType;
    private Boolean isLightningContext;
    private Boolean isUCB;
    private Default_Utility_Fee__c utilityAdminFee;
    private List<Schedule_Z_Subscription__c> szsList;
    private Map<String,UASB__c> priorUASBMap;
    private Map<String,UASB__c> transferUASBs;
    private Transfer__c transfer;

    public BillGenerationService(Transfer__c tx, BillType opType) {
        this.transfer = tx;
        this.operationType = opType;
        this.productEscalatorMap = escalatorSelector.getProductEscalations();
        this.szsList = getScheduleZSubscriptionList();
        this.isUCB = tx.Shared_Solar_System__r.UCB__c;

        Quiddity context = testQuiddityOverride == null ? Request.getCurrent().getQuiddity() : testQuiddityOverride;
        this.isLightningContext = context == System.Quiddity.AURA;

        // If UCB, pass in generated transfer UASBs originating from utility transfer .csv
        // UASBs generated with Salesforce data need elements that only exist on the Utility's transfer .csv
        // Also get other stuff we need for UCB transfer QC / UASB creation
        if (this.isUCB) {
            this.transferUASBs = getUASBsFromUtilityTransferSheet();
            this.priorUASBMap = uasbSelector.getLatestUcbUasbBySzs(szsList);
            this.utilityAdminFee = feeSelector.getActiveUCBRecordForUtility(transfer.Shared_Solar_System__r.Utility__c);
        }
    }

    /**
     * @description Method to instance this class from static context and return SF-calc'ed UASBs from a transfer record.
     *              Called from Preview Bills Screen on Transfer
     * @param transfer Transfer in question
     * @param operationType Operation type (Enum)
     * @return List of SF-generated UASB__c records for the transfer
     */
    @AuraEnabled
    public static List<UASB__c> calculateUASBsFromTransfer(Transfer__c transfer, BillType operationType) {
        BillGenerationService service = new BillGenerationService(transfer, operationType);
        return service.calculateUASBsFromTransfer();
    }

    @TestVisible
    private List<UASB__c> calculateUASBsFromTransfer() {
        String errorMessage = checkRequiredTransferFields();
        if (isLightningContext && errorMessage != null) {
            throw Util.createAuraExceptionWithMessage(errorMessage);
        } else if (errorMessage != null) {
            throw new Util.BWException(errorMessage);
        }

        List<UASB__c> uasbs = calculateUASBesFromSZSes(null);
        return uasbs;
    }

    @TestVisible
    private List<UASB__c> calculateUASBesFromSZSes(List<Schedule_Z_Subscription__c> szsListOverride) {
        List<UASB__c> uasbsToInsert = new List<UASB__c>();
        szsList = szsListOverride != null ? szsListOverride : szsList; // list override only exists for legacy system test
        for (Schedule_Z_Subscription__c szs : szsList) {
            uasbsToInsert.add(getUASB(szs));
        }
        return uasbsToInsert;
    }

    private UASB__c getUASB(Schedule_Z_Subscription__c szs) {
        UASB__c uasb = new UASB__c();
        Boolean normalBill = szs.Schedule_Z__c == transfer.Allocation_Schedule__c && !szs.Stop_Credit_Transfer__c;
        if (normalBill && !isUCB) {
            uasb = new UASB(szs, transfer, productEscalatorMap).getSObject();
        } else if (normalBill && isUCB) {
            String utilityNumber = szs.Utility_Account_Subscription__r.Utility_Account_Log__r.Name;
            UASB__c ucbParsedTransferUASB = transferUASBs?.get(utilityNumber);
            UASB__c priorUASB = priorUASBMap?.get(szs.Id);
            uasb = new UcbUASB(szs, transfer, productEscalatorMap, priorUASB, ucbParsedTransferUASB, utilityAdminFee).getSObject();
        } else {
            // Likely a zero-dollar bill. This bill type concept is subject to deprecation in the future
            uasb = new ZeroDollarUASB(szs, transfer).getSObject();
        }
        return uasb;
    }

    private Map<String,UASB__c> getUASBsFromUtilityTransferSheet() {
        Map<String,UASB__c> transferUASBs = new Map<String,UASB__c>();
        try {
            TransferSheetService.initializeClass(transfer);
            Map<Integer,List<String>> csvData = TransferSheetService.getDataFromMostRecentDocumentUpload(transfer);
            transferUASBs = TransferSheetService.convertTransferCsvToUASBs(csvData);
        } catch (Exception e) {
            String error = 'Unable to retrieve utility data from transfer sheet .csv. Error: \n'+ e.getMessage();
            if (isLightningContext != null) {
                throw Util.createAuraExceptionWithMessage(error);
            } else {
                throw new Util.BWException(error);
            }
        }
        return transferUASBs;
    }

    @TestVisible
    private List<Schedule_Z_Subscription__c> getScheduleZSubscriptionList() {
        List<Schedule_Z_Subscription__c> onTimeSZSes;
        List<Schedule_Z_Subscription__c> overdueSZSes;

        onTimeSZSes = szsSelector.getOnTimeListForBillingOffTransfer(new Set<Id>{transfer.Allocation_Schedule__c});
        overdueSZSes = getOverdueSZSList(onTimeSZSes);

        switch on operationType {
            when ONTIME {
                return onTimeSZSes;
            }
            when OVERDUE {
                return overdueSZSes;
            }
            when else {
                onTimeSZSes.addAll(overdueSZSes);
                return onTimeSZSes;
            }
        }
    }

    private List<Schedule_Z_Subscription__c> getOverdueSZSList (List<Schedule_Z_Subscription__c> onTimeSZSes) {
        Set<Id> uasIdsAlreadyBilling = new Set<Id>();
        for (Schedule_Z_Subscription__c szs : onTimeSZSes) {
            uasIdsAlreadyBilling.add(szs.Utility_Account_Subscription__c);
        }
        return szsSelector.getOverdueSZSForBillingOffTransfer(
            new Set<Id>{transfer.Shared_Solar_System__c}, uasIdsAlreadyBilling
        );
    }

    private String checkRequiredTransferFields() {
        String errorMessage = 'Cannot make UASBs from a Transfer ';
        if (transfer.Allocation_Schedule__c == null) {
            errorMessage += 'because the Transfer does not have an Allocation Schedule populated';
        } else if (transfer.Attempted_kWh_Transfer__c == null || transfer.Attempted_Transfer__c == null) {
            errorMessage += 'without Attempted kWh Transfer & Attempted Transfer populated';
        } else if (transfer.Default_Credit_Value__c == null) {
            errorMessage += 'without Default Credit Value populated';
        } else if (transfer.Bill_Period__c == null || transfer.Bill_Period__r.Bill_Date__c == null || transfer.Date_of_Transfer__c == null) {
            errorMessage += 'without Date of Transfer & Bill Period Date populated';
        } else {
            errorMessage = null;
        }
        return errorMessage;
    }
}