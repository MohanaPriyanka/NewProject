/**
 * Created by peteryao on 6/17/20.
 * Tested By: CustomerAssignmentServiceTest
 */

public without sharing class CustomerAssignmentService {
    @TestVisible
    private static SubscriptionOrderSelector subscriptionOrderSelector = new SubscriptionOrderSelector();
    @TestVisible
    private static FeatureService featureService = new FeatureService();

    public void updateAssignmentAgreements(Map<Id, Opportunity> oldMap, Map<Id, Opportunity> newMap) {
        if (featureService.isEnabled('Customer_Contract_Object')) {
            return;
        }
        Map<Id, Id> oppToAssignmentAgreementMap =
            getOppsWithUpdatedAssignmentAgreements(newMap, oldMap);
        if (oppToAssignmentAgreementMap.isEmpty()) {
            return;
        }
        List<Subscription_Order__c> approvedSubscriptionOrdersByOpp =
            subscriptionOrderSelector.selectApprovedByOppIds(oppToAssignmentAgreementMap.keySet());
        List<Subscription_Order__c> sosWithUpdatedAssignmentAgreements =
            getSOsToUpdateFromOpps(approvedSubscriptionOrdersByOpp, oppToAssignmentAgreementMap);
        Util.updateSObjs(sosWithUpdatedAssignmentAgreements);
    }
    @TestVisible
    private Map<Id, Id> getOppsWithUpdatedAssignmentAgreements(Map<Id, Opportunity> newMap, Map<Id, Opportunity> oldMap) {
        Map<Id, Id> oppToAssignmentAgreementMap = new Map<Id, Id>();
        for (Opportunity newOpp : newMap.values()) {
            if (newOpp.Assignment_Agreement__c != oldMap.get(newOpp.Id).Assignment_Agreement__c) {
                oppToAssignmentAgreementMap.put(newOpp.Id, newMap.get(newOpp.Id).Assignment_Agreement__c);
            }
        }
        return oppToAssignmentAgreementMap;
    }
    private List<Subscription_Order__c> getSOsToUpdateFromOpps(List<Subscription_Order__c> approvedSubscriptionOrdersByOpp, Map<Id, Id> oppToAssignmentAgreementMap) {
        List<Subscription_Order__c> sosWithUpdatedAssignmentAgreements = new List<Subscription_Order__c>();
        for (Subscription_Order__c so : approvedSubscriptionOrdersByOpp) {
            Id clientAssignmentAgreementId =
                oppToAssignmentAgreementMap.get(so.Utility_Account_Subscription__r.Opportunity__c);
            if (so.Client_Assignment_Agreement__c != clientAssignmentAgreementId) {
                so.Client_Assignment_Agreement__c = clientAssignmentAgreementId;
                sosWithUpdatedAssignmentAgreements.add(so);
            }
        }
        return sosWithUpdatedAssignmentAgreements;
    }

    public void updateAssignmentAgreements(Map<Id, Contract> oldMap, Map<Id, Contract> newMap) {
        if (!featureService.isEnabled('Customer_Contract_Object')) {
            return;
        }
        Map<Id, Id> contractsToAssignmentAgreementMap =
            getContractsWithUpdatedAssignmentAgreements(newMap, oldMap);
        if (contractsToAssignmentAgreementMap.isEmpty()) {
            return;
        }
        List<Subscription_Order__c> approvedSubscriptionOrdersByContract =
            subscriptionOrderSelector.selectApprovedByContractIds(contractsToAssignmentAgreementMap.keySet());
        List<Subscription_Order__c> sosWithUpdatedAssignmentAgreements =
            getSOsToUpdateFromContracts(approvedSubscriptionOrdersByContract, contractsToAssignmentAgreementMap);
        Util.updateSObjs(sosWithUpdatedAssignmentAgreements);
    }

    @TestVisible
    private Map<Id, Id> getContractsWithUpdatedAssignmentAgreements(Map<Id, Contract> newMap, Map<Id, Contract> oldMap) {
        Map<Id, Id> contractsToAssignmentAgreementMap = new Map<Id, Id>();
        for (Contract newContract : newMap.values()) {
            if (newContract.Assignment_Agreement__c != oldMap.get(newContract.Id).Assignment_Agreement__c) {
                contractsToAssignmentAgreementMap.put(newContract.Id, newMap.get(newContract.Id).Assignment_Agreement__c);
            }
        }
        return contractsToAssignmentAgreementMap;
    }
    private List<Subscription_Order__c> getSOsToUpdateFromContracts(List<Subscription_Order__c> approvedSubscriptionOrdersByContract, Map<Id, Id> contractsToAssignmentAgreementMap) {
        List<Subscription_Order__c> sosWithUpdatedAssignmentAgreements = new List<Subscription_Order__c>();
        for (Subscription_Order__c so : approvedSubscriptionOrdersByContract) {
            Id clientAssignmentAgreementId =
                contractsToAssignmentAgreementMap.get(so.Utility_Account_Subscription__r.Opportunity__r.ContractId);
            so.Client_Assignment_Agreement__c = clientAssignmentAgreementId;
            sosWithUpdatedAssignmentAgreements.add(so);
        }
        return sosWithUpdatedAssignmentAgreements;
    }
}