/**
 * Created by SarahRenfro on 7/21/2020.
 *
 * Tested By: CSLeadsDuplicateServiceTest
 */

public with sharing class BatchLeadsDuplicateService implements Database.Batchable<Lead> {
    public CSLeadsDuplicateService service = new CSLeadsDuplicateService();
    public List<Lead> leads;

    public Iterable<Lead> start(Database.BatchableContext bc) {
        return leads;
    }

    public void execute(Database.BatchableContext bc, List<Lead> leadList) {
        for (Lead l : leadList) {
            l = service.checkLeadDuplicates(l);
        }
    }
    public void finish(Database.BatchableContext bc) {
        Logger.logNow('CSLeadsDuplicateServive', 'finish','Merge Batch Finished', Logger.INFO);
    }

}