/**
 * Created by SarahRenfro on 5/12/2020.
 *
 * Batch that implements Database.QueryLocator to query for 50K+ records for deletion.
 * Called from PostSandboxSchedulable
 *
 * TestedBy: PostSandboxRefresherTest
 */

public without sharing class GenericQueryLocatorBatchDMLOperation implements Database.Batchable<sObject> {
    public String queryString;

    public GenericQueryLocatorBatchDMLOperation(String query, String dmlOperation) {
        if (!dmlOperation.contains('Delete')) {
            throw new Util.BWException('GenericQueryLocatorBatchDMLOperation only supports Delete dml operations.');
        }
        queryString = query;
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator(queryString);
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        try {
            delete scope;
        } catch (Exception e) {
            Logger.logNow('GenericQueryLocatorBatchDMLOperation', 'execute', e.getMessage() + '\n' + e.getStackTraceString(), Logger.ERROR);
        }
    }

    public void finish(Database.BatchableContext bc) {

    }

}