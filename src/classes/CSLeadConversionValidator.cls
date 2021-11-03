/**
 * @description Created by jeffparlin on 9/24/21. Validates that leads are ready for conversion and provides response
 *      to caller.
 * Tested By: CSLeadsConverterTest
 */
public without sharing class CSLeadConversionValidator {

    // CS Auto Lead Qualification & Conversion Possible Errors. String values map to
    public static final String CONVERSION_FAILURE = 'Conversion Failure';
    public static final String MULTIPLE_ISSUES = 'Multiple Issues';
    @TestVisible private static final String ALREADY_CONVERTED = 'Lead Already Converted';
    @TestVisible private static final String TESTCASE_LEAD = 'Testcase Lead';
    @TestVisible private static final String APPLICATION_INCOMPLETE = 'Application Incomplete';
    @TestVisible private static final String EMAIL_BOUNCED = 'Invalid Email';
    @TestVisible private static final String INCOMPLETE_UALS = 'Incomplete UALs';
    @TestVisible private static final String NO_QUALIFIED_SYSTEMS = 'No Qualified Systems Found';
    @TestVisible private static final String PRODUCT_MISMATCH = 'System Product Mismatch';
    @TestVisible private static final String AUTO_QC_DISABLED = 'Auto QC Turned Off';
    @TestVisible private static final String NO_DEMAND_CAPACITY_AVAILABLE = 'No Demand Capacity Available';

    private LeadConvertDetail detail;

    public CSLeadConversionValidator(LeadConvertDetail detail) {
        this.detail = detail;
        detail.determineNumberOfDemandUals();
    }

    public void validate() {
        validateLead();
        validateUtility();
        validateSelectedSystemsForConversion();
        validateUtilityAccountLogs();
    }

    @TestVisible
    private void validateLead() {
        if (detail.isAlreadyConvertedLead()) {
            detail.error = ALREADY_CONVERTED;
            detail.errorsEncountered.add(ALREADY_CONVERTED);
        }
        if (detail.isTestcaseLead()) {
            detail.error = TESTCASE_LEAD;
            detail.errorsEncountered.add(TESTCASE_LEAD);
        }
        if (detail.isApplicationIncomplete()) {
            detail.error = APPLICATION_INCOMPLETE;
            detail.errorsEncountered.add(APPLICATION_INCOMPLETE);
        }
        if (detail.isEmailBounced()) {
            detail.error = EMAIL_BOUNCED;
            detail.errorsEncountered.add(EMAIL_BOUNCED);
        }
    }

    @TestVisible
    private void validateUtility() {
        if (detail.isAutoConversionButAutoQCDisabled()) {
            detail.error = AUTO_QC_DISABLED;
            detail.errorsEncountered.add(AUTO_QC_DISABLED);
        }
    }

    @TestVisible
    private void validateSelectedSystemsForConversion() {
        if (detail.noQualifiedSystemsFound()) {
            detail.error = NO_QUALIFIED_SYSTEMS;
            detail.errorsEncountered.add(NO_QUALIFIED_SYSTEMS);
        }
        if (detail.isSystemProductMismatch()) {
            detail.error = PRODUCT_MISMATCH;
            detail.errorsEncountered.add(PRODUCT_MISMATCH);
        }
    }

    @TestVisible
    private void validateUtilityAccountLogs() {
        if (detail.ualsNotReadyForConversion()) {
            detail.error = INCOMPLETE_UALS;
            detail.errorsEncountered.add(INCOMPLETE_UALS);
        }
        if (detail.noDemandCapacityAvailable()) {
            detail.error = NO_DEMAND_CAPACITY_AVAILABLE;
            detail.errorsEncountered.add(NO_DEMAND_CAPACITY_AVAILABLE);
        }
    }
}