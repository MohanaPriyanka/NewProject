// Tested by ContractMigrationServiceTest

public without sharing class BatchContractMigration implements Database.Batchable<SObject>, Schedulable {
    @TestVisible
    private static OpportunitiesSelector oppSelector = new OpportunitiesSelector();

    @TestVisible
    private List<Opportunity> opportunitiesToRun;

    public void execute(SchedulableContext sc) {
        if (Test.isRunningTest()) {
            Database.executeBatch(new BatchContractMigration());
        } else {
            Database.executeBatch(new BatchContractMigration(), 1);
        }
    }

    public List<SObject> start(Database.BatchableContext bc) {
        if (opportunitiesToRun == null) {
            opportunitiesToRun = oppSelector.getCompleteOppsWithoutContracts();
        }
        return opportunitiesToRun;
    }

    public void execute(Database.BatchableContext batchableContext, List<SObject> scope) {
        try {
            ContractMigrationService migrationService = new ContractMigrationService();
            migrationService.executeForOpps(scope);
        } catch (Exception e){
            Logger.logNow('BatchContractMigration','execute',e.getMessage() + '\n' + e.getStackTraceString() + '\n' + JSON.serialize(scope), Logger.ERROR);
        }
    }

    public void finish(Database.BatchableContext batchableContext) {
        // Nothing to do
    }
}