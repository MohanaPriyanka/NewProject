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

    private LeadConvertDetail detail;

    public CSLeadConversionValidator(LeadConvertDetail detail) {
        this.detail = detail;
    }

    public void validate() {
        validateLead();
        validateUtility();
        validateSelectedSystemsForConversion();
        validateUtilityAccountLogs();
    }

    @TestVisible
    private void validateLead() {
        if (isAlreadyConvertedLead()) {
            detail.error = ALREADY_CONVERTED;
            detail.errorsEncountered.add(ALREADY_CONVERTED);
        }
        if (isTestcaseLead()) {
            detail.error = TESTCASE_LEAD;
            detail.errorsEncountered.add(TESTCASE_LEAD);
        }
        if (isApplicationIncomplete()) {
            detail.error = APPLICATION_INCOMPLETE;
            detail.errorsEncountered.add(APPLICATION_INCOMPLETE);
        }
        if (isEmailBounced()) {
            detail.error = EMAIL_BOUNCED;
            detail.errorsEncountered.add(EMAIL_BOUNCED);
        }
    }

    @TestVisible
    private void validateUtility() {
        if (isAutoConversionButAutoQCDisabled()) {
            detail.error = AUTO_QC_DISABLED;
            detail.errorsEncountered.add(AUTO_QC_DISABLED);
        }
    }

    @TestVisible
    private void validateSelectedSystemsForConversion() {
        if (noQualifiedSystemsFound()) {
            detail.error = NO_QUALIFIED_SYSTEMS;
            detail.errorsEncountered.add(NO_QUALIFIED_SYSTEMS);
        }
        if (isSystemProductMismatch()) {
            detail.error = PRODUCT_MISMATCH;
            detail.errorsEncountered.add(PRODUCT_MISMATCH);
        }
    }

    @TestVisible
    private void validateUtilityAccountLogs() {
        if (ualsNotReadyForConversion()) {
            detail.error = INCOMPLETE_UALS;
            detail.errorsEncountered.add(INCOMPLETE_UALS);
        }
    }

    private Boolean isTestcaseLead() {
        return detail.lead.LastName.toLowerCase() == 'testcase';
    }
    
    private Boolean isAlreadyConvertedLead() {
        return detail.lead.IsConverted;
    }
    
    private Boolean isApplicationIncomplete() {
        return detail.lead.Application_Complete_Date__c == null;
    }

    private Boolean isEmailBounced() {
        return detail.lead.EmailBouncedDate != null;
    }

    private Boolean isAutoConversionButAutoQCDisabled() {
        return detail.autoConversion && !detail.utility.Auto_Qualify_Convert_Active__c;
    }

    private Boolean noQualifiedSystemsFound() {
        return detail.selectedSystems.isEmpty() || detail.selectedSystemIds.isEmpty();
    }

    private Boolean isSystemProductMismatch() {
        for (Shared_Solar_System__c sss : detail.selectedSystems) {
            if (sss.Product__c != detail.selectedProductId) {
                return true;
            }
        }
        return false;
    }

    private Boolean ualsNotReadyForConversion() {
        String subscriptionType = !detail.selectedSystems.isEmpty()
            ? detail.selectedSystems[0].Product__r?.Customer_Subscription_Type__c
            : null;
        if (detail.utilityAccountLogs.isEmpty()) {
            return true;
        }
        for (Utility_Account_Log__c ual : detail.utilityAccountLogs) {
            Boolean pendingQC = ual.QC_Status__c == 'Pending Utility Data' || ual.QC_Status__c == 'Pending BW Review';
            Boolean notUnqualified = ual.QC_Status__c != 'Unqualified';
            Boolean kwhSubscriptionMissingData = subscriptionType == 'kWh' && ual.Annual_kWh__c == null;
            Boolean costSubscriptionMissingData = subscriptionType == 'Electricity Cost ($)' && ual.Annual_Cost_of_Electricity__c == null;
            if (notUnqualified && (pendingQC || kwhSubscriptionMissingData || costSubscriptionMissingData)) {
                return true;
            }
        }
        return false;
    }
}