/**
 * Created by peteryao on 7/15/20.
 * Tested by: ClientContractServiceTest
 */

public without sharing class ClientContractScheduler implements Schedulable {
    @TestVisible
    private static ClientContractService clientContractService = new ClientContractService();
    public void execute(SchedulableContext param1) {
        try {
            clientContractService.setActiveContractsOnAllSSSes();
        } catch (Exception e) {
            Logger.logNow('ClientContractScheduler', 'execute', e, '', Logger.ERROR);
        }
    }
}