/**
 * @description Created by jeffparlin on 5/31/22. Kickstarts partner commission generator from invocable context.
 * Tested By: PartnerCommissionGenerationTest
 */
public without sharing class InvocablePartnerCommissionGenerator {

    @TestVisible private static FeatureService featureService = new FeatureService();

    @InvocableMethod(
        Label='Invocable Partner Commission Generator'
        Description='Kickstarts Partner Commission Generator for Specified Partner Account IDs')
    public static List<Id> generateCommissions(List<List<Opportunity>> opportunities) {
        Id queueableId;
        if (featureService.isEnabled('New_Partner_Commission_Generator')) {
            List<Id> partnerAccountIds = getPartnerAccounts(opportunities[0]);
            queueableId = System.enqueueJob(new PartnerCommissionGenerator(partnerAccountIds));
        }
        return new List<Id>{queueableId};
    }

    private static List<Id> getPartnerAccounts(List<Opportunity> opportunities) {
        Set<Id> partnerAccountIds = new Set<Id>();
        for (Opportunity opp : opportunities) {
            partnerAccountIds.add(opp.Partner_Account__c);
        }
        return new List<Id>(partnerAccountIds);
    }

}