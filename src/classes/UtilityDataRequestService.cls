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
    
    @SupressWarnings('PMD.ApexCRUDViolation')    
    public void updateUDRP(Map<Id,Utility_Data_Request__c> oldUDRMap, List<Utility_Data_Request__c> udrList) {
        
        Set<Id> udrIds = new Set<Id>();
        
        for (Utility_Data_Request__c udr : udrList) {
            if (udr.Request_Status__c == 'Complete' && oldUDRMap.get(udr.Id).Request_Status__c != 'Complete') {
                udrIds.add(udr.Id);
            }
        }
        
        if(udrIds.size() > 0) {
            List<Utility_Data_Request_Period__c> updatedUDRPList = populateRateClassOnUDRP(udrIds);
            update updatedUDRPList;
        }
        
    }
    
    private List<Utility_Data_Request_Period__c> populateRateClassOnUDRP(Set<Id> udrIdSet) {
        
        List<Utility_Data_Request_Period__c> updatedUDRPList = new List<Utility_Data_Request_Period__c>();
        
        List<Utility_Data_Request_Period__c> udrpList = udrpSelector.getRelatedUDRP(udrIdSet);
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

}