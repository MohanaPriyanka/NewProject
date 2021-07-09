/**
 * Created by SarahRenfro on 5/24/2019.
 *
 * Test: LeadServiceTestclass
 *
 * Description: This class is used to dispatch Switch leads to Service Classes and all Loan/CSAP/Web leads. Once the Loan Product
 * as well as the CSAP are closed down, we can move the below calls to various services to the LeadTrigger and retire both
 * this class as well as the LeadTriggerHandler.
 */

public with sharing class LeadDispatcher {

    public class LeadHandlerResult {
        LeadTriggerHandler leadTriggerHandler = new LeadTriggerHandler();
        public List<Lead> websiteLeads = new List<Lead>();
        public List<Lead> updatedLeads = new List<Lead>();
        public Map<Id, Lead> oldLeadMap = new Map<Id, Lead>();
    }

    //Separate the Switch Leads from the Web Leads
    public static LeadHandlerResult separateLeads(List<Lead> updatedLeads, Map<Id, Lead> oldLeadMap){
        LeadHandlerResult result = new LeadHandlerResult();
        for (Lead lead : updatedLeads) {
            if (lead.LeadSource == 'Switch' || lead.LeadSource == 'Third-Party') {
                result.updatedLeads.add(lead);

                if (oldLeadMap != null) {
                    result.oldLeadMap.put(lead.Id, oldLeadMap.get(lead.Id));
                }
            } else if (lead.LeadSource == 'Website') {
                result.websiteLeads.add(lead);
            }

        }
        return result;
    }

    public void onBeforeInsert(List<Lead> leadList) {
        LeadHandlerResult result = separateLeads(leadList, null);
        if (result.updatedLeads.size()> 0 ){
            UtilityLoadZoneService.updateLZUL(result.updatedLeads, null);
        }
    }

    public void checkForDuplicates(List<Lead> leadList) {
        LeadHandlerResult result = separateLeads(leadList, null);

        if (result.websiteLeads.size() > 0 ) {
            BatchLeadsDuplicateService leadsDuplicateService = new BatchLeadsDuplicateService();
            leadsDuplicateService.leads = result.websiteLeads;
            Database.executeBatch(leadsDuplicateService, 150);
        }
    }

    public void onBeforeUpdate(List<Lead> updatedLeads, Map<Id, Lead> oldLeadMap) {
        LeadHandlerResult result = separateLeads(updatedLeads, oldLeadMap);

        if (result.updatedLeads.size()> 0 ){
            UtilityLoadZoneService.updateLZUL(result.updatedLeads, result.oldLeadMap);
        }

    }

    public void onAfterUpdate(List<Lead> updatedLeads, Map<Id, Lead> oldLeadMap){
        LeadHandlerResult result = separateLeads(updatedLeads, oldLeadMap);

        LeadService leadService = new LeadService();

        if (result.updatedLeads.size()> 0 ){
            leadService.completeLeadConversion(result.updatedLeads, result.oldLeadMap);
            leadService.convertCasesToContact(result.updatedLeads);
            leadService.updateRelatedContracts(result.updatedLeads, result.oldLeadMap);
        }
    }
}