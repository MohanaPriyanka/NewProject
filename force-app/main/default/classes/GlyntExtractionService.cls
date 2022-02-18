/**
 * @description: Creates an extraction request, and retrieves extraction results (queueing again if incomplete).
 * Tested By: GlyntExtractionServiceTest
 */
public without sharing class GlyntExtractionService extends Promise implements Processor {
    private static GlyntAPIHelper apiHelper = new GlyntAPIHelper();
    @TestVisible private static String extractionsEndpoint = '/v6/data-pools/' + GlyntAPIHelper.dataPoolId + '/extractions/';
    private Datetime retryUntil;
    @TestVisible private static GlyntExtractionService extractionRetryService;

    /**
     * @description Allows other implementations of processExtractions, which is set in the Glynt Configurations metadata
     */
    public interface Processor {
        void processExtractions(List<GlyntAPI.ExtractionResponse> extractionResponses);
    }

    /**
     * @description Default constructor used to create extractions
     */
    @SuppressWarnings('PMD.EmptyStatementBlock')
    public GlyntExtractionService() {
    }

    /**
     * @description Constructor used to retrieve extractions
     * @param retryUntil Timeout, after which this class should not queue to retrieve extractions
     */
    public GlyntExtractionService(Datetime retryUntil) {
        this.retryUntil = retryUntil;
    }

    /**
     * @description Starts querying for extraction results for the extraction ids in passThrough (the Promise variable)
     */
    public override void execute() {
        if (passThrough == null) {
            return;
        }
        List<String> incompleteExtractions = new List<String>();
        List<GlyntAPI.ExtractionResponse> completeExtractions = new List<GlyntAPI.ExtractionResponse>();
        try {
            for (String extractionId : (List<String>) passThrough) {
                GlyntAPI.ExtractionResponse response = retrieveExtraction(extractionId);
                if (response.finished) {
                    completeExtractions.add(response);
                } else {
                    incompleteExtractions.add(extractionId);
                }
            }
            handleExtractionResponses(completeExtractions, incompleteExtractions);
        } catch (Exception e) {
            Logger.logLater('GlyntExtractionService', 'execute', e.getMessage() + '\n' + e.getStackTraceString(), Logger.ERROR);
        } finally {
            Logger.flushLogs();
        }
    }

    private void handleExtractionResponses(List<GlyntAPI.ExtractionResponse> completeExtractions, List<String> incompleteExtractions) {
        if (!completeExtractions.isEmpty() && GlyntAPIHelper.extractionProcessor != null) {
            Processor processor = (Processor) Type.forName(GlyntAPIHelper.extractionProcessor).newInstance();
            processor.processExtractions(completeExtractions);
        }
        if (!incompleteExtractions.isEmpty()) {
            requeueExtractionRetrieval(incompleteExtractions);
        }
    }

    private void requeueExtractionRetrieval(List<String> incompleteExtractions) {
        if (System.now() <= retryUntil) {
            extractionRetryService = new GlyntExtractionService(retryUntil);
            extractionRetryService.passThrough = incompleteExtractions;
            if (!Test.isRunningTest()) {
                System.enqueueJob(extractionRetryService);
            }
        } else {
            Logger.logLater(
                'GlyntExtractionService',
                'execute',
                'Giving up on retrieving extractions because it has been longer than the timeout retryUntil: ' + retryUntil + ', extraction ids:\n' + incompleteExtractions,
                Logger.ERROR);
        }
    }

    /**
     * @description Creates a single extraction for the document in the extractionRequest.
     * @param extractionRequest A Glynt documentId and tag for the extraction
     * @return An ExtractionResponse
     */
    public GlyntAPI.ExtractionResponse createExtraction(GlyntAPI.ExtractionRequest extractionRequest) {
        HttpResponse response = apiHelper.callJsonEndpoint('POST', extractionsEndpoint, extractionRequest, false);
        if (response.getStatusCode() != 201) {
            throw new Util.BWException('Could not create an extraction:\n' + response.getBody());
        }
        GlyntAPI.ExtractionResponse extractionResponse =
            (GlyntAPI.ExtractionResponse) JSON.deserialize(response.getBody(), GlyntAPI.ExtractionResponse.class);
        return extractionResponse;
    }

    /**
     * @description Retrieves a single extraction from Glynt via extractionId.
     * @param extractionId Glynt Id used to request the extraction data
     * @return An ExtractionResponse
     */
    public GlyntAPI.ExtractionResponse retrieveExtraction(String extractionId) {
        HttpResponse response = apiHelper.callJsonEndpoint('GET', extractionsEndpoint + extractionId, null, false);
        if (response.getStatusCode() != 200) {
            throw new Util.BWException('Could not get extraction details:\n' + response.getBody());
        }
        GlyntAPI.ExtractionResponse extractionResponse =
            (GlyntAPI.ExtractionResponse) JSON.deserialize(response.getBody(), GlyntAPI.ExtractionResponse.class);
        return extractionResponse;
    }

    /**
     * @description Implementation of Processor interface, called when this class gets successful and finished extractions.
     * Intended to be used for debugging
     * @param extractionResponses List of responses to process
     */
    public void processExtractions(List<GlyntAPI.ExtractionResponse> extractionResponses) {
        Logger.logLater('GlyntExtractionService', 'processExtractions', JSON.serializePretty(extractionResponses), Logger.INFO);
    }
}