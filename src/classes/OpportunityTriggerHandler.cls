/**
 * @description Opportunity trigger handler
 * Tested by: OpportunityTriggerTest, CSCancellationServiceTest, ClientBrandingServiceTest, PartnerCommissionHandlerTest
 **/
public without sharing class OpportunityTriggerHandler {

    @TestVisible private static PartnerCommissionHandler partnerCommissionHandler = new PartnerCommissionHandler();
    private static Id csRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Community Solar').getRecordTypeId();
    private List<Opportunity> newList;
    private Map<Id, Opportunity> newMap; // Not present in before insert trigger context
    private Map<Id, Opportunity> oldMap;

    public OpportunityTriggerHandler(List<Opportunity> newList, Map<Id, Opportunity> newMap, Map<Id, Opportunity> oldMap) {
        this.newList = newList;
        this.newMap = newMap;
        this.oldMap = oldMap;
    }

    public void onBeforeInsert() {
        setPartnerForTests();
        setLeadLookup();
        eventHandling();
        setCSRecordType();
        setServicingOnBehalfOf();
    }

    public void onAfterInsert() {
        CSApplicationStatusEventPublisher.publishEvent(null, newList);
    }

    public void onBeforeUpdate() {
        eventHandling();
        setCSRecordType();
        setServicingOnBehalfOf();
    }

    public void onAfterUpdate() {
        List<Account> acctsToCancel = CSCancellationService.getAccountsToClose(newMap, oldMap);
        if (!acctsToCancel.isEmpty()) {
            CSCancellationService.closeAccounts(acctsToCancel);
        }
        checkPartnerCommissionAfterUpdate();
        CSApplicationStatusEventPublisher.publishEvent(oldMap, newList);
    }

    public void onAfterDelete() {
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
            } else if (Opportunities.closedOpportunityStages.contains(newOpp.StageName) && !Opportunities.closedOpportunityStages.contains(oldOpp.StageName)) {
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

    private void checkPartnerCommissionAfterUpdate() {
        Set<Id> opportunityIdSet = new Set<Id>();
        for (Opportunity newOpp : newList) {
            Opportunity oldOpp = oldMap.get(newOpp.Id);
            if (oldOpp.StageName != 'Complete' && newOpp.StageName == 'Complete') {
                opportunityIdSet.add(newOpp.Id);
            } else if (oldOpp.Commission_Structure__c != null && newOpp.Commission_Structure__c != null &&
                oldOpp.Commission_Structure__c != newOpp.Commission_Structure__c) {
                opportunityIdSet.add(newOpp.Id);
            }
        }
        partnerCommissionHandler.queueCalculatePartnerCommission(opportunityIdSet);
    }

    private void setLeadLookup() {
        for (Opportunity opp : newList) {
            opp.Lead__c = opp.Lead_ID__c;
        }
    }

    private void setCSRecordType() {
        for (Opportunity opp : newList) {
            if (opp.Product_Line__c == 'Community Solar') {
                opp.RecordTypeId = csRecordTypeId;
            }
        }
    }

    private void setServicingOnBehalfOf() {
        for (Opportunity opp : newList) {
            if (opp.Product_Line__c == 'Community Solar' && opp.Servicing_on_Behalf_oftest__c == null) {
                opp.Servicing_on_Behalf_oftest__c = opp.Servicing_on_behalf_of__c;
            }
        }
    }
}