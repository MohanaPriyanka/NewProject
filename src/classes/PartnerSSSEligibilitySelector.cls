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
            WHERE IsActive__c = TRUE
        ];
        MultiMap sssIdToEligiblePartners = MultiMap.newSetInstance();
        for (Partner_Shared_Solar_System_Eligibility__c eligibility : allPartnerEligibilities) {
            sssIdToEligiblePartners.putValue(eligibility.Shared_Solar_System__c, eligibility.Account__c);
            sssIdToEligiblePartners.putValue(eligibility.Shared_Solar_System__c, eligibility.Account__r.Partner__c);
        }
        return sssIdToEligiblePartners;
    }

    //
    //
    /**
     * @description This should not select just active eligibilities, because it is used to find overlapping
     * eligibilities (so we want to find eligibilities that may be active in the future)
     * @param partnerIds An Account Id for a Partner, for which to find eligibility records
     * @return List of Partner_Shared_Solar_System_Eligibility__c
     */
    public List<Partner_Shared_Solar_System_Eligibility__c> getSSSByPartner(Set<Id> partnerIds) {
        return [
            SELECT Id, Commission_Structure__c, Account__c, Shared_Solar_System__c, Start_Date__c, End_Date__c
            FROM Partner_Shared_Solar_System_Eligibility__c
            WHERE Account__c IN :partnerIds
        ];
    }

    /**
     * @description Used to get eligibility records on a start date or end date, in order to update sharing. Intended
     * to be run daily, with a start date of today and an end date of yesterday, in order to get the shares that should change
     * @param startDate The start date for eligibility records
     * @param endDate The end date for eligibility records
     * @return List of eligibility records that start or end on the input dates
     */
    public List<Partner_Shared_Solar_System_Eligibility__c> getRecentPartnerSSSEligibilities(Date startDate, Date endDate) {
        return [
            SELECT Id, Account__c, Shared_Solar_System__c, Start_Date__c, End_Date__c, IsActive__c
            FROM Partner_Shared_Solar_System_Eligibility__c
            WHERE Start_Date__c = :startDate
            OR End_Date__c = :endDate
        ];
    }
}