/**
 * Created by PeterYao on 2/24/2020.
 * Tested By: SimpleSignupFormControllerTest
 */
@SuppressWarnings('PMD.ApexCRUDViolation,PMD.ApexDoc')
public without sharing class SimpleSignupFormController {
    private static ContentDocumentSelector contentDocumentSelector = new ContentDocumentSelector();
    private static CustomerContractSelector customerContractSelector = new CustomerContractSelector();
    private static CSLeadsRESTControllerV3 restControllerV3 = new CSLeadsRESTControllerV3();
    private static LeadSelector leadSelector = new LeadSelector();

    @AuraEnabled
    public static String getContentDistributionById(Id leadId, String email, Id documentId) {
        try {
            restControllerV3.validateAuthorization(leadId, email);
        } catch (Util.AuthorizationBWException abwe) {
            throw Util.createAuraExceptionWithMessage('The email (' + email + ') and leadId (' + leadId + ') provided did not match');
        }

        return contentDocumentSelector.getPublicDistributionLinkByDocId(documentId);
    }

    @AuraEnabled
    public static String getContentDocumentLinksByLead(Id leadId, String email, Datetime mostRecentContractGen) {
        try {
            restControllerV3.validateAuthorization(leadId, email);
        } catch (Util.AuthorizationBWException abwe) {
            throw Util.createAuraExceptionWithMessage('The email (' + email + ') and leadId (' + leadId + ') provided did not match');
        }

        List<Contract> contracts = customerContractSelector.selectByRelatedLead(leadId);
        List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
        if(mostRecentContractGen != null) {
            cdlList = contentDocumentSelector.getContractsAfterDateByLinkedEntity(contracts[0].Id, mostRecentContractGen);
        } else {
            cdlList = contentDocumentSelector.selectByLinkedEntity(contracts[0].Id);
        }

        List<RestLead.RestContentDocument> returnRcd = new List<RestLead.RestContentDocument>();
        for(ContentDocumentLink cdl : cdlList) {
            RestLead.RestContentDocument rcd = new RestLead.RestContentDocument(cdl);
            rcd.publicUrl = contentDocumentSelector.getPublicDistributionLinkByDocId(rcd.id);
            returnRcd.add(rcd);
        }
        
        return JSON.serialize(returnRcd);
    }

    // used before we have a lead id and email, so no way to authenticate
    @AuraEnabled(cacheable=true)
    public static String getDummyRecordId(){
        if(Schema.sObjectType.Custom_File_Upload_Share__c.fields.Id.isAccessible()) {
            List<Custom_File_Upload_Share__c> cfus = [SELECT Id FROM Custom_File_Upload_Share__c ORDER BY CreatedDate DESC LIMIT 1];
            if(!cfus.isEmpty()) {
                return cfus[0].Id;
            }
        }

        return null;
    }

    // used before we have a lead id and email, so no way to authenticate
    @SuppressWarnings('PMD.ApexCRUDViolation')
    @AuraEnabled
    public static String unlinkDocsFromDummyRecord(List<String> documents, String category){
        Id dummyRecordId = getDummyRecordId();
        Id ownerId = getReparentUserId();
        if(dummyRecordId == null || ownerId == null) {
            Logger.logNow('SimpleSignupFormController', 'unlinkDocsFromDummyRecord', 'Unable to reparent uploaded docs for site guest user file upload. Missing dummy record or new owner ID.');
            return null;
        }

        List<ContentDocumentLink> linksToDelete = new List<ContentDocumentLink>();
        Set<Id> documentIds = new Set<Id>();
        for(String doc : documents) {
            documentIds.add(doc);
        }

        List<ContentVersion> contentVersions = new List<ContentVersion>();
        for (ContentDocumentLink link : [SELECT Id, LinkedEntityId, ContentDocumentId, ContentDocument.LatestPublishedVersionId FROM ContentDocumentLink WHERE ContentDocumentId IN: documentIds AND LinkedEntityId = :dummyRecordId]){
            linksToDelete.add(link);
            contentVersions.add(new ContentVersion(Id = link.ContentDocument.LatestPublishedVersionId, File_Category__c = category));
        }

        Database.SaveResult[] srList = Database.update(contentVersions, false);
        for(Database.SaveResult sr : srList) {
            if(!sr.isSuccess()) {
                for(Database.Error error : sr.getErrors()) {
                    Logger.logLater('SimpleSignupFormController', 'unlinkDocsFromDummyRecord', 'Unable to assign category of ' + category + ' to site guest user file upload. ' + error.getMessage());
                }
            }
        }

        try {
            delete linksToDelete;
            changeOwnerOfUpload(documentIds, ownerId);
        } catch(Exception ex) {
            Logger.logLater('SimpleSignupFormController', 'unlinkDocsFromDummyRecord', 'Unable to reparent uploaded docs for site guest user file upload. ' + ex.getMessage() + '\nStack Trace: ' + ex.getStackTraceString());
        }
        Logger.flushLogs();
        return 'OK';
    }

    /**
     * @param className     Class/component where failure occurred
     * @param methodName    Method where failure occurred
     * @param message       Error message or stack trace
     * @param severity      Severity (e.g. 'Error', 'Warn', 'Debug', etc.)
     * <p>
     *     See Logger.logNow() for more information
     *
     *     @author Jeff Parlin
     */
    @AuraEnabled
    public static void log(String className, String methodName, String message, String severity) {
        Logger.logNow(className, methodName, message, severity);
    }

    /**
     * @description Checks result of latest credit report (if it exists) to determine if we want to request
     *  additional information from the applicant or partner in SSF via a separate screen
     * @param leadId id of the lead to check for Personal Credit Report (PCR) records
     * @param queryAllHistoric Query for all historic PCRs on the lead, true or false
     * @param queryAfter (Optional) query only for PCRs created on or after specified datetime string
     * @return returns CreditReportChecker.LatestReportDetail object if needed, otherwise returns null
     */
    @SuppressWarnings('PMD.ApexCRUDViolation')
    @AuraEnabled(Cacheable=false)
    public static CreditReportChecker.LatestReportDetail getLatestCreditReport(
        Id leadId, Boolean queryAllHistoric, String queryAfter)
    {
        CreditReportChecker checker;
        if (queryAllHistoric) {
            checker = new CreditReportChecker(leadId);
        } else {
            Datetime queryAfterDatetime = queryAfter == null ? Datetime.now() : Datetime.parse(queryAfter);
            checker = new CreditReportChecker(leadId, queryAfterDatetime);
        }

        return checker.getLatestReportDetail();
    }

    /**
     * @description Deserializes input data into Lead object and updates server, triggering run of soft credit pull
     * @param lead Partial lead record passed in
     * @return Datetime string corresponding to time of last successful update on the Lead, or ERROR if err encountered
     */
    @SuppressWarnings('PMD.ApexCRUDViolation')
    @AuraEnabled(Cacheable=false)
    public static String updateLeadAndRunCreditCheck(Lead lead) {
        String response;
        try {
            lead.Soft_Pull_Credit_Report__c = true;
            response = Datetime.now().format();
            update lead;
        } catch (Exception e) {
            log('SimpleSignupFormController',
                'updateLeadAndRunCreditCheck',
                e.getMessage() + '\n\n' + e.getStackTraceString() + '\n\n' + 'lead: ' + lead,
                'ERROR'
            );
            return 'ERROR';
        }
        return response;
    }

    @AuraEnabled
    public static String findDuplicateUALs(String ualNumber) {
        List<Utility_Account_Log__c> duplicateUALs = new UALSelector().selectDuplicateUALs(ualNumber);
        String duplicateResult = 'No Duplicate Found';

        if (duplicateUALs.size() > 0) {
            duplicateResult = handleDuplicateUALs(duplicateUALs);
        }
        return duplicateResult;
    }

    /**
     * @description Loops through duplicate UALs to determine the state of the Application or Subscriptions.
     * @param duplicateUALs List of Utility Account Logs and their subscriptions
     * @return Gives further instruction on how to handle duplicate. If incomplete application, returns lead Id in order
     * to send a "Continue Application" email
     */
    public static String handleDuplicateUALs(List<Utility_Account_Log__c> duplicateUALs) {
        for (Utility_Account_Log__c ual : duplicateUALs) {
            if ((ual.Lead__r.Application_Complete_Date__c != null && ual.Lead__r.Status != 'Unqualified' && !ual.Lead__r.IsConverted
            ) || hasExistingSubscription(ual) ) {
                return 'Application in Review';
            } else if (ual.Lead__c != null && ual.Lead__r.Application_Complete_Date__c == null
                && ual.Lead__r.Status != 'Unqualified') {
                return ual.Lead__r.Id;
            }
        }
        return 'No Duplicate Found';
    }

    /**
     * @description When a duplicate SSF applicant is found, we send them (along with their partner) an email with a link to
     * continue their existing application.
     * @param leadId Lead Id for duplicate lead already in SF
     */
    @AuraEnabled
    public static void sendContinueApplicationEmail(Id leadId) {
        System_Default__mdt systemDefault = new FeatureSelector().getSystemDefaults();
        Lead lead = leadSelector.selectOne(leadId);

        if (Test.isRunningTest() && lead == null) {
            //For tests that are using mocks, the lead cannot be mocked in a future method - we therefore exit the method
            return;
        }
        if (systemDefault.Continue_Application_Email_Template__c == null) {
            Logger.logNow('SimpleSignupFormController', 'sendContinueApplicationEmail',
                'Continue Application email was not sent to ' + lead.Id, Logger.WARN);
            return;
        }

        MessagingService.EmailEnvelope ee = new MessagingService.EmailEnvelope();
        ee.emailTemplateName = systemDefault.Continue_Application_Email_Template__c;
        ee.orgWideEmail =  MessagingService.getCustomerCareEmail().Address;
        ee.addressList = new List<String>{lead.Email, lead.Partner_Email__c};
        ee.subjectLine = 'Continue Your Application for Bluewave Community Solar';
        MessagingService.ReplacementText url = new MessagingService.ReplacementText('{{{Recipient.Continue_Application_Link__c}}}', lead.Continue_Application_Link__c);
        MessagingService.ReplacementText leadName = new MessagingService.ReplacementText('{{{Recipient.Name}}}', lead.Name);
        ee.replacementTexts = new List<MessagingService.ReplacementText>{url, leadName};
        ee.sobjectId = lead.Id;

        try {
            MessagingService.sendEmailTemplate(ee);
        } catch (Exception e) {
            Logger.logNow('SimpleSignupFormController', 'sendContinueApplicationEmail', e.getMessage() +
                '; ' + e.getStackTraceString());
        }
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static Id getReparentUserId() {
        String siteName = Site.getName();
        List<Site> sites = [SELECT GuestRecordDefaultOwnerId FROM Site WHERE Name = :siteName];
        if(!sites.isEmpty() && sites[0].GuestRecordDefaultOwnerId != null) {
            return sites[0].GuestRecordDefaultOwnerId;
        }

        // if method is not called from site context, return backup user
        List<User> backupUser = [SELECT Id, Email, Username FROM User WHERE Name = 'API'];
        if(!backupUser.isEmpty()) {
            return backupUser[0].Id;
        }

        return null;
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    @TestVisible
    private static void changeOwnerOfUpload(Set<Id> docIds, Id ownerId){
        List<ContentDocument> newDocs = new List<ContentDocument>();
        for(ContentDocument myDoc : [SELECT Id FROM ContentDocument WHERE Id IN: docIds]){
            myDoc.OwnerId = ownerId;
            newDocs.add(mydoc);
        }
        update newDocs;
    }

    private static Boolean hasExistingSubscription(Utility_Account_Log__c ual) {
        for (Utility_Account_Subscription__c uas : ual.Utility_Account_Subscriptions__r ) {
            if (uas.Opportunity__r.StageName != 'Cancelled' &&
                uas.Opportunity__r.StageName != 'DUPLICATE' &&
                uas.Opportunity__r.StageName != 'Expired' &&
                uas.Opportunity__r.StageName != 'Dead') {
                return true;
            }
        }
        return false;
    }

    /**
     * @description Retrieves truncated RestZipCode for resume apps. Method tested in CapacityServiceTest.
     * @param zip ZIP Code
     * @param utilityId Utility ID
     * @param isFico Underwriting == FICO?
     * @return Stringified RestZipCode for immediate use in SSF in resume app situations where capacity check not needed
     */
    @SuppressWarnings('PMD.ApexCRUDViolation')
    @AuraEnabled(Cacheable=false)
    public static String getZipcodeDataForResumeApp(String zip, String utilityId, Boolean isFico) {
        CapacityService capacityService = new CapacityService();
        return JSON.serialize(new RestZipCode(capacityService.getZipcodeResponseForResumeApp(zip,utilityId,isFico)));
    }
}