/**
 * Created by rebeccanachison on 4/21/22.
 * Tested by: GeocoderAPIServiceTest
 */


public with sharing class GeocoderAPIService {

    private static final String API_BASE_URL = 'https://maps.googleapis.com/maps';

    @AuraEnabled
    public static GeocodeData getGeocodeResults(String addressInput, String cityInput, String stateInput, String zipCodeInput) {
        try {
            String url = API_BASE_URL + '/api/geocode/json?'
                + 'address=' + EncodingUtil.urlEncode(addressInput, 'UTF-8')
                + '&components='
                    + 'locality:' + EncodingUtil.urlEncode(cityInput, 'UTF-8') + '|'
                    + 'administrative_area:' + EncodingUtil.urlEncode(stateInput, 'UTF-8') + '|'
                    + 'postal_code:' + EncodingUtil.urlEncode(zipCodeInput, 'UTF-8') + '|'
                    + 'country:us'
                +  getKeyParam();
            String response = getResponse(url);
            APIResponse data = (APIResponse) JSON.deserialize(response, APIResponse.class);
            // get data ready for the front end to parse and serve
            GeocodeData geocodeData = validateAddress(data, addressInput, cityInput, stateInput, zipCodeInput);
            return geocodeData;
        } catch(Exception e) {
            logError('getGeocodeResults', e.getMessage());
            return null;
        }
    }

    private static String getResponse(String endpoint) {
        HttpRequest request = new HttpRequest();
        request.setMethod('GET');
        request.setEndpoint(endpoint);
        request.setTimeout(120000);
        HttpResponse response = new Http().send(request);
        return response.getBody();
    }

    private static String getKeyParam() {
        List<System_Properties__c> systemProperties = System_Properties__c.getAll().values();
        if (systemProperties.size() == 0 || systemProperties[0].Google_Maps_API_Key__c == null) {
            throw new Util.BWException('Missing Google Maps API Key');
        }
        String key = systemProperties[0].Google_Maps_API_Key__c;
        return '&key=' + key;
    }

    private static GeocodeData validateAddress(APIResponse response, String addressInput, String cityInput, String stateInput, String zipCodeInput) {
        if (response.status != 'OK' && response.status != 'ZERO_RESULTS') {
            throw new Util.BWException('Google Geocoder API returned with status ' + response.status);
        }
        GeocodeData geocodeData = new GeocodeData();

        for (GeocodeResult result : response.results) {
            // only return results with precise locations, all other location type values are for approximate locations
            if (result.geometry.location_type != 'ROOFTOP') {
                continue;
            }

            ResultAddress resultAddress = getResultAddress(result, addressInput, cityInput, stateInput, zipCodeInput);
            geocodeData.addresses.add(resultAddress.address);

            if (resultAddress.isExactMatch) {
                // if exact match, flag and move on
                // won't need to run through individual address components, so set lat/lng at highest level to grab easily
                geocodeData.isExactMatch = true;
                geocodeData.latitude = result.geometry.location.lat;
                geocodeData.longitude = result.geometry.location.lng;
                break;
            }
        }

        return geocodeData;
    }

    private static ResultAddress getResultAddress(GeocodeResult result, String addressInput, String cityInput, String stateInput, String zipCodeInput) {
        Address address = new Address();
        Boolean isExactMatch = true;
        String streetAddress = '';
        String streetAddressLong = '';
        for (AddressComponent addressComponent : result.address_components) {
            switch on addressComponent.types[0] {
                when 'street_number' {
                    streetAddress = addressComponent.short_name + ' ' + streetAddress;
                    streetAddressLong = addressComponent.long_name + ' ' + streetAddressLong;
                }
                when 'route' {
                    streetAddress += addressComponent.short_name;
                    streetAddressLong += addressComponent.long_name;
                }
                when 'locality' {
                    address.city = addressComponent.long_name;
                    if (cityInput != addressComponent.long_name && cityInput != addressComponent.short_name) {
                        isExactMatch = false;
                    }
                }
                when 'administrative_area_level_1' {
                    address.state = addressComponent.short_name;
                    if (stateInput != addressComponent.short_name) {
                        isExactMatch = false;
                    }
                }
                when 'postal_code' {
                    address.zipCode = addressComponent.long_name;
                    if (zipCodeInput != addressComponent.long_name && zipCodeInput != addressComponent.short_name) {
                        isExactMatch = false;
                    }
                }
            }
        }
        // input might end with a subpremise if updating existing object
        if (!addressInput.startsWith(streetAddress) && !addressInput.startsWith(streetAddressLong)) {
            isExactMatch = false;
        }
        address.street = streetAddress;
        address.latitude = result.geometry.location.lat;
        address.longitude = result.geometry.location.lng;
        address.id = result.place_id;
        return new ResultAddress(address, isExactMatch);
    }

    private static void logError(String method, String message) {
        Logger.logNow('GeocoderAPIService', method, message);
    }

    private class APIResponse {
        public List<GeocodeResult> results;
        public String status;
    }

    @TestVisible
    private class GeocodeData {
        public List<Address> addresses;
        public Boolean isExactMatch;
        public Decimal latitude;
        public Decimal longitude;

        public GeocodeData() {
            this.addresses = new List<Address>();
            this.isExactMatch = false;
        }

        @AuraEnabled
        public List<Address> getAddresses() {
            return this.addresses;
        }

        @AuraEnabled
        public Boolean getIsExactMatch() {
            return this.isExactMatch;
        }

        @AuraEnabled
        public Decimal getLatitude() {
            return this.latitude;
        }

        @AuraEnabled
        public Decimal getLongitude() {
            return this.longitude;
        }
    }

    @TestVisible
    private class Address {
        public String street;
        public String city;
        public String state;
        public String zipCode;
        public Decimal latitude;
        public Decimal longitude;
        public String id;

        @AuraEnabled
        public String getStreet() {
            return this.street;
        }

        @AuraEnabled
        public String getCity() {
            return this.city;
        }

        @AuraEnabled
        public String getState() {
            return this.state;
        }

        @AuraEnabled
        public String getZipCode() {
            return this.zipCode;
        }

        @AuraEnabled
        public Decimal getLatitude() {
            return this.latitude;
        }

        @AuraEnabled
        public Decimal getLongitude() {
            return this.longitude;
        }

        @AuraEnabled
        public String getId() {
            return this.id;
        }
    }

    private class GeocodeResult {
        public List<AddressComponent> address_components;
        public String formatted_address;
        public Geometry geometry;
        public List<String> types;
        public Boolean partial_match;
        public String place_id;
    }

    private class AddressComponent {
        public String long_name;
        public String short_name;
        public List<String> types;
    }

    private class Geometry {
        public Location location;
        public String location_type;
    }

    private class Location {
        public Decimal lat;
        public Decimal lng;
    }

    private class ResultAddress {
        public Address address;
        public Boolean isExactMatch;

        public ResultAddress(Address address, Boolean isExactMatch) {
            this.address = address;
            this.isExactMatch = isExactMatch;
        }
    }
}