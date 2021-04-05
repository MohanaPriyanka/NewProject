/**
 * Created by SarahRenfro on 4/5/2021.
 * Called by the "Assign Customers to Client Agreement" Flow
 * TestedBy: ContractSelectorTest
 */

public inherited sharing class InvocableAddendumGenerator {
    @TestVisible private static ContractSelector contractSelector = new ContractSelector();

    @InvocableMethod(Label='generateAddendumsForContracts' Description='Gets Contract in need of Addendum Contract')
    public static void generateAddendumsForContracts(List<List<Contract>> contracts) {
        List<Contract> contractsToUpdate = contracts[0];
        Set<Id> contractIds = new Set<Id>();
        for (Contract c : contractsToUpdate) {
            contractIds.add(c.Id);
        }
        contractsToUpdate = contractSelector.getCustomerContractsForAddendum(contractIds);

        for (Contract contract : contractsToUpdate) {
            contract.Generate_Addendum__c = true;
        }
        try {
            update contractsToUpdate;
        } catch (Exception e) {
            Logger.logNow('InvocableAddendumGenerator', 'generateAddendumsForContracts', 'Unable to generate Addendum documents for Contracts: '
            + JSON.serialize(contractIds) + '\n' + e.getMessage() + '\n' +  e.getStackTraceString());
        }
    }
}