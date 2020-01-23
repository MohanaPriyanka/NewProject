@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class TransferSheetService {
    public static ContentDocumentSelector docSelector = new ContentDocumentSelector();
    public enum MatchStatus {MATCH, CREDIT_MISMATCH, MISSING_BILL, MISSING_TRANSFER}

    public class UASBWithStatus {
        @AuraEnabled
        public UASB__c UASB;
        @AuraEnabled
        public matchStatus Status;
        @AuraEnabled
        public String MatchMessage;
    }

    @AuraEnabled
    public static void setCategoryOnContentVersion(Id contentDocumentId, String category){
        List<ContentDocument> contentDocuments = docSelector.selectById(new Set<Id>{contentDocumentId});
        ContentVersion versionToUpdate = new ContentVersion(
            Id = contentDocuments[0].LatestPublishedVersionId,
            File_Category__c = category
        );
        update versionToUpdate;
    }

    @AuraEnabled
    public static List<UASBWithStatus> getUASBListFromTransferSheet(Transfer__c transfer) {
        try {
            Map<Integer, List<String>> csvData = getDataFromMostRecentDocumentUpload(transfer);
            Map<String,UASB__c> transferUASBs = convertTransferSheetToUASBs(csvData);
            List<UASB__c> pregeneratedSFBills = BillGenerationService.calculateUASBsFromTransfer(transfer);
            return compareSFBillsToTransferSheet(pregeneratedSFBills, transferUASBs, transfer);
        } catch (Exception excep) {
            throw Util.createAuraExceptionWithMessage(String.valueOf(excep.getMessage()) + String.valueOf(excep.getStackTraceString()));
        }
    }

    private static Map<Integer, List<String>> getDataFromMostRecentDocumentUpload(Transfer__c transfer){
        ContentDocument document = docSelector.getMostRecentTransferSheet(transfer);
        return Util.readCSV(document.LatestPublishedVersion.VersionData.toString());
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
            Decimal credits = Decimal.valueOf(Util.nullToZero(rowData[1]));
            Decimal production = Decimal.valueOf(Util.nullToZero(rowData[2]));
            Decimal nmcRate =  Decimal.valueOf(Util.nullToZero(rowData[3]));
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
            if (columnTitles[0] != 'UtilityNumber' && message == null){
                message += 'Expected first column named UtilityNumber, found ' + columnTitles[0];
            }
            if (columnTitles[1] != 'Credits') {
                message += 'Expected second column named Credits, found ' + columnTitles[1];
            }
            if (columnTitles[2] != 'Production'){
                message += 'Expected third column named Production, found ' + columnTitles[2];
            }
            if (columnTitles[3] != 'CreditValue'){
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
    private static List<UASBWithStatus> compareSFBillsToTransferSheet(List<UASB__c> sfBills, Map<String,UASB__c> transferSheetBills, Transfer__c transfer) {
        List<UASBWithStatus> conglomeratedUASBList = new List<UASBWithStatus>();

        for (UASB__c sfBill : sfBills){
            UASBWithStatus lineItem = new UASBWithStatus();
            lineItem.UASB = sfBill;
            String cleanUALName = cleanUtilityNumber(sfBill.PreGen_Utility_Acct__c);
            if (transferSheetBills.containsKey(cleanUALName)){
                lineItem = compareUASBFields(lineItem, transferSheetBills.get(cleanUALName));
                transferSheetBills.remove(cleanUALName);
            } else {
                lineItem.Status = matchStatus.MISSING_TRANSFER;
            }
            conglomeratedUASBList.add(lineItem);
        }

        for (UASB__c transferUASB : transferSheetBills.values()){
            UASBWithStatus lineItem = new UASBWithStatus();
            lineItem.UASB = transferUASB;
            lineItem.Status = matchStatus.MISSING_BILL;
            conglomeratedUASBList.add(lineItem);
        }
        return conglomeratedUASBList;
    }

    private static UASBWithStatus compareUASBFields(UASBWithStatus lineItem, UASB__c transferBill) {
        Decimal transferCredits = Util.nullToZero(transferBill.Credits_Allocated__c);
        Decimal transferProduction = Util.nullToZero(transferBill.Subscription_Production_kWh_Static__c);
        Decimal transferNMCRate = Util.nullToZero(transferBill.NMC_Rate__c);
        Decimal sfCredits = Util.nullToZero(lineItem.UASB.Credits_Allocated__c);
        Decimal sfProduction = Util.nullToZero(lineItem.UASB.Subscription_Production_kWh_Static__c);
        Decimal sfNMCRate = Util.nullToZero(lineItem.UASB.NMC_Rate__c);

        /*  Depending on the utility and program, we may only get 1 of these 3 categories.
            For ex.) Xcel in MN gives us Production (kWh) and NMC Rate ($/kWh), but
            National Grid in MA gives us Credits Allocated ($) only.
            To avoid having to hard code for each circumstance, only check variables that are provided
            and throw error if no data is provided.
        */

        lineItem.Status = matchStatus.CREDIT_MISMATCH;
        if (transferCredits != 0 && sfCredits != transferCredits){
            lineItem.MatchMessage = 'Credits Allocated Mismatch';
        } else if (transferProduction != 0 && (sfProduction != transferProduction)){
            lineItem.MatchMessage = 'Production kWh Mismatch';
        } else if (transferNMCRate != 0 && (sfNMCRate != transferNMCRate)){
            lineItem.MatchMessage = 'NMC Rate mismatch';
        } else if (transferCredits == 0 && transferProduction == 0 && transferNMCRate == 0){
            lineItem.MatchMessage = 'All Values are Null Or Zero';
        } else {
            lineItem.Status = matchStatus.MATCH;
        }
        return lineItem;
    }
}