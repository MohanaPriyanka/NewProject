/**
 * @description: Enrolls Contacts in a Marketing Cloud Journey and fills respective Data Extension (through API callouts)
 * Tested By: MarketingJourneyEnrollerTest
 */
public without sharing class MarketingJourneyEnroller implements Queueable, Database.AllowsCallouts {

    private static final String ENDPOINT = '/interaction/v1/events';
    private static MarketingAPIHelper api = new MarketingAPIHelper();
    private static Integer maxCallouts = MarketingAPIHelper.calloutsPerTransaction;
    private List<MarketingAPI.JourneyEnrollment> enrollments;

    public MarketingJourneyEnroller(List<MarketingAPI.JourneyEnrollment> details) {
        this.enrollments = details;
    }

    @InvocableMethod(Label='Marketing Cloud Journey Enroller')
    public static void enrollContactsInJourney(List<MarketingAPI.JourneyEnrollment> details) {
        System.enqueueJob(new MarketingJourneyEnroller(details));
    }

    public void execute(QueueableContext context) {
        MarketingAPI.JourneyEnrollment enrollment;
        if (!MarketingAPIHelper.publishToAPI) {
            return;
        }
        try {
            for (Integer i = enrollments.size()-1; i >= 0; i--) {
                enrollment = enrollments[i];
                enrollContact(enrollment.constructPayload());
                enrollments.remove(i);
                Boolean chainJobs = Limits.getCallouts() >= maxCallouts && !Test.isRunningTest() && !enrollments.isEmpty();
                if (chainJobs) {
                    System.enqueueJob(new MarketingJourneyEnroller(enrollments));
                    break;
                }
            }
        } catch (Exception e) {
            String err = e.getMessage() + ' ' + e.getStackTraceString() + '\n\nEnrollment:\n' + enrollment;
            Logger.logLater('MarketingJourneyEnroller','execute',err,Logger.ERROR);
        }
        Logger.flushLogs();
    }

    private void enrollContact(Object payload) {
        HttpResponse response = api.callJsonEndpoint('POST', ENDPOINT, payload);
        if (response?.getStatusCode() == 201 && MarketingAPIHelper.logResults) {
            String message = 'Successful Marketing Cloud journey enrollment!\nRequest: ' + JSON.serialize(payload) +
                '\nResponse: ' + response.getBody() + '\n\n';
            Logger.logLater('MarketingJourneyEnroller', 'enrollContact', message, Logger.FINE);
        } else if (response?.getStatusCode() != 201 || response == null) {
            String message = 'Error encountered in Marketing Cloud journey enrollment....\nRequest: ' +
                JSON.serialize(payload) + '\nResponse: ' + response?.getBody() + '\n\n';
            Logger.logLater('MarketingJourneyEnroller', 'enrollContact', message, Logger.ERROR);
        }
    }
}