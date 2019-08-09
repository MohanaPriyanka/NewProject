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
        ReferralCodeHandler referralCodeHandler  = new ReferralCodeHandler();

        public List<Lead> updatedCSAPLeads = new List<Lead>();
        public Map<Id, Lead> oldCSAPMap = new Map<Id, Lead>();

        public List<Lead> updatedLeads = new List<Lead>();
        public Map<Id, Lead> oldLeadMap = new Map<Id, Lead>();
    }


    //Separate the Switch Leads from the CSAP/Web/Loan Leads
    public static LeadHandlerResult separateLeads(List<Lead> updatedLeads, Map<Id, Lead> oldLeadMap){
        LeadHandlerResult result = new LeadHandlerResult();


        for (Lead lead : updatedLeads) {
            if (lead.LeadSource == 'Switch' || lead.LeadSource == 'Third-Party') {
                result.updatedLeads.add(lead);

                if (oldLeadMap != null) {
                    result.oldLeadMap.put(lead.Id, oldLeadMap.get(lead.Id));
                }
            } else {
                result.updatedCSAPLeads.add(lead);

                if (oldLeadMap != null) {
                    result.oldCSAPMap.put(lead.Id, oldLeadMap.get(lead.Id));
                }
            }

        }
        return result;
    }

    public void onBeforeInsert(List<Lead> leadList) {
        LeadHandlerResult result = separateLeads(leadList, null);

        if (result.updatedCSAPLeads.size() > 0) {
            result.leadTriggerHandler.onBeforeInsert(result.updatedCSAPLeads);
            result.referralCodeHandler.OnBeforeInsert(result.updatedCSAPLeads);
        }

        if (result.updatedLeads.size()> 0 ){
            UtilityLoadZoneService.updateLZUL(result.updatedLeads, null);

            // When we remove the "If Switch" statement with retirement of CSAP,we will need to retire ReferralCodeHandler
            // and change to assignPartner(leadList); This will require an update to all TestClasses that still use the CustomId
            // assignPartner(result.updatedSwitchLeads);
        }
    }

    public void onBeforeUpdate(List<Lead> updatedLeads, Map<Id, Lead> oldLeadMap) {
        LeadHandlerResult result = separateLeads(updatedLeads, oldLeadMap);

        if (result.updatedCSAPLeads.size() > 0 ) {
            result.leadTriggerHandler.onBeforeUpdate(null, result.updatedCSAPLeads, result.oldCSAPMap, null);
            UtilityAccountLogConversionHandler.utilityAccountLogConversion(result.updatedCSAPLeads);
        }

        if (result.updatedLeads.size()> 0 ){
            UtilityLoadZoneService.updateLZUL(result.updatedLeads, result.oldLeadMap);

        }

    }

    public void onAfterUpdate(List<Lead> updatedLeads, Map<Id, Lead> oldLeadMap){
        LeadHandlerResult result = separateLeads(updatedLeads, oldLeadMap);

        LeadService leadService = new LeadService();
        if (result.updatedCSAPLeads.size() > 0 ) {
            result.leadTriggerHandler.onAfterUpdate(null, result.updatedCSAPLeads, result.oldCSAPMap);
        }

        if (result.updatedLeads.size()> 0 ){
            leadService.completeLeadConversion(result.updatedLeads, result.oldLeadMap);
            leadService.convertCasesToContact(result.updatedLeads);
        }
    }

//    public void assignPartner(List<Lead> leadList){
//        //Handle all leads that do not have a Partner yet - ie from Website or Campaigns
//        //will take the place of ReferralCodeHandler after we retire the old LeadTriggerHandler Class
//
//        Partner__c defaultCSPartner = PartnerSelector.selectDefaultCSPartner();
//
//        for (Lead lead : leadList) {
//            if (lead.Product_line__c == 'Community Solar' && lead.Partner_Lookup__c == null) {
//                lead.Partner_Lookup__c = defaultCSPartner.Id;
//                lead.bs_Sales_ID__c = defaultCSPartner.Default_Sales_Rep__r.Id;
//                lead.Partner_Email__c = defaultCSPartner.Email__c;
//            }
//        }
//
//    }



}