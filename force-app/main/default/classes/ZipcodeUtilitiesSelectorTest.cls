/**
 * Created by mstackhouse on 1/23/2019.
 * Description: 
 * Test: 
 */

@IsTest
public with sharing class ZipcodeUtilitiesSelectorTest {

    public static zipcodeUtilitiesTestData insertTestData() {
        // Insert Utilities
        Utility__c eversource = new Utility__c(
            Name = 'Eversource',
            Number_of_Decimal_Places__c = 2
        );
        Utility__c nationalGrid = new Utility__c(
            Name = 'National Grid',
            Number_of_Decimal_Places__c = 2
        );
        List<Utility__c> utilities = new List<Utility__c>{eversource, nationalGrid};
        insert utilities;

        // Insert Load Zones
        Load_U__c lzu12345 = new Load_U__c (
            Name = '12345',
            LZ__c = 'SEMA',
            Town__c= 'Medfield'
        );
        Load_U__c lzu54321 = new Load_U__c (
            Name = '54321',
            LZ__c = 'SEMA',
            Town__c= 'Medfield'
        );
        List<Load_U__c> loadZones = new List<Load_U__c>{lzu12345, lzu54321};
        insert loadZones;

        // Insert Zipcode Utility Junctions
        ZipCode_Utility_Junction__c junction = new ZipCode_Utility_Junction__c(
            Load_Zone_Utility__c = lzu12345.Id,
            Utility__c = eversource.Id
        );
        ZipCode_Utility_Junction__c junction2 = new ZipCode_Utility_Junction__c(
            Load_Zone_Utility__c = lzu54321.Id,
            Utility__c = nationalGrid.Id
        );
        List<Zipcode_Utility_Junction__c> junctions= new List<ZipCode_Utility_Junction__c>{junction, junction2};
        insert junctions;

        return new zipcodeUtilitiesTestData(utilities, loadZones, junctions);
    }

    public class zipcodeUtilitiesTestData {
        public List<Utility__c> utilities;
        public List<Load_U__c> loadZones;
        public List<ZipCode_Utility_Junction__c> junctions;

        public zipcodeUtilitiesTestData(
            List<Utility__c> utilities, List<Load_U__c> loadZones, List<ZipCode_Utility_Junction__c> junctions)
        {
            this.utilities = utilities;
            this.loadZones = loadZones;
            this.junctions = junctions;
        }
    }

    @IsTest
    public static void testGetZipcodeUtilitiesAndLoadzones() {
        zipcodeUtilitiesTestData dataSet = insertTestData();

        // Test no match query
        List<ZipCode_Utility_Junction__c> noJunctions = ZipcodeUtilitiesSelector.selectZipcodeUtilitiesAndLoadzones('11111');
        System.assertEquals(0, noJunctions.size());

        // Test query match with one junction record found
        List<ZipCode_Utility_Junction__c> junctions12345 = ZipcodeUtilitiesSelector.selectZipcodeUtilitiesAndLoadzones('12345');
        System.assertEquals(1, junctions12345.size());
        System.assertEquals(dataSet.junctions[0].Id, junctions12345[0].Id);
        System.assertEquals(dataSet.utilities[0].Id, junctions12345[0].Utility__r.Id);
        System.assertEquals(dataSet.loadZones[0].Name, junctions12345[0].Load_Zone_Utility__r.Name);
        System.assertEquals(dataSet.loadZones[0].Id, junctions12345[0].Load_Zone_Utility__r.Id);

        // Test selectZipCodesServedByUtility query match
        Set<String> zipsServedByUtility = ZipcodeUtilitiesSelector.selectZipCodesServedByUtility((String) dataSet.utilities[0].Id);
        List<String> zipsServed = new List<String>(zipsServedByUtility);
        System.assertEquals(1, zipsServedByUtility.size());
        System.assertEquals(dataSet.loadZones[0].Name, zipsServed[0], 'Incorrect result for query of zipcodes served by Utility');
    }
}