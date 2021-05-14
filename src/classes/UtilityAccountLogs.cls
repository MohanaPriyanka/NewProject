/**
 * Created by jeffparlin on 5/6/21.
 * @description Handles appropriate modifications to Utility_Account_Log__c records when mandated from other contexts
 * Specifically is built to handle updating UALs when Utility_Data_Request__c records are marked as 'Complete'
 *
 * Tested by: UtilityDataRequestServiceTest
 */
public without sharing class UtilityAccountLogs {

    /* STATIC PROPERTIES */
    @TestVisible private static UALSelector ualSelector = new UALSelector();

    /* INSTANCE PROPERTIES */
    private List<UtilityAccountData> utilityAccountDataList = new List<UtilityAccountData>();
    public QCMethod autoQcMethod;

    public enum QCMethod {EDI, GLYNT}

    /**
     * @description Constructor for when EDI Utility Data Requests are marked as 'Complete' and updates need to happen
     * on the respective Utility Account Log records
     * @param completedUDRs Completed Utility_Data_Request__c records with data relevant to UAL update
     * @param udrRateClassMap Map of Utility_Data_Request__c => Rate_Class__c reference
     */
    public UtilityAccountLogs(Map<Id,Utility_Data_Request__c> completedUDRs, Map<Id,Id> udrRateClassMap) {
        Map<Id,Utility_Account_Log__c> uals = ualSelector.selectAllMap(
            CollectionUtil.mapByIdField(completedUDRs.values(), Utility_Data_Request__c.Utility_Account_Log__c).keySet()
        );
        for (Utility_Data_Request__c udr : completedUDRs.values()) {
            UtilityAccountData data = new UtilityAccountData();
            data.ual = uals.get(udr.Utility_Account_Log__c);
            data.udr = udr;
            data.rateClassId = udrRateClassMap.get(udr.Id);
            utilityAccountDataList.add(data);
        }
    }

    /**
     * @return Returns Utility_Account_Log__c sObjects which have been modified by code within this class
     */
    public List<Utility_Account_Log__c> getSObjects() {
        List<Utility_Account_Log__c> uals = new List<Utility_Account_Log__c>();
        for (UtilityAccountData data : utilityAccountDataList) {
            uals.add(data.ual);
        }
        return uals;
    }

    /**
     * @description Apex-defined object structure that links Utility_Account_Log__c to related records without maps
     */
    public class UtilityAccountData {
        Utility_Account_Log__c ual;
        Utility_Data_Request__c udr;
        Id rateClassId;
        Boolean hasAddressChange = false;
        Boolean hasDuplicateUAL = false;
        Boolean hasDiscountRates = false;
        Boolean isAboveMaxAvgDemand = false;
        Boolean isBelowMinKwh = false;
        Boolean missingSizingData = false;
    }

    public void updateOnEDIRequestComplete() {
        autoQcMethod = QCMethod.EDI;
        setFieldsFromEDI();
        checkForAddressChange();
        checkForDuplicates();
        checkDiscountRates();
        checkSizingParameters();
        autoQC();
    }

    private void setFieldsFromEDI() {
        for (UtilityAccountData data : utilityAccountDataList) {
            data.ual.Utility_Rate_Class__c = data.rateClassId;
            data.ual.Annual_kWh__c = data.udr.Annual_kWh__c;
            data.ual.Average_Demand__c = data.udr.Average_Demand__c;
            data.ual.Num_UDRPs_Annual_kWh__c = data.udr.Num_UDRPs_Annual_kWh__c;
            data.ual.Num_UDRPs_Avg_Demand__c = data.udr.Num_UDRPs_Avg_Demand__c;
            data.ual.NYPA__c = parseEDIString(data.udr.Government_Credit_Code__c);
            data.ual.RNY__c = parseEDIString(data.udr.LDC_Customer_Eligibility__c);
        }
    }

    private void checkForAddressChange() {
        for (UtilityAccountData data : utilityAccountDataList) {
            assessEDIAddressChange(data);
            if (data.hasAddressChange) {
                handleEDIAddressChange(data);
            }
        }
    }

    private void checkForDuplicates() {
        List<String> cleanUtilityAccNumbers = new List<String>();
        for (UtilityAccountData data : utilityAccountDataList) {
            cleanUtilityAccNumbers.add(data.ual.Cleaned_Utility_Account_Number__c);
        }
        Map<String,Integer> ualCounts = ualSelector.getCountOfUALsByCleanedAccNumber(cleanUtilityAccNumbers);
        for (UtilityAccountData data : utilityAccountDataList) {
            Integer numberOfUALs = ualCounts.get(data.ual.Cleaned_Utility_Account_Number__c);
            data.hasDuplicateUAL = numberOfUALs != null && numberOfUALs > 1;
        }
    }

    private void checkDiscountRates() {
        for (UtilityAccountData data : utilityAccountDataList) {
            data.hasDiscountRates = data.ual.NYPA__c == 'Yes' || data.ual.RNY__c == 'Yes';
        }
    }

    private void checkSizingParameters() {
        for (UtilityAccountData data : utilityAccountDataList) {
            Decimal annualKwh = data.ual.Annual_kWh__c;
            Decimal minKwhAllowable = data.ual.Utility_lookup__r.Auto_QC_Minimum_kWH__c;
            data.isBelowMinKwh = minKwhAllowable != null && annualKwh != null ? annualKwh < minKwhAllowable : false;

            Decimal demand = data.ual.Average_Demand__c;
            Decimal maxDemandAllowable = data.ual.Utility_lookup__r.Auto_QC_Maximum_Demand__c;
            if (demand != null && demand != 0) { // Only check demand if a value exists (some customers don't get this data)
                data.isAboveMaxAvgDemand = maxDemandAllowable != null ? demand > maxDemandAllowable : false;
            }

            data.missingSizingData = annualKwh == null;
        }
    }

    private String parseEDIString(String ediCode) {
        switch on ediCode {
            when 'N' {
                return 'No';
            }
            when 'Y' {
                return 'Yes';
            }
        }
        return null;
    }

    /**
     * @description Auto-QC's UALs based on a number of factors, and determines what the resultant QC_Status__c field
     * on UALs should be set to. Also stamps a result of this Auto-QC on UALs if rejected.
     */
    private void autoQC() {
        switch on autoQcMethod {
            when EDI {
                for (UtilityAccountData data : utilityAccountDataList) {
                    qcForEDI(data);
                }
            }
        }
    }

    private void qcForEDI(UtilityAccountData data) {
        String rejectReason;
        rejectReason = appendRejectReason(data.hasAddressChange, rejectReason, 'Address Change');
        rejectReason = appendRejectReason(data.hasDuplicateUAL, rejectReason, 'Duplicate UAL Found');
        rejectReason = appendRejectReason(data.hasDiscountRates, rejectReason, 'Has Discount Rates');
        rejectReason = appendRejectReason(data.isAboveMaxAvgDemand, rejectReason, 'Above Max Avg Demand');
        rejectReason = appendRejectReason(data.isBelowMinKwh, rejectReason, 'Below Min kWh');
        rejectReason = appendRejectReason(data.missingSizingData, rejectReason, 'Missing Sizing Data');

        if (rejectReason != null) { // A reason to auto-reject the UAL was found
            data.ual.QC_Status__c = 'Pending BW Review';
            rejectReason = Datetime.now().format() + ' | ' + rejectReason;
            data.ual.Auto_QC_Reject_Reason__c = data.ual.Auto_QC_Reject_Reason__c == null ? rejectReason :
                data.ual.Auto_QC_Reject_Reason__c + '\n' + rejectReason;
        } else {
            data.ual.QC_Status__c = 'Complete';
        }
    }

    private static String appendRejectReason(Boolean append, String currentReason, String nextReason) {
        if (!append) {
            return currentReason;
        } else if (currentReason == null) {
            return nextReason;
        } else {
            return currentReason + ', ' + nextReason;
        }
    }

    private void assessEDIAddressChange(UtilityAccountData data) {
        String udrName = standardizeText(data.udr.Customer_Name__c);
        String udrAddress = standardizeText(data.udr.Address_Line_1__c) + standardizeText(data.udr.Address_Line_2__c);
        String udrCity = standardizeText(data.udr.City__c);
        String udrState = standardizeText(data.udr.State__c);
        String udrZip = standardizeText(data.udr.Zip_Code__c);
        String udrFullAddress = udrName + '|' + udrAddress + '|' + udrCity + '|' + udrState + '|' + udrZip;

        String ualName = standardizeText(data.ual.Name_on_Account__c);
        String ualAddress = standardizeText(data.ual.Service_Address__c);
        String ualCity = standardizeText(data.ual.Service_City__c);
        String ualState = standardizeText(data.ual.Service_State__c);
        String ualZip = standardizeText(data.ual.Service_Zip_Code__c);
        String ualFullAddress = ualName + '|' + ualAddress + '|' + ualCity + '|' + ualState + '|' + ualZip;

        if (udrFullAddress != ualFullAddress) {
            data.hasAddressChange = true;
        }
    }

    private void handleEDIAddressChange(UtilityAccountData data) {
        data.ual.Address_Update__c = true;
        data.ual.Previous_Name_on_Utility_Account__c = cleanString(data.ual.Name_on_Account__c);
        data.ual.Previous_Service_Address__c = cleanString(data.ual.Service_Address__c);
        data.ual.Previous_Service_City__c = cleanString(data.ual.Service_City__c);
        data.ual.Previous_Service_State__c = cleanString(data.ual.Service_State__c);
        data.ual.Previous_Service_Zip_Code__c = cleanString(data.ual.Service_Zip_Code__c);
        data.ual.Name_on_Account__c = cleanString(data.udr.Customer_Name__c);
        data.ual.Service_Address__c = cleanString(data.udr.Address_Line_1__c) + ' ' + cleanString(data.udr.Address_Line_2__c);
        data.ual.Service_City__c = cleanString(data.udr.City__c);
        data.ual.Service_State__c = cleanString(data.udr.State__c);
        data.ual.Service_Zip_Code__c = cleanString(data.udr.Zip_Code__c);
    }

    private String standardizeText(String str) {
        if (str == 'null' || str == null) {
            return '';
        }
        str = str.replaceAll('\\s+','');
        str = str.replaceAll('[^a-zA-Z0-9]','');
        str = str.toUpperCase();
        return str;
    }

    private String cleanString(String str) {
        if (str == 'null' || str == null) {
            return '';
        }
        return str;
    }
}