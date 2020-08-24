/**
 * Created by peteryao on 2/7/20.
 * Tested By: CSLeadsRESTControllerV2Test
 */

public inherited sharing class RestZipCode {
    public String zipCode;
    public Boolean hasCapacity;
    public Boolean collectRateClass;
    public Set<Utility> utilities;
    public Set<String> loadZones;
    public Set<String> products;
    public Set<String> rateClasses;
    public Boolean ficoUnderwriting;
    public Boolean finDocsUnderwriting;

    public RestZipCode(CapacityService.ZipcodeResponse response) {
        this.zipCode = response.zipcode;
        this.hasCapacity = response.hasCapacity();
        this.collectRateClass = response.collectRateClass();
        this.utilities = getUtilities(response.utilities);
        this.loadZones = response.loadZoneNames;
        this.products = getProductNames(response.products);
        this.rateClasses = getRateClassNames(response.rateClasses);
        this.ficoUnderwriting = response.ficoUnderwriting;
        this.finDocsUnderwriting = response.finDocsUnderwriting;
    }

    private Set<Utility> getUtilities(Set<Utility__c> utilitySobjs) {
        Set<Utility> utilities = new Set<Utility>();
        for (Utility__c utility : utilitySobjs) {
            utilities.add(new Utility(utility.Id, utility.Name, utility.Utility_Data_Collection_Mechanism__c));
        }
        return utilities;
    }

    private Set<String> getProductNames(Set<Product2> products) {
        Set<String> productNames = new Set<String>();
        for (Product2 product2 : products) {
            productNames.add(product2.Name);
        }
        return productNames;
    }

    private Set<String> getRateClassNames(Set<Rate_Class__c> rateClasses) {
        Set<String> rateClassNames = new Set<String>();
        for(Rate_Class__c rc : rateClasses) {
            rateClassNames.add(rc.Name);
        }
        return rateClassNames;
    }

    public class Utility {
        public String utilityId;
        public String name;
        public String dataCollectionMethod;

        public Utility(String id, String name) {
            this.utilityId = id;
            this.name = name;
            this.dataCollectionMethod = 'File Upload';
        }

        public Utility(String id, String name, String dataCollectionMethod) {
            this.utilityId = id;
            this.name = name;
            this.dataCollectionMethod = dataCollectionMethod;
        }
    }
}