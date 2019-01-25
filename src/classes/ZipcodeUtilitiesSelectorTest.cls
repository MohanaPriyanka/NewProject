/**
 * Created by mstackhouse on 1/23/2019.
 * Description: 
 * Test: 
 */

@IsTest
public with sharing class ZipcodeUtilitiesSelectorTest {
    @IsTest
    public static void testGetZipcodeUtilitiesAndLoadzones() {
        Utility__c eversource = new Utility__c(
            Name = 'Eversource',
            Number_of_Decimal_Places__c = 2
        );
        Utility__c nationalGrid = new Utility__c(
            Name = 'National Grid',
            Number_of_Decimal_Places__c = 2
        );
        insert new List<Utility__c>{eversource, nationalGrid};

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

        insert new List<Load_U__c>{
            lzu12345, lzu54321
        };

        ZipCode_Utility_Junction__c junction = new ZipCode_Utility_Junction__c(
            Load_Zone_Utility__c = lzu12345.Id,
            Utility__c = eversource.Id
        );
        ZipCode_Utility_Junction__c junction2 = new ZipCode_Utility_Junction__c(
            Load_Zone_Utility__c = lzu54321.Id,
            Utility__c = nationalGrid.Id
        );
        insert new List<ZipCode_Utility_Junction__c>{junction, junction2};

        List<ZipCode_Utility_Junction__c> noJunctions = ZipcodeUtilitiesSelector.selectZipcodeUtilitiesAndLoadzones('11111');
        System.assertEquals(0, noJunctions.size());


        List<ZipCode_Utility_Junction__c> junctions12345 = ZipcodeUtilitiesSelector.selectZipcodeUtilitiesAndLoadzones('12345');

        System.assertEquals(1, junctions12345.size());
        System.assertEquals(junction.Id, junctions12345[0].Id);
        System.assertEquals(eversource.Id, junctions12345[0].Utility__r.Id);
        System.assertEquals('12345', junctions12345[0].Load_Zone_Utility__r.Name);
        System.assertEquals(lzu12345.Id, junctions12345[0].Load_Zone_Utility__r.Id);

        List<ZipCode_Utility_Junction__c> junctions54321 = ZipcodeUtilitiesSelector.selectZipcodeUtilitiesAndLoadzones('54321');

        System.assertEquals(1, junctions54321.size());
        System.assertEquals(junction2.Id, junctions54321[0].Id);
        System.assertEquals(nationalGrid.Id, junctions54321[0].Utility__r.Id);
        System.assertEquals('54321', junctions54321[0].Load_Zone_Utility__r.Name);
        System.assertEquals(lzu54321.Id, junctions54321[0].Load_Zone_Utility__r.Id);

    }
}