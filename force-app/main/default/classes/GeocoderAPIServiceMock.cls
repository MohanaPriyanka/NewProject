/**
 * Created by rebeccanachison on 5/19/22.
 */

@IsTest
public with sharing class GeocoderAPIServiceMock implements HttpCalloutMock {

    public HttpResponse respond(HttpRequest request) {

        String endpoint = request.getEndpoint();

        if (endpoint.contains('geocode')) {
            return getGeocodeResults();
        } else {
            return null;
        }
    }

    public static HttpResponse createHttpResponse() {
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setStatusCode(200);
        response.setStatus('OK');
        return response;
    }

    public static HttpResponse getGeocodeResults() {
        HttpResponse response = createHttpResponse();
        response.setBody('{' +
            '"results": [' +
            '{' +
            '"address_components": [' +
            '{"long_name": "55", "short_name": "55", "types": ["street_number"]},' +
            '{"long_name": "Lake Street", "short_name": "Lake St", "types": ["route"]},' +
            '{"long_name": "Webster", "short_name": "Webster", "types": ["locality","political"]},' +
            '{"long_name": "Worcester County", "short_name": "Worcester County", "types": ["administrative_area_level_2","political"]},' +
            '{"long_name": "Massachusetts", "short_name": "MA", "types": ["administrative_area_level_1","political"]},' +
            '{"long_name": "United States", "short_name": "US", "types": ["country","political"]},' +
            '{"long_name": "01570", "short_name": "01570", "types": ["postal_code"]},' +
            '{"long_name": "2608", "short_name": "2608", "types": ["postal_code_suffix"]}' +
            '],' +
            '"formatted_address": "55 Lake St, Webster, MA 01570, USA",' +
            '"geometry": {' +
            '"bounds": {' +
            '"northeast": {"lat": 42.0494566, "lng": -71.87486899999999},' +
            '"southwest": {"lat": 42.049313, "lng": -71.8749959}' +
            '},' +
            '"location": {"lat": 42.049381, "lng": -71.8749325},' +
            '"location_type": "ROOFTOP",' +
            '"viewport": {' +
            '"northeast": {"lat": 42.0507108802915, "lng": -71.87358366970848},' +
            '"southwest": {"lat": 42.0480129197085, "lng": -71.8762816302915}' +
            '}' +
            '},' +
            '"place_id": "ChIJKS0rq0Af5IkRa7KhhbXRHSM",' +
            '"types": ["premise"]' +
            '}' +
            '],' +
            '"status": "OK"' +
            '}');
        return response;
    }
}