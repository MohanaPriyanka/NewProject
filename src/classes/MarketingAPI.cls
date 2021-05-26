/**
 * @description: Classes representing the JSON objects that are used by the Marketing Cloud (MC) API
 * Tested By: MarketingAPITest, MarketingJourneyEnrollerTest
 */
@SuppressWarnings('PMD')
public without sharing class MarketingAPI {

    public class OauthRequest {
        public String grant_type = 'client_credentials';
        public String client_id = '{!HTMLENCODE($Credential.Username)}';
        public String client_secret = '{!HTMLENCODE($Credential.Password)}';
    }

    public class AuthResponse {
        public String access_token;
        public String token_type;
        public Integer expires_in;
        public String scope;
        public String rest_instance_url;
    }

    public class JourneyEnrollment {
        @InvocableVariable(
            Label='Contact Id'
            Required=true
            Description='The Id of the Contact to Enroll in the Journey')
        public String ContactId;

        @InvocableVariable(
            Label='Journey Id'
            Required=true
            Description='EventDefinitionKey of the Journey in MC')
        public String EventDefinitionKey;

        @InvocableVariable(
            Label='Event Properties'
            Required=false
            Description='(Optional) Key/Value pairs for the Journey Data Extension')
        public List<FlowMap> EventProperties;

        @SuppressWarnings('PMD.EmptyStatementBlock')
        public JourneyEnrollment() { // Invocable types require a no-arg constructor
        }

        public JourneyEnrollmentPayload constructPayload() {
            JourneyEnrollmentPayload payload = new JourneyEnrollmentPayload();
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

    public class JourneyEnrollmentPayload {
        public String ContactKey;
        public String EventDefinitionKey;
        public Map<String,String> Data;
    }
}