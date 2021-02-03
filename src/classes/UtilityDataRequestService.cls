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
            if (udr.Request_Status_new__c == 'Complete' && oldUDRMap.get(udr.Id).Request_Status_new__c != 'Complete') {
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

        Map<Id, UDRWrapper> udrObjectMap = new Map<Id, UDRWrapper>();
        for(Id udrId : udrToUdrpMap.keySet()){
            UDRWrapper currentUDR = new UDRWrapper(udrId);
            orderUDRPs(currentUDR, udrId);
            udrObjectMap.put(udrId, currentUDR);
        }
        //Need to get map of new UDRs with specific query criteria needed for the kWh calculation
        Map<Id, Utility_Data_Request__c> udrMap = udrSelector.selectMapForKWHById(completedUDRMap.values());

        calcFieldValuesUDR(udrObjectMap, udrMap);
    }
    
    private void calcFieldValuesUDR(Map<Id, UDRWrapper> udrObjectMap, Map<Id, Utility_Data_Request__c> udrMap) {

        for(Utility_Data_Request__c udr : completedUDRMap.values()) {
            Utility_Data_Request__c currentUDR = udrMap.get(udr.Id);

            UDRWrapper currentUdrObject = udrObjectMap.get(udr.Id);

            if(currentUdrObject != null) {

                UDRPTotalHelper kWhHelper = getAnnualkWh(currentUDR, currentUdrObject.getListKH());
                udr.Annual_kWh__c = kWhHelper.kWh;
                udr.Num_UDRPs_Annual_kWh__c = kWhHelper.numUDRP;
                
                UDRPTotalHelper avgDemandHelper = getAverageDemand(currentUdrObject.getListK1());
                udr.Average_Demand__c = avgDemandHelper.avgDemand;
                udr.Num_UDRPs_Avg_Demand__c = avgDemandHelper.numUDRP;
            }         
        }
    }
    
    private void orderUDRPs(UDRWrapper currentUDR, Id udrId) {
        for(Utility_Data_Request_Period__c udrp : udrToUdrpMap.get(udrId)) {
            placeUDRP(currentUDR, udrp);

                }
    }

    private void placeUDRP(UDRWrapper currentUDR, Utility_Data_Request_Period__c udrp) {
        if(udrp.Measurement_Unit__c == 'KH' && udrp.Measurement_Significance_Code__c == '51') {
            currentUDR.addUdrpKH51(udrp);
        } else if(udrp.Measurement_Unit__c == 'KH' && (udrp.Measurement_Significance_Code__c == '41' || udrp.Measurement_Significance_Code__c == '42' || udrp.Measurement_Significance_Code__c == '43')){
            currentUDR.addUdrpKH40s(udrp);
        } else if(udrp.Measurement_Unit__c == 'K1' && udrp.Measurement_Significance_Code__c == '51') {
            currentUDR.addUdrpK151(udrp);
        } else if(udrp.Measurement_Unit__c == 'K1' && (udrp.Measurement_Significance_Code__c == '42' || udrp.Measurement_Significance_Code__c == '49')) {
            currentUDR.addUdrpK140s(udrp);
        }
    }

    
    private UDRPTotalHelper getAnnualkWh(Utility_Data_Request__c udr, List <Utility_Data_Request_Period__c> udrpList) { 
        UDRPTotalHelper udrpTotalHelper = new UDRPTotalHelper();
        String customerType = udr.Utility_Account_Log__r.Lead__r.Customer_type__c;
        
        if(udrpList.size() == 0) {
            return udrpTotalHelper;
        }
        
        for(Utility_Data_Request_Period__c udrp : udrpList){
            if(udrpTotalHelper.updateUDRPTotals(udrp, udrpList, Schema.Utility_Data_Request_Period__c.Used_in_Annual_kWh_Calculation__c)) {
                break;

        }
    }
        udrpTotalHelper.updatekWh(customerType, udr);
        update udrpList;
        return udrpTotalHelper;
    }
    
    private UDRPTotalHelper getAverageDemand(List <Utility_Data_Request_Period__c> udrpList) { 
        UDRPTotalHelper udrpTotalHelper = new UDRPTotalHelper();
        
        if(udrpList.size() == 0) {
            return udrpTotalHelper;
        }
        
        for(Utility_Data_Request_Period__c udrp : udrpList){
            if(udrpTotalHelper.updateUDRPTotals(udrp, udrpList, 
                                                Schema.Utility_Data_Request_Period__c.Used_in_Average_Demand_Calculation__c)) {
                break;
            }

        }
        udrpTotalHelper.avgDemand = (udrpTotalHelper.quantity/udrpTotalHelper.days)*30;
        udrpTotalHelper.avgDemand = udrpTotalHelper.avgDemand.setScale(2);
        update udrpList;
        return udrpTotalHelper;
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
        if(udrpList == null) {
            return new List<Utility_Data_Request_Period__c>();
                    }
        Boolean firstKH = false;
        for(Utility_Data_Request_Period__c udrp : udrpList) {
            String rateSubclass = udrp.Rate_Subclass__c;
            String rateClass = udrp.Rate_Class__c;
            udrp.Rate_Class_Lookup__c = setRateClassLookupOnUDRP(rateSubclass, rateClass, udrp);
            if (!firstKH && udrp.Measurement_Unit__c == 'KH') {
                // Only the first UDRP (most recent service date) where the Measurement_Unit is KH, is what we use for Rate Class lookup elsewhere
                udrToRateClassMap.put(udrId, udrp.Rate_Class_Lookup__c);
                firstKH = true;
            }
        }
        return udrpList;
    }
    private Id setRateClassLookupOnUDRP(String rateSubclass, String rateClass, Utility_Data_Request_Period__c udrp) {
        if(rateSubclass !=null && rateClassWithEDIMap.containsKey(rateSubclass) && (udrp.Utility_Data_Request__r.Utility__c == rateClassWithEDIMap.get(rateSubclass).Utility__c)) {
            return rateClassWithEDIMap.get(rateSubclass).Id;
        } else if(rateClass != null && rateClassWithEDIMap.containsKey(rateClass) && (udrp.Utility_Data_Request__r.Utility__c == rateClassWithEDIMap.get(rateClass).Utility__c)) {
            return rateClassWithEDIMap.get(rateClass).Id;
        } else if (rateSubclass == null && rateClass == null) {
            Logger.logLater('UtilityDataRequestService', 'populateRateClassOnUDRP', 'Null Rate Subclass & Rate Class on ' + udrp.Name, Logger.INFO);
        } else {
            String message = 'No matching Rate Class record with an EDI_Rate_Class__c that matches the Rate_Subclass__c or Rate_Class__c on ' + udrp;
            Logger.logLater('UtilityDataRequestService', 'populateRateClassOnUDRP', message);
        }
        return null;
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
            String message = 'UAL Rate Class could not be populated because there is a ' + 
                'null Rate_Class_Lookup__c for the most recent UDRP, where the Measurement Unit is KH, related to UDR ' + udrId;
            Logger.logLater('UtilityDataRequestService', 'populateRateClassOnUAL', message);
        }
    }
    @TestVisible
    private void populateFieldsOnUAL(Utility_Account_Log__c ual, Utility_Data_Request__c udr) {
        ual.Annual_kWh__c = udr.Annual_kWh__c;
        ual.Average_Demand__c = udr.Average_Demand__c;

        ual.Num_UDRPs_Annual_kWh__c = udr.Num_UDRPs_Annual_kWh__c;
        ual.Num_UDRPs_Avg_Demand__c = udr.Num_UDRPs_Avg_Demand__c;
        

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
        // returns true if there is no difference between the UDR and UAL addresses
        // returns flase if there is a difference between the UDR and UAL addresses
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
        // If the UAL has multiple bills and is getting data via Glynt, we might need to make multiple UDRs, one for each
        // bill. That way, Glynt can extract the data from each bill, which Salesforce can process further downstream
        // Until then, if there are multiple attachments, GlyntUploadService will upload all of them, extract all of them,
        // and write all of the data back to the single UDR.
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
            Header_Status__c        = 'Pending',
            Detail_Status__c        = 'Pending',
            Premise_Number__c       = ual.Premise_Number__c,
            Service_Provider__c = ual.Utility_lookup__r.Use_Glynt__c?'Glynt':'ESG'
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

    public class UDRWrapper {
    	private Id udrId;
    	private List<Utility_Data_Request_Period__c> listKH51;
        private List<Utility_Data_Request_Period__c> listKH40s;
    	private List<Utility_Data_Request_Period__c> listK151;
        private List<Utility_Data_Request_Period__c> listK140s;
        public UDRWrapper(Id udrId) {

            this.udrId = udrId;
            this.listKH51 = new List<Utility_Data_Request_Period__c>();
            this.listKH40s = new List<Utility_Data_Request_Period__c>();
            this.listK151 = new List<Utility_Data_Request_Period__c>();
            this.listK140s = new List<Utility_Data_Request_Period__c>();
        }

        
        public void addUdrpKH51(Utility_Data_Request_Period__c udrp) {
            listKH51.add(udrp);
        }
        
        public void addUdrpKH40s(Utility_Data_Request_Period__c udrp) {
            listKH40s.add(udrp);

        }
        public void addUdrpK151(Utility_Data_Request_Period__c udrp) {
            listK151.add(udrp);
        }
        public void addUdrpK140s(Utility_Data_Request_Period__c udrp) {
            listK140s.add(udrp);
        }
        public List<Utility_Data_Request_Period__c> getListKH() {
            if(this.listKH51.size() > 0) {
                return this.listKH51;
            } else{
                return this.listKH40s;
            }
        }
        public List<Utility_Data_Request_Period__c> getListK1() {
            if(this.listK151.size() > 0) {
                return this.listK151;
            } else{
                return this.listK140s;
            }
        }
	}
    
    public class UDRPTotalHelper {
        private Integer numUDRP = 0;
        private Decimal days = 0;
        private Decimal quantity = 0;
        Decimal kWh = 0;
        Decimal avgDemand = 0;
        
        private void updatekWh(String customerType, Utility_Data_Request__c udr) {
            if(days>=120 || (customerType == 'Residential' && customerType!= null)){
                kWh=(quantity/days)*365;
            }else if ((days > 0) && (customerType != 'Residential' && customerType != null)){
                String sizingMethod = udr.Utility_Account_Log__r.Lead__r.Product__r.X4_month_sizing_method__c;
                if (sizingMethod == 'State Average Annual Usage') {
                    State__c state = stateSelector.selectByName(udr.Utility_Account_Log__r.Service_State__c);                    
                    kWh = state.Avg_Annual_Resi_kWh__c;
                } 
                //additional sizingMethods will be added later
            }
            kWh = kWh.setScale(2);
        }
        
        private Boolean updateUDRPTotals(Utility_Data_Request_Period__c udrp, List <Utility_Data_Request_Period__c> udrpList, SObjectField fieldToUpdate) {
            Decimal potentialNumDaysWithUDRP = days + udrp.Num_Days__c;
            
            if(potentialNumDaysWithUDRP == 365){
                includeUDRP(udrp, fieldToUpdate);
                return true;
            }else if(potentialNumDaysWithUDRP < 365){
                includeUDRP(udrp, fieldToUpdate);
                return false;
            }else if((365 - days) > (potentialNumDaysWithUDRP - 365)){
                includeUDRP(udrp, fieldToUpdate);
                return true;
            }else if((365 - days) < (potentialNumDaysWithUDRP - 365)){
                return true;
            }
            return true;
        }
        
        private void includeUDRP(Utility_Data_Request_Period__c udrp, SObjectField fieldToUpdate) {
            udrp.put(fieldToUpdate, true);
            numUDRP++;
            days = days + udrp.Num_Days__c;
            quantity = quantity + udrp.Quantity__c;
        }
        
    }
    
}