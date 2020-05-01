/**
 * Created by PeterYao on 2/24/2020.
 * Tested By: SimpleSignupFormControllerTest
 */

public without sharing class SimpleSignupFormController {
    private static ContentDocumentSelector contentDocumentSelector = new ContentDocumentSelector();
    private static CSLeadsRESTControllerV3 restControllerV3 = new CSLeadsRESTControllerV3();


    @AuraEnabled
    public static String getContentDocumentDataById(Id leadId, String email, Id documentId) {
        try {
            restControllerV3.validateAuthorization(leadId, email);
        } catch (Util.AuthorizationBWException abwe) {
            throw Util.createAuraExceptionWithMessage('The email (' + email + ') and leadId (' + leadId + ') provided did not match');
        }

        List<ContentDocumentLink> contentDocumentLinks = contentDocumentSelector.selectByLinkedEntity(leadId);
        if (contentDocumentLinks.isEmpty()) {
            throw Util.createAuraExceptionWithMessage('Did not find any content docs for lead id ' + leadId);
        }
        for (ContentDocumentLink cdl : contentDocumentLinks) {
            if (cdl.ContentDocumentId == documentId) {
                return EncodingUtil.base64Encode(cdl.ContentDocument.LatestPublishedVersion.VersionData);
            }
        }
        throw Util.createAuraExceptionWithMessage('Document id ' + documentId + ' is not related to lead id ' + leadId);
    }


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
    public static List<ContentDocumentLink> getContentDocumentLinksByLead(Id leadId, String email) {
        try {
            restControllerV3.validateAuthorization(leadId, email);
        } catch (Util.AuthorizationBWException abwe) {
            throw Util.createAuraExceptionWithMessage('The email (' + email + ') and leadId (' + leadId + ') provided did not match');
        }

        return contentDocumentSelector.selectByLinkedEntity(leadId);
    }
}