/**
 * Created by SarahRenfro on 1/4/2021.
 * Description: Called from the Lead_Qualification_Conversion Flow to retrieve a List of SSS that qualify for the given lead
 * Tested By: LeadServiceTestclass
 */

public with sharing class InvocableQualifiedSSSSelector {
    @TestVisible private static SharedSolarSystemsSelector sssSelector = new SharedSolarSystemsSelector();

    @InvocableMethod(Label='Get Ordered Qualified Shared Solar Systems')
    public static List<List<Shared_Solar_System__c>> invokeGetQualifiedForLead(List<Lead> leadsFromFlow) {
        List<Shared_Solar_System__c> sssList = sssSelector.getSharedSolarSystemsForEnrollment();
        SharedSolarSystems sharedSolarSystems = new SharedSolarSystems(sssList);
        List<Shared_Solar_System__c> orderedSharedSolarSystems = sharedSolarSystems.getQualifiedForLead(leadsFromFlow[0]);
        return new List<List<Shared_Solar_System__c>>{orderedSharedSolarSystems};
    }

}