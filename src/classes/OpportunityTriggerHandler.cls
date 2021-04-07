/*************************************************************************************
 * Test: OpportunityTriggerTest,LeadTriggerHandlerTest,CSCancellationServiceTest,
 * ClientBrandingServiceTest, PartnerCommissionHandlerTest, mapDocuSignRSTestClass
 *************************************************************************************/

public without sharing class OpportunityTriggerHandler {
    @TestVisible
    private static PartnerCommissionHandler partnerCommissionHandler = new PartnerCommissionHandler();
    private static Id csRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Community Solar').getRecordTypeId();

    public void onBeforeInsert(List<Opportunity> newOppList){
        mapDocuSignRS(newOppList);
        setLeadLookup(newOppList);
        eventHandling(newOppList, null);
        setPartnerForTests(newOppList);
        setCSRecordType(newOppList);
        setServicingOnBehalfOf(newOppList);
    }

    public void onBeforeUpdate(List<Opportunity> updatedOppList, Map<Id, Opportunity> oldOppMap){
        mapDocuSignRS(updatedOppList);
        eventHandling(updatedOppList, oldOppMap);
        setCSRecordType(updatedOppList);
        setServicingOnBehalfOf(updatedOppList);
    }

    public void onAfterUpdate(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap) {
        List<Account> acctsToCancel = CSCancellationService.getAccountsToClose(newMap, oldMap);
        if (!acctsToCancel.isEmpty()) {
            CSCancellationService.closeAccounts(acctsToCancel);
        }
        createPartnerCommission(oldMap, newMap);
    }

    @TestVisible
    private Map<Id,Subscription_Change_Event__e> eventHandling(List<Opportunity> newOpps, Map<Id, Opportunity> oldOpps){
        Map<Id,Subscription_Change_Event__e> subscriptionEventMap = createSubscriptionChangeEvents(newOpps, oldOpps);
        EventBus.publish(subscriptionEventMap.values());
        return subscriptionEventMap;
    }

    private Map<Id, Subscription_Change_Event__e> createSubscriptionChangeEvents(List<Opportunity> newOpps, Map<Id, Opportunity> oldOpps) {
        Map<Id, Subscription_Change_Event__e> subscriptionEventMap = new Map<Id,Subscription_Change_Event__e>();
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
            } else if (Opportunities.lostOpportunityStages.contains(newOpp.StageName) && !Opportunities.lostOpportunityStages.contains(oldOpp.StageName)) {
                createSubscriptionChangeEvent(newOpp.AccountId, subscriptionEventMap);
            }
        }
        return subscriptionEventMap;
    }

    private static void createSubscriptionChangeEvent(Id accountId, Map<Id, Subscription_Change_Event__e> eventMap) {
        Subscription_Change_Event__e stageChange = new Subscription_Change_Event__e(
            Property_Account_Id__c = accountId
        );
        eventMap.put(accountId,stageChange);
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static void setPartnerForTests(List<Opportunity> newOppList){
        // Only for test records, to avoid validation rule error that opportunities must have a partner
        if (!Test.isRunningTest()) {
            return;
        }
        List<Partner__c> partners = [
            SELECT Id
            FROM Partner__c
        ];
        if (partners.size() == 0){
            Partner__c newPartner = new Partner__c(
                Name = 'BW Inside Sales'
            );
            insert newPartner;
            partners.add(newPartner);
        }
        for (Opportunity opp : newOppList){
            opp.Partner_tag_lookup__c = partners[0].Id;
        }
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    private void mapDocuSignRS(List<Opportunity> oppList){
        Set<Object> opportunitiesByEmail = CollectionUtil.multiMapByField(oppList, Opportunity.Email__c).keySet();
        Set<String> emails = CollectionUtil.toStrings(opportunitiesByEmail);
        List<dsfs__DocuSign_Recipient_Status__c> docuSignRecipientStatuses = [
            SELECT Id, Name, dsfs__Parent_Status_Record__c, dsfs__Recipient_Status__c, dsfs__DocuSign_Recipient_Email__c
            FROM dsfs__DocuSign_Recipient_Status__c
            WHERE dsfs__DocuSign_Recipient_Email__c IN : emails
        ];
        Map<Object, SObject> mapDocRS =
            CollectionUtil.mapByField(docuSignRecipientStatuses, dsfs__DocuSign_Recipient_Status__c.dsfs__DocuSign_Recipient_Email__c);
        for (Opportunity opp : oppList) {
            opp.DocuSign_Recipient__c = mapDocRS.get(opp.Email__c)?.Id;
        }
    }

    @InvocableMethod
    public static void activatePortalUser(List<Id> oppIdList) {
        List<Opportunity> updatedOpps = OpportunitiesSelector.selectByIds(oppIdList);
        Set<Object> accountKeys = CollectionUtil.multiMapByField(updatedOpps, Opportunity.Parent_Account_ID__c).keySet();
        Set<Id> accountIds = CollectionUtil.toIds(accountKeys);
        if (accountIds.size() > 0){
            List<Contact> contactList = ContactSelector.selectByParentAccountIds(new List<Id>(accountIds));
            UserHandler userInsertJob = new UserHandler(contactList);
            System.enqueueJob(userInsertJob);
        }
    }

    private void createPartnerCommission(Map<Id, Opportunity> oldOpps, Map<Id, Opportunity> newOpps){
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

    private void setLeadLookup(List<Opportunity> insertedOpportunities) {
        for (Opportunity o : insertedOpportunities) {
            if (!String.isBlank(o.Lead_ID__c)) {
                o.Lead__c = o.Lead_ID__c;
            }
        }
    }

    private void setCSRecordType(List<Opportunity> triggerNew) {
        for (Opportunity opportunity : triggerNew) {
            if (opportunity.Product_Line__c == 'Community Solar') {
                opportunity.RecordTypeId = csRecordTypeId;
            }
        }
    }

    private void setServicingOnBehalfOf(List<Opportunity> triggerNew) {
        for (Opportunity opportunity : triggerNew) {
            if (opportunity.Product_Line__c == 'Community Solar' && opportunity.Servicing_on_Behalf_oftest__c == null) {
                opportunity.Servicing_on_Behalf_oftest__c = opportunity.Servicing_on_behalf_of__c;
            }
        }
    }
}