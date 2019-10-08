/*************************************************************************************
 * Test: OpportunityTriggerTest,LeadTriggerHandlerTest,CSCancellationServiceTest
 *************************************************************************************/

public without sharing class OpportunityTriggerHandler {
    private Boolean m_isExecuting = false;
    private Integer batchSize = 0;

    public void OnBeforeInsert(List<Opportunity> newOppList){
        customIdSwapOpp(newOppList, null);
        mapDocuSignRS(newOppList, null);
        setLeadLookup(newOppList);
    }

    public void OnBeforeUpdate(List<Opportunity> oldOppList, List<Opportunity> updatedOppList, Map<ID, Opportunity> oldOppMap, Map<ID, Opportunity> newOppMap){
        customIdSwapOpp(updatedOppList, oldOppMap);
        mapDocuSignRS(updatedOppList, oldOppMap);
        updateInvoicedSubscription(oldOppMap, newOppMap);
    }

    public void onAfterUpdate(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap) {
        List<Account> acctsToCancel = CSCancellationService.getAccountsToClose(newMap, oldMap);
        if (!acctsToCancel.isEmpty()) {
            CSCancellationService.closeAccounts(acctsToCancel);
        }

        ClientReportingService.updateClientUAS(newMap, oldMap);
    }

    public void customIdSwapOpp(List<Opportunity> oppList, Map<ID, Opportunity> oldOppMap){
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
                }else if (
                    Trigger.isUpdate &&
                    oldOppMap.get(opp.Id).Custom_Id__c != opp.Custom_Id__c &&
                    !salesIdMap.containsKey(opp.Custom_Id__c)){
                    opp.BS_Sales_Id__c = null;
                }
            }
        }
    }
    public void mapDocuSignRS(List<Opportunity> oppList, Map<ID, Opportunity> oldOppMap){
        Set<String> oppIdSet = new Set<String>();
        for (Opportunity opp : oppList) {
            if (opp.Email__c != null) {
                oppIdSet.add(opp.Email__c);
            }
        }
        if (oppIdSet.size() > 0){
            Map<String, dsfs__DocuSign_Recipient_Status__c> mapDocRS = new Map<String, dsfs__DocuSign_Recipient_Status__c>();
            for (dsfs__DocuSign_Recipient_Status__c obj : [SELECT Id, Name, dsfs__Parent_Status_Record__c, dsfs__Recipient_Status__c, dsfs__DocuSign_Recipient_Email__c
                                                          FROM dsfs__DocuSign_Recipient_Status__c
                                                          WHERE dsfs__DocuSign_Recipient_Email__c IN : oppIdSet]){
                mapDocRS.put(obj.dsfs__DocuSign_Recipient_Email__c, obj);
            }
            for (Opportunity opp : oppList) {
                if (Trigger.isInsert || Trigger.isUpdate || oldOppMap.get(opp.Id). Email__c != opp.Email__C){
                    if (mapDocRS.containsKey(opp.Email__c)){
                       opp.DocuSign_Recipient__c = mapDocRS.get(opp.Email__c).Id;
                    }
                }
                else if (oldOppMap.get(opp.Id).Email__c != opp.Email__c && !mapDocRS.containsKey(opp.Email__c)) {
                    opp.DocuSign_Recipient__c = null;
                }
            }
        }
    }

   @InvocableMethod public static void activatePortalUser(List<Id> oppIdList) {

       List<Opportunity> updatedOpps = [
           SELECT Id, Contract_Status__c, Product_Line__c, Parent_Account_ID__c,
           BlueWave_Signature_Status__c
           FROM Opportunity
           WHERE Id IN: oppIdList];

       List<Id> parentAccountIdList = new List<Id>();

       for (Opportunity newOpp : updatedOpps) {
           if (newOpp.Parent_Account_ID__c != null) {
               parentAccountIdList.add(newOpp.Parent_Account_ID__c);
           }
       }

       if (parentAccountIdList.size() > 0){
            List<Contact> contactList = [
                SELECT Id, FirstName, LastName, Email, AccountId
                FROM Contact
                WHERE AccountId IN : parentAccountIdList];
            UserHandler userInsertJob = new UserHandler(contactList);
            System.enqueueJob(userInsertJob);
        }
    }

    public void updateInvoicedSubscription(Map<ID, Opportunity> oldOpps, Map<ID, Opportunity> newOpps){
        List<Opportunity> opportunityList = new List<Opportunity>();
        Map<Id, Decimal> oppUASTotalMap = new Map<Id, Decimal>();

        for (Opportunity newOpp : newOpps.values()) {
            if (oldOpps.get(newOpp.Id).StageName != 'Complete'
                && newOpp.StageName == 'Complete'
                && newOpp.Product_Line__c == 'Community Solar'
                && newOpp.Subscription_Size_for_Invoicing__c == null){
                    opportunityList.add(newOpp);
            }

            //if sss changes

            // query for client uas where Opportunity ID = opp
            // update client uas
        }
        if (opportunityList.size() > 0){
            for (AggregateResult uasSUM : [SELECT Opportunity__r.Id oppId,
                                                SUM(Customer_Subscription_KW_DC__c) subscriptionSum
                                            FROM Utility_Account_Subscription__c
                                            WHERE Opportunity__r.Id IN : opportunityList
                                            GROUP BY Opportunity__r.Id]){
                oppUASTotalMap.put((Id)uasSUM.get('oppId'), (Decimal)uasSUM.get('subscriptionSum'));
            }
            for (Opportunity oppToUpdate : opportunityList){
                if (oppUASTotalMap.containsKey(oppToUpdate.Id)){
                    oppToUpdate.Subscription_Size_for_Invoicing__c = oppUASTotalMap.get(oppToUpdate.Id);
                }
            }
        }
    }

    public void setLeadLookup(List<Opportunity> insertedOpportunities) {
        for (Opportunity o : insertedOpportunities) {
            if (o.Lead_ID__c != null && o.Lead_ID__c != '') {
                o.Lead__c = o.Lead_ID__c;
            }
        }
    }
}