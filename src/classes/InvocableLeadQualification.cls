/**
 * Created by Kristin White on 12/9/2020
 * 
 * Description: Called by Lead Qualification/Conversion Flow.
 * 
 * Test: InvocableLadQualificationTest
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class InvocableLeadQualification {
    
    private static LeadSelector leadSelector = new LeadSelector();
    private static SharedSolarSystemsSelector sssSelector = new SharedSolarSystemsSelector();
    @InvocableMethod(label='Run Lead Qualification Check')
    public static void runLeadQualificationCheck(List<Id> leadIds) {
        List<Shared_Solar_System__c> sssList = sssSelector.getSharedSolarSystemsForEnrollment();
        if(leadIds != null && sssList != null && !leadIds.isEmpty()) {
            Lead lead = leadSelector.selectOne(leadIds[0]);
            SharedSolarSystems sss = new SharedSolarSystems(sssList);
            String leadStatus = sss.checkCSQualification(lead, null);
            lead.Status = leadStatus;
            update lead;
        }
    }
}