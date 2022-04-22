/**
 * @description Created by: Kristin White on 9/28/2020
 * Tested by: UtilityDataRequestServiceTest
 */
@SuppressWarnings('ApexDocValidation')
public without sharing class UtilityDataRequestService {

    /* STATIC PROPERTIES */
    @TestVisible private static RateClassesSelector rateClassesSelector = new RateClassesSelector();
    @TestVisible private static UtilityDataRequestPeriodSelector udrpSelector = new UtilityDataRequestPeriodSelector();
    @TestVisible private static UtilityDataRequestSelector udrSelector = new UtilityDataRequestSelector();

    /* INSTANCE PROPERTIES */
    @TestVisible private Map<Id, Utility_Data_Request__c> completedUDRMap = new Map<Id, Utility_Data_Request__c>();
    @TestVisible private Set<Id> erroredUtilityDataRequestIds = new Set<Id>();
    @TestVisible private Map<Id, Utility_Data_Request__c> newUDRMap;
    @TestVisible private Map<Id, Utility_Data_Request__c> oldUDRMap;
    @TestVisible private List<Utility_Data_Request__c> newUdrRecords;
    @TestVisible private Map<String, Rate_Class__c> rateClassWithEDIMap;
    @TestVisible private Map<Id, Id> udrToRateClassMap = new Map<Id, Id>();
    @TestVisible private Map<Id, List<Utility_Data_Request_Period__c>> completedUDRToUdrpMap;
    @TestVisible private fflib_SObjectUnitOfWork uow;

    /**
     * @description Constructor for service class instance
     * @param oldUDRMap Trigger.oldMap
     * @param newUDRMap Trigger.newMap
     * @param newUdrs
     */
    public UtilityDataRequestService(Map<Id, Utility_Data_Request__c> oldUDRMap, Map<Id, Utility_Data_Request__c> newUDRMap, List<Utility_Data_Request__c> newUdrs) {
        this.oldUDRMap = oldUDRMap;
        this.newUDRMap = newUDRMap;
        this.newUdrRecords = newUdrs;
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
        } catch (Exception e) {
            String message = 'Unable to commit work before completion of UDRs: ' + completedUDRMap.keySet().toString()
                + '\n\n' + e.getMessage() + '\n\n' + e.getStackTraceString();
            Logger.logLater('UtilityDataRequestService', 'beforeStatusUpdatedToComplete', message);
        }
        Logger.flushLogs();
    }

    public void beforeUDRInsert() {
        checkExistingUDR();
    }

    public void checkExistingUDR() {
        Set<Id> ualIdset = new Set<Id>();
        for (Utility_Data_Request__c req : newUdrRecords) {
                ualIdset.add(req.Utility_Account_Log__c);
        }
        Map<Id, Utility_Data_Request__c> existingUDRMap = new Map<Id, Utility_Data_Request__c>();
        if (ualIdset.size() > 0) {
            for (Utility_Data_Request__c udr : UtilityDataRequestSelector.getRelatedUdrsByUal(ualIdset)) {
                existingUDRMap.put(udr.Utility_Account_Log__c, udr);
            }
        }
        for (Utility_Data_Request__c newUdr : newUdrRecords) {
            if (!existingUDRMap.isEmpty() && existingUDRMap.containsKey(newUdr.Utility_Account_Log__c)) {
                newudr.addError('There is an open UDR for this UAL. Please wait for response before creating a new UDR or close the existing open UDR');
            }
        }
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
        } catch (Exception e) {
            String message = 'Unable to commit work on completion of UDRs: ' + completedUDRMap.keySet().toString()
                + '\n\n' + e.getMessage() + '\n\n' + e.getStackTraceString();
            Logger.logLater('UtilityDataRequestService', 'afterStatusUpdatedToComplete', message);
        }
        Logger.flushLogs();
    }

    /**
     * @description Uses CaseFactory to insert QC Cases for EDI transactions resulting in 'Error' status
     */
    public void openErrorCasesIfEncountered() {
        for (Utility_Data_Request__c udr : newUDRMap.values()) {
            if (udr.Request_Status_new__c == 'Error' && oldUDRMap.get(udr.Id).Request_Status_new__c != 'Error') {
                erroredUtilityDataRequestIds.add(udr.Id);
            }
        }
        if (!erroredUtilityDataRequestIds.isEmpty()) {
            CaseFactory caseFactory = new CaseFactory();
            caseFactory.erroredUtilityDataRequestIds = erroredUtilityDataRequestIds;
            caseFactory.setQueueType('EDI Error');
            System.enqueueJob(caseFactory);
        }
    }

    private void setupTriggerContext() {
        // Instance UOW
        uow = new fflib_SObjectUnitOfWork(
            new List<SObjectType>{
                Utility_Data_Request_Period__c.getSObjectType(),
                Utility_Account_Log__c.getSObjectType()
            }
        );
        // Map completed UDRs for further processing if criteria is met
        Map<Id, Utility_Data_Request__c> udrsWithServiceProviders = udrSelector.selectMapForKWHById(newUDRMap.values());
        for (Utility_Data_Request__c udr : newUDRMap.values()) {
            if (udr.Request_Status_new__c == 'Complete' &&
                oldUDRMap.get(udr.Id).Request_Status_new__c != 'Complete' &&
                udrsWithServiceProviders.get(udr.Id)?.Service_Provider__c != 'Glynt') // Ignore Glynt UDRs, handled elsewhere
            {
                completedUDRMap.put(udr.Id, udr);
            }
        }
        // Retrieve Rate Classes, UDR->UDRPs, and UALs for Completed UDRs
        rateClassWithEDIMap = rateClassesSelector.selectWithEDI();
        completedUDRToUdrpMap = udrpSelector.selectByUDR(completedUDRMap.keySet());
    }

    private void setAnnualkWhAndAvgDemandOnUDRs() {
        Map<Id, UDRWrapper> udrObjectMap = new Map<Id, UDRWrapper>();
        for (Id udrId : completedUDRToUdrpMap.keySet()) {
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
        UtilityAccountLogs uals = new UtilityAccountLogs(completedUDRMap, udrToRateClassMap);
        uals.updateOnEDIRequestComplete();
        uow.registerDirty(uals.getSObjects());
    }

    /**
     * @description Populates the UDRP.Rate_Class_Lookup__c where
     * the Rate Class object's EDI_Rate_Class__c text matches the UDRP's Rate_Subclass__c text.
     * @param udrId
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
}