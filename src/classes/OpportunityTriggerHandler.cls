/**
 * @description Trigger handler for Opportunity
 * Tested by: OpportunityTriggerTest, CSCancellationServiceTest, ClientBrandingServiceTest, PartnerCommissionHandlerTest,
 *      UserHandlerTest
 */
public without sharing class OpportunityTriggerHandler {

    @TestVisible private static PartnerCommissionHandler partnerCommissionHandler = new PartnerCommissionHandler();
    private static Id csRecordTypeId = SObjectType.Opportunity.getRecordTypeInfosByName().get('Community Solar').getRecordTypeId();
    private Map<Id, Opportunity> oldMap;
    private Map<Id, Opportunity> newMap;
    private List<Opportunity> newList;

    public OpportunityTriggerHandler(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap, List<Opportunity> newList) {
        this.oldMap = oldMap;
        this.newMap = newMap;
        this.newList = newList;
    }

    public void beforeInsert() {
        setLeadLookup();
        eventHandling();
        setPartnerForTests();
        setCSRecordType();
        setServicingOnBehalfOf();
        setActivePartnerCommissionStructure();
    }

    public void afterInsert() {
        CSApplicationStatusEventPublisher.publishEvent(null, newList);
    }

    public void beforeUpdate() {
        eventHandling();
        setCSRecordType();
        setServicingOnBehalfOf();
    }

    public void afterUpdate() {
        List<Account> acctsToCancel = CSCancellationService.getAccountsToClose(newMap, oldMap);
        if (!acctsToCancel.isEmpty()) {
            CSCancellationService.closeAccounts(acctsToCancel);
        }
        createPartnerCommission(oldMap, newMap);
        CSApplicationStatusEventPublisher.publishEvent(oldMap, newList);
        new SystemCapacityRollupCalculator(new OpportunityCapacityRollupInitializer(oldMap, newList)).performRollup();
    }

    public void afterDelete() {
        CSApplicationStatusEventPublisher.publishEventAfterDelete(oldMap.values());
    }

    @TestVisible
    private Map<Id, Subscription_Change_Event__e> eventHandling() {
        Map<Id, Subscription_Change_Event__e> subscriptionEventMap = createSubscriptionChangeEvents(newList, oldMap);
        EventBus.publish(subscriptionEventMap.values());
        return subscriptionEventMap;
    }

    private Map<Id, Subscription_Change_Event__e> createSubscriptionChangeEvents(List<Opportunity> newOpps, Map<Id, Opportunity> oldOpps) {
        Map<Id, Subscription_Change_Event__e> subscriptionEventMap = new Map<Id, Subscription_Change_Event__e>();
        for (Opportunity newOpp : newOpps) {
            Opportunity oldOpp = oldOpps?.get(newOpp.Id);
            // Fire Subscription Change Event on insert, or on update if the Account, SSS or Stage change:
            if (oldOpp == null) {
                createSubscriptionChangeEvent(newOpp.AccountId, subscriptionEventMap);
            } else if (newOpp.AccountId != oldOpp.AccountId) {
                createSubscriptionChangeEvent(newOpp.AccountId, subscriptionEventMap);
                createSubscriptionChangeEvent(oldOpp.AccountId, subscriptionEventMap);
            } else if (newOpp.Shared_Solar_System__c != oldOpp.Shared_Solar_System__c) {
                createSubscriptionChangeEvent(newOpp.AccountId, subscriptionEventMap);
            } else if ((Opportunities.closedOpportunityStages.contains(newOpp.StageName) && !Opportunities.closedOpportunityStages.contains(oldOpp.StageName)) ||
                // We want to reevaluate the client brand key if an opportunity was won and changes to lost (which are both closed stages)
                (Opportunities.lostOpportunityStages.contains(newOpp.StageName) && !Opportunities.lostOpportunityStages.contains(oldOpp.StageName))) {
                createSubscriptionChangeEvent(newOpp.AccountId, subscriptionEventMap);
            }
        }
        return subscriptionEventMap;
    }

    private static void createSubscriptionChangeEvent(Id accountId, Map<Id, Subscription_Change_Event__e> eventMap) {
        Subscription_Change_Event__e stageChange = new Subscription_Change_Event__e(
            Property_Account_Id__c = accountId
        );
        eventMap.put(accountId, stageChange);
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    private void setPartnerForTests() {
        // Only for test records, to avoid validation rule error that opportunities must have a partner
        if (!Test.isRunningTest()) {
            return;
        }
        List<Partner__c> partners = [
            SELECT Id
            FROM Partner__c
        ];
        if (partners.size() == 0) {
            Partner__c newPartner = new Partner__c(
                Name = 'BW Inside Sales'
            );
            insert newPartner;
            partners.add(newPartner);
        }
        for (Opportunity opp : newList) {
            opp.Partner_tag_lookup__c = partners[0].Id;
        }
    }

    @InvocableMethod
    public static void activatePortalUser(List<Id> oppIdList) {
        List<Opportunity> updatedOpps = OpportunitiesSelector.selectByIds(oppIdList);
        Set<Object> accountKeys = CollectionUtil.multiMapByField(updatedOpps, Opportunity.Parent_Account_ID__c).keySet();
        Set<Id> accountIds = CollectionUtil.toIds(accountKeys);
        if (accountIds.size() > 0) {
            List<Contact> contactList = ContactSelector.selectByParentAccountIds(new List<Id>(accountIds));
            UserHandler userInsertJob = new UserHandler(contactList);
            System.enqueueJob(userInsertJob);
        }
    }

    private void createPartnerCommission(Map<Id, Opportunity> oldOpps, Map<Id, Opportunity> newOpps) {
        Set<Id> opportunityIdSet = new Set<Id>();
        for (Opportunity newOpp : newOpps.values()) {
            Opportunity oldOpp = oldOpps.get(newOpp.Id);
            if (oldOpp.StageName != 'Complete' && newOpp.StageName == 'Complete') {
                opportunityIdSet.add(newOpp.Id);
            } else if (oldOpp.Commission_Structure__c != null &&
                newOpp.Commission_Structure__c != null &&
                oldOpp.Commission_Structure__c != newOpp.Commission_Structure__c) {
                opportunityIdSet.add(newOpp.Id);
            }
        }
        partnerCommissionHandler.queueCalculatePartnerCommission(opportunityIdSet);
    }

    private void setLeadLookup() {
        for (Opportunity o : newList) {
            if (!String.isBlank(o.Lead_ID__c)) {
                o.Lead__c = o.Lead_ID__c;
            }
        }
    }

    private void setCSRecordType() {
        for (Opportunity opportunity : newList) {
            if (opportunity.Product_Line__c == 'Community Solar') {
                opportunity.RecordTypeId = csRecordTypeId;
            }
        }
    }

    private void setServicingOnBehalfOf() {
        for (Opportunity opportunity : newList) {
            if (opportunity.Product_Line__c == 'Community Solar' && opportunity.Servicing_on_Behalf_oftest__c == null) {
                opportunity.Servicing_on_Behalf_oftest__c = opportunity.Servicing_on_behalf_of__c;
            }
        }
    }

    private void setActivePartnerCommissionStructure() {
        PartnerCommissionStructureLocator service = new PartnerCommissionStructureLocator(newList);
        service.setStructureOnOpportunities();
        Logger.postLog('OpportunityTriggerHandler','setActivePartnerCommissionStructure',
            JSON.serializePretty(newList), System.now(), Logger.ERROR);
    }
}