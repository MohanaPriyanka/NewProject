/**
 * @description: Uploads utility bills to Glynt and starts an extraction
 * Tested By: GlyntUploadServiceTest
 */
public without sharing class GlyntUploadService extends Promise {
    private static GlyntAPIHelper apiHelper = new GlyntAPIHelper();
    @TestVisible private static ContentDocumentSelector contentDocumentSelector = new ContentDocumentSelector();
    @TestVisible private static GlyntExtractionService extractionService = new GlyntExtractionService();
    private Id sobjectToUpload;

    @SuppressWarnings('PMD.EmptyStatementBlock')
    public GlyntUploadService() {
    }

    public GlyntUploadService(Id sObjectId) {
        sobjectToUpload = sObjectId;
    }

     /**
     * @description Starts the upload to Glynt via queueable for any UDRs with Service Provider of Glynt
     * @param utilityDataRequests List of Utility Data Requests, with Service Provider
     */
    public void queueGlyntUpload(List<Utility_Data_Request__c> utilityDataRequests) {
        Promise firstUploadPromise;
        Promise lastUploadPromise;
        for (Utility_Data_Request__c udr : utilityDataRequests) {
            if (udr.Service_Provider__c == 'Glynt') {
                if (firstUploadPromise == null) {
                    firstUploadPromise = lastUploadPromise = new GlyntUploadService(udr.Id);
                } else {
                    lastUploadPromise = lastUploadPromise.then(new GlyntUploadService(udr.Id));
                }
            }
        }
        if (firstUploadPromise != null) {
            lastUploadPromise.then(new GlyntExtractionService(System.now().addMinutes(GlyntAPIHelper.extractionQueryTimeout)));
            System.enqueueJob(firstUploadPromise);
        }
    }

    /**
     * @description Uploads the content docs related to the first sObject and starts the extraction,  then queues the
     *  remaining objects to upload (if any). Once all are uploaded to Glynt with extractions started, it starts querying
     *  for completed extractions. This assumes that the sObject (e.g. a Utility Data Request) will have a single content
     *  doc, or all content docs will fit in the available heap.
     */
    public override void execute() {
        try {
            List<ContentDocumentLink> contentDocumentLinks =
                contentDocumentSelector.selectByLinkedEntity(sobjectToUpload);
            for (ContentDocumentLink cdl : contentDocumentLinks) {
                String glyntDocumentId = createDocument(cdl);
                GlyntAPI.ExtractionResponse extractionResponse =
                    extractionService.createExtraction(new GlyntAPI.ExtractionRequest(glyntDocumentId, cdl.LinkedEntityId));
                updatePassThrough(extractionResponse.id);
            }
        } catch (Exception e) {
            Logger.logLater('GlyntUploadService', 'execute', e.getMessage() + '\n' + e.getStackTraceString(), Logger.ERROR);
        } finally {
            Logger.flushLogs();
        }
    }

    private void updatePassThrough(String extractionResponseId) {
        if (passThrough == null) {
            passThrough = new List<String>{extractionResponseId};
        } else {
            ((List<String>) passThrough).add(extractionResponseId);
        }
        chain.updatePassThrough(passThrough);
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