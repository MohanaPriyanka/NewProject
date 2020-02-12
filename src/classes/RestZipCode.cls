/**
 * Created by peteryao on 2/7/20.
 * Tested By: CSLeadsRESTControllerV2Test
 */

public inherited sharing class RestZipCode {
    public String zipCode;
    public Boolean hasCapacity;
    public Set<Utility> utilities;
    public Set<String> loadZones;

    public RestZipCode(CapacityService.ZipcodeResponse response) {
        this.zipCode = response.zipcode;
        this.hasCapacity = response.hasCapacity();
        this.utilities = getUtilities(response.utilities);
        this.loadZones = response.loadZoneNames;
    }

    private Set<Utility> getUtilities(Set<Utility__c> utilitySobjs) {
        Set<Utility> utilities = new Set<Utility>();
        for (Utility__c utility : utilitySobjs) {
            utilities.add(new Utility(utility.Id, utility.Name));
        }
        return utilities;
    }

    public class Utility {
        public String utilityId;
        public String name;

        public Utility(String id, String name) {
            this.utilityId = id;
            this.name = name;
        }
    }
}