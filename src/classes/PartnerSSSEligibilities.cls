/**
 * Created by PeterYao on 2/27/2021.
 * Tested By: PartnerSSSEligibilitiesTest
 */

public without sharing class PartnerSSSEligibilities {
    private List<Partner_Shared_Solar_System_Eligibility__c> records;
    @TestVisible private static PartnerSSSEligibilitySelector partnerSSSEligibilitySelector = new PartnerSSSEligibilitySelector();

    public PartnerSSSEligibilities(List<Partner_Shared_Solar_System_Eligibility__c> partnerEligibilities) {
        this.records = partnerEligibilities;
    }

    /**
     * @description Ensures the records in this class are valid: that they have a start date, that the end date is after
     * the start, and that they do not overlap with any existing records for the same System and Account
     */
    public void validate() {
        List<Partner_Shared_Solar_System_Eligibility__c> existingEligibilities = getExistingEligibilities();
        for (Partner_Shared_Solar_System_Eligibility__c partnerEligibility : records) {
            validate(partnerEligibility, existingEligibilities);
        }
    }

    public void preventDeleteForPreviouslyActiveRecords() {
        for (Partner_Shared_Solar_System_Eligibility__c partnerEligibility : records) {
            if (partnerEligibility.Start_Date__c <= System.today()) {
                partnerEligibility.addError('You cannot delete ' + partnerEligibility.Id + ' which that started in the past');
            }
        }
    }

    private List<Partner_Shared_Solar_System_Eligibility__c> getExistingEligibilities() {
        Set<Id> partnerAccountIds = new Set<Id>();
        for (Partner_Shared_Solar_System_Eligibility__c partnerEligibility : records) {
            partnerAccountIds.add(partnerEligibility.Account__c);
        }
        return partnerSSSEligibilitySelector.getSSSByPartner(partnerAccountIds);
    }

    private void validate(Partner_Shared_Solar_System_Eligibility__c newEligibility,
        List<Partner_Shared_Solar_System_Eligibility__c> existingEligibilities) {
        if (newEligibility.Start_Date__c == null) {
            newEligibility.addError('The start date must be populated');
            return;
        }
        if (newEligibility.End_Date__c != null && newEligibility.End_Date__c < newEligibility.Start_Date__c) {
            newEligibility.addError('The end date should be after the start date');
            return;
        }
        for (Partner_Shared_Solar_System_Eligibility__c existingEligibility : existingEligibilities) {
            if (hasExisting(newEligibility, existingEligibility)) {
                newEligibility.addError('An existing Partner SSS Access ('+ existingEligibility.Id +') is active at the ' +
                    'same time this one would be. Please change the dates');
                return;
            }
        }
    }

    private static Boolean hasExisting(Partner_Shared_Solar_System_Eligibility__c newEligibility,
        Partner_Shared_Solar_System_Eligibility__c existingEligibility)
    {
        return newEligibility.Id != existingEligibility.Id &&
            newEligibility.Shared_Solar_System__c == existingEligibility.Shared_Solar_System__c &&
            newEligibility.Account__c == existingEligibility.Account__c &&
            DateUtil.overlapsDates(
                existingEligibility.Start_Date__c,
                existingEligibility.End_Date__c,
                newEligibility.Start_Date__c,
                newEligibility.End_Date__c
            );
    }

}