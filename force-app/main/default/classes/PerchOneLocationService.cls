/**
 * Gets location attributes via the PerchOne platform
 * Tested By: PerchOneLocationServiceTest
 */

public without sharing class PerchOneLocationService {
    public Boolean isInDisadvantagedCommunity(Decimal latitude, Decimal longitude) {
        GraphQLNode dacRequest = new GraphQLNode('DACAttributesForLocation')
            .setOperation('query')
            .addArguments(new GraphQLArgument('$request', 'DACAttributesForLocationRequest!', true))
            .add(
                new GraphQLNode('getDACAttributesForLocation')
                    .addArguments(new List<GraphQLArgument>{
                        new GraphQLArgument('request', '$request', true)
                    })
                    .add(new GraphQLNode('isDisadvantagedCommunity'))
            );

        LocationRequest locationVariable = new LocationRequest();
        Location location = new Location();
        location.latitude = latitude;
        location.longitude = longitude;
        locationVariable.request = location;
        GraphQLQuery query = new GraphQLQuery(dacRequest, locationVariable);
        HttpResponse response = new PerchOneAPIHelper().callGraphQlEndpoint('POST', query);
        if (response.getStatusCode() != 200) {
            throw new Util.BWException('Received ' + response.getStatusCode() + ' for query:\n' + JSON.serialize(query));
        }
        DACResponse dacResponse = (DACResponse) JSON.deserialize(response.getBody(), DACResponse.class);
        if (dacResponse.errors != null) {
            throw new Util.BWException('Received:\n' + response.getBody() + '\nfor query:\n' + JSON.serialize(query));
        }
        return dacResponse.data.getDACAttributesForLocation.isDisadvantagedCommunity;
    }


    private class LocationRequest {
        private Location request;
    }
    private class Location {
        private Decimal latitude;
        private Decimal longitude;
    }

    @TestVisible
    private class DACResponse {
        @TestVisible
        private DACAttributesForLocation data;
        private List<Error> errors;
    }
    @TestVisible
    private class DACAttributesForLocation {
        @TestVisible
        private DACAttributes getDACAttributesForLocation;
    }
    @TestVisible
    private class DACAttributes {
        @TestVisible
        private Boolean isDisadvantagedCommunity;
    }
    @TestVisible
    private class Error {
        @TestVisible
        private String message;
    }
}