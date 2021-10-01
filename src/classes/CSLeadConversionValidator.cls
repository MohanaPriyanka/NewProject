/**
 * @description Created by jeffparlin on 9/24/21. Validates that leads are ready for conversion and provides response
 *      to caller.
 * Tested By: CSLeadsConverterTest
 */
public without sharing class CSLeadConversionValidator {

    private LeadConvertDetail detail;

    public CSLeadConversionValidator(LeadConvertDetail detail) {
        this.detail = detail;
    }

    public void validate() {
        validateSystems();
        validateUtilityAccountLogs();
    }

    private void validateSystems() {
        if (systemProductMismatch()) {
            detail.error = CSLeadsConverter.PRODUCT_MISMATCH;
            detail.errorsEncountered.add(CSLeadsConverter.PRODUCT_MISMATCH);
        }
    }

    private void validateUtilityAccountLogs() {
        if (ualsNotReadyForConversion()) {
            detail.error = CSLeadsConverter.INCOMPLETE_UALS;
            detail.errorsEncountered.add(CSLeadsConverter.INCOMPLETE_UALS);
        }
    }

    private Boolean systemProductMismatch() {
        for (Shared_Solar_System__c sss : detail.selectedSystems) {
            if (sss.Product__c != detail.selectedProductId) {
                return true;
            }
        }
        return false;
    }

    private Boolean ualsNotReadyForConversion() {
        String subscriptionType = detail.selectedSystems[0].Product__r.Customer_Subscription_Type__c;
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