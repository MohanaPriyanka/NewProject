/**
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

    public class ExtractionResult {
        public ExtractedData AccountNumber;
        public ExtractedData CurrentCharges;
        public ExtractedData PreviousBalance;
        public ExtractedData StatementDueDate;
        public ExtractedData StatementDate;
        public ExtractedData ElecUsageKWH1;
        public ExtractedData ElecUsageMonth1;
        public ExtractedData EleUsageMonth2;
        public ExtractedData ElecUsageMonth3;
        public ExtractedData ElecUsageMonth4;
        public ExtractedData ElecUsageMonth5;
        public ExtractedData ElecUsageMonth6;
        public ExtractedData ElecUsageMonth7;
        public ExtractedData ElecUsageMonth8;
        public ExtractedData ElecUsageKWH2;
        public ExtractedData ElecUsageKWH3;
        public ExtractedData ElecUsageKWH4;
        public ExtractedData ElecUsageKWH5;
        public ExtractedData ElecUsageKWH6;
        public ExtractedData ElecUsageKWH7;
        public ExtractedData ElecUsageKWH8;
        public ExtractedData ElecUsageMonth9;
        public ExtractedData ElecUsageKWH9;
        public ExtractedData ElecUsageMonth10;
        public ExtractedData ElecUsageMonth11;
        public ExtractedData ElecUsageMonth12;
        public ExtractedData ElecUsageKWH10;
        public ExtractedData ElecUsageKWH11;
        public ExtractedData ElecUsageKWH12;
        public ExtractedData ElecUsageMonth6_2;
        public ExtractedData ElecUsageMonth7_2;
        public ExtractedData ElecUsageMonth9_2;
        public ExtractedData ElecUsageMonth5_2;
        public ExtractedData ElecUsageKWH5_2;
        public ExtractedData ElecUsageKWH6_2;
        public ExtractedData ElecUsageKWH7_2;
        public ExtractedData ElecUsageKWH9_2;
    }

    public class ExtractedData {
        String content;

    }
}