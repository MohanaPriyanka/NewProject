/**
 * @description Created by jeffparlin on 1/4/22. Identifies the correct Commission Structure to be applied to an Opportunity
 * based on Partner_Shared_Solar_System_Eligibility__c junction records.
 * Tested By: PartnerCommissionStructureLocatorTest
 */
public with sharing class PartnerCommissionStructureLocator {

    @TestVisible private static CommissionStructureSelector commissionStructureSelector = new CommissionStructureSelector();
    @TestVisible private static PartnerSSSEligibilitySelector eligibilitySelector = new PartnerSSSEligibilitySelector();
    @TestVisible private static PartnerSelector partnerSelector = new PartnerSelector();

    private List<Opportunity> opportunities;
    private Set<Id> relatedPartnerAccountIds = new Set<Id>();
    private Map<Id, Id> legacyPartnerToPartnerAccountIdMap = new Map<Id, Id>(); // TODO: Deprecate in future
    private List<Partner_Shared_Solar_System_Eligibility__c> partnerEligibilities;
    private Map<String, Id> eligibleCommissionStructureMap = new Map<String, Id>();
    private Map<Id, Commission_Structure__c> commissionStructureMap = new Map<Id, Commission_Structure__c>();

    public PartnerCommissionStructureLocator(List<Opportunity> opportunities) {
        this.opportunities = opportunities;
    }

    /**
     * @description Caches needed information from database, then sets the Commission_Structure__c field on Opportunity
     * records passed in via Constructor. This class does not handle the DML and instead that is the responsibility of
     * the caller. The expected calling context is a BEFORE_INSERT trigger where no DML would be necessary.
     */
    public void setStructureOnOpportunities() {
        cachePartnerAccountIds();
        retrievePartnerEligibilities();
        populateCommissionStructureMap();
        for (Opportunity opp : opportunities) {
            opp.Commission_Structure__c = getActiveCommissionStructure(opp);
        }
    }

    /**
     * @description Cache Partner Account Ids from Opportunities. Also queries for and caches the Partner Account Id
     * from the [legacy] Partner__c object related to some Opportunities via Opportunity.Partner_tag_lookup__c field.
     * This latter mechanism should be deprecated in the future with the deprecation of the Partner__c object type.
     */
    private void cachePartnerAccountIds() {
        for (Opportunity opp : opportunities) {
            relatedPartnerAccountIds.add(opp.Partner_Account__c);
        }
        legacyPartnerToPartnerAccountIdMap = partnerSelector.legacyGetPartnerAccountIdsByOpp(opportunities);
    }

    /**
     * @description Retrieves the Partner_Shared_Solar_System_Eligibility__c junction records relevant for the transaction,
     * isolating the viable Commission Structure(s) for all deals in the transaction.
     */
    private void retrievePartnerEligibilities() {
        Set<Id> partnerAccountIds = new Set<Id>();
        partnerAccountIds.addAll(relatedPartnerAccountIds);
        partnerAccountIds.addAll(legacyPartnerToPartnerAccountIdMap.values());
        partnerEligibilities = eligibilitySelector.getSSSByPartner(partnerAccountIds);
    }

    /**
     * @description Identifies a Key corresponding to a Partner and Project from junction 'Eligibility' records. This
     * method then maps Key => Commission Structure for use in determining the correct Commission Structure for an Opp.
     */
    private void populateCommissionStructureMap() {
        Set<Id> commissionStructureIds = new Set<Id>();
        for (Partner_Shared_Solar_System_Eligibility__c junction : partnerEligibilities) {
            String eligibilityKey = junction.Account__c + '-' + junction.Shared_Solar_System__c;
            eligibleCommissionStructureMap.put(eligibilityKey, junction.Commission_Structure__c);
            commissionStructureIds.add(junction.Commission_Structure__c);
        }
        commissionStructureMap = commissionStructureSelector.getCommissionStructureMapByIds(commissionStructureIds);
    }

    /**
     * @description Assigns Commission Structure to Opportunity using Partner and SSS assignment. If no commission
     * structure found, create case. Have to use commissionStructureMap to assign Commission_Structure__r in order
     * to maintain data related to Commission Structure record for calculateCommissionPayments()
     * @param opp Opportunity having Commission Structure assigned
     * @return Id of Commission Structure to apply to Opportunity
     */
    private Id getActiveCommissionStructure(Opportunity opp) {
        String partnerAccountId = opp.Partner_Account__c == null ?
            legacyPartnerToPartnerAccountIdMap.get(opp.Partner_tag_lookup__c) :
            opp.Partner_Account__c;
        String eligibilityKey = partnerAccountId + '-' + opp.Shared_Solar_System__c;
        Id structureId = eligibleCommissionStructureMap.get(eligibilityKey);
        return structureId;
    }
}