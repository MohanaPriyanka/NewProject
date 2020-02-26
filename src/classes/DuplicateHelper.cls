/**
 * Created by SarahRenfro on 2/25/2020.
 *
 * TestedBy: CSLeadsDuplicateServiceTest
 */

public with sharing class DuplicateHelper {

    public List<Datacloud.FindDuplicatesResult> findDuplicatesResults(List<SObject> sObjects) {
        return Datacloud.FindDuplicates.findDuplicates(sObjects);
    }

    public Database.MergeResult[] mergeRecords(SObject master, List<SObject> duplicateSObjects, Boolean allOrNothing) {
        //TODO: not catching the error - should we do it in this method or let it bubble up to be handled later?
        return Database.merge(master, duplicateSObjects, allOrNothing);
    }
}