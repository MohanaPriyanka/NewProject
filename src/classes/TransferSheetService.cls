// Tested by TransferSheetBillingTest

@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class TransferSheetService {
    public static ContentDocumentSelector docSelector = new ContentDocumentSelector();
    public static AccountsSelector accountsSelector = new AccountsSelector();

    public class UASBWithStatus {
        @AuraEnabled
        public UASB__c SfUASB;
        @AuraEnabled
        public UASB__c UtilUASB;
        @AuraEnabled
        public String Status; // MATCH, CREDIT_MISMATCH, MISSING_BILL, MISSING_TRANSFER
        @AuraEnabled
        public String MatchMessage;
        @AuraEnabled
        public String Resolution; // UseUtility, UseSalesforce
        @AuraEnabled
        public Boolean Overdue;
    }

    public class TransferResolutionData {
        public String Uniqueid;
        public String Resolution;
    }

    @AuraEnabled
    public static List<UASBWithStatus> getTransferFromId(Id transferRecordId) {
        Transfer__c transfer = TransferSelector.getTransferById(transferRecordId);
        if (transfer.Bills_Generated__c){
            throw Util.createAuraExceptionWithMessage('Bills Already Generated for this Transfer');
        }
        return getUASBListFromTransferSheet(transfer);
    }

    public static List<UASBWithStatus> getUASBListFromTransferSheet(Transfer__c transfer) {
        try {
            Map<Integer, List<String>> csvData = getDataFromMostRecentDocumentUpload(transfer);
            Map<String,UASB__c> transferUASBs = convertTransferSheetToUASBs(csvData);
            List<UASB__c> pregeneratedSFBills = BillGenerationService.calculateUASBsFromTransfer(transfer);
            return compareSFBillsToTransferSheet(pregeneratedSFBills, transferUASBs);
        } catch (Exception excep) {
            throw Util.createAuraExceptionWithMessage(String.valueOf(excep.getMessage()) + String.valueOf(excep.getStackTraceString()));
        }
    }

    private static Map<Integer, List<String>> getDataFromMostRecentDocumentUpload(Transfer__c transfer){
        ContentDocument document;
        try {
            document = docSelector.getMostRecentTransferSheet(transfer);
            return Util.readCSV(document.LatestPublishedVersion.VersionData.toString());
        } catch (Exception docExcep) {
            // If no transfer sheet is uploaded, treat the same as if there is a transfer sheet with no rows:
            Map<Integer, List<String>> blankMap = new Map<Integer, List<String>>();
            blankMap.put(0,new List<String>{'UtilityNumber', 'Credits', 'Production', 'CreditValue'});
            return blankMap;
        }
    }

    @TestVisible
    private static Map<String,UASB__c> convertTransferSheetToUASBs(Map<Integer, List<String>> rowNumberToDataMap) {
        Map<String,UASB__c> uasbsFromTransfer = new Map<String,UASB__c>();
        enforceTransferSheetTemplate(rowNumberToDataMap.get(0));
        rowNumberToDataMap.remove(0);

        for (List<String> rowData : rowNumberToDataMap.values()){
            if (rowData.size() < 4){
                throw Util.createAuraExceptionWithMessage('Expected 4 data points in CSV row: ' + rowData);
            }
            String utilityNumKey = cleanUtilityNumber(rowData[0]);
            String creditsAsString = rowData[1].stripHtmlTags();
            String productionAsString = rowData[2].stripHtmlTags();
            String nmcRateAsString = rowData[3].stripHtmlTags();
            Decimal credits = Decimal.valueOf(Util.nullToZero(creditsAsString));
            Decimal production = Decimal.valueOf(Util.nullToZero(productionAsString));
            Decimal nmcRate =  Decimal.valueOf(Util.nullToZero(nmcRateAsString));
            if (credits.scale() > 2){
                throw Util.createAuraExceptionWithMessage('Fractional decimals present in transfer sheet: ' + rowData);
            }

            if (uasbsFromTransfer.containsKey(utilityNumKey)) {
                // If the transfer sheet has 2 rows for the same utility account, take the SUM of the rows
                UASB__c uasbToUpdate = uasbsFromTransfer.get(utilityNumKey);
                uasbToUpdate.Credits_Allocated__c += credits;
                uasbToUpdate.Subscription_Production_kWh_Static__c += production;
                uasbToUpdate.NMC_Rate__c += nmcRate;
                uasbsFromTransfer.put(utilityNumKey,uasbToUpdate);
            } else {
                UASB__c transferSheetUASB = new UASB__c(
                    PreGen_Utility_Acct__c = rowData[0],
                    Credits_Allocated__c = credits,
                    Subscription_Production_kWh_Static__c = production,
                    NMC_Rate__c = nmcRate
                );
                uasbsFromTransfer.put(utilityNumKey,transferSheetUASB);
            }
        }
        return uasbsFromTransfer;
    }

    private static void enforceTransferSheetTemplate(List<String> columnTitles) {
        String message = 'Enforce Transfer Sheet Template: ';
        if (columnTitles.size() < 4) {
            message += 'Expected 4 Columns in CSV data found ' + String.valueOf(columnTitles.size());
        } else {
            if (!columnTitles[0].contains('UtilityNumber')){
                message += 'Expected first column named UtilityNumber, found ' + columnTitles[0];
            }
            if (!columnTitles[1].contains('Credits')) {
                message += 'Expected second column named Credits, found ' + columnTitles[1];
            }
            if (!columnTitles[2].contains('Production')){
                message += 'Expected third column named Production, found ' + columnTitles[2];
            }
            if (!columnTitles[3].contains('CreditValue')){
                message += 'Expected fourth column named CreditValue, found ' + columnTitles[3];
            }
        }
        if (message != 'Enforce Transfer Sheet Template: '){
            throw Util.createAuraExceptionWithMessage(message);
        }
    }

    public static String cleanUtilityNumber(String utilityNumber) {
        utilityNumber = utilityNumber.replaceAll('-','');
        utilityNumber = utilityNumber.replaceAll('_','');
        utilityNumber = utilityNumber.replaceAll(' ','');
        return utilityNumber;
    }

    @TestVisible
    private static List<UASBWithStatus> compareSFBillsToTransferSheet(List<UASB__c> sfBills, Map<String,UASB__c> transferSheetBills) {
        List<UASBWithStatus> conglomeratedUASBList = new List<UASBWithStatus>();

        for (UASB__c sfBill : sfBills){
            UASBWithStatus lineItem = new UASBWithStatus();
            lineItem.sfUASB = sfBill;
            String cleanUALName = cleanUtilityNumber(sfBill.PreGen_Utility_Acct__c);
            if (transferSheetBills.containsKey(cleanUALName)){
                UASB__c transferUASB = transferSheetBills.get(cleanUALName);
                lineItem = compareUASBFields(lineItem,transferUASB);
                lineItem.utilUASB = transferUASB;
                transferSheetBills.remove(cleanUALName);
            } else {
                lineItem.Status = 'MISSING_TRANSFER';
                lineItem.utilUASB = new UASB__c();
            }
            conglomeratedUASBList.add(lineItem);
        }

        conglomeratedUASBList = populateOverdueCheckbox(conglomeratedUASBList);

        for (UASB__c transferUASB : transferSheetBills.values()){
            UASBWithStatus lineItem = new UASBWithStatus();
            lineItem.utilUASB = transferUASB;
            lineItem.Status = 'MISSING_BILL';
            lineItem.sfUASB = new UASB__c();
            conglomeratedUASBList.add(lineItem);
        }
        return conglomeratedUASBList;
    }

    private static List<UASBWithStatus> populateOverdueCheckbox(List<UASBWithStatus> pregeneratedBills) {
        Set<Id> acctIds = new Set<Id>();
        for (UASBWithStatus uasb : pregeneratedBills){
            acctIds.add(uasb.SfUASB.Account__c);
        }

        Map<Id, Account> acctMap = accountsSelector.selectById(acctIds);

        Decimal minimumBalance = Util.getSystemPropertyDecimal('Minimum_Balance_Bills_for_Cancelled__c');
        Date maxPastDueDate = Date.today() - (Integer) Util.getSystemPropertyDecimal('Days_Generate_Bills_For_Cancelled__c');

        for (UASBWithStatus uasb : pregeneratedBills){
            Account propAccount = acctMap.get(uasb.SfUASB.Account__c);
            if (propAccount.Last_Bill_Send_Date_New_Charges_Zuora__c != null
                && propAccount.Last_Bill_Send_Date_New_Charges_Zuora__c >= maxPastDueDate
                && propAccount.Total_Outstanding_Balance_Zuora__c > minimumBalance){
                uasb.Overdue = true;
            } else {
                uasb.Overdue = false;
            }
        }
        return pregeneratedBills;
    }

    private static UASBWithStatus compareUASBFields(UASBWithStatus lineItem, UASB__c transferBill) {
        Decimal transferCredits = Util.nullToZero(transferBill.Credits_Allocated__c);
        Decimal transferProduction = Util.nullToZero(transferBill.Subscription_Production_kWh_Static__c);
        Decimal transferNMCRate = Util.nullToZero(transferBill.NMC_Rate__c);
        Decimal sfCredits = Util.nullToZero(lineItem.sfUASB.Credits_Allocated__c);
        Decimal sfProduction = Util.nullToZero(lineItem.sfUASB.Subscription_Production_kWh_Static__c);
        Decimal sfNMCRate = Util.nullToZero(lineItem.sfUASB.NMC_Rate__c);

        /*  Depending on the utility and program, we may only get 1 of these 3 categories.
            For ex.) Xcel in MN gives us Production (kWh) and NMC Rate ($/kWh), but
            National Grid in MA gives us Credits Allocated ($) only.
            To avoid having to hard code for each circumstance, only check variables that are provided
            and throw error if no data is provided.
        */

        lineItem.Status = 'CREDIT_MISMATCH';
        if (transferCredits != 0 && sfCredits != transferCredits){
            lineItem.MatchMessage = 'Credits Allocated Mismatch';
        } else if (transferProduction != 0 && (sfProduction != transferProduction)){
            lineItem.MatchMessage = 'Production kWh Mismatch';
        } else if (transferNMCRate != 0 && (sfNMCRate != transferNMCRate)){
            lineItem.MatchMessage = 'NMC Rate mismatch';
        } else if (transferCredits == 0 && transferProduction == 0 && transferNMCRate == 0){
            lineItem.MatchMessage = 'All Values are Null Or Zero';
        } else {
            lineItem.Status = 'MATCH';
        }
        return lineItem;
    }

    @AuraEnabled
    public static void handleTransferSheetResolutions(String pregenBills, List<String> overrideValues){
        List<UASBWithStatus> uasbWithStatusList = (List<UASBWithStatus>) System.JSON.deserialize(pregenBills, List<UASBWithStatus>.class);
        Map<Id,String> resolutionMap = readDataFromLWC(overrideValues);
        List<UASB__c> uasbsToInsert = resolveUASBs(uasbWithStatusList, resolutionMap);
        insert uasbsToInsert;
        Transfer__c transferToUpdate = new Transfer__c(
            Id = uasbsToInsert[0].Transfer__c,
            Bills_Generated__c = true
        );
        update transferToUpdate;
    }

    @TestVisible
    private static Map<Id,String> readDataFromLWC(List<String> overrideValues){
        Map<Id,String> resolutionMap = new Map<Id, String>();
        for (String lineItem : overrideValues){
            TransferResolutionData overrideData = (TransferResolutionData) System.JSON.deserialize(lineItem, TransferResolutionData.class);
            if (!overrideData.Uniqueid.contains('missingBill')){
                resolutionMap.put(overrideData.Uniqueid, overrideData.Resolution);
            }
        }
        return resolutionMap;
    }

    @TestVisible
    private static List<UASB__c> resolveUASBs(List<UASBWithStatus> uasbWithStatusList, Map<Id,String> resolutionMap){
        List<UASB__c> uasbsToInsert = new List<UASB__c>();
        for (UASBWithStatus uasbStatus : uasbWithStatusList){
            uasbStatus.Resolution = resolutionMap.get(uasbStatus.SfUASB.Schedule_Z_Subscription__c);
            switch on uasbStatus.Status {
                when 'MATCH' {
                    uasbsToInsert.add(uasbStatus.SfUASB);
                } when 'CREDIT_MISMATCH' {
                    uasbsToInsert.add(resolveCreditMismatch(uasbStatus));
                } when 'MISSING_BILL' {
                    // No bill to insert, do nothing
                } when 'MISSING_TRANSFER' {
                    UASB__c bill = resolveMissingTransfer(uasbStatus);
                    if (bill != null){
                        uasbsToInsert.add(bill);
                    }
                }
            }
        }
        return uasbsToInsert;
    }

    private static UASB__c resolveCreditMismatch(UASBWithStatus uasbWithStatus){
        UASB__c uasbToModify = uasbWithStatus.SfUASB;
        if (uasbWithStatus.Resolution == 'UseUtility'){
            if (uasbWithStatus.UtilUASb.Credits_Allocated__c != 0){
                uasbToModify.Credits_Allocated__c = uasbWithStatus.UtilUASb.Credits_Allocated__c;
            }
            if (uasbWithStatus.UtilUASb.Subscription_Production_kWh_Static__c != 0){
                uasbToModify.Subscription_Production_kWh_Static__c = uasbWithStatus.UtilUASb.Subscription_Production_kWh_Static__c;
            }
            if (uasbWithStatus.UtilUASb.Subscription_Production_kWh_Static__c != 0){
                uasbToModify.NMC_Rate__c = uasbWithStatus.UtilUASb.Subscription_Production_kWh_Static__c;
            }
        }
        return uasbToModify;
    }

    private static UASB__c resolveMissingTransfer(UASBWithStatus uasbWithStatus){
        // If a pre-generated bill is not on the transfer sheet and we want to use the utility's value
        // we can either not insert a bill at all or insert a $0 bill. For overdue customers, we want a $0 bill

        UASB__c uasbToModify;
        if (uasbWithStatus.Resolution == 'UseUtility' && uasbWithStatus.Overdue){
            uasbToModify = uasbWithStatus.SfUASB;
            uasbToModify.Total_System_NMCs__c = 0;
            uasbToModify.Total_System_Production_kWh__c = 0;
            uasbToModify.Subscription_Production_kWh_Static__c = 0;
            uasbToModify.NMC_Rate__c = 0;
            uasbToModify.Share_of_System__c = 0;
            uasbToModify.Credits_Allocated__c = 0;
        } else if (uasbWithStatus.Resolution == 'UseSalesforce'){
            uasbToModify = uasbWithStatus.SfUASB;
        }
        return uasbToModify;
    }
}