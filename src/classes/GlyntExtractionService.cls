/**
 * @description:
 */
public without sharing class GlyntExtractionService implements Queueable, Processor, Database.AllowsCallouts {
    private static GlyntAPIHelper apiHelper = new GlyntAPIHelper();
    private static String extractionsEndpoint = '/v6/data-pools/'+GlyntAPIHelper.dataPoolId+'/extractions/';
    private Datetime retryUntil;
    private List<String> extractionsToRetrieve;
    @TestVisible private static GlyntExtractionService extractionRetryService;

    /**
     * @description Allows other implementations of processExtractions, which is set in the Glynt Configurations metadata
     */
    public interface Processor {
        void processExtractions(List<GlyntAPI.ExtractionResponse> extractionResponses);
    }

    /**
     * @description Default constructor
     */
    @SuppressWarnings('PMD.EmptyStatementBlock')
    public GlyntExtractionService() {
    }

    public GlyntExtractionService(Datetime retryUntil, List<String> extractionsToRetrieve) {
        this.retryUntil = retryUntil;
        this.extractionsToRetrieve = extractionsToRetrieve;
    }

    public void execute(QueueableContext context) {
        List<String> incompleteExtractions = new List<String>();
        List<GlyntAPI.ExtractionResponse> completeExtractions = new List<GlyntAPI.ExtractionResponse>();
        try {
            for (String extractionId : extractionsToRetrieve) {
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
            extractionRetryService = new GlyntExtractionService(retryUntil, incompleteExtractions);
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

    private GlyntAPI.ExtractionResponse retrieveExtraction(String extractionId) {
        HttpResponse response = apiHelper.callJsonEndpoint('GET', extractionsEndpoint + extractionId, null, false);
        if (response.getStatusCode() != 200) {
            throw new Util.BWException('Could not get extraction details:\n' + response.getBody());
        }
        GlyntAPI.ExtractionResponse extractionResponse =
            (GlyntAPI.ExtractionResponse) JSON.deserialize(response.getBody(), GlyntAPI.ExtractionResponse.class);
        return extractionResponse;
    }

    public class ProcessingParameter {
        public String className;
        public Datetime timeStarted;
        public List<String> extractionsToRetrieve;
    }

    public void processExtractions(List<GlyntAPI.ExtractionResponse> extractionResponses) {
        Logger.logLater('GlyntExtractionService', 'processExtractions', JSON.serializePretty(extractionResponses), Logger.INFO);
    }
}