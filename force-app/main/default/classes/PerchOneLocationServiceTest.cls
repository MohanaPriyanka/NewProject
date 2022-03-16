/**
 * Created by PeterYao_6fwtfg1 on 3/13/2022.
 */
@IsTest
private with sharing class PerchOneLocationServiceTest {
    @IsTest
    private static void testIsInDisadvantagedCommunity() {
        PerchOneLocationService.DACAttributes attributes = new PerchOneLocationService.DACAttributes();
        attributes.isDisadvantagedCommunity = true;
        PerchOneLocationService.DACAttributesForLocation attributesForLocation = new PerchOneLocationService.DACAttributesForLocation();
        attributesForLocation.getDACAttributesForLocation = attributes;
        PerchOneLocationService.DACResponse dacResponse = new PerchOneLocationService.DACResponse();
        dacResponse.data = attributesForLocation;
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new PerchOneDACMock(JSON.serialize(dacResponse), 200));
        System.assertEquals(attributes.isDisadvantagedCommunity, new PerchOneLocationService().isInDisadvantagedCommunity(41, -73),
            'Expected to construct a GraphQL query and get the expected response back');
    }

    @IsTest
    private static void testDACStatusHandling() {
        Test.startTest();
        try {
            Test.setMock(HttpCalloutMock.class, new PerchOneDACMock('', 404));
            new PerchOneLocationService().isInDisadvantagedCommunity(41, -73);
            System.assert(false, 'PerchOneLocationService should have thrown an exception if PerchOne returns a 404');
        } catch (Util.BWException bwe) {
            System.assert(bwe.getMessage().contains('404'),
                'When PerchOneLocationService throws an exception, it should include the status code, but it threw: ' + bwe.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    private static void testDACSErrorHandling() {
        String response = '{"errors":[{"message":"Internal Server Error(s) while executing query"}],"data":{"getDACAttributesForLocation":null}}';
        Test.startTest();
        try {
            Test.setMock(HttpCalloutMock.class, new PerchOneDACMock(response, 200));
            new PerchOneLocationService().isInDisadvantagedCommunity(41, -73);
            System.assert(false, 'PerchOneLocationService should have thrown an exception if PerchOne returns errors');
        } catch (Util.BWException bwe) {
            System.assert(bwe.getMessage().contains('Internal Server Error(s)'),
                'When PerchOneLocationService throws an exception, it should include errors, but it threw: ' + bwe.getMessage());
        }
        Test.stopTest();
    }

    private class PerchOneDACMock implements HttpCalloutMock {
        private String response;
        private Integer status;
        public PerchOneDACMock(String response, Integer status) {
            this.response = response;
            this.status = status;
        }
        public HttpResponse respond(HttpRequest request) {
            HttpResponse httpResponse = new HttpResponse();
            httpResponse.setHeader('Content-Type', 'application/json');
            httpResponse.setStatusCode(status);
            httpResponse.setBody(response);
            return httpResponse;
        }
    }
}