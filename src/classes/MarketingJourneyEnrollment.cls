/**
 * Tested By: MarketingJourneyEnrollerTest
 */
public with sharing class MarketingJourneyEnrollment {

    @InvocableVariable(
        Label='Enrollments'
        Required=true
        Description='Marketing Cloud Journey Enrollments, with all necessary properties for the Journey data extension')
    public List<MarketingJourneyEnrollmentDetail> details;

    @SuppressWarnings('PMD.EmptyStatementBlock')
    public MarketingJourneyEnrollment() {
    }
}