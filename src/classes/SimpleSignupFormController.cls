/**
 * Created by PeterYao on 2/24/2020.
 * Tested By: SimpleSignupFormControllerTest
 */

public without sharing class SimpleSignupFormController {
    private static ContentDocumentSelector contentDocumentSelector = new ContentDocumentSelector();
    private static CustomerContractSelector customerContractSelector = new CustomerContractSelector();
    private static CSLeadsRESTControllerV3 restControllerV3 = new CSLeadsRESTControllerV3();
    private static ContentService contentService = new ContentService();


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
    public static String getContentDocumentLinksByLead(Id leadId, String email, String mostRecentDocsStr) {
        try {
            restControllerV3.validateAuthorization(leadId, email);
        } catch (Util.AuthorizationBWException abwe) {
            throw Util.createAuraExceptionWithMessage('The email (' + email + ') and leadId (' + leadId + ') provided did not match');
        }

        List<RestLead.RestContentDocument> mostRecentDocs = new List<RestLead.RestContentDocument>();
        if(String.isNotBlank(mostRecentDocsStr)) {
            mostRecentDocs = (List<RestLead.RestContentDocument>)JSON.deserialize(mostRecentDocsStr, List<RestLead.RestContentDocument>.class);
        }

        List<Contract> contracts = customerContractSelector.selectByRelatedLead(leadId);
        List<ContentDocumentLink> cdlList = new List<ContentDocumentLink>();
        if(mostRecentDocs!=null && !mostRecentDocs.isEmpty()) {
            cdlList = contentDocumentSelector.getContractsAfterDateByLinkedEntity(contracts[0].Id, mostRecentDocs[0].createdDate);
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


    @SuppressWarnings('PMD.ApexCRUDViolation')
    public static void changeOwnerOfUpload(Set<Id> docIds, Id ownerId){
        List<ContentDocument> newDocs = new List<ContentDocument>();
        for(ContentDocument myDoc : [SELECT Id FROM ContentDocument WHERE Id IN: docIds]){
            myDoc.OwnerId = ownerId;
            newDocs.add(mydoc);
        }
        update newDocs;
    }

}