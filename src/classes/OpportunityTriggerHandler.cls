/*************************************************************************************
 * Test: OpportunityTriggerTest,LeadTriggerHandlerTest,CSCancellationServiceTest,
 * ClientBrandingServiceTest, PartnerCommissionHandlerTest
 *************************************************************************************/

public without sharing class OpportunityTriggerHandler {
    @TestVisible
    private static PartnerCommissionHandler partnerCommissionHandler = new PartnerCommissionHandler();
    private static CustomerAssignmentService customerAssignmentService = new CustomerAssignmentService();
    private static Id csRecordTypeId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Community Solar').getRecordTypeId();

    public void onBeforeInsert(List<Opportunity> newOppList){
        customIdSwapOpp(newOppList, null);
        mapDocuSignRS(newOppList, null);
        setLeadLookup(newOppList);
        eventHandling(newOppList, null);
        setPartnerForTests(newOppList);
        setCSRecordType(newOppList);
        setServicingOnBehalfOf(newOppList);
    }

    public void onBeforeUpdate(List<Opportunity> oldOppList, List<Opportunity> updatedOppList, Map<ID, Opportunity> oldOppMap, Map<ID, Opportunity> newOppMap){
        customIdSwapOpp(updatedOppList, oldOppMap);
        mapDocuSignRS(updatedOppList, oldOppMap);
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

    public void queueNMCTariffChange(List<Opportunity> oppList, Map<Id, Opportunity> oldMap) {
        Set<Id> oppsWithNMCTariffChange = new Set<Id>();
        for (Opportunity opp : oppList) {
            if (opp.NMC_Tariff__c != oldMap.get(opp.Id).NMC_Tariff__c) {
                oppsWithNMCTariffChange.add(opp.Id);
            }
        }
        if (oppsWithNMCTariffChange.size() > 0 ) {
            SubscriptionManagementService subscriptionService = new SubscriptionManagementService();
            subscriptionService.oppIdsWithChangedNMCTariff = oppsWithNMCTariffChange;
            System.enqueueJob(subscriptionService);
        }
    }

    private void customIdSwapOpp(List<Opportunity> oppList, Map<ID, Opportunity> oldOppMap){
        Set<String> customIdSet = new Set<String>();
        for (Opportunity opp : oppList){
            if (opp.Custom_Id__c != null){
                customIdSet.add(opp.Custom_Id__c);
            }
        }
        if (customIdSet.size() > 0 ){
            Map<String, BSST__c> salesIdMap = new Map<String, BSST__c>();
            for (BSST__c obj : [SELECT Id, Custom_Id__c FROM BSST__c WHERE Custom_Id__c IN : customIdSet] ){
                salesIdMap.put(obj.Custom_Id__c, obj);
            }
            for (Opportunity opp : oppList){
                if (( Trigger.isInsert || oldOppMap.get(opp.Id).Custom_Id__c != opp.Custom_Id__c) && salesIdMap.containsKey(opp.Custom_Id__c)){
                    opp.BS_Sales_Id__c = salesIdMap.get(opp.Custom_Id__c).id;
                } else if (
                    Trigger.isUpdate &&
                    oldOppMap.get(opp.Id).Custom_Id__c != opp.Custom_Id__c &&
                    !salesIdMap.containsKey(opp.Custom_Id__c)){
                    opp.BS_Sales_Id__c = null;
                }
            }
        }
    }

    @TestVisible
    private Map<Id,Subscription_Change_Event__e> eventHandling(List<Opportunity> newOpps, Map<Id, Opportunity> oldOpps){
        Map<Id,Subscription_Change_Event__e> subscriptionEventMap = new Map<Id,Subscription_Change_Event__e>();
        Set<Id> oppIdsWithChangedSSS = createSubscriptionChangeEvents(newOpps, oldOpps, subscriptionEventMap);

        if (oppIdsWithChangedSSS.size() > 0) {
            SubscriptionManagementService subscriptionService = new SubscriptionManagementService();
            subscriptionService.oppIdsWithChangedSSS = oppIdsWithChangedSSS;
            System.enqueueJob(subscriptionService);
        }

        EventBus.publish(subscriptionEventMap.values());
        return subscriptionEventMap;
    }

    private Set<Id> createSubscriptionChangeEvents(List<Opportunity> newOpps, Map<Id, Opportunity> oldOpps, Map<Id, Subscription_Change_Event__e> subscriptionEventMap) {
        Set<Id> oppIdsWithChangedSSS = new Set<Id>();
        for (Opportunity newOpp : newOpps) {
            Opportunity oldOpp = oldOpps?.get(newOpp.Id);
            // Fire Subscription Change Event on insert, or on update if the Account, SSS or Stage change:
            if (oldOpp == null) {
                createSubscriptionChangeEvent(newOpp.AccountId, subscriptionEventMap);
            } else if (newOpp.AccountId != oldOpp.AccountId) {
                createSubscriptionChangeEvent(newOpp.AccountId, subscriptionEventMap);
                createSubscriptionChangeEvent(oldOpp.AccountId, subscriptionEventMap);
            } else if (newOpp.Shared_Solar_System__c != oldOpp.Shared_Solar_System__c) {
                oppIdsWithChangedSSS.add(newOpp.Id);
                createSubscriptionChangeEvent(newOpp.AccountId, subscriptionEventMap);
            } else if (Opportunities.lostOpportunityStages.contains(newOpp.StageName) && !Opportunities.lostOpportunityStages.contains(oldOpp.StageName)) {
                createSubscriptionChangeEvent(newOpp.AccountId, subscriptionEventMap);
            }
        }
        return oppIdsWithChangedSSS;
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

    private void mapDocuSignRS(List<Opportunity> oppList, Map<Id, Opportunity> oldOppMap){
        Set<String> oppIdSet = new Set<String>();
        for (Opportunity opp : oppList) {
            if (opp.Email__c != null) {
                oppIdSet.add(opp.Email__c);
            }
        }
        if (oppIdSet.isEmpty()) {
            return;
        }
        Map<String, dsfs__DocuSign_Recipient_Status__c> mapDocRS = new Map<String, dsfs__DocuSign_Recipient_Status__c>();
        for (dsfs__DocuSign_Recipient_Status__c obj : [
            SELECT Id, Name, dsfs__Parent_Status_Record__c, dsfs__Recipient_Status__c, dsfs__DocuSign_Recipient_Email__c
            FROM dsfs__DocuSign_Recipient_Status__c
            WHERE dsfs__DocuSign_Recipient_Email__c IN : oppIdSet
        ]) {
            mapDocRS.put(obj.dsfs__DocuSign_Recipient_Email__c, obj);
        }
        for (Opportunity opp : oppList) {
            if (Trigger.isInsert || Trigger.isUpdate || oldOppMap.get(opp.Id).Email__c != opp.Email__c) {
                if (mapDocRS.containsKey(opp.Email__c)) {
                    opp.DocuSign_Recipient__c = mapDocRS.get(opp.Email__c).Id;
                }
            } else if (oldOppMap.get(opp.Id).Email__c != opp.Email__c && !mapDocRS.containsKey(opp.Email__c)) {
                opp.DocuSign_Recipient__c = null;
            }
        }
    }

    @InvocableMethod
    public static void activatePortalUser(List<Id> oppIdList) {
       List<Opportunity> updatedOpps = OpportunitiesSelector.selectByIds(oppIdList);

       List<Id> parentAccountIdList = new List<Id>();

       for (Opportunity newOpp : updatedOpps) {
           if (newOpp.Parent_Account_ID__c != null) {
               parentAccountIdList.add(newOpp.Parent_Account_ID__c);
           }
       }

       if (parentAccountIdList.size() > 0){
            List<Contact> contactList = ContactSelector.selectByParentAccountIds(parentAccountIdList);
            UserHandler userInsertJob = new UserHandler(contactList);
            System.enqueueJob(userInsertJob);
        }
    }

    private void createPartnerCommission(Map<ID, Opportunity> oldOpps, Map<ID, Opportunity> newOpps){
        Set<Id> opportunityIdSet = new Set<Id>();

        for (Opportunity newOpp : newOpps.values()) {
            Opportunity oldOpp = oldOpps.get(newOpp.Id);
            if (oldOpp.StageName != 'Complete'
                && newOpp.StageName == 'Complete') {
                opportunityIdSet.add(newOpp.Id);
            } else if (oldOpp.Commission_Structure__c != null && newOpp.Commission_Structure__c != null
                && oldOpp.Commission_Structure__c != newOpp.Commission_Structure__c){
                opportunityIdSet.add(newOpp.Id);
            }
        }
        if (opportunityIdSet.size() > 0){
            partnerCommissionHandler.queueCalculatePartnerCommission(opportunityIdSet);
        }
    }

    private void setLeadLookup(List<Opportunity> insertedOpportunities) {
        for (Opportunity o : insertedOpportunities) {
            if (o.Lead_ID__c != null && o.Lead_ID__c != '') {
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