/**
 * @description: Uploads utility bills to Glynt and starts an extraction
 * Tested By: GlyntUploadServiceTest
 */
public without sharing class GlyntUploadService implements Queueable, Database.AllowsCallouts {
    private static GlyntAPIHelper apiHelper = new GlyntAPIHelper();
    @TestVisible private static ContentDocumentSelector contentDocumentSelector = new ContentDocumentSelector();
    @TestVisible private static GlyntExtractionService extractionService = new GlyntExtractionService();
    @TestVisible private static GlyntExtractionService extractionRetrievalService;
    @TestVisible private Set<Id> utilityDataRequestsToUpload;

    /**
     * @description Associates a Utility Account Log's Content (assumed to be a utility bill) to the corresponding
     * Utility Data Request, to make it obvious which bill upload is being requested.
     * @param utilityDataRequests The UDRs, from an after insert Trigger.new
     */
    public void associateContentToUDRs(List<Utility_Data_Request__c> utilityDataRequests) {
        Set<Id> utilityAccountLogIds = new Set<Id>();
        Map<Id, Id> ualIdToUDRIdMap = new Map<Id, Id>();
        for (Utility_Data_Request__c udr : utilityDataRequests) {
            utilityAccountLogIds.add(udr.Utility_Account_Log__c);
            ualIdToUDRIdMap.put(udr.Utility_Account_Log__c, udr.Id);
        }
        List<ContentDocumentLink> contentDocumentLinksForUALs =
            contentDocumentSelector.selectByLinkedEntitiesWithoutData(utilityAccountLogIds);
        List<ContentDocumentLink> contentDocumentLinksForUDRs = new List<ContentDocumentLink>();
        for (ContentDocumentLink ualCDL : contentDocumentLinksForUALs) {
            contentDocumentLinksForUDRs.add(
                new ContentDocumentLink(
                    LinkedEntityId = ualIdToUDRIdMap.get(ualCDL.LinkedEntityId),
                    Visibility = 'AllUsers',
                    ShareType = 'V',
                    ContentDocumentId = ualCDL.ContentDocumentId
                )
            );
        }
        insert contentDocumentLinksForUDRs;
    }

    /**
     * @description Starts the upload to Glynt via queueable
     * @param utilityDataRequestIds The list of UDR Ids to upload
     */
    public void queueGlyntUpload(Set<Id> utilityDataRequestIds) {
        GlyntUploadService uploadService = new GlyntUploadService();
        uploadService.utilityDataRequestsToUpload = utilityDataRequestIds;
        System.enqueueJob(uploadService);
    }

    /**
     * @description Queueable execution
     * @param context Unused
     */
    public void execute(QueueableContext context) {
        try {
            List<ContentDocumentLink> contentDocumentLinks =
                contentDocumentSelector.selectByLinkedEntities(utilityDataRequestsToUpload);
            List<String> extractions = new List<String>();
            for (ContentDocumentLink cdl : contentDocumentLinks) {
                String glyntDocumentId = createDocument(cdl);
                GlyntAPI.ExtractionResponse extractionResponse =
                    extractionService.createExtraction(new GlyntAPI.ExtractionRequest(glyntDocumentId, cdl.LinkedEntityId));
                extractions.add(extractionResponse.id);
            }
            extractionRetrievalService =
                new GlyntExtractionService(System.now().addMinutes(GlyntAPIHelper.extractionQueryTimeout), extractions);
            if (!Test.isRunningTest()) {
                System.enqueueJob(extractionRetrievalService);
            }
        } catch (Exception e) {
            Logger.logLater('GlyntUploadService', 'execute', e.getMessage() + '\n' + e.getStackTraceString(), Logger.ERROR);
        } finally {
            Logger.flushLogs();
        }
    }

    /**
     * @description POSTS a new document to Glynt. As of Jan 2021, supported types are pdf, jpeg, png, tiff
     * @param documentLinkWithVersionData The contentDocument with ContentVersion.VersionData and FileExtension
     * @return The Glynt document id, to use when creating an extraction
     */
    private String createDocument(ContentDocumentLink documentLinkWithVersionData) {
        GlyntAPI.DocumentUpload documentUpload = new GlyntAPI.DocumentUpload();
        documentUpload.label = documentLinkWithVersionData.ContentDocumentId;
        documentUpload.content_type =
            'application/' + documentLinkWithVersionData.ContentDocument.LatestPublishedVersion.FileExtension; // TODO: only handle supported types
        documentUpload.tags = new List<String>{documentLinkWithVersionData.Id};
        documentUpload.content =
            EncodingUtil.base64Encode(documentLinkWithVersionData.ContentDocument.LatestPublishedVersion.VersionData);
        HttpResponse response =
            apiHelper.callJsonEndpoint('POST', '/v6/data-pools/'+GlyntAPIHelper.dataPoolId+'/documents/', documentUpload, false);
        if (response.getStatusCode() != 201){
            throw new Util.BWException('Could not upload document:\n' + 'Status Code: ' + response.getStatusCode() + '\n' + response.getBody());
        }
        GlyntAPI.DocumentUploadResult uploadResult =
            (GlyntAPI.DocumentUploadResult) JSON.deserialize(response.getBody(), GlyntAPI.DocumentUploadResult.class);
        return uploadResult.id;
    }
}