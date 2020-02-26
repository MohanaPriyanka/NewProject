/**
 * Created by SarahRenfro on 2/20/2020.
 *
 * Tested By: CSLeadDuplicateServiceTest
 */

public without sharing class CSLeadsDuplicateService {

    @TestVisible private LeadSelector leadSelector = new LeadSelector();
    @TestVisible private DuplicateHelper duplicateHelper = new DuplicateHelper();
    @TestVisible private Lead masterLead;

    public Lead checkLeadDuplicates(Lead newLead) {
        Map<Id, Lead> duplicateMap = new Map<Id, Lead>();

        //Must catch exception in the scenario that there are no active Duplicate Rules
        try {
            duplicateMap = findDuplicateLeads(newLead);
        } catch (Exception e) {
            return newLead;
        }

        if (duplicateMap.size() == 0) {
            return newLead;
        }

        List<Lead> duplicateLeads = createOrderedDuplicateLeadList(duplicateMap, newLead);

        Savepoint sp = Database.setSavepoint();
        try {
            mapDataToMasterLead(newLead);
            mergeDuplicateAPILeads(duplicateLeads);
            return masterLead;
        } catch (Exception e) {
            Logger.logNow('CSLeadsDuplicateService', 'checkLeadDuplicates',
                'Failed to merge duplicate leads for lead: ' + masterLead.Id + '; ' + e.getMessage());
            Database.rollback(sp);
            return newLead;
        }
    }

    public Map<Id, Lead> findDuplicateLeads(Lead lead) {
        Map<Id, Lead> duplicateLeads = new Map<Id, Lead>();

        List<Datacloud.FindDuplicatesResult> results = duplicateHelper.findDuplicatesResults(new List<Lead>{lead});

        //Loop through DuplicateResults if there is more than one active rule
        for (Datacloud.DuplicateResult dr : results[0].getDuplicateResults()) {
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

    public List<Lead> createOrderedDuplicateLeadList(Map<Id, Lead> duplicateMap, Lead newLead) {

        //Get ordered list of duplicate leads to find Oldest for Master Lead to preserve timeline and chatter
        List<Lead> duplicateList = new List<Lead>();
        duplicateList = leadSelector.selectForMerge(duplicateMap.keySet());
        masterLead = duplicateList[0];

        //Add the API Lead to front of map so that it is one of the 2 leads grabbed for merge below to have most up-to-date data
        //Remove the master lead from the duplicate list so that it is not merged with itself (currently at index = 1 because moved by newLead)
        duplicateList.add(0, newLead);
        duplicateList.remove(1);

        if (duplicateList.size() > 2) {
            Logger.logNow('CSLeadDuplicateService', 'mergeDuplicateAPILeads',
                'CSLeadDuplicateService found more than 2 matching Leads for ' + masterLead.Id + '; ' +
                    'We are automatically merging the first two records - Check out the master lead for more duplicates.');
        }


        //Database.merge can only handle 2 duplicate records - Remove all other leads
        for (Integer i = duplicateList.size() - 1; i >= 2; i--) {
            duplicateList.remove(i);
        }

        return duplicateList;
    }

    public void mapDataToMasterLead(Lead newLead) {
        for (String field : leadFields) {
            if (masterLead.get(field) != newLead.get(field) && newLead.get(field) != null) {
                masterLead.put(field, newLead.get(field));
            }
        }

        Util.updateSObjs(new List<Lead>{masterLead});
    }

    public void mergeDuplicateAPILeads(List<Lead> duplicateLeads) {
        if (duplicateLeads.isEmpty()) {
            return;
        }

        Database.MergeResult[] mergeResults = duplicateHelper.mergeRecords(masterLead, duplicateLeads, false);

        for (Database.MergeResult res : mergeResults) {
            if (res.isSuccess()) {
                System.assertEquals(masterLead.Id, res.getId());
                Logger.logNow('CSLeadDuplicateService', 'mergeDuplicateAPILeads',
                    'Successfully merged leads into master lead: ' + res.getId() + '; Records were reparented to master lead: ' +
                        res.getUpdatedRelatedIds(), 'INFO' );
            } else {
                Logger.logNow('CSLeadDuplicateService', 'mergeDuplicateAPILeads',
                    'Failed to merge duplicate leads into master lead: ' + masterLead.Id + '; ' + '\n' + res.getErrors());
            }
        }
    }

    //These are all the fields that we get from the API -- Want to update existing leads with any new data from API
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