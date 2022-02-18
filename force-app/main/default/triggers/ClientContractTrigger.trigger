/**
 * Created by peteryao on 7/15/20.
 * Tested By: ClientContractTest
 */

trigger ClientContractTrigger on Client_Contract__c (before insert, before update, after insert, after update, after delete, after undelete) {
    if (Util.isDisabled('Disable_ClientContractTrigger__c')) {
        return;
    }
    ClientContractService clientContractService = new ClientContractService();
    switch on Trigger.operationType {
        when BEFORE_INSERT, BEFORE_UPDATE {
            new ClientContracts(Trigger.new).validate();
        } when AFTER_INSERT, AFTER_UPDATE {
            clientContractService.setActiveContractsOnSSS(new ClientContracts(Trigger.new).getSharedSolarSystemIds());
        } when AFTER_UNDELETE {
            new ClientContracts(Trigger.new).validate();
            clientContractService.setActiveContractsOnSSS(new ClientContracts(Trigger.new).getSharedSolarSystemIds());
        } when AFTER_DELETE {
            clientContractService.setActiveContractsOnSSS(new ClientContracts(Trigger.old).getSharedSolarSystemIds());
        }
    }
}