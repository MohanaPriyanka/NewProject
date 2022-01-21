/**
 * @description Created by SarahRenfro on 7/6/2020.
 * Description: Domain class for SSS
 * Test: CSUtilityAccountSubscriptionFactoryTest, SharedSolarSystemsTest, LeadServiceTestclass, CapacityServiceTest
 */
public inherited sharing class SharedSolarSystems {

    private List<Shared_Solar_System__c> records;
    private Lead virtualLead;
    private static SharedSolarSystemQualifier qualifier = new SharedSolarSystemQualifier();

    /**
     * @description Default constructor used in most cases
     * @param records List of SSS to be used throughout this class
     */
    public SharedSolarSystems(List<Shared_Solar_System__c> records) {
        this.records = records;
    }

    /**
     * @description Constructor for running Capacity Checks through qualification logic in CapacityService{} to return
     *      rank-ordered SSS for a given ZIP code by Assignment Order.
     * <p></p>
     *     Creates a (virtual) lead to be used throughout this class instance to avoid necessity of method overloading
     * @param sharedSolarSystems List of Shared_Solar_System__c
     * @param utilityId Utility ID of Applicant
     * @param partnerId Partner lookup ID used for capacity check
     */
    public SharedSolarSystems(List<Shared_Solar_System__c> sharedSolarSystems, Id utilityId, String partnerId) {
        this.records = sharedSolarSystems;
        this.virtualLead = new Lead(
            Partner_Lookup__c = partnerId,
            System_Assignment__c = 'Automatic - Assignment Order',
            Utility_relationship__c = utilityId
        );
        SharedSolarSystemQualifier.setCapacityCheck(true);
    }

    /**
     * @description Rank-orders SSSs found in Capacity Check by Assignment Order for use with
     *      CapacityService.setProductsAndSharedSolarSystems()
     * @return Rank-ordered SSS list by Automatic Assignment Order
     */
    public List<Shared_Solar_System__c> orderedSssForCapacityCheck() {
        return getQualifiedForLead(virtualLead);
    }

    public static Decimal calculateMaximumkWh(Shared_Solar_System__c sss) {
        return SharedSolarSystemCapacityCalculator.calculateMaximumkWh(sss);
    }

    /**
     * @description Gets the qualified systems for this lead, sorted by the lead's System Assignment setting
     * @param lead Lead being qualified
     * @return List of systems that qualify
     */
    public List<Shared_Solar_System__c> getQualifiedForLead(Lead lead) {
        return qualifier.getQualifiedForLead(lead, records);
    }

    /**
     * @description Gets the lead's qualification based on Utility, Service Territory, Partner, Product, and Credit Score.
     * If the lead does not meet any of the project's credit requirement, the lead is "Unqualified"
     * @param lead The lead to check
     * @param creditScore The lead's credit score
     * @return Qualified or Unqualified
     */
    public String checkCSQualification(Lead lead, String creditScore) {
        return qualifier.checkCSQualification(lead, creditScore, records);
    }
}