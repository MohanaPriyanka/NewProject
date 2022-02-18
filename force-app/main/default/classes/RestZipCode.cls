/**
 * Created by peteryao on 2/7/20.
 * Tested By: CSLeadsRESTControllerV2Test
 */

@SuppressWarnings('PMD.ExcessivePublicCount')
public inherited sharing class RestZipCode {
    public String zipCode;
    public Boolean hasCapacity;
    public Boolean collectRateClass;
    public Set<Utility> utilities;
    public Set<String> loadZones;
    public Set<Product> products;
    public Set<RateClass> rateClasses;
    public Set<String> utilityZipCodesServed;
    public Boolean ficoUnderwriting;
    public Boolean finDocsUnderwriting;
    public Boolean collectPayment;
    public Boolean underwrite;
    public Boolean collectPOD;

    public RestZipCode(CapacityService.ZipcodeResponse response) {
        this.zipCode = response.zipcode;
        this.hasCapacity = response.hasCapacity();
        this.collectRateClass = response.collectRateClass();
        this.utilities = response.utilities == null ? getUtilities(new Set<Utility__c>()) : getUtilities(response.utilities);
        this.loadZones = response.loadZoneNames;
        this.products = response.products == null ? getProducts(new Set<Product2>()) : getProducts(response.products);
        this.rateClasses = response.rateClasses == null ? getRateClasses(new Set<Rate_Class__c>()) : getRateClasses(response.rateClasses);
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
}