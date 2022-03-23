/**
 * @description Created by jeffparlin on 3/15/22.
 * Tested By: PartnerCommissionGenerationTest
 */
public without sharing class PartnerCommissionScheduler implements Schedulable {

    @TestVisible private static AccountsSelector accountsSelector = new AccountsSelector();
    private static List<Id> partnerAccountIds;

    public void execute(SchedulableContext ctx) {
        partnerAccountIds = accountsSelector.getPartnerAccountsForCommissionGeneration();
        System.enqueueJob(new PartnerCommissionGenerator(partnerAccountIds));
    }
}