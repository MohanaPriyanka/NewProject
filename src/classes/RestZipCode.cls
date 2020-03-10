/**
 * Created by peteryao on 2/7/20.
 * Tested By: CSLeadsRESTControllerV2Test
 */

public inherited sharing class RestZipCode {
    public String zipCode;
    public Boolean hasCapacity;
    public Set<Utility> utilities;
    public Set<String> loadZones;
    public Set<String> products;

    public RestZipCode(CapacityService.ZipcodeResponse response) {
        this.zipCode = response.zipcode;
        this.hasCapacity = response.hasCapacity();
        this.utilities = getUtilities(response.utilities);
        this.loadZones = response.loadZoneNames;
        this.products = getProductNames(response.products);
    }

    private Set<Utility> getUtilities(Set<Utility__c> utilitySobjs) {
        Set<Utility> utilities = new Set<Utility>();
        for (Utility__c utility : utilitySobjs) {
            utilities.add(new Utility(utility.Id, utility.Name, utility.EIA_ID__c));
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

    public class Utility {
        public String utilityId;
        public String name;
        public String eiaId;

        public Utility(String id, String name, String eiaId) {
            this.utilityId = id;
            this.name = name;
            this.eiaId = eiaId;
        }
    }
}