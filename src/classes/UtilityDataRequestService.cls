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
    @TestVisible private Map<Id,Utility_Account_Log__c> ualMap;
    @TestVisible private Map<Id,Id> udrToRateClassMap = new Map<Id,Id>();
    @TestVisible private Map<Id,List<Utility_Data_Request_Period__c>> udrToUdrpMap;
    @TestVisible private fflib_SObjectUnitOfWork uow;

    @TestVisible private static RateClassesSelector rateClassesSelector = new RateClassesSelector();
    @TestVisible private static UtilityDataRequestPeriodSelector udrpSelector = new UtilityDataRequestPeriodSelector();
    @TestVisible private static UtilityDataRequestSelector udrSelector = new UtilityDataRequestSelector();
    @TestVisible private static UALSelector ualSelector = new UALSelector();
    @TestVisible private static StateSelector stateSelector = new StateSelector();


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
    @SuppressWarnings('PMD.ApexCRUDViolation')

    public void beforeStatusUpdatedToComplete() {
        //Need to create a map of UDR Ids to a list of UDRPs related to that UDR where the measurement unit is 'KH'
        Map<Id, List<Utility_Data_Request_Period__c>> udrMapToUDRP = new Map<Id, List<Utility_Data_Request_Period__c>>();
        List<Utility_Data_Request_Period__c> udrpList = udrpSelector.selectWithKHByUDR(newUDRMap.values());

        for(Utility_Data_Request_Period__c udrp : udrpList) {
            if(udrMapToUDRP.keySet().contains(udrp.Utility_Data_Request__c)) {
                udrMapToUDRP.get(udrp.Utility_Data_Request__c).add(udrp);
            } else {
                List<Utility_Data_Request_Period__c> tempUDRPList = new List<Utility_Data_Request_Period__c>();
                tempUDRPList.add(udrp);
                udrMapToUDRP.put(udrp.Utility_Data_Request__c, tempUDRPList);
            }
        }
        //Need to get map of new UDRs with specific query criteria needed for the kWh calculation
        Map<Id,Utility_Data_Request__c> udrMap = udrSelector.selectMapForKWHById(newUDRMap.values());
        List<Utility_Account_Log__c> updatedUALList = new List<Utility_Account_Log__c>();

        for (Utility_Data_Request__c udr : newUDRMap.values()) {

            if (udr.Request_Status__c == 'Complete' && oldUDRMap.get(udr.Id).Request_Status__c != 'Complete') {
                Utility_Data_Request__c udrRecord = udrMap.get(udr.Id);
                List <Utility_Data_Request_Period__c> udrRecordUDRP = udrMapToUDRP.get(udrRecord.Id);
                Double updatedAnnualkWh = getAnnualkWh(udrRecord, udrRecordUDRP);
                udr.Annual_kWh__c = updatedAnnualkWh;
                Utility_Account_Log__c currentUAL = new Utility_Account_Log__c (
                Id = udr.Utility_Account_Log__c,
                Annual_kWh__c = updatedAnnualkWh
                );
                updatedUALList.add(currentUAL);
            }
        }
        update updatedUALList;
    }
    /**
     * Handler method for when UDR records are returned from Boomi as 'Complete'
     * <p></p>
     * Handles related UDRP and UAL modifications
     */
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public void afterStatusUpdatedToComplete() {
        // Setup after-trigger context, retrieve data
        setupAfterTriggerContext();
        // Perform actions
        if (!completedUDRMap.isEmpty()) {
            updateUDRP();
            updateUAL();
        }
        // Commit work
        try {
            uow.commitWork();
        } catch (Exception e ) {
            String message = 'Unable to commit work on completion of UDRs: ' + completedUDRMap.keySet().toString()
                + '\n\n' + e.getMessage() + '\n\n' + e.getStackTraceString();
            Logger.logLater('UtilityDataRequestService', 'afterStatusUpdatedToComplete', message);
        }
        Logger.flushLogs();
    }
    @TestVisible
    private void setupAfterTriggerContext() {
        // Instance UOW
        uow = new fflib_SObjectUnitOfWork(
            new List<SObjectType>{
                Utility_Data_Request_Period__c.getSObjectType(),
                Utility_Account_Log__c.getSObjectType()
            }
        );
        // Map completed UDRs for further processing
        for (Utility_Data_Request__c udr : newUDRMap.values()) {
            if (udr.Request_Status__c == 'Complete' && oldUDRMap.get(udr.Id).Request_Status__c != 'Complete') {
                completedUDRMap.put(udr.Id,udr);
            }
        }
        // Retrieve Rate Classes, UDR->UDRPs, and UALs for Completed UDRs
        if (!completedUDRMap.isEmpty()) {
            rateClassWithEDIMap = rateClassesSelector.selectWithEDI();
            udrToUdrpMap = udrpSelector.selectByUDR(completedUDRMap.keySet());
            ualMap = ualSelector.selectAllMap(
                CollectionUtil.mapByIdField(completedUDRMap.values(), Utility_Data_Request__c.Utility_Account_Log__c).keySet()
            );
        }
    }
    @TestVisible // Modify UDRPs
    private void updateUDRP() {
        // Only want to update the Rate Classes if the Status updated from something else to Complete
        List<Utility_Data_Request_Period__c> udrpsToUpdate = new List<Utility_Data_Request_Period__c>();
        for (Id udrId : completedUDRMap.keySet()) {
            udrpsToUpdate.addAll(populateRateClassOnUDRP(udrId));
        }
        uow.registerDirty(udrpsToUpdate);
    }
    @TestVisible // Modify UALs
    private void updateUAL() {
        for (Id udrId : completedUDRMap.keySet()) {
            Utility_Account_Log__c ual = getUalForCompletedUdr(udrId);
            Id rateClass = getRateClassForCompletedUdr(udrId);
            populateRateClassOnUAL(ual, rateClass, udrId);
            populateAddressNameOnUAL(ual);
        }
        // Register work
        uow.registerDirty(ualMap.values());
    }
    /**
     * @description Populates the UAL.Utility_Rate_Class__c (lookup to Rate Class) with 
     * the most recent UDRP's Rate_Class_Lookup__c where the Rate_Class_Lookup__c is not null.
     * 
     * Note: A UDR has a lookup to a UAL, and a UDRP has a lookup to a UDR.
     */
    @TestVisible
    private void populateRateClassOnUAL(Utility_Account_Log__c ual, Id udrpRateClass, Id udrId) {
        if (udrpRateClass != null) {
            ual.Utility_Rate_Class__c = udrpRateClass;
        } else {
            String message = 'Null Rate_Class_Lookup__c value for most recent UDRP related to ' + udrId;
            Logger.logLater('UtilityDataRequestService', 'populateRateClassOnUAL', message);
        }
    }
    @TestVisible
    private void populateAddressNameOnUAL(Utility_Account_Log__c ual) {
        // future state:
        // Utility_Account_Log__c ual = getUal(udrId);
        // ual.QC_Status__c = 'Complete';
        // ual.previous address = ual.address
        // ual.address = UDR.address
        // ual.previous name = ual.name
        // ual.name = udr.name
    }
    @TestVisible
    private Id getRateClassForCompletedUdr(Id udrId) {
        return udrToRateClassMap.get(udrId);
    }
    @TestVisible
    private Utility_Account_Log__c getUalForCompletedUdr(Id udrId) {
        return ualMap.get(completedUDRMap.get(udrId).Utility_Account_Log__c);
    }
    /**
     * @description Populates the UDRP.Rate_Class_Lookup__c where 
     * the Rate Class object's EDI_Rate_Class__c text matches the UDRP's Rate_Class__c text.
     */
    @TestVisible
    private List<Utility_Data_Request_Period__c> populateRateClassOnUDRP(Id udrId) {
        List<Utility_Data_Request_Period__c> udrpList = udrToUdrpMap.get(udrId);
        for (Integer i=0; i<udrpList.size(); i++) {
            String rateClass = udrpList[i].Rate_Class__c;
            if (rateClass != null && rateClassWithEDIMap.containsKey(rateClass)
                && udrpList[i].Utility_Data_Request__r.Utility__c == rateClassWithEDIMap.get(rateClass).Utility__c)
            {
                Id rateClassId = rateClassWithEDIMap.get(rateClass).Id;
                udrpList[i].Rate_Class_Lookup__c = rateClassId;
                if (i == 0) {
                    // First UDRP (most recent service date) is what we use for Rate Class lookup elsewhere
                    udrToRateClassMap.put(udrId, rateClassId);
                }
            } else if (rateClass == null) {
                Logger.logLater('UtilityDataRequestService', 'populateRateClassOnUDRP', 'Null Rate Class on ' + udrpList[i].Name);
            } else {
                String message = 'No matching Rate Class record with an EDI Rate Class for the Rate Class text on ' + udrpList[i];
                Logger.logLater('UtilityDataRequestService', 'populateRateClassOnUDRP', message);
            }
        }
        return udrpList;
    }
    /**
     * @description Calculates the number for the Annual kWh field for a UDR and its related UAL.
     * It needs the number of UDRPs for the given UDR where the UDRP.Measurement_Unit is 'KH', and finds the Annual kWh based on how many UDRPs there are.
     * 
     * If there are more than 12 UDRPs: it returns the sum of the UDRP.Quantity__c from the 12 most recent UDRPs.
     * 
     * If there are 11-4 UDRPs: it adds the UDRP.Quantity__c values, divides that by 4, and then multiplies it by 12.
     * 
     * If there are less than 4 UDRPs: it checkes to see if the UDR has a 'Residential' customer type.
     * 		Less than 4 and Residential - then it adds the UDRP.Quantity__c values, divides that by 4, and then multiplies it by 12.
     * 		Less than 4 and not Residential - it checks the ">4 month sizing method" picklist on the related Product to see how to calculate the field.
     * 				If the picklist value == 'Using State Usage'- it uses the Avg_Annual_Resi_kWh__c from the related State object.
     */
    @TestVisible
    private Double getAnnualkWh(Utility_Data_Request__c udr, List <Utility_Data_Request_Period__c> udrpList) { 
        Double kWh = 0;
        Integer numUDRP = udrpList.size();
        if (numUDRP >= 12) {
            for (Integer i=0; i<12; i++) {
                kWh = kWh + udrpList[i].Quantity__c;
                udrpList[i].Used_In_Annual_kWh_Calculation__c = true;
            }
        } else if (numUDRP < 12 && numUDRP >= 4) {
            for (Integer i=0; i<numUDRP; i++) {
                kWh = kWh + udrpList[i].Quantity__c;
                udrpList[i].Used_In_Annual_kWh_Calculation__c = true;
            }
            kWh = (kWh/numUDRP)*12;
        } else if (numUDRP < 4 && numUDRP > 0) { 
            String customerType = udr.Utility_Account_Log__r.Lead__r.Customer_type__c;
            if (customerType == 'Residential' && customerType!= null) {
                for(Integer i=0; i<numUDRP; i++) {
                	kWh = kWh + udrpList[i].Quantity__c;
                    udrpList[i].Used_In_Annual_kWh_Calculation__c = true;
            	}
            	kWh = (kWh/numUDRP)*12;
            } else if (customerType != 'Residential' && customerType != null){
                String sizingMethod = udr.Utility_Account_Log__r.Lead__r.Product__r.X4_month_sizing_method__c;
                if (sizingMethod == 'State Average Annual Usage') {
                    State__c state = stateSelector.selectByName(udr.Utility_Account_Log__r.Service_State__c);                    
                    kWh = state.Avg_Annual_Resi_kWh__c;
                }
            }
        }
        update udrpList;
        return kWh;
    }


    /**
     * Assesses if UDRs should be generated for passed-in lead ids based on Utility Data Collection Mechanism
     * <p></p>
     * This method will NOT generate UDRs if any existing are found and related to UALs
     * @param leadIds Leads to check for UDR creation
     * @author Jeff Parlin 10-28-20
     */
    @Future
    public static void create (List<String> leadIds) {
        UALSelector ualSelector = new UALSelector();
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
            new List<Schema.SObjectType> {Utility_Data_Request__c.SObjectType, Utility_Account_Log__c.SObjectType}
        );

        List<Utility_Account_Log__c> uals = ualSelector.selectUalsWithUdrs(leadIds);

        for (Utility_Account_Log__c ual : uals) {
            if (ual.Utility_Data_Requests__r.isEmpty()) {
                uow.registerNew(constructNewUDR(ual));
                ual.QC_Status__c = 'Pending Utility Data';
                uow.registerDirty(ual);
            }
        }


        try {
            uow.commitWork();
        } catch (Exception e) {
            String message = 'Unable to create UDRs or update UALs for Leads: '
                + leadIds.toString() + '\n\n' + e.getMessage() + '\n\n' + e.getStackTraceString();
            Logger.logNow('UtilityDataRequestService', 'create (@future)', message, 'Error');
        }
    }

    @TestVisible

    private static Utility_Data_Request__c constructNewUDR(Utility_Account_Log__c ual) {
        return new Utility_Data_Request__c(
            Account_Number__c       = ual.Name,
            Utility__c              = ual.Utility_lookup__c,
            Utility_DUNS__c         = ual.Utility_lookup__r.Utility_DUNS_Number__c,
            Utility_Name__c         = ual.Utility_lookup__r.Name,
            Utility_Account_Log__c  = ual.Id,
            Request_Status__c       = 'Pending'
        );
    }


}