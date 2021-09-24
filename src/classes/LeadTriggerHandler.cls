/**
 * @description Handles Lead post-processing and procedure redirection from a trigger context
 * Tested By: LeadServiceTestclass, CSLeadsDuplicateServiceTest
 */
public without sharing class LeadTriggerHandler {
    public List<Lead> newRecords = new List<Lead>();
    public Map<Id, Lead> oldRecordMap = new Map<Id, Lead>();
    @TestVisible private static fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{
        CampaignMember.SObjectType
    });

    public LeadTriggerHandler(List<Lead> triggerNew, Map<Id, Lead> triggerOldMap) {
        this.newRecords = triggerNew;
        this.oldRecordMap = triggerOldMap;
    }

    // <---- TRIGGER CONTEXT METHODS ---->
    public void beforeInsert() {
        UtilityLoadZoneService.updateLZUL(newRecords, null);
    }

    public void afterInsert() {
        checkDuplicateWebsiteLeads();
        CSApplicationStatusEventPublisher.publishEvent(null, newRecords);
        attachLeadsToCampaign(newRecords);
    }

    public void beforeUpdate() {
        UtilityLoadZoneService.updateLZUL(newRecords, oldRecordMap);
        updateContinueApplicationLinks();
    }

    public void afterUpdate() {
        LeadService leadService = new LeadService();
        leadService.completeLeadConversion(newRecords, oldRecordMap);
        leadService.convertCasesToContact(newRecords);
        leadService.updateRelatedContracts(newRecords, oldRecordMap);

        closeQCCasesForUnqualifiedLeads();
        CSApplicationStatusEventPublisher.publishEvent(oldRecordMap, newRecords);
        bouncedEmailCleared();
    }

    // <---- ROUTER METHODS ---->
    private void checkDuplicateWebsiteLeads() {
        List<Lead> websiteLeads = (List<Lead>)
            new SObjectFilter(newRecords, Lead.LeadSource, SObjectFilter.EQUAL_TO, 'Website')
                .get(SObjectFilter.SOBJECT_LIST);
        if (!websiteLeads.isEmpty()) {
            BatchLeadsDuplicateService leadsDuplicateService = new BatchLeadsDuplicateService();
            leadsDuplicateService.leads = websiteLeads;
            Database.executeBatch(leadsDuplicateService, 150);
        }
    }

    private void updateContinueApplicationLinks() {
        List<Lead> leadsWithEmailChanges = (List<Lead>)
            new SObjectFilter(oldRecordMap, newRecords, Lead.Email, SObjectFilter.ANY_VALUE, SObjectFilter.ANY_VALUE)
                .addFilterCriteria(Lead.Continue_Application_Link__c, SObjectFilter.NOT_EQUAL_TO, null)
                .get(SObjectFilter.SOBJECT_LIST);
        for (Lead lead : leadsWithEmailChanges) {
            CSLeadsRESTControllerV2.setContinueApplicationLinks(lead, null);
        }
    }

    private void closeQCCasesForUnqualifiedLeads() {
        Set<Id> newlyUnqualifiedLeadIds = (Set<Id>)
            new SObjectFilter(oldRecordMap, newRecords, Lead.Status, SObjectFilter.ANY_VALUE, 'Unqualified')
                .get(SObjectFilter.SOBJECT_ID_SET);
        if (!newlyUnqualifiedLeadIds.isEmpty()) {
            LeadService.closeQCCasesForUnqualifiedLeads(newlyUnqualifiedLeadIds);
        }
    }

    private void bouncedEmailCleared() {
        Set<Id> leadsWithUpdatedEmails = new Set<Id>();
        CaseFactory caseFactory = new CaseFactory();

        for (Lead lead : newRecords) {
            Lead oldLead = oldRecordMap.get(lead.Id);

            if (lead.Email != oldLead.Email && oldLead.EmailBouncedDate != null) {
                leadsWithUpdatedEmails.add(lead.Id);
            }
        }

        caseFactory.closeRelatedBouncedEmailCases(leadsWithUpdatedEmails);
    }

    /**
     * @description Attaches Leads to a Campaign via it's Manual_Campaign_Id__c field, set by Unbounce
     * @param newList List of leads, from Trigger.New
     */
    @TestVisible
    private void attachLeadsToCampaign(List<Lead> newList) {
        try {
            for (Lead lead : newList) {
                if (lead.Manual_Campaign_ID__c != null) {
                    uow.registerNew(new CampaignMember(
                        CampaignId = lead.Manual_Campaign_ID__c,
                        LeadId = lead.Id,
                        Status = 'Responded'
                    ));
                }
            }
            uow.commitWork();
        } catch (Exception e) {
            Logger.logNow(
                'LeadTriggerHandler',
                'attachLeadsToCampaign',
                'Exception caught attaching leads:\n' + e.getMessage() + '\n' + e.getStackTraceString() + '\n' + JSON.serialize(newList),
                Logger.ERROR
            );
        }
    }
}