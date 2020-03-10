/**
 * Created by mstackhouse on 1/23/2019.
 * Description: Used to query zipcode utility junctions
 * Test: ZipcodeUtilitySelectorTest
 */


public inherited sharing class ZipcodeUtilitiesSelector {
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public static List<ZipCode_Utility_Junction__c> selectZipcodeUtilitiesAndLoadzones(String zipcode) {
        List<ZipCode_Utility_Junction__c> zipcodeUtilities = [
            SELECT Utility__r.Id, Utility__r.Name, Utility__r.EIA_ID__c, Load_Zone_Utility__r.LZ__c,
                Load_Zone_Utility__r.Town__c, Load_Zone_Utility__r.Id, Load_Zone_Utility__r.Name
            FROM ZipCode_Utility_Junction__c
            WHERE Load_Zone_Utility__r.Name = :zipcode
        ];

        return zipcodeUtilities;
    }
}