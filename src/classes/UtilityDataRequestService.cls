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
    private static UALSelector ualSelector = new UALSelector();
    
    @SupressWarnings('PMD.ApexCRUDViolation')    
    public void updateUDRP(Map<Id,Utility_Data_Request__c> oldUDRMap, List<Utility_Data_Request__c> udrList) {
        
        Set<Id> udrIds = new Set<Id>();
        List<Utility_Data_Request__c> udrRecords = new List<Utility_Data_Request__c>();
        
        for (Utility_Data_Request__c udr : udrList) {
            if (udr.Request_Status__c == 'Complete' && oldUDRMap.get(udr.Id).Request_Status__c != 'Complete') {
                udrIds.add(udr.Id);
                udrRecords.add(udr);
            }
        }
        
        if(udrIds.size() > 0 && udrIds.size() == udrRecords.size()) {
            List<Utility_Data_Request_Period__c> updatedUDRPList = populateRateClassOnUDRP(udrIds);
            update updatedUDRPList;
            List<Utility_Account_Log__c> updatedUALList = populateRateClassOnUAL(udrRecords);
            update updatedUALList;
        }
        
    }
    
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
                Logger.logLater('UtilityDataRequestService', 'populateRateClassOnUDRP', 'Null Rate Class on UDRP' + udrp.Name);
            } else {
                Logger.logLater('UtilityDataRequestService', 'populateRateClassOnUDRP', 'No matching Rate Class record with an EDI Rate Class for the Rate Class text on UDRP ' + udrp.Name);
            }
        }
        
        Logger.flushLogs();
        
        return updatedUDRPList;
    }
    
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
                Logger.logLater('UtilityDataRequestService', 'populateRateClassOnUAL', 'Null Rate_Class_Lookup__c value for most recent UDRP related to UDR ' + udr.Name);
            }
        }
        
        Logger.flushLogs();
        
        return updatedUALList;
    }

}