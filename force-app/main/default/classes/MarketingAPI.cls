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

    public class JourneyEnrollmentPayload {
        public String ContactKey;
        public String EventDefinitionKey;
        public Map<String,String> Data;
    }
}