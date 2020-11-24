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
        // Setup trigger context, retrieve data
        setupTriggerContext();
        if(!completedUDRMap.isEmpty()) {
            beforeUpdateUDR();
        }
    }
    /**
     * Method used when a UDR record status is updated to 'Complete' from previously being something else
     * <p></p>
     * Handles related UDRP and UAL modifications
     */
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public void afterStatusUpdatedToComplete() {
        // Setup trigger context, retrieve data
        setupTriggerContext();
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
    @TestVisible
    private void beforeUpdateUDR(){
        Map<Id, udrObject> udrObjectMap = new Map<Id, udrObject>();
        for(Id udrId : udrToUdrpMap.keySet()){
            udrObject currentUDR = new udrObject(udrId);
            for(Utility_Data_Request_Period__c udrp : udrToUdrpMap.get(udrId)) {
                if(udrp.Measurement_Significance_Code__c == '51' && udrp.Measurement_Unit__c == 'KH') {
                    currentUDR.addUdrpKH(udrp);
                } else if(udrp.Measurement_Significance_Code__c == '51' && udrp.Measurement_Unit__c == 'K1') {
                    currentUDR.addUdrpK1(udrp);
                }
            }
            udrObjectMap.put(udrId, currentUDR);
        }
        //Need to get map of new UDRs with specific query criteria needed for the kWh calculation
        Map<Id, Utility_Data_Request__c> udrMap = udrSelector.selectMapForKWHById(completedUDRMap.values());
        for(Utility_Data_Request__c udr : completedUDRMap.values()) {
            Utility_Data_Request__c currentUDR = udrMap.get(udr.Id);
            udrObject currentUdrObject = udrObjectMap.get(udr.Id);

            if(currentUdrObject != null) {
                Double kWhNumMonths = currentUdrObject.getListKH().size();

            Double updatedAnnualkWh = getAnnualkWh(currentUDR, currentUdrObject.getListKH());
            currentUDR.Annual_kWh__c = updatedAnnualkWh;
                Double demandNumMonths = currentUdrObject.getListK1().size();
            Double updatedAverageDemand = getAverageDemand(currentUDR, currentUdrObject.getListK1());
            udr.Annual_kWh__c = updatedAnnualkWh;
            udr.Num_months_Annual_kWh__c = kWhNumMonths;
                udr.Average_Demand__c = updatedAverageDemand;
            udr.Num_months_Average_Demand__c = demandNumMonths;

            }         

        }
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
        Decimal kWh = 0;
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
        kWh = kWh.setScale(2);
        return kWh.doubleValue();
    }
    /**
     * @description Calculates the number for the Average Demand field for a UDR and its related UAL.
     * Used the same basic logic as the getAnnualkWh method
     */
    @TestVisible
    private Double getAverageDemand(Utility_Data_Request__c udr, List <Utility_Data_Request_Period__c> udrpList) { 
        Decimal avgDemand = 0;
        Integer numUDRP = udrpList.size();
        if (numUDRP >= 12) {
            for (Integer i=0; i<12; i++) {
                avgDemand = avgDemand + udrpList[i].Quantity__c;
                udrpList[i].Used_In_Average_Demand_Calculation__c = true;
            }
            avgDemand = avgDemand/12;
        } else if (numUDRP < 12 && numUDRP > 0) {
            for (Integer i=0; i<numUDRP; i++) {
                avgDemand = avgDemand + udrpList[i].Quantity__c;
                udrpList[i].Used_In_Average_Demand_Calculation__c = true;
            }
            avgDemand = avgDemand/numUDRP;
        }
        update udrpList;
        avgDemand = avgDemand.setScale(2);
        return avgDemand.doubleValue();
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
            populateFieldsOnUAL(ual, completedUDRMap.get(udrId));
        }
        // Register work
        uow.registerDirty(ualMap.values());
    }
    /**
     * @description Populates the UDRP.Rate_Class_Lookup__c where 
     * the Rate Class object's EDI_Rate_Class__c text matches the UDRP's Rate_Subclass__c text.
     */
    @TestVisible
    private List<Utility_Data_Request_Period__c> populateRateClassOnUDRP(Id udrId) {
        List<Utility_Data_Request_Period__c> udrpList = udrToUdrpMap.get(udrId);

        if(udrpList != null) {

        for (Integer i=0; i<udrpList.size(); i++) {
            String rateSubclass = udrpList[i].Rate_Subclass__c;
            if (rateSubclass != null && rateClassWithEDIMap.containsKey(rateSubclass)
                && udrpList[i].Utility_Data_Request__r.Utility__c == rateClassWithEDIMap.get(rateSubclass).Utility__c) {
                    Id rateClassId = rateClassWithEDIMap.get(rateSubclass).Id;
                    udrpList[i].Rate_Class_Lookup__c = rateClassId;
                    if (i == 0) {
                        // First UDRP (most recent service date) is what we use for Rate Class lookup elsewhere
                        udrToRateClassMap.put(udrId, rateClassId);
                    }
            } else if (rateSubclass == null) {
                Logger.logLater('UtilityDataRequestService', 'populateRateClassOnUDRP', 'Null Rate Subclass on ' + udrpList[i].Name);
            } else {
                String message = 'No matching Rate Class record with an EDI_Rate_Class__c that matches the Rate_Subclass__c on ' + udrpList[i];
                Logger.logLater('UtilityDataRequestService', 'populateRateClassOnUDRP', message);
            }
        }
        return udrpList;
    }

        return new List<Utility_Data_Request_Period__c>();
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
    private void populateFieldsOnUAL(Utility_Account_Log__c ual, Utility_Data_Request__c udr) {
        ual.Annual_kWh__c = udr.Annual_kWh__c;
        ual.Average_Demand__c = udr.Average_Demand__c;
        ual.Num_months_Annual_kWh__c = udr.Num_months_Annual_kWh__c;
        ual.Num_months_Average_Demand__c = udr.Num_months_Average_Demand__c;
        if(udr.Government_Credit_Code__c == 'N') {
            ual.NYPA__c = 'No';
        } else if(udr.Government_Credit_Code__c == 'Y') {
            ual.NYPA__c = 'Yes';
        }
        if(udr.LDC_Customer_Eligibility__c == 'N') {
            ual.RNY__c = 'No';
        } else if(udr.LDC_Customer_Eligibility__c == 'Y') {
            ual.RNY__c = 'Yes';
        }
        Boolean addressStatus = ualNameAddressChange(ual, udr);
        if(ual.NYPA__c == 'Yes' || ual.RNY__c == 'Yes') {
            ual.QC_Status__c = 'Pending BW Review';
        } else if(addressStatus) {
            ual.QC_Status__c = 'Complete';
        } else if(!addressStatus) {
            ual.QC_Status__c = 'Pending BW Review';
        }
    }
    @TestVisible
    private boolean ualNameAddressChange(Utility_Account_Log__c ual, Utility_Data_Request__c udr) {
        // returns true if there's no difference
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
        if(udrName != ualName) {
            ual.Address_Update__c = true;
        } else if(udrAddress != ualAddress) {
            ual.Address_Update__c = true;
        } else if(udrCity != ualCity) {
            ual.Address_Update__c = true;
        } else if(udrState != ualState) {
            ual.Address_Update__c = true;
        } else if(udrZip != ualZip) {
            ual.Address_Update__c = true;
        }
        if(ual.Address_Update__c == false) {
            return true;
        } else {
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
    }
    @TestVisible
    private String getComparisonString(String str) {
        if(str == 'null' || str == null) {
            return '';
        } else {
            str = str.replaceAll('\\s+','');
        	str = str.replaceAll('[^a-zA-Z0-9]','');
            str = str.toUpperCase();
        	return str;
        }
    }
    @TestVisible
    private String cleanString(String str) {
        if(str == 'null' || str == null) {
            return '';
        } else {
            return str;
        }
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
    @TestVisible
    private Utility_Account_Log__c getUalForCompletedUdr(Id udrId) {
        return ualMap.get(completedUDRMap.get(udrId).Utility_Account_Log__c);
    }
    @TestVisible
    private Id getRateClassForCompletedUdr(Id udrId) {
        return udrToRateClassMap.get(udrId);
    }
    public class udrObject {
    	private Id udrId;

    	private List<Utility_Data_Request_Period__c> listKH;
    	private List<Utility_Data_Request_Period__c> listK1;

        public udrObject(Id udrId) {
            this.udrId = udrId;
            this.listKH = new List<Utility_Data_Request_Period__c>();
            this.listK1 = new List<Utility_Data_Request_Period__c>();
        }
        public void addUdrpKH(Utility_Data_Request_Period__c udrp) {
            listKH.add(udrp);
        }
        public void addUdrpK1(Utility_Data_Request_Period__c udrp) {
            listK1.add(udrp);
        }
        public List<Utility_Data_Request_Period__c> getListKH() {
            return this.listKH;
        }
        public List<Utility_Data_Request_Period__c> getListK1() {
            return this.listK1;
        }
	}
}