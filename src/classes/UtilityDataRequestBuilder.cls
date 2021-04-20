/**
 * @description Creates UDRs
 * Tested by: UtilityDataRequestServiceTest, GlyntUploadServiceTest
 */
public without sharing class UtilityDataRequestBuilder {
    private static UALSelector ualSelector = new UALSelector();
    private static GlyntUploadService glyntUploadService = new GlyntUploadService();
    private static fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
        new List<Schema.SObjectType> {
            Utility_Data_Request__c.SObjectType,
            Utility_Account_Log__c.SObjectType,
            ContentDocumentLink.SObjectType
        }
    );

    /**
     * @description Assesses if UDRs should be generated for passed-in lead ids based on Utility Data Collection Mechanism
     * <p></p>
     * This method will NOT generate UDRs if any existing are found already related to UALs
     * It will queue the Glynt upload and extraction if it creates UDRs for utilities for which we're using Glynt
     * @param leadIds Leads to check for UDR creation
     * @author Jeff Parlin 10-28-20
     */
    @Future
    public static void create(List<String> leadIds) {
        try {
            innerCreate(leadIds);
        } catch (Exception e) {
            String message = 'Unable to create UDRs or update UALs for Leads: '
                + leadIds.toString() + '\n\n' + e.getMessage() + '\n\n' + e.getStackTraceString();
            Logger.logNow('UtilityDataRequestService', 'create (@future)', message, 'Error');
        }
    }
    private static void innerCreate(List<String> leadIds) {
        List<Utility_Account_Log__c> uals = ualSelector.selectUalsWithUdrs(leadIds);
        List<Utility_Data_Request__c> utilityDataRequestsForGlynt = new List<Utility_Data_Request__c>();
        for (Utility_Account_Log__c ual : uals) {
            if (!ual.Utility_Data_Requests__r.isEmpty()) {
                continue;
            }
            if (ual.Utility_lookup__r.Use_Glynt__c) {
                utilityDataRequestsForGlynt.addAll(constructUDRsForGlyntUAL(ual));
            } else {
                constructNewUDR(ual);
            }
        }
        uow.commitWork();
        if (!utilityDataRequestsForGlynt.isEmpty()) {
            glyntUploadService.queueGlyntUpload(utilityDataRequestsForGlynt);
        }
    }

    @TestVisible
    private static Utility_Data_Request__c constructNewUDR(Utility_Account_Log__c ual) {
        Utility_Data_Request__c udr = new Utility_Data_Request__c(
            Account_Number__c       = ual.Name,
            Utility__c              = ual.Utility_lookup__c,
            Utility_DUNS__c         = ual.Utility_lookup__r.Utility_DUNS_Number__c,
            Utility_Name__c         = ual.Utility_lookup__r.Name,
            Utility_Account_Log__c  = ual.Id,
            Header_Status__c        = 'Pending',
            Detail_Status__c        = 'Pending',
            Premise_Number__c       = ual.Premise_Number__c,
            Service_Provider__c     = ual.Utility_lookup__r.Use_Glynt__c ? 'Glynt' : 'ESG'
        );
        uow.registerNew(udr);
        ual.QC_Status__c = 'Pending Utility Data';
        uow.registerDirty(ual);
        return udr;
    }

    private static List<Utility_Data_Request__c> constructUDRsForGlyntUAL(Utility_Account_Log__c ual) {
        List<Utility_Data_Request__c> utilityDataRequests = new List<Utility_Data_Request__c>();
        if (!ual.Utility_Data_Requests__r.isEmpty()) {
            return utilityDataRequests;
        }
        for (ContentDocumentLink ualCDL : ual.ContentDocumentLinks) {
            Utility_Data_Request__c udr = constructNewUDR(ual);
            utilityDataRequests.add(udr);
            ContentDocumentLink udrCDL = new ContentDocumentLink(
                Visibility = 'AllUsers',
                ShareType = 'V',
                ContentDocumentId = ualCDL.ContentDocumentId
            );
            uow.registerNew(udrCDL, ContentDocumentLink.LinkedEntityId, udr);
        }
        return utilityDataRequests;
    }

}