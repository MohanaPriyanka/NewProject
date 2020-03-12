/**
 * Created by SarahRenfro on 2/25/2020.
 *
 * TestedBy: CSLeadsDuplicateServiceTest
 */

public without sharing class DuplicateHelper {

    public List<Datacloud.FindDuplicatesResult> findDuplicatesResults(List<SObject> sObjects) {
        return Datacloud.FindDuplicates.findDuplicates(sObjects);
    }

    public Database.MergeResult[] mergeRecords(SObject master, List<SObject> duplicateSObjects, Boolean allOrNothing) {
        return Database.merge(master, duplicateSObjects, allOrNothing);
    }
}