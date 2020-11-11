/**
 * Created by mstackhouse on 1/23/2019.
 * Description: Provides a service to input a zipcode and find whether we have utilities, load zones,
 * products and shared solar systems for this location.
 *
 * Test: CapacityServiceTest
 */


public without sharing class CapacityService {
    @TestVisible private RateClassesSelector rateClassSelector = new RateClassesSelector();

    // To support CSAP, which ignores Sales Partners when querying for systems
    public ZipcodeResponse findCapacityByZipcode(String zipcode) {
        return findCapacityByZipcode(zipcode, null, null);
    }

    public ZipcodeResponse findCapacityByZipcode(String zipcode, String partnerId) {
        return findCapacityByZipcode(zipcode, partnerId, null);
    }

    public ZipcodeResponse findCapacityByZipcode(String zipcode, String partnerId, String utilityId) {
        ZipcodeResponse zipcodeResponse = new ZipcodeResponse();
        // get first 5 characters incase a Zip+4 was sent
        zipcode = zipcode.left(5);
        if (!isZipcodeValid(zipcode)) {
            return zipcodeResponse;
        }
        zipcodeResponse.zipcode = zipcode;
        setUtilitiesAndLoadZones(zipcodeResponse, utilityId);
        zipcodeResponse.rateClasses = new Set<Rate_Class__c>(rateClassSelector.selectByUtilities(zipcodeResponse.utilityIds));
        setProductsAndSharedSolarSystems(zipcodeResponse, getPartnerName(partnerId));
        setZipCodesServedInUtilityTerritory(zipcodeResponse);
        return zipcodeResponse;
    }

    // Retrieve zip codes served by Utility ID. If no or multiple utilities provided, do nothing
    private void setZipCodesServedInUtilityTerritory(ZipcodeResponse zipcodeResponse) {
        if (zipcodeResponse.utilityIds.size() == 1) {
            String utilityId = (String) new List<Id>(zipcodeResponse.utilityIds)[0];
            zipcodeResponse.utilityZipCodesServed = ZipcodeUtilitiesSelector.selectZipCodesServedByUtility(utilityId);
        }
    }

    // A null partner name should find all systems to support CSAP, blank should get the default partner
    private String getPartnerName(String partnerId) {
        if (partnerId == null) {
            return null;
        } else if (partnerId != '') {
            try {
                return PartnerSelector.selectPartnerByPartnerId(partnerId).Name;
            } catch (QueryException qe) {
                Logger.logNow(
                    'CapacityService',
                    'findCapacityByZipcode',
                    'Did not find a partner for id ' + partnerId + ', but proceeding with the default partner\n' + qe.getStackTraceString(),
                    Logger.ERROR
                );
            }
        }
        return PartnerSelector.selectDefaultCSPartner().Name;
    }

    public void setUtilitiesAndLoadZones(ZipcodeResponse zipcodeResponse, Id utilityId) {
        String zipcode = zipcodeResponse.zipcode;
        List<ZipCode_Utility_Junction__c> zipcodeUtilities = ZipcodeUtilitiesSelector.selectZipcodeUtilitiesAndLoadzones(zipcode);

        for (ZipCode_Utility_Junction__c zipCodeUtility : zipcodeUtilities) {
            if(utilityId == null || zipCodeUtility.Utility__r.Id == utilityId) {
                zipcodeResponse.utilities.add(zipCodeUtility.Utility__r);
                zipcodeResponse.utilityIds.add(zipCodeUtility.Utility__r.Id);

                List<String> allZones = zipCodeUtility.Load_Zone_Utility__r.LZ__c.split('/');
                zipcodeResponse.loadZones.add(zipCodeUtility.Load_Zone_Utility__r);
                zipcodeResponse.loadZoneNames.addAll(allZones);
            }
        }
    }

    public void setProductsAndSharedSolarSystems(ZipcodeResponse zipcodeResponse, String partnerName) {
        List<Shared_Solar_System__c> sharedSolarSystems =
            SharedSolarSystemsSelector.selectSharedSolarSystemsWithCapacityByUtilityAndLoadZone(
                zipcodeResponse.utilityIds,
                zipcodeResponse.loadZoneNames
            );

        zipcodeResponse.ficoUnderwriting = false;
        zipcodeResponse.finDocsUnderwriting = false;
        
        // Allowing null partnerNames to match to all systems, to support CSAP behavior
        for (Shared_Solar_System__c sharedSolarSystem: sharedSolarSystems) {
            if (partnerName == null ||
                (sharedSolarSystem.Sales_Partners__c != null &&
                (sharedSolarSystem.Sales_Partners__c.split(';').contains(partnerName) ||
                sharedSolarSystem.Sales_Partners__c.split(';').contains('All')))) {
                zipcodeResponse.sharedSolarSystems.add(sharedSolarSystem);
                zipcodeResponse.products.add(sharedSolarSystem.Product__r);

                if(sharedSolarSystem.Available_SMB_Underwriting_Method_FICO__c) {
                    zipcodeResponse.ficoUnderwriting = true;
                }
                if(sharedSolarSystem.Available_SMB_Underwriting_Method_Docs__c) {
                    zipcodeResponse.finDocsUnderwriting = true;
                }
            }
        }
    }

    public class ZipcodeResponse {
        public String zipcode;
        public Set<Utility__c> utilities = new Set<Utility__c>();
        public Set<Load_U__c> loadZones = new Set<Load_U__c>();
        public Set<Product2> products = new Set<Product2>();
        public Set<Shared_Solar_System__c> sharedSolarSystems = new Set<Shared_Solar_System__c>();
        public Set<Rate_Class__c> rateClasses = new Set<Rate_Class__c>();
        public Set<Id> utilityIds = new Set<Id>();
        public Set<String> loadZoneNames = new Set<String>();
        public Boolean ficoUnderwriting;
        public Boolean finDocsUnderwriting;
        public Set<String> utilityZipCodesServed = new Set<String>();

        public Boolean hasCapacity() {
            return (
                sharedSolarSystems.size() >= 1
                    && products.size() >= 1
                    && loadZones.size() >= 1
                    && utilities.size() >= 1
            );
        }

        public Boolean collectRateClass() {
            for(Product2 prod : products) {
                if (prod.Collect_Rate_Class_via_Application__c) {
                    return true;
                }
            }
            return false;
        }
    }

    @TestVisible
    private Boolean isZipcodeValid(String zipcode) {
        // check that the zipcode can be a number
        Boolean invalidNumber = false;
        try {
            Integer zipInt = Integer.valueOf(zipcode);
        } catch (Exception e) {
            invalidNumber = true;
        }

        Boolean notFiveDigitsLong = zipcode.length() != 5;

        // zipcode is invalid if it isn't 5 digits long or it cannot be converted to a number
        return !(notFiveDigitsLong || invalidNumber);
    }
}