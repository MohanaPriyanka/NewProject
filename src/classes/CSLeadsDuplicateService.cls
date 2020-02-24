/**
 * Created by SarahRenfro on 2/20/2020.
 *
 * Tested By: CSLeadDuplicateServiceTest
 */

public without sharing class CSLeadsDuplicateService {
    public Map<Id, Lead> findDuplicateLeads(Lead lead) {
        Map<Id, Lead> duplicateLeads = new Map<Id, Lead>();
        List<Datacloud.FindDuplicatesResult> results;
        try {
            results = Datacloud.FindDuplicates.findDuplicates(new List<Lead>{lead});
            //Have to catch exception in the scenario that there are no active Duplicate Rules
        } catch (Exception e) {
            return null;
        }

        //NEED TO LOOP HERE THROUGH THE DUPLICATE RESULTS IF THERE ARE MORE THAN ONE ACTIVE RULES
        for (Datacloud.DuplicateResult dr : results[0].getDuplicateResults()) {
            // Only using the Lead_Duplicate_Rule for API Leads
            if (dr.duplicateRule == 'Lead_Duplicate_Rule' && dr.matchResults.size() > 0 && dr.getMatchResults()[0].matchRecords.size() >  0 ) {
                duplicateLeads.putAll(getMatchLeadRecords(dr.matchResults));
            }
        }

        return duplicateLeads;
    }

    private Map<Id, Lead> getMatchLeadRecords(List<Datacloud.MatchResult> matchResults) {
        Map<Id, Lead> duplicateMap = new Map<Id, Lead>();
        List<Datacloud.MatchRecord> matchRecords = matchResults[0].getMatchRecords();
        for (Datacloud.MatchRecord mr : matchRecords) {
            Lead duplicate = (Lead) mr.getRecord();
            if (duplicate.LeadSource != 'Switch' && duplicate.LeadSource != 'CSAP'){
                duplicateMap.put(duplicate.Id, duplicate);
            }
        }
        return duplicateMap;
    }

    public Lead mapDataToMasterLead(Lead masterLead, Lead lead) {
        SavePoint sp = Database.setSavepoint();

        try {
            for (String field : leadFields) {
                if (masterLead.get(field) != lead.get(field) && lead.get(field) != null) {
                    masterLead.put(field, lead.get(field));
                }
            }

            update masterLead;
            return masterLead;
        } catch (Exception e) {
            Database.rollback(sp);
            Logger.logNow('CSLeadDuplicateService', 'mapDataToMasterLead',
                'Error when trying to update master lead with new lead: ' + e.getMessage());
            return null;
        }
    }

    public void mergeDuplicateAPILeads(Lead master, List<Lead> duplicateLeads) {
        if (duplicateLeads.isEmpty()) {
            return;
        }

        Database.MergeResult[] mergeResults = Database.merge(master, duplicateLeads, false);

        for (Database.MergeResult res : mergeResults) {
            if (res.isSuccess()) {
                System.assertEquals(master.Id, res.getId());
                Logger.logNow('CSLeadDuplicateService', 'mergeDuplicateAPILeads',
                    'Successfully merged leads into master lead: ' + res.getId() + '; Records were reparented to master lead: ' +
                        res.getUpdatedRelatedIds(), 'INFO' );

                System.debug('Merged Ids:  ' + res.getMergedRecordIds());

            } else {
                Logger.logNow('CSLeadDuplicateService', 'mergeDuplicateAPILeads',
                    'Failed to merge duplicate leads into master lead: ' + master.Id + '; ' + '\n' + res.getErrors());
                System.debug('Error merging: ' + res.getErrors());
            }
        }
    }

    //These are all the fields that we get from the API -- Want to update existing leads with any new data
    public List<String> leadFields = new List<String>{
        'FirstName',
        'LastName',
        'Email',
        'MobilePhone',
        'Phone',
        'Company',
        'Application_Type__c',
        'LASERCA__Home_Address__c',
        'LASERCA__Home_City__c',
        'LASERCA__Home_State__c',
        'LASERCA__Home_Zip__c',
        'Street',
        'City',
        'State',
        'PostalCode',
        'Parcel_Zip__c',
        'LeadSource',
        'LoadZone__c',
        'Product_Line__c',
        'Business_Phone__c',
        'Business_Title__c',
        'Customer_type__c',
        'Application_Complete_Date__c',
        'Status',
        'Partner_Email__c',
        'Partner_lookup__c',
        'bs_Sales_ID__c',
        'Product__c',
        'Utility_relationship__c',
        'Continue_Application_Link__c',
        'Manual_Campaign_ID__c',
        'Referral_Name__c',
        'Referral_Email__c'
    };
}