/**
 * Created by: Kristin White on 9/28/2020
 * 
 * Test: UtilityDataRequestServiceTest
 * 
 */

public without sharing class UtilityDataRequestService {
    
    @TestVisible
    private static RateClassesSelector rateClassesSelector = new RateClassesSelector();
    @TestVisible
    private static UtilityDataRequestPeriodSelector udrpSelector = new UtilityDataRequestPeriodSelector();
    @TestVisible
    private static UtilityDataRequestSelector udrSelector = new UtilityDataRequestSelector();
    @TestVisible
    private static UALSelector ualSelector = new UALSelector();
    @TestVisible
    private static StateSelector stateSelector = new StateSelector();
        
    @SupressWarnings('PMD.ApexCRUDViolation')    
    public void afterStatusUpdatedToComplete(Map<Id,Utility_Data_Request__c> oldUDRMap, List<Utility_Data_Request__c> udrList) {
        
        Set<Id> udrIds = new Set<Id>();
        List<Utility_Data_Request__c> udrRecords = new List<Utility_Data_Request__c>();
        
        //Only want to update the Rate Classes if the Status updated from something else to Complete
        //Loops through the new udrList and takes the UDRs where the status updated to Complete
        for (Utility_Data_Request__c udr : udrList) {
            if (udr.Request_Status__c == 'Complete' && oldUDRMap.get(udr.Id).Request_Status__c != 'Complete') {
                udrIds.add(udr.Id);
                udrRecords.add(udr);
            }
        }
        
        if(udrIds.size() > 0 && udrIds.size() == udrRecords.size()) {
            List<Utility_Data_Request_Period__c> updatedUDRPRateClassList = populateRateClassOnUDRP(udrIds);
            update updatedUDRPRateClassList;
            List<Utility_Account_Log__c> updatedUALRateClassList = populateRateClassOnUAL(udrRecords);
            update updatedUALRateClassList;
        }
        
    }
    
    /**
     * @description Populates the UDRP.Rate_Class_Lookup__c where 
     * the Rate Class object's EDI_Rate_Class__c text matches the UDRP's Rate_Class__c text.
     * 
     */
    private List<Utility_Data_Request_Period__c> populateRateClassOnUDRP(Set<Id> udrIdSet) {
        
        List<Utility_Data_Request_Period__c> updatedUDRPList = new List<Utility_Data_Request_Period__c>();
        
        List<Utility_Data_Request_Period__c> udrpList = udrpSelector.selectByUDR(udrIdSet);
        Map<String, Rate_Class__c> rateClassWithEDIMap = rateClassesSelector.selectWithEDI();
        
        for(Utility_Data_Request_Period__c udrp : udrpList) {
            if(udrp.Rate_Class__c != null 
               && rateClassWithEDIMap.containsKey(udrp.Rate_Class__c) 
               && udrp.Utility_Data_Request__r.Utility__c == rateClassWithEDIMap.get(udrp.Rate_Class__c).Utility__c){
                udrp.Rate_Class_Lookup__c = rateClassWithEDIMap.get(udrp.Rate_Class__c).Id;
                updatedUDRPList.add(udrp);
            } else if(udrp.Rate_Class__c == null) {
                Logger.logLater('UtilityDataRequestService', 'populateRateClassOnUDRP', 'Null Rate Class on ' + udrp.Name);
            } else {
                Logger.logLater('UtilityDataRequestService', 'populateRateClassOnUDRP', 'No matching Rate Class record with an EDI Rate Class for the Rate Class text on ' + udrp.Name);
            }
        }
        
        Logger.flushLogs();
        
        return updatedUDRPList;
    }
    
    /**
     * @description Populates the UAL.Utility_Rate_Class__c (lookup to Rate Class) with 
     * the most recent UDRP's Rate_Class_Lookup__c where the Rate_Class_Lookup__c is not null.
     * 
     * Note: A UDR has a lookup to a UAL, and a UDRP has a lookup to a UDR.
     */
    private List<Utility_Account_Log__c> populateRateClassOnUAL(List<Utility_Data_Request__c> udrRecords) {
        List<Utility_Account_Log__c> updatedUALList = new List<Utility_Account_Log__c>();
        
        for (Utility_Data_Request__c udr : udrRecords) {
            
            Set<Id> tempUDRId = new Set<Id>();
            tempUDRId.add(udr.Id);
            
            List<Utility_Data_Request_Period__c> tempUDRPList = udrpSelector.selectByUDR(tempUDRId);
            Utility_Account_Log__c tempUAL = ualSelector.selectByUDR(udr);
            
            if(tempUDRPList[0].Rate_Class_Lookup__c != null && udr.Utility_Account_Log__c != null) {
                tempUAL.Utility_Rate_Class__c = tempUDRPList[0].Rate_Class_Lookup__r.Id;
                updatedUALList.add(tempUAL);
            } else {
                Logger.logLater('UtilityDataRequestService', 'populateRateClassOnUAL', 'Null Rate_Class_Lookup__c value for most recent UDRP related to ' + udr.Name);
            }
        }
        
        Logger.flushLogs();
        
        return updatedUALList;
    }
    
    /**
     * @description Populates the UDR.Annual_kWh and the UAL.Annual_kWh with the value calculated in the getAnnualkWh method.
     * Only want to update where the UDR Request Status is being updated to Complete from something else.
     */
    @SupressWarnings('PMD.ApexCRUDViolation')    
    public void beforeStatusUpdatedToComplete(Map<Id,Utility_Data_Request__c> oldUDRMap, List<Utility_Data_Request__c> newUDRList, Map<Id,Utility_Data_Request__c> newUDRMap) {
        //Need to create a map of UDR Ids to a list of UDRPs related to that UDR where the measurement unit is 'KH'
        Map<Id, List<Utility_Data_Request_Period__c>> udrMapToUDRP = new Map<Id, List<Utility_Data_Request_Period__c>>();
        List<Utility_Data_Request_Period__c> udrpList = udrpSelector.selectWithKHByUDR(newUDRList);
        
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
        Map<Id, Utility_Data_Request__c> udrMap = udrSelector.selectMapForKWHById(newUDRList);
        List<Utility_Account_Log__c> updatedUALList = new List<Utility_Account_Log__c>();
        
        for (Utility_Data_Request__c udr : newUDRList) {
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
            kWh = (kWh/4)*12;
        } else if (numUDRP < 4 && numUDRP > 0) { 
            String customerType = udr.Utility_Account_Log__r.Lead__r.Customer_type__c;
            if (customerType == 'Residential' && customerType!= null) {
                for(Integer i=0; i<numUDRP; i++) {
                	kWh = kWh + udrpList[i].Quantity__c;
                    udrpList[i].Used_In_Annual_kWh_Calculation__c = true;
            	}
            	kWh = (kWh/4)*12;
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
    
}