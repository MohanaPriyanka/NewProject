/**
 * Created by mstackhouse on 1/23/2019.
 * Description: Used to query zipcode utility junctions
 * Test: ZipcodeUtilitySelectorTest
 */

@SuppressWarnings('PMD.ApexCRUDViolation')
public inherited sharing class ZipcodeUtilitiesSelector {
    public static List<ZipCode_Utility_Junction__c> selectZipcodeUtilitiesAndLoadzones(String zipcode) {
        List<ZipCode_Utility_Junction__c> zipcodeUtilities = [
            SELECT Utility__r.Id, Utility__r.Name, Utility__r.Utility_Data_Collection_Mechanism__c, Load_Zone_Utility__r.LZ__c,
                Load_Zone_Utility__r.Town__c, Load_Zone_Utility__r.Id, Load_Zone_Utility__r.Name
            FROM ZipCode_Utility_Junction__c
            WHERE Load_Zone_Utility__r.Name = :zipcode
        ];

        return zipcodeUtilities;
    }

    public static Set<String> selectZipCodesServedByUtility(String utilityId) {
        Set<String> zipCodesServed = new Set<String>();
        for (ZipCode_Utility_Junction__c junction : [
            SELECT Load_Zone_Utility__r.Name
            FROM ZipCode_Utility_Junction__c
            WHERE Utility__c =: utilityId
            ORDER BY Load_Zone_Utility__r.Name] )
        {
            zipCodesServed.add(junction.Load_Zone_Utility__r.Name);
        }

        return zipCodesServed;
    }

}