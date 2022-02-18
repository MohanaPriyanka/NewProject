/**
 * Created by SarahRenfro on 5/24/2019.
 */

public without sharing class UtilityLoadZoneService {

    public static void updateLZUL(List<Lead> leadList, Map<Id, Lead> oldLeadMap){
        Set<String> zipCodeSet = new Set<String>();
        for (Lead l : leadList){
            if (l.Product_line__c == 'Community Solar' && l.Parcel_Zip__c != null) {
                zipCodeSet.add(l.Parcel_Zip__c);
            }
        }
        if (zipCodeSet.size() > 0 ){
            Map<String, Load_u__c> validLZU = new Map<String, Load_u__c>();
            for (Load_u__c obj : [
                SELECT Id, Name, LZ__c, Utility__c,
                (SELECT Id, Name, Utility__r.Id, Utility__r.Name FROM ZipCode_Utility_Junctions__r)
                FROM Load_u__c
                WHERE Name IN : zipCodeSet] ){
                validLZU.put(obj.Name, obj);
            }
            for (Lead l : leadList){
                if ((oldLeadMap == null || oldLeadMap.get(l.Id).Parcel_Zip__c != l.Parcel_Zip__c) && validLZU.containsKey(l.Parcel_Zip__c)){
                    Load_u__c zone = validLZU.get(l.Parcel_Zip__c);
                    l.ZipCode__c = zone.Id;
                    l.LoadZone__c = zone.LZ__c;
                    if (zone.ZipCode_Utility_Junctions__r.size() == 1 && l.Utility_relationship__c == null){
                        l.Utility_relationship__c = zone.ZipCode_Utility_Junctions__r[0].Utility__r.Id;
                        l.Confirm_Utility__c =  zone.ZipCode_Utility_Junctions__r[0].Utility__r.Name + '>'
                            + zone.ZipCode_Utility_Junctions__r[0].Utility__r.Id;
                    } else {
                        //Split zip code - multiple Utilities
                        String utilityNames;
                        String utilityIds;
                        for (ZipCode_Utility_Junction__c junction : zone.ZipCode_Utility_Junctions__r){
                            if (utilityNames == null){
                                utilityNames = junction.Utility__r.Name;
                                utilityIds = junction.Utility__r.Id;
                            } else {
                                utilityNames += '/' + junction.Utility__r.Name;
                                utilityIds += '/' + junction.Utility__r.Id;
                            }
                        }
                        //Populates the Confirm utility field
                        l.Confirm_Utility__c= utilityNames + '>' + utilityIds;
                    }
                }
            }
        }
    }

}