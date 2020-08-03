// Tested by ContractMigrationServiceTest

public without sharing class BatchContractMigration implements Database.Batchable<SObject>, Schedulable {
    @TestVisible
    private static OpportunitiesSelector oppSelector = new OpportunitiesSelector();

    public List<Opportunity> opportunitiesToRun;
    public Integer batchSize = 10;

    public void execute(SchedulableContext sc) {
        runBatch();
    }

    public void runBatch(){
        if (opportunitiesToRun == null){
            opportunitiesToRun = oppSelector.getCompleteOppsWithoutContracts();
        }
        Database.executeBatch(this, batchSize);
    }

    public List<SObject> start(Database.BatchableContext bc) {
        return opportunitiesToRun;
    }

    public void execute(Database.BatchableContext batchableContext, List<SObject> scope) {
        try {
            ContractMigrationService migrationService = new ContractMigrationService();
            migrationService.executeForOpps(scope);
        } catch (Exception excep){
            Logger.logNow('BatchContractMigration','execute',excep,JSON.serialize(scope),'ERROR');
        }
    }

    public void finish(Database.BatchableContext batchableContext) {
        // Nothing to do
    }
}