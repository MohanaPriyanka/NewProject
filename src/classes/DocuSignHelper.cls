/*************************************************************************************
 * Created By:  Peter Yao
 * Description: Convenience methods to use DocuSignAPI class generated from WSDL. Originally
 *              used in the loan change order and contingent contracting process
 * Test: DocuSignHelperTest,LeadTriggerHandlerTest,CAPControllerTest
 *************************************************************************************/

public without sharing class DocuSignHelper {
    public static DocuSignAPI.APIServiceSoap dsAPI;
    @TestVisible
    private static List<dsfs__DocuSign_Status__c> envelopesToVoid;
    @TestVisible
    private static List<Opportunity> oppsToResend;
    @TestVisible
    private static List<Opportunity> oppLoansSent;

    private static String apiAccountId;
    private static System_Properties__c sysProp;
    private static String restAPIServer;
    private static String baseURL;
    private static String accountId;
    private static String restHeader;

    // We could probably use just the REST API, but most examples were for SOAP API, so we use both below
    // (since the SOAP API doesn't support getting signing groups).
    public static void connect() {
        if (dsAPI == null) {
            sysProp = System_Properties__c.getAll().values()[0];
            apiAccountId = sysProp.DocuSign_API_Account_ID__c;

            dsAPI = new DocuSignAPI.APIServiceSoap();
            // Set timeout to 90 seconds, up from default of 10 seconds
            dsAPI.timeout_x = 90000;
            Organization o = [SELECT IsSandbox FROM Organization LIMIT 1];
            if (o.IsSandbox || Test.isRunningTest()) {
                dsAPI.endpoint_x = 'https://demo.docusign.net/api/3.0/dsapi.asmx';
                restAPIServer = 'https://demo.docusign.net/restapi/v2';
            } else {
                dsAPI.endpoint_x = 'https://www.docusign.net/api/3.0/dsapi.asmx';
                restAPIServer = 'https://www.docusign.net/restapi/v2';
            }
            dsAPI.inputHttpHeaders_x = new Map<String, String>();
            String auth =
                '<DocuSignCredentials>' +
                    '<Username>' + sysProp.DocuSign_Guest_User__c + '</Username>' +
                    '<Password>' + sysProp.DocuSign_Guest_User_Credential__c + '</Password>' +
                    '<IntegratorKey>' + sysProp.DocuSign_Integrator_Key__c + '</IntegratorKey>' +
                    '<SendOnBehalfOf>' + sysProp.DocuSign_Customer_Care_User__c + '</SendOnBehalfOf>' +
                    '</DocuSignCredentials>';
            dsAPI.inputHttpHeaders_x.put('X-DocuSign-Authentication', auth);

            Map<String, String> restHeaderMap = new Map<String, String>();
            restHeaderMap.put('Username', sysProp.DocuSign_Guest_User__c);
            restHeaderMap.put('Password', sysProp.DocuSign_Guest_User_Credential__c);
            restHeaderMap.put('IntegratorKey', sysProp.DocuSign_Integrator_Key__c);
            restHeader = System.JSON.serialize(restHeaderMap);
        }
    }

    // Called from lead trigger when a change order status is set to Customer Authorized for converted leads.
    // We don't yet know if any DocuSign packages exist (in which case we need to void and resend)
    @Future(Callout=true)
    public static void handleLoanChangeOrder(String oppIdListJSON) {
        List<Id> oppIds = (List<Id>) System.JSON.deserialize(oppIdListJSON, List<Id>.class);
        oppsToResend = new List<Opportunity>();
        envelopesToVoid = new List<dsfs__DocuSign_Status__c>();
        List<Opportunity> opps = [
            SELECT Id, Name, Docusign_Template__c, Email__c, Co_Applicant_Email__c, Co_Applicant_Full_Name__c,
            (SELECT Id, dsfs__DocuSign_Envelope_ID__c, dsfs__Opportunity__c, dsfs__Envelope_Status__c
            FROM dsfs__R00N80000002fD9vEAE__r),
            (SELECT Id FROM Partner_Tasks__r WHERE (Name = 'Obtain Contract Signature' OR Name = 'Provide Sales Agreement') AND Status__c != 'Pending')
            FROM Opportunity
            WHERE Id IN :oppIds
        ];
        for (Opportunity o : opps) {
            if (!o.dsfs__R00N80000002fD9vEAE__r.isEmpty()) {
                oppsToResend.add(o);
                for (dsfs__DocuSign_Status__c env : o.dsfs__R00N80000002fD9vEAE__r) {
                    if (env.dsfs__Envelope_Status__c != 'Voided') {
                        envelopesToVoid.add(env);
                    }
                }
            }
        }
        for (dsfs__DocuSign_Status__c env : envelopesToVoid) {
            voidPackage(env.dsfs__DocuSign_Envelope_ID__c, 'Voided due to a change order.');
        }
        for (Opportunity o : oppsToResend) {
            try {
                sendLoanPackage(o.Id);
            } catch (Util.BWException bwe) {
                break;
            }
        }
        // DML needs to happen after the callouts
        for (Opportunity o : oppsToResend) {
            resetOppAndTasks(o);
        }
        Logger.flushLogs();
    }

    public static void voidPackage(String envelopeId, String reason) {
        try {
            connect();
            DocuSignAPI.VoidEnvelopeStatus result = dsAPI.VoidEnvelope(envelopeId, reason);
            if (result == null || !result.VoidSuccess) {
                Logger.logLater('DocuSignHelper', 'checkAndRegeneratePackage', 'Unsuccessful void for envelope ' + envelopeId, 'Error');
            }
        } catch (CalloutException e) {
            Logger.logLater('DocuSignHelper', 'checkAndRegeneratePackage',
                'Callout Exception caught voiding envelope ' + envelopeId + ' error message: ' + e.getMessage(), 'Error');
        }
    }

    public static void resetOppAndTasks(Opportunity o) {
        for (Partner_Task__c pt : o.Partner_Tasks__r) {
            pt.Status__c = 'Pending';
            pt.Completion_Date__c = null;
        }
        update o.Partner_Tasks__r;
        Opportunity opp = new Opportunity(
            Id = o.Id,
            StageName = 'Contract Pending',
            Contract_Status__c = 'Sent',
            Partner_Sales_Agreement_Status__c = '',
            BlueWave_Signature_Status__c = ''
        );
        update opp;
    }

    @Future(Callout=true)
    public static void sendLoanPackageFuture(Id oppId) {
        sendLoanPackage(oppId);
    }

    // Makes callouts to DocuSign to send loan docs, and sets Contract Signature partner task to Pending
    public static DocuSignAPI.EnvelopeStatus sendLoanPackage(Id oppId) {
        connect();
        Integer chrisGoslineGroupId = getSigningGroup('BW RL');
        Integer qcGroupId = getSigningGroup('BW QC Signature');
        Opportunity opp = [
            SELECT Id, Name, Application_Type__c, Email__c, Co_Applicant_Email__c, Co_Applicant_Full_Name__c, Docusign_Template__c,
            (SELECT Id, Status__c FROM Partner_Tasks__r WHERE Name = 'Obtain Contract Signature')
            FROM Opportunity
            WHERE Id = :oppId
        ];

        DocuSignAPI.EnvelopeInformation envelope = new DocuSignAPI.EnvelopeInformation();
        envelope.Subject = opp.Name + ' Residential Loan Contract';
        envelope.EmailBlurb = 'This is your BlueWave Solar Loan Contract. Please click “Review Documents” to view your ' +
            'contract and execute electronically. As a reminder, this contract is conditional based on qualifying your loan.';

        envelope.AccountId = apiAccountId;

        DocuSignAPI.EnvelopeTemplate et = dsAPI.RequestTemplateWithDocumentFields(opp.Docusign_Template__c, true);
        for (DocuSignAPI.Recipient r : et.Envelope.Recipients.Recipient) {
            if (r.RoleName == 'Signer 1') {
                r.UserName = opp.Name;
                r.Email = opp.Email__c;
            } else if (r.RoleName == 'Signer 2') {
                if (opp.Application_Type__c == 'Joint') {
                    r.UserName = opp.Co_Applicant_Full_Name__c;
                    r.Email = opp.Co_Applicant_Email__c;
                } else {
                    r.SigningGroupId = qcGroupId;
                }
            } else if (r.RoleName == 'Signer 3') {
                if (opp.Application_Type__c == 'Joint') {
                    r.SigningGroupId = qcGroupId;
                } else {
                    r.SigningGroupId = chrisGoslineGroupId;
                }
            } else if (r.RoleName == 'Signer 4' && opp.Application_Type__c == 'Joint') {
                r.SigningGroupId = chrisGoslineGroupId;
            } else if (r.RoleName == 'Recipient 4' && opp.Application_Type__c != 'Joint') {
                r.UserName = opp.Name;
                r.Email = opp.Email__c;
            } else if (r.RoleName == 'Recipient 5' && opp.Application_Type__c == 'Joint') {
                r.UserName = opp.Name;
                r.Email = opp.Email__c;
            } else {
                Logger.logLater('DocuSignHelper', 'sendLoanPackage',
                    'Found unexpected recipient role: ' + System.JSON.serializePretty(r) +
                        ' while processing Opportunity: ' + System.JSON.serializePretty(opp), 'Error');
            }
        }

        DocuSignAPI.InlineTemplate it = new DocuSignAPI.InlineTemplate();
        it.Sequence = 1;
        it.Envelope = et.Envelope;

        DocuSignAPI.ArrayOfCompositeTemplate compositeTemplates = new DocuSignAPI.ArrayOfCompositeTemplate();
        compositeTemplates.CompositeTemplate = new DocuSignAPI.CompositeTemplate[1];
        compositeTemplates.CompositeTemplate[0] = new DocuSignAPI.CompositeTemplate();
        compositeTemplates.CompositeTemplate[0].InlineTemplates = new DocuSignAPI.ArrayOfInlineTemplate();
        compositeTemplates.CompositeTemplate[0].InlineTemplates.InlineTemplate = new DocuSignAPI.InlineTemplate[1];
        compositeTemplates.CompositeTemplate[0].InlineTemplates.InlineTemplate[0] = it;

        DocuSignAPI.CustomField field = new DocuSignAPI.CustomField();
        field.Name = '##SFOpportunity';
        field.Value = opp.Id;    //value of your external source Id
        field.Show = 'false';
        DocuSignAPI.ArrayOfCustomField arrayOfCustomField = new DocuSignAPI.ArrayOfCustomField();
        arrayOfCustomField.CustomField = new DocuSignAPI.CustomField[1];
        arrayOfCustomField.CustomField[0] = field;
        it.Envelope.CustomFields = arrayOfCustomField;

        DocuSignAPI.EnvelopeStatus result;
        Boolean queuedJobForSending = false;
        try {
            result = dsAPI.CreateEnvelopeFromTemplatesAndForms(envelope, compositeTemplates, true);
        } catch (CalloutException e) {
            String errorMessage = e.getMessage();
            if (errorMessage.contains('Exceeded maximum time allotted for callout')) {
                System.enqueueJob(new AutoRetryContractSend(dsAPI, envelope, compositeTemplates, true, 1));
                queuedJobForSending = true;
            } else {
                Logger.logLater('DocuSignHelper', 'sendLoanPackage',
                    'Unsuccessful CreateEnvelopeFromTemplatesAndForms for Opportunity ' + opp.Id +
                        ' error message: ' + e.getMessage(), 'Error');
            }
        }
        if (opp.Partner_Tasks__r[0] != null && (queuedJobForSending || result != null)) {
            // need to update partner task to pending after sending
            opp.Partner_Tasks__r[0].Status__c = 'Pending';
            update opp.Partner_Tasks__r[0];
        }
        Logger.flushLogs();
        if (oppLoansSent == null) {
            oppLoansSent = new List<Opportunity>();
        }
        oppLoansSent.add(opp);
        return result;
    }

    public static DocuSignAPI.RecipientCaptiveInfo getCaptiveInfo(Opportunity opp, String recipientRole) {
        DocuSignAPI.RecipientCaptiveInfo captiveInfo = new DocuSignAPI.RecipientCaptiveInfo();
        captiveInfo.ClientUserId = opp.Id + ': ' + recipientRole;
        return captiveInfo;
    }

    public static DocuSignAPI.EnvelopeStatus sendCSPackage(Opportunity opp, Integer count, Integer total) {
        connect();
        DocuSignAPI.EnvelopeInformation envelope = new DocuSignAPI.EnvelopeInformation();
        envelope.Subject = opp.Name + ' Community Solar Contract ' + '(' + count + ' of ' + total + ')';
        envelope.EmailBlurb = 'Please Review and Sign this Contract';
        envelope.AccountId = apiAccountId;
        Integer csBWSignatureGroup = getSigningGroup('BW CS');
        Integer qcSignatureGroup = getSigningGroup('BW QC Signature');
        DocuSignAPI.EnvelopeTemplate et = dsAPI.RequestTemplateWithDocumentFields(opp.Docusign_Template__c, true);
        for (DocuSignAPI.Recipient r : et.Envelope.Recipients.Recipient) {
            if (r.RoleName == 'Signer 1') {
                r.UserName = opp.Parent_Account_Name__c;
                r.Email = opp.Email__c;
                r.CaptiveInfo = getCaptiveInfo(opp, r.Type_x);
            } else if (r.RoleName == 'Signer 2'){
                r.SigningGroupId = csBWSignatureGroup;
            } else if (r.RoleName == 'QC Approver'){
                r.SigningGroupId = qcSignatureGroup;
            } else if (r.RoleName == 'Recipient 1'){
                r.UserName = opp.Sales_tag__c;
                r.Email = opp.Salesperson_Email__c;
            } else if (r.RoleName == 'Recipient 3'){
                r.UserName = opp.Parent_Account_Name__c;
                r.Email = opp.Email__c;
            } else if (r.RoleName == 'Customer CC'){
                r.UserName = opp.Parent_Account_Name__c;
                r.Email = opp.Email__c;
            } else {
                Logger.logLater('DocuSignHelper', 'sendCSPackage', 'error in mapping this recipient:' + String.valueOf(r.RoleName), 'Error');
            }
        }
        DocuSignAPI.InlineTemplate it = new DocuSignAPI.InlineTemplate();
        it.Sequence = 1;
        it.Envelope = et.Envelope;
        DocuSignAPI.ArrayOfCompositeTemplate compositeTemplates = new DocuSignAPI.ArrayOfCompositeTemplate();
        compositeTemplates.CompositeTemplate = new DocuSignAPI.CompositeTemplate[1];
        compositeTemplates.CompositeTemplate[0] = new DocuSignAPI.CompositeTemplate();
        compositeTemplates.CompositeTemplate[0].InlineTemplates = new DocuSignAPI.ArrayOfInlineTemplate();
        compositeTemplates.CompositeTemplate[0].InlineTemplates.InlineTemplate = new DocuSignAPI.InlineTemplate[1];
        compositeTemplates.CompositeTemplate[0].InlineTemplates.InlineTemplate[0] = it;
        DocuSignAPI.CustomField field = new DocuSignAPI.CustomField();
        field.Name = '##SFOpportunity';
        field.Value = opp.Id;    //value of your external source Id
        field.Show = 'false';
        DocuSignAPI.ArrayOfCustomField arrayOfCustomField = new DocuSignAPI.ArrayOfCustomField();
        arrayOfCustomField.CustomField = new DocuSignAPI.CustomField[1];
        arrayOfCustomField.CustomField[0] = field;
        it.Envelope.CustomFields = arrayOfCustomField;
        DocuSignAPI.EnvelopeStatus result;
        try {
            result = dsAPI.CreateEnvelopeFromTemplatesAndForms(envelope, compositeTemplates, true);
        } catch (CalloutException e) {
            String errorMessage = e.getMessage();
            if (errorMessage.contains('Exceeded maximum time allotted for callout')) {
                Logger.logLater('DocuSignHelper', 'sendCSPackage',
                    'CalloutException due to timeout caught when trying to send contracts for opp: ' + opp.Id +
                        ', but queueing to retry', 'Info');
                System.enqueueJob(new AutoRetryContractSend(dsAPI, envelope, compositeTemplates, true, 1));
            } else {
                Logger.logLater('DocuSignHelper', 'sendCSPackage',
                    'Unsuccessful CreateEnvelopeFromTemplatesAndForms for Opportunity ' + opp.Id +
                        ' error message: ' + e.getMessage(), 'Error');
            }
        }
        // Don't flush logs here, since this is called in a loop which will result in another callout
        // Logger.flushLogs();
        return result;
    }

    public static void getBaseUrl() {
        DocuSignHelper result = requestResource('/login_information', 'GET');
        baseUrl = result.loginAccounts[0].baseUrl;
        accountId = result.loginAccounts[0].accountId;
    }

    public static Integer getSigningGroup(String groupName) {
        if (baseUrl == null) {
            getBaseUrl();
        }
        DocuSignHelper result = requestResource('/accounts/'+accountId+'/signing_groups', 'GET');
        for (SigningGroup sg : result.groups) {
            if (sg.groupName == groupName) {
                return Integer.valueOf(sg.signingGroupId);
            }
        }
        return 0;
    }

    public static DocuSignHelper requestResource(String endpoint, String method) {
        connect();
        HttpRequest req = new HttpRequest();
        req.setEndpoint(restAPIServer + endpoint);
        req.setMethod(method);
        req.setHeader('X-DocuSign-Authentication', restHeader);
        req.setTimeout(120000); // 2 minute timeout

        Http http = new Http();
        HTTPResponse res = http.send(req);
        String json = res.getBody();
        DocuSignHelper result = (DocuSignHelper) System.JSON.deserialize(json, DocuSignHelper.class);
        if (result.errorCode != null) {
            throw new Util.BWException(result.message);
        }
        return result;
    }

    public class AutoRetryContractSend implements Queueable, Database.AllowsCallouts  {
        public DocuSignAPI.APIServiceSoap  dsAPI;
        public DocuSignAPI.EnvelopeInformation envelope;
        public DocuSignAPI.ArrayOfCompositeTemplate compositeTemplates;
        public Boolean activateEnvelope;
        public Integer attempt;
        public Integer maxAttempts = 3;

        public AutoRetryContractSend(DocuSignAPI.APIServiceSoap  dsAPI, DocuSignAPI.EnvelopeInformation envelope, DocuSignAPI.ArrayOfCompositeTemplate compositeTemplates,Boolean activateEnvelope, Integer attempt) {
            this.dsAPI = dsAPI;
            this.envelope = envelope;
            this.compositeTemplates = compositeTemplates;
            this.activateEnvelope = activateEnvelope;
            this.attempt = attempt;
        }

        public void execute(QueueableContext context) {
            try {
                dsAPI.CreateEnvelopeFromTemplatesAndForms(envelope, compositeTemplates, true);
            } catch (CalloutException e) {
                String errorMessage = e.getMessage();
                if (attempt <= maxAttempts && errorMessage.contains('Exceeded maximum time allotted for callout')) {
                    System.enqueueJob(new AutoRetryContractSend(dsAPI, envelope, compositeTemplates, true, attempt++));
                } else {
                    String message = 'Tried to send contracts ' + attempt + ' times, but it failed.'
                        + '. Message: ' + errorMessage;
                    Logger.logNow('DocuSignHelper', 'AutoRetryContractSend', message);
                }
            }
        }
    }

    public String errorCode;
    public String message;

    public class LoginAccounts {
        public String name;
        public String accountId;
        public String baseUrl;
        public String isDefault;
        public String userName;
        public String userId;
        public String email;
        public String siteDescription;
    }
    public List<LoginAccounts> loginAccounts;

    public class SigningGroup {
        public String signingGroupId;
        public String groupName;
        public String groupType;
        public String created;
        public String createdBy;
        public String modified;
        public String modifiedBy;
    }
    public List<SigningGroup> groups;
}