/**
 * @description Creates new portal users when opportunities are updated to be Complete
 * Tested By: OpportunityTriggerTest
 */
public without sharing class CustomerPortalActivator {
    public void activatePortalAfterInsert(Map<Id, Opportunity> newOpps) {
        List<Opportunity> listOpps = new List<Opportunity>();
        for (Opportunity Opp : newOpps.values()) {
            if (newOpps.get(Opp.Id).StageName == 'Complete') {
                listOpps.add(newOpps.get(Opp.Id));
            }
        }
        activatePortal(listOpps);
    }
    public void activatePortalAfterUpdate(Map<Id, Opportunity> newOpps, Map<Id, Opportunity> oldOpps) {
        List<Opportunity> listOpps = new List<Opportunity>();
        for (Opportunity Opp : newOpps.values()) {
            if (newOpps.get(Opp.Id).StageName != oldOpps.get(Opp.Id).StageName && newOpps.get(Opp.Id).StageName == 'Complete') {
                listOpps.add(newOpps.get(Opp.Id));
            }
        }
        activatePortal(listOpps);
    }
    public void activatePortal(List<Opportunity> oppsNewlyCompleted) {
        for (Opportunity opp : oppsNewlyCompleted) {
            Map<String, SObject> flowParameters = new Map<String, SObject>();
            flowParameters.put('sov_Opportunity', opp);
            if (opp.Lead__c == null || opp.Shared_Solar_System__c == null) {
                // We need a lead and system to activate a portal. Anchor opportunities may not have both (but do not
                // need portal accounts)
                continue;
            }
            flowParameters.put('sov_Lead', new Lead(Id = opp.Lead__c));
            flowParameters.put('sov_SSS', new Shared_Solar_System__c(Id = opp.Shared_Solar_System__c));
            Flow.Interview.Portal_Activation activatePortal = new Flow.Interview.Portal_Activation(flowParameters);
            activatePortal.start();
        }
    }
}