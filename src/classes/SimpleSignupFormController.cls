/**
 * Created by PeterYao on 2/24/2020.
 * Tested By: SimpleSignupFormControllerTest
 */

public without sharing class SimpleSignupFormController {
    private static ContentDocumentSelector contentDocumentSelector = new ContentDocumentSelector();
    private static CustomerContractSelector customerContractSelector = new CustomerContractSelector();
    private static CSLeadsRESTControllerV3 restControllerV3 = new CSLeadsRESTControllerV3();


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
}