/**
 * Created by rebeccanachison on 5/19/22.
 */

@IsTest
private class GeocoderAPIServiceTest {

    @TestSetup
    private static void testSetup() {
        System_Properties__c systemProperties = new System_Properties__c(Name='System', Google_Maps_API_Key__c='asldkjweroi2342j3lasd');
        insert systemProperties;
    }

    @IsTest
    private static void testGetPartialMatch() {
        GeocoderAPIService.GeocodeData data = new GeocoderAPIService.GeocodeData();
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new GeocoderAPIServiceMock());
        data = GeocoderAPIService.getGeocodeResults('55 Lak Street', 'Webster', 'MA', '01570');
        Test.stopTest();
        List<GeocoderAPIService.Address> addresses = data.getAddresses();
        System.assertEquals(1, addresses.size(), 'Callout should have returned an address');
        System.assertEquals('55 Lake St', addresses[0].getStreet(), 'Street should return "55 Lake St"');
        System.assertEquals('Webster', addresses[0].getCity(), 'City should return "Webster"');
        System.assertEquals('MA', addresses[0].getState(), 'State should return "MA"');
        System.assertEquals('01570', addresses[0].getZipCode(), 'Description should return "01570"');
        System.assertEquals(null, data.getLatitude(), 'The latitude should not be set');
        System.assertEquals(null, data.getLongitude(), 'The longitude should not be set');
        System.assert(!data.getIsExactMatch(), 'The returned address should not be an exact match with the input');
    }

    @IsTest
    private static void testGetExactMatch() {
        GeocoderAPIService.GeocodeData data = new GeocoderAPIService.GeocodeData();
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new GeocoderAPIServiceMock());
        data = GeocoderAPIService.getGeocodeResults('55 Lake St', 'Webster', 'MA', '01570');
        Test.stopTest();
        List<GeocoderAPIService.Address> addresses = data.getAddresses();
        System.assertEquals(1, addresses.size(), 'Callout should have returned an address');
        System.assertEquals('55 Lake St', addresses[0].getStreet(), 'Street should return "55 Lake St"');
        System.assertEquals('Webster', addresses[0].getCity(), 'City should return "Webster"');
        System.assertEquals('MA', addresses[0].getState(), 'State should return "MA"');
        System.assertEquals('01570', addresses[0].getZipCode(), 'Description should return "01570"');
        System.assertEquals(42.049381, data.getLatitude(), 'The latitude should be 42.049381');
        System.assertEquals(-71.8749325, data.getLongitude(), 'The longitude should be -71.8749325');
        System.assert(data.getIsExactMatch(), 'The returned address should be an exact match with the input');
    }

    @IsTest
    private static void testAPIKeyError() {
        List<System_Properties__c> systemProperties = System_Properties__c.getAll().values();
        systemProperties[0].Google_Maps_API_Key__c = null;
        update systemProperties;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new GeocoderAPIServiceMock());
        GeocoderAPIService.getGeocodeResults('55 Lake Street', 'Webster', 'MA', '01570');
        Test.stopTest();
        List<Error_Log__c> errorLogs = [
            SELECT Id, Message__c
            FROM Error_Log__c
            WHERE Class__c = 'GeocoderAPIService'
            AND Severity__c = :Logger.ERROR
        ];
        System.assertEquals(1, errorLogs.size(), 'Callout should have resulted in an error');
        System.assertEquals(errorLogs[0].Message__c, 'Missing Google Maps API Key', 'Callout should have resulted in an error due to the Google Maps API key missing');
    }
}