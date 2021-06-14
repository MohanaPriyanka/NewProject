/**
 * Tested By: MarketingJourneyEnrollerTest
 */
public with sharing class MarketingJourneyEnrollmentDetail {

    @AuraEnabled public String ContactId;
    @AuraEnabled public String EventDefinitionKey;
    @AuraEnabled public List<FlowMap> EventProperties;

    @SuppressWarnings('PMD.EmptyStatementBlock')
    public MarketingJourneyEnrollmentDetail() {
    }

    public MarketingAPI.JourneyEnrollmentPayload constructPayload() {
        MarketingAPI.JourneyEnrollmentPayload payload = new MarketingAPI.JourneyEnrollmentPayload();
        payload.ContactKey = ContactId;
        payload.EventDefinitionKey = EventDefinitionKey;
        payload.Data = parseEnrollmentProperties(EventProperties);
        payload.Data.put('ContactId',ContactId);
        return payload;
    }

    private Map<String,String> parseEnrollmentProperties(List<FlowMap> properties) {
        Map<String,String> propertyMap = new Map<String,String>();
        for (FlowMap property : properties) {
            if (property.key != null && property.value != null) {
                propertyMap.put(property.key, property.value);
            }
        }
        return propertyMap;
    }
}