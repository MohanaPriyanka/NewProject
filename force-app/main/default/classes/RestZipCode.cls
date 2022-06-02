/**
 * Created by peteryao on 2/7/20.
 * Tested By: CSLeadsRESTControllerV2Test
 */

@SuppressWarnings('PMD.ExcessivePublicCount')
public inherited sharing class RestZipCode {
    public String zipCode;
    public Boolean hasCapacity;
    public Boolean hasLMICapacity;
    public Boolean hasSmallCSCapacity;
    public Boolean collectRateClass;
    public Set<Utility> utilities;
    public Set<String> loadZones;
    public Set<Product> products;
    public Set<RateClass> rateClasses;
    public List<SolarSystem> solarSystems;
    public Set<String> utilityZipCodesServed;
    public Boolean ficoUnderwriting;
    public Boolean finDocsUnderwriting;
    public Boolean collectPayment;
    public Boolean underwrite;
    public Boolean collectPOD;

    public RestZipCode(CapacityService.ZipcodeResponse response) {
        this.zipCode = response.zipcode;
        this.hasCapacity = response.hasCapacity();
        this.hasLMICapacity = response.hasLMICapacity();
        this.hasSmallCSCapacity = response.hasSmallCSCapacity();
        this.collectRateClass = response.collectRateClass();
        this.utilities = response.utilities == null ? getUtilities(new Set<Utility__c>()) : getUtilities(response.utilities);
        this.loadZones = response.loadZoneNames;
        this.products = response.products == null ? getProducts(new Set<Product2>()) : getProducts(response.products);
        this.rateClasses = response.rateClasses == null ? getRateClasses(new Set<Rate_Class__c>()) : getRateClasses(response.rateClasses);
        this.solarSystems = response.sharedSolarSystems == null ? getSolarSystems(new List<Shared_Solar_System__c>()) : getSolarSystems(response.sharedSolarSystems);
        this.utilityZipCodesServed = response.utilityZipCodesServed;
        this.ficoUnderwriting = response.ficoUnderwriting;
        this.finDocsUnderwriting = response.finDocsUnderwriting;
        this.collectPayment = response.collectPayment;
        this.underwrite = response.underwrite;
        this.collectPOD = response.collectPOD;
    }

    private Set<Utility> getUtilities(Set<Utility__c> utilitySobjs) {
        Set<Utility> utilities = new Set<Utility>();
        for (Utility__c utility : utilitySobjs) {
            utilities.add(new Utility(
                utility.Id,
                utility.Name,
                utility.Utility_Data_Collection_Mechanism__c,
                utility.Utility_Account_Number_Regex_Groups__c,
                utility.Utility_Account_Number_Format__c,
                utility.Utility_Account_Number_Prefix__c,
                utility.Utility_Account_Number_Length__c,
                utility.POD_Id_Regex_Groups__c,
                utility.POD_Id_Format__c,
                utility.POD_Id_Prefix__c,
                utility.POD_Id_Length__c
            ));
        }
        return utilities;
    }

    private Set<Product> getProducts(Set<Product2> productSobjs) {
        Set<Product> products = new Set<Product>();
        for (Product2 prod : productSobjs) {
            products.add(new Product(prod.Id,
                prod.Name, prod.Disclosure_Form_Conga_Template__c));
        }
        return products;
    }

    private Set<RateClass> getRateClasses(Set<Rate_Class__c> rateClassSobjs) {
        Set<RateClass> rateClasses = new Set<RateClass>();
        for (Rate_Class__c rc : rateClassSobjs) {
            rateClasses.add(new RateClass(rc.Id, rc.Name, rc.Suppress_Disclosure_Form__c));
        }
        return rateClasses;
    }

    private List<SolarSystem> getSolarSystems(List<Shared_Solar_System__c> sssSobjs) {
        List<SolarSystem> solarSystems = new List<SolarSystem>();
        for (Shared_Solar_System__c sss : sssSobjs) {
            solarSystems.add(new SolarSystem(sss.Id, sss.Name, sss.Capacity_Available_to_be_Reserved__c > 0 ? true : false, sss.Perch_Acq_Available_LMI_Capacity__c > 0 ? true : false, sss.Available_SMB_Underwriting_Method_FICO__c, sss.Available_SMB_Underwriting_Method_Docs__c, !sss.Do_Not_Ask_for_Payment_Method__c, !sss.Do_Not_Underwrite__c));
        }
        return solarSystems;
    }

    public class Utility {
        public String utilityId;
        public String name;
        public String dataCollectionMethod;
        public String uanRegexGroups;
        public String uanFormat;
        public String uanPrefix;
        public Decimal uanLength;
        public String podIdRegexGroups;
        public String podIdFormat;
        public String podIdPrefix;
        public Decimal podIdLength;

        public Utility(String id, String name) {
            this.utilityId = id;
            this.name = name;
            this.dataCollectionMethod = 'File Upload';
        }

        public Utility(String id, String name, String dataCollectionMethod, String uanRegexGroups, String uanFormat, String uanPrefix, Decimal uanLength, String podIdRegexGroups, String podIdFormat, String podIdPrefix, Decimal podIdLength) {
            this.utilityId = id;
            this.name = name;
            this.dataCollectionMethod = dataCollectionMethod;
            this.uanRegexGroups = uanRegexGroups;
            this.uanFormat = uanFormat;
            this.uanPrefix = uanPrefix;
            this.uanLength = uanLength;
            this.podIdRegexGroups = podIdRegexGroups;
            this.podIdFormat = podIdFormat;
            this.podIdPrefix = podIdPrefix;
            this.podIdLength = podIdLength;
        }
    }

    public class Product {
        public String productId;
        public String name;
        public Boolean standaloneDisclosureForm;

        public Product(String id, String name, String disclosureFormTemplate) {
            this.productId = id;
            this.name = name;
            this.standaloneDisclosureForm = (disclosureFormTemplate != null);
        }
    }

    public class RateClass {
        public String rateClassId;
        public String name;
        public Boolean suppressDisclosureForm;

        public RateClass(String id, String name, Boolean suppressDisclosureForm) {
            this.rateClassId = id;
            this.name = name;
            this.suppressDisclosureForm = suppressDisclosureForm;
        }
    }

    public class SolarSystem {
        public String sssId;
        public String name;
        public Boolean smallCsCapacityAvailable;
        public Boolean lmiCapacityAvailable;
        public Boolean ficoUnderwriting;
        public Boolean finDocsUnderwriting;
        public Boolean collectPayment;
        public Boolean underwrite;

        public SolarSystem(String id, String name, Boolean smallCsCapacityAvailable, Boolean lmiCapacityAvailable,
            Boolean ficoUnderwriting, Boolean finDocsUnderwriting, Boolean collectPayment, Boolean underwrite) {
            this.sssId = id;
            this.name = name;
            this.smallCsCapacityAvailable = smallCsCapacityAvailable;
            this.lmiCapacityAvailable = lmiCapacityAvailable;
            this.ficoUnderwriting = ficoUnderwriting;
            this.finDocsUnderwriting = finDocsUnderwriting;
            this.collectPayment = collectPayment;
            this.underwrite = underwrite;
        }
    }
}