/**
 * @description Created by Kristin White on 12/9/2020. Called by Lead Qualification/Conversion Flow.
 * Tested By: InvocableLeadQualificationTest
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class InvocableLeadQualification {
    
    private static LeadSelector leadSelector = new LeadSelector();
    private static SharedSolarSystemsSelector sssSelector = new SharedSolarSystemsSelector();
    
    /**
     * @description Updates the lead's status to Qualified, Sales Qualified, or Unqualified based on a set of logic
     * @param leadIds A list of lead ids to qualify (to support invoking from flow), but this method only handles the first one
     */
    @InvocableMethod(Label='Run Lead Qualification Check')
    public static void runLeadQualificationCheck(List<Id> leadIds) {
        List<Shared_Solar_System__c> sssList = sssSelector.getSharedSolarSystemsForEnrollment();
        if (leadIds != null && sssList != null && !leadIds.isEmpty()) {
            Lead lead = leadSelector.selectOne(leadIds[0]);
            SharedSolarSystems sss = new SharedSolarSystems(sssList);
            String leadStatus = sss.checkCSQualification(lead, lead.LASER_Credit_Score__c);
            lead.Status = leadStatus;
            update lead;
        }
    }
}