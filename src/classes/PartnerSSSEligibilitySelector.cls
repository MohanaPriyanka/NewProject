/**
 * Created by PeterYao on 11/14/2020.
 * Tested By: PartnerSSSEligibilitySelectorTest
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public inherited sharing class PartnerSSSEligibilitySelector {
    public MultiMap getPartnersBySSS() {
        List<Partner_Shared_Solar_System_Eligibility__c> allPartnerEligibilities = [
            SELECT Id, Account__c, Account__r.Partner__c, Shared_Solar_System__c
            FROM Partner_Shared_Solar_System_Eligibility__c
            WHERE Active__c = TRUE
        ];
        MultiMap sssIdToEligiblePartners = MultiMap.newSetInstance();
        for (Partner_Shared_Solar_System_Eligibility__c eligibility : allPartnerEligibilities) {
            sssIdToEligiblePartners.putValue(eligibility.Shared_Solar_System__c, eligibility.Account__c);
            sssIdToEligiblePartners.putValue(eligibility.Shared_Solar_System__c, eligibility.Account__r.Partner__c);
        }
        return sssIdToEligiblePartners;
    }

    public List<Partner_Shared_Solar_System_Eligibility__c> getSSSByPartner(Set<Id> partnerIds) {
        return [
            SELECT Id, Commission_Structure__c, Account__c, Shared_Solar_System__c
            FROM Partner_Shared_Solar_System_Eligibility__c
            WHERE Account__c IN :partnerIds
        ];
    }
}