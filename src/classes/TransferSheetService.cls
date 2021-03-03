// Tested by TransferSheetBillingTest
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class TransferSheetService {

    // Field mappings for .csv import headers => SObject fields
    @TestVisible private static final Map<String,String> GENERIC_UASB_FIELDS = new Map<String,String>{
        'UtilityNumber' => 'PreGen_Utility_Acct__c', // Should always be in column 1
        'Credits' => 'Credits_Allocated__c', // Should always be in column 2
        'Production' => 'Subscription_Production_kWh_Static__c',
        'CreditValue' => 'NMC_Rate__c'
    };
    @TestVisible private static final Map<String,String> UCB_UASB_FIELDS = new Map<String,String>{
        'UtilityNumber' => 'PreGen_Utility_Acct__c', // Should always be in column 1
        'Credits' => 'Credits_Allocated__c', // Should always be in column 2
        'Production' => 'Subscription_Production_kWh_Static__c',
        'CreditValue' => 'NMC_Rate__c',
        'StartingBankedCredits' => 'Starting_Banked_Credits__c',
        'NewAvailableCredits' => 'New_available_credits__c',
        'TotalAvailableCredits' => 'Total_Available_Credits__c',
        'SatelliteCharges' => 'Satellite_Charges__c',
        'CalculatedCredits' => 'Calculated_Credits__c',
        'NetMemberCredits' => 'Net_Member_Credits__c',
        'EndingBankedCredits' => 'Ending_Banked_Credits__c',
        'CDGSubscriptionFee' => 'CDG_Subscription_Fee__c',
        'UtilityAdminFee' => 'Utility_Admin_Fee__c',
        'CDGSponsorPayment' => 'CDG_Sponsor_Payment__c'
    };
    @TestVisible private static AccountsSelector accountsSelector = new AccountsSelector();
    @TestVisible private static ContentDocumentSelector docSelector = new ContentDocumentSelector();
    @TestVisible private static TransferSelector transferSelector = new TransferSelector();
    private static Boolean isUCB;
    private static Integer expectedColumnCount;
    private static List<String> uasbFields;

    /**
     * @description Object intended for JSON-encoding for transferSheetReconciliation.lwc (Transfer QC)
     */
    public class UASBWithStatus {
        @AuraEnabled public UASB__c sfUASB;
        @AuraEnabled public UASB__c utilUASB;
        @AuraEnabled public String status; // MATCH, CREDIT_MISMATCH, MISSING_BILL, MISSING_TRANSFER
        @AuraEnabled public String matchMessage;
        @AuraEnabled public String resolution; // UseUtility, UseSalesforce
        @AuraEnabled public Boolean overdue;
    }

    public class TransferResolutionData {
        public String uniqueid;
        public String resolution;
    }

    /**
     * @description Retrieves UASBWithStatus object list (used by LWC) for Transfer QC
     * @param transferRecordId Record ID of Transfer__c record in question
     * @return List of UASBWithStatus apex objects to pass to LWC
     */
    @AuraEnabled
    public static List<UASBWithStatus> getTransferFromId(Id transferRecordId) {
        Transfer__c transfer = transferSelector.getTransferById(transferRecordId);
        initializeClass(transfer);

        if (transfer.Bills_Generated__c) {
            throw Util.createAuraExceptionWithMessage('Bills Already Generated for this Transfer');
        }
        preventBillingTransferOutOfOrder(transfer);
        return getUASBListFromTransferSheet(transfer);
    }

    /**
     * @description LWC server-side method to handle resolution on Transfer Sheet QC and insert UASB__c's into DB
     * @param pregenBills JSON string of previously-generated List<UASBWithStatus> records
     * @param overrideValues JSON array of resolution data from Transfer QC
     */
    @AuraEnabled
    public static void handleTransferSheetResolutions(String pregenBills, List<String> overrideValues) {
        try {
            // Deserialize content from LWC, load needed vars
            List<UASBWithStatus> uasbWithStatusList = (List<UASBWithStatus>) System.JSON.deserialize(pregenBills, List<UASBWithStatus>.class);
            Transfer__c transfer = transferSelector.getTransferById(uasbWithStatusList[0].sfUASB.Transfer__c);
            initializeClass(transfer);

            // Read data from LWC
            Map<Id, String> resolutionMap = readDataFromLWC(overrideValues);

            // Resolve data conflicts and insert UASBs
            List<UASB__c> resolvedUasbs = resolveUASBs(uasbWithStatusList, resolutionMap);
            insert resolvedUasbs;

            // Perform final steps
            if (!isUCB) {
                insertZeroDollarBills(transfer);
            }
            postUASBInsertProcessing(transfer, overrideValues);
        } catch (Exception e) {
            throw Util.createAuraExceptionWithMessage(e.getMessage() + '\n' + e.getStackTraceString());
        }
    }

    /**
     * @description Static class initializer to set static class vars
     * @param transfer Transfer__c record to initialize class for
     */
    public static void initializeClass(Transfer__c transfer) {
        isUCB = transfer.Shared_Solar_System__r.UCB__c;
        expectedColumnCount = isUCB ? UCB_UASB_FIELDS.size() : GENERIC_UASB_FIELDS.size();
        uasbFields = isUCB ? UCB_UASB_FIELDS.values() : GENERIC_UASB_FIELDS.values();
    }

    /**
     * @description Converts raw csv data in Map format to Map of UAL# => UASB__c for specified transfer
     * @param rowNumberToDataMap Raw csv data provided by getDataFromMostRecentDocumentUpload()
     * @return Map of Utility Account Number => UASB__c for specified transfer
     */
    public static Map<String,UASB__c> convertTransferCsvToUASBs(Map<Integer,List<String>> rowNumberToDataMap) {
        Map<String,UASB__c> uasbsFromTransfer = new Map<String,UASB__c>();

        // Run validation check on the utility transfer sheet (.csv)
        validateCsv(rowNumberToDataMap);
        rowNumberToDataMap.remove(0); // Strip header column

        // For each row of data, process into a UASB record
        for (List<String> rowData : rowNumberToDataMap.values()) {
            addUASBFromTransfer(uasbsFromTransfer, rowData);
        }

        return uasbsFromTransfer;
    }

    /**
     * @description Gets csv data from latest utility transfer sheet csv (uploaded & attached to Transfer__c) in Map form
     * @param transfer Transfer__c record in question
     * @return csv data map
     */
    public static Map<Integer,List<String>> getDataFromMostRecentDocumentUpload(Transfer__c transfer) {
        ContentDocument document;
        try {
            document = docSelector.getMostRecentTransferSheet(transfer);
            return Util.readCSV(document.LatestPublishedVersion.VersionData.toString());
        } catch (Exception e) {
            // If no transfer sheet is uploaded, treat the same as if there is a transfer sheet with no rows:
            List<String> columnHeaders = getColumnHeaders();
            Map<Integer, List<String>> blankMap = new Map<Integer, List<String>>();
            blankMap.put(0, columnHeaders);
            return blankMap;
        }
    }

    @TestVisible
    private static void preventBillingTransferOutOfOrder(Transfer__c transfer) {
        List<Transfer__c> allTransfers = transferSelector.getUnbilledTransfersBySSS(new Set<Id>{
            transfer.Shared_Solar_System__c
        });
        for (Transfer__c otherTransfer : allTransfers) {
            if (otherTransfer.Date_of_Transfer__c < transfer.Date_of_Transfer__c) {
                throw Util.createAuraExceptionWithMessage('There is another transfer (' + otherTransfer.Id + ')' +
                    ' not yet billed that has a Date of Transfer (' + otherTransfer.Date_of_Transfer__c.format() + ')' +
                    ' older than this one that should be handled first');
            }
        }
    }

    @TestVisible
    private static List<UASBWithStatus> getUASBListFromTransferSheet(Transfer__c transfer) {
        try {
            Map<Integer,List<String>> csvData = getDataFromMostRecentDocumentUpload(transfer);
            Map<String,UASB__c> transferUASBs = convertTransferCsvToUASBs(csvData);
            List<UASB__c> pregeneratedSFBills = BillGenerationService.calculateUASBsFromTransfer(
                transfer, BillGenerationService.BillType.ONTIME
            );
            return compareSFBillsToTransferSheet(pregeneratedSFBills, transferUASBs);
        } catch (Exception excep) {
            throw Util.createAuraExceptionWithMessage(String.valueOf(
                excep.getMessage()) + String.valueOf(excep.getStackTraceString())
            );
        }
    }

    private static void validateCsv(Map<Integer,List<String>> rowNumberToDataMap) {
        List<String> columnTitles = rowNumberToDataMap.get(0);
        List<String> columnHeaders = getColumnHeaders();
        
        String message = '';
        if (columnTitles.size() < expectedColumnCount) {
            message += 'Expected ' + expectedColumnCount + ' Columns in CSV data. Found ' + columnTitles.size();
        } else {
            for (Integer i = 0; i < expectedColumnCount; i++) {
                if (!columnTitles[i].contains(columnHeaders[i])) {
                    message += 'Expected column '+String.valueOf(i+1)+' named '+columnHeaders[i]+', found '+columnTitles[i];
                }
            }
        }
        if (message != '') {
            String errorMessage = 'Enforce Transfer Sheet Template: ' + message;
            throw Util.createAuraExceptionWithMessage(errorMessage);
        }
    }

    private static List<String> getColumnHeaders() {
        return isUCB ? new List<String>(UCB_UASB_FIELDS.keySet()) : new List<String>(GENERIC_UASB_FIELDS.keySet());
    }

    private static void addUASBFromTransfer(Map<String,UASB__c> uasbsFromTransfer, List<String> rowData) {
        String utilityNumberKey = cleanUtilityNumber(rowData[0]);
        UASB__c uasb;

        // Run validation check on data row
        validateRowData(rowData);

        // Build UASB depending on scenario
        if (!uasbsFromTransfer.containsKey(utilityNumberKey)) {
            // Typical scenario, no duplicates found in csv
            uasb = getParsedUASB(rowData);
        } else {
            // Duplicate key found, indicating 2+ rows for same account number in transfer .csv, fix existing entry
            uasb = getParsedUASBWithDuplicateRows(uasbsFromTransfer.get(utilityNumberKey), rowData);
        }

        uasbsFromTransfer.put(utilityNumberKey, uasb);
    }

    private static void validateRowData(List<String> rowData) {
        // Check if columns are missing
        if (rowData.size() < expectedColumnCount) {
            throw Util.createAuraExceptionWithMessage('Expected ' + expectedColumnCount + ' data points in CSV row: ' + rowData);
        }

        // Check if credits field contains fractional decimal
        Decimal credits = getDecimalFromCSV(rowData[1]);
        if (credits != null && credits.scale() > 2) {
            throw Util.createAuraExceptionWithMessage('Fractional decimals present in transfer sheet: ' + rowData);
        }
    }

    private static UASB__c getParsedUASB(List<String> rowData) {
        UASB__c newParsedUasb = new UASB__c();
        newParsedUasb.put(uasbFields[0], cleanUtilityNumber(rowData[0])); // Key field, use string
        for (Integer i = 1; i < expectedColumnCount; i++) {
            String uasbFieldName = uasbFields[i];
            Decimal fieldValue = getDecimalFromCSV(rowData[i]); // Default .csv field data type is Decimal
            newParsedUasb.put(uasbFieldName, fieldValue);
        }
        return newParsedUasb;
    }

    private static UASB__c getParsedUASBWithDuplicateRows(UASB__c duplicateUasbToUpdate, List<String> rowData) {
        // If the transfer sheet has 2+ rows for the same utility account, take the SUM of the rows
        // Except for production (kWh), because it is used to calculate credits allocated.
        // For ex. in some programs, a 100 kWh transfer is multiplied by two separate Credit Rates,
        // (say, $0.02/kWh and $0.13/kWh) to get a total credits allocated = $2 + $13 = $15
        // but production is only 100kWh not 200kWh, even though it is listed twice
        for (Integer i = 1; i < expectedColumnCount; i++) {
            if (uasbFields[i] == 'Subscription_Production_kWh_Static__c') {
                handleDuplicateProductionKwh(duplicateUasbToUpdate, getDecimalFromCSV(rowData[i]));
            } else {
                handleDuplicateGenericField(duplicateUasbToUpdate, getDecimalFromCSV(rowData[i]), uasbFields[i]);
            }
        }
        return duplicateUasbToUpdate;
    }

    private static void handleDuplicateProductionKwh(UASB__c uasb, Decimal newData) {
        Decimal existingData = uasb.Subscription_Production_kWh_Static__c;
        if (existingData == null) {
            uasb.Subscription_Production_kWh_Static__c = newData;
        } else {
            uasb.Subscription_Production_kWh_Static__c = Math.max(Util.nullToZero(newData), existingData);
        }
    }

    private static void handleDuplicateGenericField(UASB__c uasb, Decimal newData, String fieldName) {
        Decimal existingData = (Decimal) uasb.get(fieldName);
        if (existingData == null) {
            uasb.put(fieldName, newData);
        } else {
            uasb.put(fieldName, Util.nullToZero(newData) + existingData);
        }
    }

    private static String cleanUtilityNumber(String utilityNumber) {
        utilityNumber = utilityNumber.replaceAll('-', '');
        utilityNumber = utilityNumber.replaceAll('_', '');
        utilityNumber = utilityNumber.replaceAll(' ', '');
        return utilityNumber;
    }

    private static Decimal getDecimalFromCSV(String csvValue) {
        String csvString = String.isBlank(csvValue.stripHtmlTags()) ? null : csvValue.stripHtmlTags();
        csvString = csvString?.replace('$', '');
        Decimal csvDecimal = csvString==null ? null : Decimal.valueOf(csvString);
        return csvDecimal;
    }

    @TestVisible
    private static List<UASBWithStatus> compareSFBillsToTransferSheet(List<UASB__c> sfBills, Map<String,UASB__c> transferSheetBills) {
        List<UASBWithStatus> conglomeratedUASBList = new List<UASBWithStatus>();

        for (UASB__c sfBill : sfBills) {
            UASBWithStatus lineItem = new UASBWithStatus();
            lineItem.sfUASB = sfBill;
            String cleanUALName = cleanUtilityNumber(sfBill.PreGen_Utility_Acct__c);
            if (transferSheetBills.containsKey(cleanUALName)) {
                UASB__c transferUASB = transferSheetBills.get(cleanUALName);
                lineItem = compareUASBFields(lineItem, transferUASB);
                lineItem.utilUASB = transferUASB;
                transferSheetBills.remove(cleanUALName);
            } else {
                lineItem.status = 'MISSING_TRANSFER';
                lineItem.utilUASB = new UASB__c();
            }
            conglomeratedUASBList.add(lineItem);
        }

        conglomeratedUASBList = populateOverdueCheckbox(conglomeratedUASBList);

        for (UASB__c transferUASB : transferSheetBills.values()) {
            UASBWithStatus lineItem = new UASBWithStatus();
            lineItem.utilUASB = transferUASB;
            lineItem.status = 'MISSING_BILL';
            lineItem.sfUASB = new UASB__c();
            conglomeratedUASBList.add(lineItem);
        }
        return conglomeratedUASBList;
    }

    private static List<UASBWithStatus> populateOverdueCheckbox(List<UASBWithStatus> pregeneratedBills) {
        Set<Id> acctIds = new Set<Id>();
        for (UASBWithStatus uasb : pregeneratedBills) {
            acctIds.add(uasb.sfUASB.Account__c);
        }

        Map<Id, Account> acctMap = accountsSelector.selectById(acctIds);

        Decimal minimumBalance = Util.getSystemPropertyDecimal('Minimum_Balance_Bills_for_Cancelled__c');
        Date maxPastDueDate = Date.today() - (Integer) Util.getSystemPropertyDecimal('Days_Generate_Bills_For_Cancelled__c');

        for (UASBWithStatus uasb : pregeneratedBills) {
            Account propAccount = acctMap.get(uasb.sfUASB.Account__c);
            if (propAccount.Last_Bill_Send_Date_New_Charges_Zuora__c != null
                && propAccount.Last_Bill_Send_Date_New_Charges_Zuora__c >= maxPastDueDate
                && propAccount.Total_Outstanding_Balance_Zuora__c > minimumBalance) {
                uasb.overdue = true;
            } else {
                uasb.overdue = false;
            }
        }
        return pregeneratedBills;
    }

    private static UASBWithStatus compareUASBFields(UASBWithStatus lineItem, UASB__c transferBill) {
        Decimal transferCredits = transferBill.Credits_Allocated__c;
        Decimal transferProduction = transferBill.Subscription_Production_kWh_Static__c;
        Decimal transferNMCRate = transferBill.NMC_Rate__c;
        Decimal sfCredits = lineItem.sfUASB.Credits_Allocated__c;
        Decimal sfProduction = lineItem.sfUASB.Subscription_Production_kWh_Static__c;
        Decimal sfNMCRate = lineItem.sfUASB.NMC_Rate__c;

        /*  Depending on the utility and program, we may only get 1 of these 3 categories.
            For ex.) Xcel in MN gives us Production (kWh) and NMC Rate ($/kWh), but
            National Grid in MA gives us Credits Allocated ($) only.
            To avoid having to hard code for each circumstance, only check variables that are provided
            and throw error if no data is provided.
        */
        lineItem.status = 'CREDIT_MISMATCH';
        if (isNotNullAndDifferent(transferCredits, sfCredits)) {
            lineItem.matchMessage = 'Credits Allocated Mismatch';
        } else if (isNotNullAndDifferent(transferProduction, sfProduction)) {
            lineItem.matchMessage = 'Production kWh Mismatch';
        } else if (isNotNullAndDifferent(transferNMCRate, sfNMCRate)) {
            lineItem.matchMessage = 'NMC Rate mismatch';
        } else if (transferCredits == null && transferProduction == null && transferNMCRate == null) {
            lineItem.matchMessage = 'All Values are Null';
        } else {
            lineItem.status = 'MATCH';
        }
        return lineItem;
    }

    private static Boolean isNotNullAndDifferent(Decimal transferAmount, Decimal sfAmount) {
        return transferAmount != null && sfAmount != transferAmount;
    }

    private static void insertZeroDollarBills(Transfer__c transfer) {
        List<UASB__c> overdueUASBs = BillGenerationService.calculateUASBsFromTransfer(
            transfer, BillGenerationService.BillType.OVERDUE
        );
        insert overdueUASBs;
    }

    @TestVisible
    private static Map<Id,String> readDataFromLWC(List<String> overrideValues) {
        Map<Id,String> resolutionMap = new Map<Id,String>();
        for (String lineItem : overrideValues) {
            TransferResolutionData overrideData = (TransferResolutionData) System.JSON.deserialize(lineItem, TransferResolutionData.class);
            if (!overrideData.uniqueid.contains('missingBill')) {
                resolutionMap.put(overrideData.uniqueid, overrideData.resolution);
            }
        }
        return resolutionMap;
    }

    @TestVisible
    private static List<UASB__c> resolveUASBs(List<UASBWithStatus> uasbWithStatusList, Map<Id, String> resolutionMap) {
        List<UASB__c> uasbsToInsert = new List<UASB__c>();
        for (UASBWithStatus uasbWrapper : uasbWithStatusList) {
            uasbWrapper.resolution = resolutionMap.get(uasbWrapper.sfUASB.Schedule_Z_Subscription__c);
            uasbWrapper.sfUASB.Transfer_Sheet_Resolution__c = uasbWrapper.resolution;
            switch on uasbWrapper.status {
                when 'MATCH' {
                    uasbsToInsert.add(uasbWrapper.sfUASB);
                } when 'CREDIT_MISMATCH' {
                    uasbsToInsert.add(resolveCreditMismatch(uasbWrapper));
                } when 'MISSING_TRANSFER' {
                    UASB__c bill = resolveMissingTransfer(uasbWrapper);
                    if (uasbWrapper.resolution == 'UseSalesforce' || uasbWrapper.overdue) {
                        uasbsToInsert.add(bill);
                    }
                }
            }
        }
        return uasbsToInsert;
    }

    private static UASB__c resolveCreditMismatch(UASBWithStatus data) {
        UASB__c uasbToModify = data.sfUASB;
        if (data.resolution == 'UseUtility') {
            if (data.utilUASB.Credits_Allocated__c != 0) {
                uasbToModify.Credits_Allocated__c = data.utilUASB.Credits_Allocated__c;
            }
            if (data.utilUASB.Subscription_Production_kWh_Static__c != 0) {
                uasbToModify.Subscription_Production_kWh_Static__c = data.utilUASB.Subscription_Production_kWh_Static__c;
            }
            if (data.utilUASB.NMC_Rate__c != 0) {
                uasbToModify.NMC_Rate__c = data.utilUASB.NMC_Rate__c;
            }
        }
        return uasbToModify;
    }

    private static UASB__c resolveMissingTransfer(UASBWithStatus data) {
        // If a pre-generated bill is not on the transfer sheet and we want to use the utility's value
        // we can either not insert a bill at all or insert a $0 bill. For overdue customers, we want a $0 bill
        UASB__c uasbToModify;
        if (data.resolution == 'UseUtility') {
            uasbToModify = data.sfUASB;
            setMissingTransferFields(uasbToModify);
        } else if (data.resolution == 'UseSalesforce') {
            uasbToModify = data.sfUASB;
        }
        return uasbToModify;
    }
    
    private static void setMissingTransferFields(UASB__c uasb) {
        uasb.Total_System_NMCs__c = 0;
        uasb.Total_System_Production_kWh__c = 0;
        uasb.Subscription_Production_kWh_Static__c = 0;
        uasb.NMC_Rate__c = 0;
        uasb.Share_of_System__c = 0;
        uasb.Credits_Allocated__c = 0;
    }

    @TestVisible
    private static void postUASBInsertProcessing(Transfer__c transfer, List<String> overrideValues) {
        transfer.Bills_Generated__c = true;
        update transfer;

        Bill_Period__c billPeriodToUpdate = new Bill_Period__c(
            Id = transfer.Bill_Period__c,
            Bill_Status__c = 'Generated'
        );
        update billPeriodToUpdate;
        saveResultsAsCSVToRecord(transfer.Id, overrideValues);
    }

    private static void saveResultsAsCSVToRecord(Id transferId, List<String> overrideValues) {
        String csvString = '';
        for (String lineItem : overrideValues) {
            lineItem = lineItem.replace('{', '');
            lineItem = lineItem.replace('}', '\n');
            csvString += lineItem;
        }
        String fileName = 'TransferSheetResolution_' + transferId + '.csv';
        ContentService service = new ContentService();
        service.uploadFileToRecordAndShareInternally(csvString, transferId, fileName);
    }
}