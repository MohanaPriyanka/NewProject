/**
 * @description: Classes representing the JSON objects that are used by the Glynt API: https://api.glynt.ai/v6/docs#definitions
 * Tested By: GlyntAPIHelperTest
 */
@SuppressWarnings('PMD')
public with sharing class GlyntAPI {
    public class OauthRequest {
        public String grant_type = 'client_credentials';
        public String client_id = '{!HTMLENCODE($Credential.Username)}';
        public String client_secret = '{!HTMLENCODE($Credential.Password)}';
        public String audience = 'glynt-public-api';
    }

    public class BasicAuthRequest {
        public String username = '{!HTMLENCODE($Credential.Username)}';
        public String password = '{!HTMLENCODE($Credential.Password)}';
    }

    public class AuthResponse {
        public String access_token;
        public String token_type;
    }

    public class DataPool {
        public String id; // f6qD82
        public String label; // Demo
    }

    public class DocumentUpload {
        public String label;
        public List<String> tags;
        public String content_type;
        public String content;
    }

    public class DocumentUploadResult {
        public String id;
    }

    public class ExtractionRequest {
        public String document;
        public Boolean classify;
        public List<String> tags;
        public ExtractionRequest(String documentId, String tag) {
            this.document = documentId;
            this.classify = true;
            this.tags = new List<String>{tag};
        }
    }

    public class ExtractionResponse {
        public String id;
        public String status;
        public Boolean finished;
        public List<String> tags;
        public ExtractionResult results;
        public ExtractionResponse(String status, Boolean finished) {
            this.status = status;
            this.finished = finished;
        }
    }

    public class ExtractionResult extends CustomApexObject {
        public ExtractedData AccountNumber;
        public ExtractedData CustomerName;
        public ExtractedData ServiceAddressL1;
        public ExtractedData ServiceAddressL2;
        public ExtractedData E_StartDate; // Bill start date
        public ExtractedData E_EndDate; // Bill end date
        public ExtractedData E_NumberDays; // Number of days in statement
        public ExtractedData E_Usage; // Electric usage in current statement
        public ExtractedData E_UsageUnits; // Electric usage unit of measurement
        public ExtractedData E_MeterNumber;
        public ExtractedData E_TotalDeliveryCharge;
        public ExtractedData E_TotalSupplyCharge;
        public ExtractedData E_PreviousUsage1;
        public ExtractedData E_PreviousUsagekWh1;
        public ExtractedData E_PreviousUsage2;
        public ExtractedData E_PreviousUsagekWh2;
        public ExtractedData E_PreviousUsage3;
        public ExtractedData E_PreviousUsagekWh3;
        public ExtractedData E_PreviousUsage4;
        public ExtractedData E_PreviousUsagekWh4;
        public ExtractedData E_PreviousUsage5;
        public ExtractedData E_PreviousUsagekWh5;
        public ExtractedData E_PreviousUsage6;
        public ExtractedData E_PreviousUsagekWh6;
        public ExtractedData E_PreviousUsage7;
        public ExtractedData E_PreviousUsagekWh7;
        public ExtractedData E_PreviousUsage8;
        public ExtractedData E_PreviousUsagekWh8;
        public ExtractedData E_PreviousUsage9;
        public ExtractedData E_PreviousUsagekWh9;
        public ExtractedData E_PreviousUsage10;
        public ExtractedData E_PreviousUsagekWh10;
        public ExtractedData E_PreviousUsage11;
        public ExtractedData E_PreviousUsagekWh11;
        public ExtractedData E_PreviousUsage12;
        public ExtractedData E_PreviousUsagekWh12;
    }

    public class ExtractedData {
        public String content;
    }
}