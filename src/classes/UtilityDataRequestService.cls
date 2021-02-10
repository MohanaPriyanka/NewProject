/**
 * Created by: Kristin White on 9/28/2020
 * 
 * Test: UtilityDataRequestServiceTest
 * 
 */
@SuppressWarnings('ApexDocValidation')
public without sharing class UtilityDataRequestService {
    @TestVisible private Map<Id,Utility_Data_Request__c> completedUDRMap = new Map<Id,Utility_Data_Request__c>();
    @TestVisible private Map<Id,Utility_Data_Request__c> newUDRMap;
    @TestVisible private Map<Id,Utility_Data_Request__c> oldUDRMap;
    @TestVisible private Map<String,Rate_Class__c> rateClassWithEDIMap;
    @TestVisible private Map<Id,Utility_Account_Log__c> ualsWithCompletedUDRMap;
    @TestVisible private Map<Id,Id> udrToRateClassMap = new Map<Id,Id>();
    @TestVisible private Map<Id,List<Utility_Data_Request_Period__c>> completedUDRToUdrpMap;
    @TestVisible private fflib_SObjectUnitOfWork uow;
    @TestVisible private static RateClassesSelector rateClassesSelector = new RateClassesSelector();
    @TestVisible private static UtilityDataRequestPeriodSelector udrpSelector = new UtilityDataRequestPeriodSelector();
    @TestVisible private static UtilityDataRequestSelector udrSelector = new UtilityDataRequestSelector();
    @TestVisible private static UALSelector ualSelector = new UALSelector();
    /**
     * Constructor for service class instance
     * @param oldUDRMap Trigger.oldMap
     * @param newUDRMap Trigger.newMap
     */
    public UtilityDataRequestService(Map<Id,Utility_Data_Request__c> oldUDRMap, Map<Id,Utility_Data_Request__c> newUDRMap) {
        this.oldUDRMap = oldUDRMap;
        this.newUDRMap = newUDRMap;
    }
    /**
     * @description Populates the UDR.Annual_kWh and the UAL.Annual_kWh with the value calculated in the getAnnualkWh method.
     * Only want to update where the UDR Request Status is being updated to Complete from something else.
     */
    public void beforeStatusUpdatedToComplete() {
        try {
            setupTriggerContext();
            setAnnualkWhAndAvgDemandOnUDRs();
            // Flags the related UDRPs that were used in Annual kWh and Avg Demand calcs
            uow.commitWork();
        } catch (Exception e ) {
            String message = 'Unable to commit work before completion of UDRs: ' + completedUDRMap.keySet().toString()
                + '\n\n' + e.getMessage() + '\n\n' + e.getStackTraceString();
            Logger.logLater('UtilityDataRequestService', 'beforeStatusUpdatedToComplete', message);
        }
        Logger.flushLogs();
    }
    /**
     * @description Method used when a UDR record status is updated to 'Complete' from previously being something else
     * <p></p>
     * Handles related UDRP and UAL modifications
     */
    public void afterStatusUpdatedToComplete() {
        try {
            setupTriggerContext();
            populateUDRPRateClassOnCompletedUDRs();
            updateUALForCompletedUDRs();
            uow.commitWork();
        } catch (Exception e ) {
            String message = 'Unable to commit work on completion of UDRs: ' + completedUDRMap.keySet().toString()
                + '\n\n' + e.getMessage() + '\n\n' + e.getStackTraceString();
            Logger.logLater('UtilityDataRequestService', 'afterStatusUpdatedToComplete', message);
        }
        Logger.flushLogs();
    }

    private void setupTriggerContext() {
        // Instance UOW
        uow = new fflib_SObjectUnitOfWork(
            new List<SObjectType>{
                Utility_Data_Request_Period__c.getSObjectType(),
                Utility_Account_Log__c.getSObjectType()
            }
        );
        // Map completed UDRs for further processing
        for (Utility_Data_Request__c udr : newUDRMap.values()) {
            if (udr.Request_Status_new__c == 'Complete' && oldUDRMap.get(udr.Id).Request_Status_new__c != 'Complete') {
                completedUDRMap.put(udr.Id,udr);
            }
        }
        // Retrieve Rate Classes, UDR->UDRPs, and UALs for Completed UDRs
        rateClassWithEDIMap = rateClassesSelector.selectWithEDI();
        completedUDRToUdrpMap = udrpSelector.selectByUDR(completedUDRMap.keySet());
        ualsWithCompletedUDRMap = ualSelector.selectAllMap(
            CollectionUtil.mapByIdField(completedUDRMap.values(), Utility_Data_Request__c.Utility_Account_Log__c).keySet()
        );
    }

    private void setAnnualkWhAndAvgDemandOnUDRs(){
        Map<Id, UDRWrapper> udrObjectMap = new Map<Id, UDRWrapper>();
        for (Id udrId : completedUDRToUdrpMap.keySet()){
            UDRWrapper currentUDR = new UDRWrapper(udrId);
            currentUDR.addUDRPs(completedUDRToUdrpMap.get(udrId));
            udrObjectMap.put(udrId, currentUDR);
        }
        //Need to get map of new UDRs with specific query criteria needed for the kWh calculation
        Map<Id, Utility_Data_Request__c> udrMap = udrSelector.selectMapForKWHById(completedUDRMap.values());
        for (Utility_Data_Request__c udr : completedUDRMap.values()) {
            Utility_Data_Request__c currentUDR = udrMap.get(udr.Id);
            UDRWrapper currentUdrObject = udrObjectMap.get(udr.Id);
            if (currentUdrObject == null) {
                continue;
            }
            UDRPTotalCalculator kWhHelper = new UDRPTotalCalculator(uow);
            kWhHelper.setAnnualkWh(currentUDR, currentUdrObject.getListKH());
            udr.Annual_kWh__c = kWhHelper.kWh;
            udr.Num_UDRPs_Annual_kWh__c = kWhHelper.numberOfUDRPsUsedInCalc;

            UDRPTotalCalculator avgDemandHelper = new UDRPTotalCalculator(uow);
            avgDemandHelper.setAverageDemand(currentUdrObject.getListK1());
            udr.Average_Demand__c = avgDemandHelper.avgDemand;
            udr.Num_UDRPs_Avg_Demand__c = avgDemandHelper.numberOfUDRPsUsedInCalc;
        }
    }

    private void populateUDRPRateClassOnCompletedUDRs() {
        // Only want to update the Rate Classes if the Status updated from something else to Complete
        for (Id udrId : completedUDRToUdrpMap.keySet()) {
            populateRateClassOnUDRP(udrId);
        }
    }

    private void updateUALForCompletedUDRs() {
        for (Id udrId : completedUDRMap.keySet()) {
            Utility_Account_Log__c ual = ualsWithCompletedUDRMap.get(completedUDRMap.get(udrId).Utility_Account_Log__c);
            ual.Utility_Rate_Class__c = udrToRateClassMap.get(udrId);
            populateFieldsOnUAL(ual, completedUDRMap.get(udrId));
        }
        // Register work
        uow.registerDirty(ualsWithCompletedUDRMap.values());
    }
    /**
     * @description Populates the UDRP.Rate_Class_Lookup__c where 
     * the Rate Class object's EDI_Rate_Class__c text matches the UDRP's Rate_Subclass__c text.
     */
    private void populateRateClassOnUDRP(Id udrId) {
        List<Utility_Data_Request_Period__c> udrpList = completedUDRToUdrpMap.get(udrId);
        Boolean firstKH = false;
        for (Utility_Data_Request_Period__c udrp : udrpList) {
            String rateSubclass = udrp.Rate_Subclass__c;
            String rateClass = udrp.Rate_Class__c;
            udrp.Rate_Class_Lookup__c = setRateClassLookupOnUDRP(rateSubclass, rateClass, udrp);
            uow.registerDirty(udrp);
            if (!firstKH && udrp.Measurement_Unit__c == 'KH') {
                // Only the first UDRP (most recent service date) where the Measurement_Unit is KH, is what we use for Rate Class lookup elsewhere
                udrToRateClassMap.put(udrId, udrp.Rate_Class_Lookup__c);
                firstKH = true;
            }
        }
    }
    private Id setRateClassLookupOnUDRP(String rateSubclass, String rateClass, Utility_Data_Request_Period__c udrp) {
        Rate_Class__c rateSubclassSObj = rateClassWithEDIMap.get(rateSubclass);
        Rate_Class__c rateClassSObj = rateClassWithEDIMap.get(rateClass);
        if (udrp.Utility_Data_Request__r.Utility__c == rateSubclassSObj?.Utility__c) {
            return rateSubclassSObj.Id;
        } else if (udrp.Utility_Data_Request__r.Utility__c == rateClassSObj?.Utility__c) {
            return rateClassSObj.Id;
        }
        return null;
    }

    private void populateFieldsOnUAL(Utility_Account_Log__c ual, Utility_Data_Request__c udr) {
        ual.Annual_kWh__c = udr.Annual_kWh__c;
        ual.Average_Demand__c = udr.Average_Demand__c;

        ual.Num_UDRPs_Annual_kWh__c = udr.Num_UDRPs_Annual_kWh__c;
        ual.Num_UDRPs_Avg_Demand__c = udr.Num_UDRPs_Avg_Demand__c;

        ual.NYPA__c = convertYesNo(udr.Government_Credit_Code__c);
        ual.RNY__c = convertYesNo(udr.LDC_Customer_Eligibility__c);
        Boolean addressStatus = ualNameAddressChange(ual, udr);
        if (ual.NYPA__c == 'Yes' || ual.RNY__c == 'Yes') {
            ual.QC_Status__c = 'Pending BW Review';
        } else if (addressStatus) {
            ual.QC_Status__c = 'Complete';
        } else {
            ual.QC_Status__c = 'Pending BW Review';
        }
    }
    private String convertYesNo(String singleChar) {
        if (singleChar == 'N') {
            return 'No';
        } else if (singleChar == 'Y') {
            return 'Yes';
        }
        return null;
    }
    private Boolean ualNameAddressChange(Utility_Account_Log__c ual, Utility_Data_Request__c udr) {
        // returns true if there is no difference between the UDR and UAL addresses
        // returns false if there is a difference between the UDR and UAL addresses
        String udrName = getComparisonString(udr.Customer_Name__c);
        String udrAddress1 = getComparisonString(udr.Address_Line_1__c);
        String udrAddress2 = getComparisonString(udr.Address_Line_2__c);
        String udrAddress = udrAddress1 + udrAddress2;
        String udrCity = getComparisonString(udr.City__c);
        String udrState = getComparisonString(udr.State__c);
        String udrZip = getComparisonString(udr.Zip_Code__c);
        String ualName = getComparisonString(ual.Name_on_Account__c);
        String ualAddress = getComparisonString(ual.Service_Address__c);
        String ualCity = getComparisonString(ual.Service_City__c);
        String ualState = getComparisonString(ual.Service_State__c);
        String ualZip = getComparisonString(ual.Service_Zip_Code__c);
        if (udrName + '|' + udrAddress + '|' + udrCity + '|' + udrState + '|' + udrZip !=
            ualName + '|' + ualAddress + '|' + ualCity + '|' + ualState + '|' + ualZip) {
            ual.Address_Update__c = true;
        } else {
            return true;
        }
        ual.Previous_Name_on_Utility_Account__c = cleanString(ual.Name_on_Account__c);
        ual.Previous_Service_Address__c = cleanString(ual.Service_Address__c);
        ual.Previous_Service_City__c = cleanString(ual.Service_City__c);
        ual.Previous_Service_State__c = cleanString(ual.Service_State__c);
        ual.Previous_Service_Zip_Code__c = cleanString(ual.Service_Zip_Code__c);
        ual.Name_on_Account__c = cleanString(udr.Customer_Name__c);
        ual.Service_Address__c = cleanString(udr.Address_Line_1__c) + ' ' + cleanString(udr.Address_Line_2__c);
        ual.Service_City__c = cleanString(udr.City__c);
        ual.Service_State__c = cleanString(udr.State__c);
        ual.Service_Zip_Code__c = cleanString(udr.Zip_Code__c);
        return false;
    }
    private String getComparisonString(String str) {
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