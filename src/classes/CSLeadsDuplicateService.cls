/**
 * Created by SarahRenfro on 2/20/2020.
 *
 * Tested By: CSLeadDuplicateServiceTest
 */

public without sharing class CSLeadsDuplicateService {
    public List<Lead> findDuplicateLeads(Lead apiLead) {
        List<Lead> duplicateLeads = new List<Lead>();

        List<Datacloud.FindDuplicatesResult> results;

        try {
            results = Datacloud.FindDuplicates.findDuplicates(new List<Lead>{apiLead});

        //Have to catch exception in the scenario that there are no active Duplicate Rules
        } catch (Exception e) {
            return null;
        }

        //NEED TO LOOP HERE THROUGH THE DUPLICATE RESULTS IF THERE ARE MORE THAN ONE ACTIVE RULES
        // Not super sure i need this integer loop because we only have one lead?
        for (Integer i = 0; i < results.size(); i++) {
            for (Datacloud.DuplicateResult dr : results[i].getDuplicateResults()) {
                //dont really know why we have to check the match records size
                //TODO: Need to check if there are actually multiple matchResults per DuplicateResult
                if (dr.matchResults.size() > 0 && dr.getMatchResults()[0].matchRecords.size() >  0 ) {
                  duplicateLeads.addAll(getMatchLeadRecords(dr.matchResults));
                }
            }
        }

        return duplicateLeads;

    }

    private List<Lead> getMatchLeadRecords(List<Datacloud.MatchResult> matchResults) {
        List<Lead> duplicateLeads = new List<Lead>();
        List<Datacloud.MatchRecord> matchRecords = matchResults[0].getMatchRecords();
        for (Datacloud.MatchRecord mr : matchRecords) {
            Lead duplicate = (Lead) mr.getRecord();
            duplicateLeads.add(duplicate);
        }

        return duplicateLeads;
    }

    public void mergeDuplicateAPILeads(Lead master, List<Lead> duplicateLeads) {
        //Handle duplicates if there are more than 2 leads
        if (duplicateLeads.size() > 2) {
            Logger.logNow('CSLeadDuplicateService', 'mergeDuplicateAPILeads',
                'CSLeadDuplicateService found more than 2 matching Leads for ' + master.Id + ';');
        }

        List<Lead> mergeDuplicates = new List<Lead>();
        if (duplicateLeads.size() > 0 ) {
            //Database.merge can only handle 2 duplicate records.
            for (Lead duplicate : duplicateLeads) {
                if (mergeDuplicates.size() != 2) {
                    mergeDuplicates.add(duplicate);
                } else {
                    break;
                }
            }
        } else {
            return;
        }



        Database.MergeResult[] mergeResults = Database.merge(master, mergeDuplicates, false);

        for (Database.MergeResult res : mergeResults) {
            if (res.isSuccess()) {
                System.assertEquals(master.Id, res.getId());
                Logger.logNow('CSLeadDuplicateService', 'mergeDuplicateAPILeads',
                    'Successfully merged leads into master lead: ' + res.getId() + '; Records were reparented to master lead: ' +
                        res.getUpdatedRelatedIds(), 'INFO' );
            } else {
                Logger.logNow('CSLeadDuplicateService', 'mergeDuplicateAPILeads',
                    'Failed to merge duplicate leads into master lead: ' + master.Id + '; ' + '\n' + res.getErrors());
            }
        }
    }

}