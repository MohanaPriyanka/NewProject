/**
 * @description Created by jeffparlin on 2/24/22. Queueable class to run to generate Partner Commission records. Accepts
 * a List<Id> of Partner Account Ids and processes ONE Partner per queueable execution.
 * Tested By: PartnerCommissionGenerationTest
 */
public without sharing class PartnerCommissionGenerator implements Queueable {

    @TestVisible private static OpportunitiesSelector oppSelector = new OpportunitiesSelector();
    @TestVisible private Id currentPartner;
    private List<Id> partnersToProcess;
    private Map<Id,Opportunity> variableRateOpportunities;
    private fflib_SObjectUnitOfWork unitOfWork;

    public PartnerCommissionGenerator(List<Id> partnerAccountIds) {
        this.partnersToProcess = partnerAccountIds;
        this.currentPartner = partnerAccountIds.get(partnerAccountIds.size()-1);
    }

    public void execute(QueueableContext ctx) {
        process();
        partnersToProcess.remove(partnersToProcess.size()-1);
        if (!partnersToProcess.isEmpty()) {
            System.enqueueJob(new PartnerCommissionGenerator(partnersToProcess));
        }
    }

    private void process() {
        unitOfWork = new fflib_SObjectUnitOfWork(new List<SObjectType> {
            Commission_Payment__c.SObjectType,
            Subscription_Order__c.SObjectType
        });
        try {
            generateCommissionPayments();
        } catch (Exception e) {
            String message = e.getMessage() + '\n\n' + e.getStackTraceString();
            Logger.postLog('PartnerCommissionGenerator', 'execute (Queueable)', message, System.now(), Logger.ERROR);
        }
    }

    private void generateCommissionPayments() {
        variableRateOpportunities = oppSelector.getVariableRateCommissionOppsForPartner(currentPartner);
        if (!variableRateOpportunities.isEmpty()) {
            new VariableRateCommissionProcessor(variableRateOpportunities, unitOfWork, currentPartner).generateCommissionPayments();
        }
        unitOfWork.commitWork();
    }
}