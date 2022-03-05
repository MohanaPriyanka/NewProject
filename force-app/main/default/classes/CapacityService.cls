/**
 * Created by mstackhouse on 1/23/2019.
 * Description: Provides a service to input a zipcode and find whether we have utilities, load zones,
 * products and shared solar systems for this location.
 *
 * Test: CapacityServiceTest
 */

public without sharing class CapacityService {
    @TestVisible private RateClassesSelector rateClassSelector = new RateClassesSelector();
    private ZipcodeResponse zipcodeResponse;

    /**
     * @description Find capacity when single Utility ID is known
     * @param zipcode ZIP code to check capacity for
     * @param partnerId Partner ID for application
     * @param utilityId Utility ID
     * @return ZipcodeResponse indicating capacity / availability of our CS product for specified ZIP + Partner + Utility
     */
    public ZipcodeResponse findCapacityByZipcode(String zipcode, String partnerId, String utilityId) {
        zipcodeResponse = new ZipcodeResponse();
        if (!isZipcodeValid(zipcode.left(5))) {
            return zipcodeResponse;
        }

        zipcodeResponse.zipcode = zipcode.left(5);
        setUtilitiesAndLoadZones(utilityId);
        setRateClasses();
        setProductsAndSharedSolarSystems(validatePartnerId(partnerId));
        setZipCodesServedInUtilityTerritory();
        setBooleanFlags();

        return zipcodeResponse;
    }

    private void setUtilitiesAndLoadZones(Id utilityId) {
        List<ZipCode_Utility_Junction__c> zipcodeUtilities = ZipcodeUtilitiesSelector.selectZipcodeUtilitiesAndLoadzones(
            zipcodeResponse.zipcode
        );

        for (ZipCode_Utility_Junction__c zipCodeUtility : zipcodeUtilities) {
            if (utilityId == null || zipCodeUtility.Utility__r.Id == utilityId) {
                zipcodeResponse.utilities.add(zipCodeUtility.Utility__r);
                zipcodeResponse.utilityIds.add(zipCodeUtility.Utility__r.Id);

                List<String> allZones = zipCodeUtility.Load_Zone_Utility__r.LZ__c.split('/');
                zipcodeResponse.loadZones.add(zipCodeUtility.Load_Zone_Utility__r);
                zipcodeResponse.loadZoneNames.addAll(allZones);
            }
        }
    }

    private void setRateClasses() {
        zipcodeResponse.rateClasses = new Set<Rate_Class__c>(rateClassSelector.selectByUtilities(
            zipcodeResponse.utilityIds)
        );
    }

    private void setProductsAndSharedSolarSystems(String partnerId) {
        // Perform initial query of open SSS per utility and LZ
        List<Shared_Solar_System__c> openSystems =
            SharedSolarSystemsSelector.selectSharedSolarSystemsWithCapacityByUtilityAndLoadZone(
                zipcodeResponse.utilityIds,
                zipcodeResponse.loadZoneNames
            );

        if (openSystems.isEmpty()) {
            return;
        } else {
            // Run SSSs through SharedSolarSystems{} qualification logic to order them by Assignment Order
            List<Shared_Solar_System__c> orderedSSS = new SharedSolarSystems(
                openSystems, new List<Id>(zipcodeResponse.utilityIds)[0], partnerId)
            .orderedSssForCapacityCheck();

            for (Shared_Solar_System__c sss : orderedSSS) {
                zipcodeResponse.sharedSolarSystems.add(sss);
                zipcodeResponse.products.add(getSSSProduct(sss));
            }
        }
    }

    private Product2 getSSSProduct(Shared_Solar_System__c sss) {
        if (sss.Product__r.Parent_Product__c != null) {
            return sss.Product__r.Parent_Product__r;
        } else {
            return sss.Product__r;
        }
    }

    private void setZipCodesServedInUtilityTerritory() {
        if (zipcodeResponse.utilityIds.size() == 1) {
            String utilityId = (String) new List<Id>(zipcodeResponse.utilityIds)[0];
            zipcodeResponse.utilityZipCodesServed = ZipcodeUtilitiesSelector.selectZipCodesServedByUtility(utilityId);
        }
    }

    private void setBooleanFlags() {
        zipcodeResponse.ficoUnderwriting = ficoSupported();
        zipcodeResponse.finDocsUnderwriting = financialReviewSupported();
        zipcodeResponse.collectPayment = collectPaymentSupported();
        zipcodeResponse.underwrite = underwriteSupported();
        zipcodeResponse.collectPOD = collectPOD();
    }

    /**
     * @description Set boolean flags for capacity check on resume app for SSF.
     * This method should differ from setBooleanFlags() in that it does not pull information from SSS and instead takes
     * information from the Lead and other sources that were set at the time of Lead creation (e.g. application submission)
     */
    private void setBooleanFlagsOnResume() {
        zipcodeResponse.collectPOD = collectPOD();
    }

    /**
     * @description Validates that a partnerId is in the database. A null partner id should find all systems to support
     *   CSAP, but a empty string partnerId should get the default partner
     * @param partnerId partnerId to validate
     * @return null or a valid Partner__c.Id
     */
    private String validatePartnerId(String partnerId) {
        try {
            return PartnerSelector.selectPartnerByPartnerId(partnerId).Id;
        } catch (QueryException qe) {
            Logger.logNow(
                'CapacityService',
                'findCapacityByZipcode',
                'Did not find a partner for id ' + partnerId + ', but proceeding with the default partner\n' + qe.getStackTraceString(),
                Logger.ERROR
            );
        }
        return PartnerSelector.selectDefaultCSPartner().Id;
    }

    // If any SSS have FICO available for underwriting, indicate TRUE
    private Boolean ficoSupported() {
        for (Shared_Solar_System__c sss : zipcodeResponse.sharedSolarSystems) {
            if (sss.Available_SMB_Underwriting_Method_FICO__c) {
                return true;
            }
        }
        return false;
    }

    // If any SSS have Fin Docs/Review available for underwriting, indicate TRUE
    private Boolean financialReviewSupported() {
        for (Shared_Solar_System__c sss : zipcodeResponse.sharedSolarSystems) {
            if (sss.Available_SMB_Underwriting_Method_Docs__c) {
                return true;
            }
        }
        return false;
    }

    // Use top-ranked SSS to determine if payment will be collected in SSF
    private Boolean collectPaymentSupported() {
        if (zipcodeResponse.sharedSolarSystems.size() >= 1) {
            return !zipcodeResponse.sharedSolarSystems[0].Do_Not_Ask_for_Payment_Method__c;
        }
        return true;
    }

    // Use top-ranked SSS to determine if underwriting language and behavior will be present in SSF
    private Boolean underwriteSupported() {
        if (zipcodeResponse.sharedSolarSystems.size() >= 1) {
            return !zipcodeResponse.sharedSolarSystems[0].Do_Not_Underwrite__c;
        }
        return true;
    }

    // Determine if collecting PoD ID (e.g. NYSEG requirements for EDI)
    private Boolean collectPOD() {
        if (!zipcodeResponse.utilities.isEmpty()) {
            Utility__c selectedUtility = new List<Utility__c>(zipcodeResponse.utilities)[0];
            if (selectedUtility.Collect_Customer_POD_Number__c) {
                return true;
            }
        }
        return false;
    }

    /**
     * @description Provides a valid ZipcodeResponse to pass back to SSF for resume applications ONLY. Data provided
     *              does not include SSS/Product/Capacity data since W-021427 for resumed applications (to mitigate bugs)
     * @param zipCode ZIP Code of first UAL
     * @param utilityId Utility ID previously selected during Lead creation / initial SSF application submission
     * @return ZipcodeResponse to pass back to SSF
     */
    public ZipcodeResponse getZipcodeResponseForResumeApp(String zipCode, String utilityId) {
        zipcodeResponse = new ZipcodeResponse();
        zipcodeResponse.zipcode = zipCode;
        setUtilitiesAndLoadZones(utilityId);
        setRateClasses();
        setZipCodesServedInUtilityTerritory();
        setBooleanFlagsOnResume();
        return zipcodeResponse;
    }

    public class ZipcodeResponse {
        public String zipcode;
        public Set<Utility__c> utilities = new Set<Utility__c>();
        public Set<Load_U__c> loadZones = new Set<Load_U__c>();
        public Set<Product2> products = new Set<Product2>();
        public List<Shared_Solar_System__c> sharedSolarSystems = new List<Shared_Solar_System__c>();
        public Set<Rate_Class__c> rateClasses = new Set<Rate_Class__c>();
        public Set<Id> utilityIds = new Set<Id>();
        public Set<String> loadZoneNames = new Set<String>();
        public Set<String> utilityZipCodesServed = new Set<String>();
        public Boolean ficoUnderwriting;
        public Boolean finDocsUnderwriting;
        public Boolean collectPayment;
        public Boolean underwrite;
        public Boolean collectPOD;

        public Boolean hasCapacity() {
            return (
                sharedSolarSystems.size() >= 1
                    && products.size() >= 1
                    && loadZones.size() >= 1
                    && utilities.size() >= 1
            );
        }
        public Boolean collectRateClass() {
            for (Product2 prod : products) {
                if (prod.Collect_Rate_Class_via_Application__c) {
                    return true;
                }
            }
            return false;
        }
    }

    @TestVisible
    private Boolean isZipcodeValid(String zipcode) {
        return Pattern.matches('\\d{5}', zipcode);
    }
}