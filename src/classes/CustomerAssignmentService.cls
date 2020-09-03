/**
 * Created by peteryao on 6/17/20.
 * Tested By: CustomerAssignmentServiceTest
 */

public without sharing class CustomerAssignmentService {
    @TestVisible
    private static SubscriptionOrderSelector subscriptionOrderSelector = new SubscriptionOrderSelector();
    @TestVisible
    private static OpportunitiesSelector opportunitiesSelector = new OpportunitiesSelector();
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

    //when invoice date on AA is populated, need to populate it on all subscription orders
    private void setInvoiceDateOnSubscriptionOrdersByBatch(Set<Id> invoicedAAIds, Map<Id, Contract> assignmentAgreementMap) {
        List<Subscription_Order__c> subscriptionOrdersToUpdate = subscriptionOrderSelector.getSubscriptionOrdersByAssignmentAgreement(invoicedAAIds);
        for (Subscription_Order__c so : subscriptionOrdersToUpdate) {
            so.Invoice_Date__c = assignmentAgreementMap.get(so.Client_Assignment_Agreement__c).Date_Invoiced__c;
        }

        GenericBatchDMLOperation batchSOs = new GenericBatchDMLOperation(subscriptionOrdersToUpdate, 'Update');
        Database.executeBatch(batchSOs);
    }

    public void assignSOsAssignmentAgreement(Map<Id, Contract> oldMap, Map<Id, Contract> newMap) {
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

    public void updatedAssignmentAgreement(Map<Id, Contract> oldMap, Map<Id, Contract> newMap) {
        Id aaTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Assignment Agreement').getRecordTypeId();
        Set<Id> signedAAIds = new Set<Id>();
        Set<Id> invoicedAAIds = new Set<Id>();
        for (Contract aa : newMap.values()) {
            if (aa.RecordTypeId == aaTypeId && (aa.CompanySignedDate != null && oldMap.get(aa.Id).CompanySignedDate == null)) {
                signedAAIds.add(aa.Id);
            }
            if (aa.RecordTypeId == aaTypeId && aa.Date_Invoiced__c != null &&
                aa.Date_Invoiced__c != oldMap.get(aa.Id).Date_Invoiced__c) {
                invoicedAAIds.add(aa.Id);
            }
        }

        if (signedAAIds.size() > 0 ) {
            List<Shared_Solar_System__c> sssList = populateFirstCustomerAssignmentDate(signedAAIds);
            Util.updateSObjs(sssList);
        }

        if (invoicedAAIds.size() > 0) {
            setInvoiceDateOnSubscriptionOrdersByBatch(invoicedAAIds, newMap);
        }
    }

    public List<Shared_Solar_System__c> populateFirstCustomerAssignmentDate(Set<Id> contractIds) {
        Map<Id, Date> sssFirstCustomerDateMap = opportunitiesSelector.selectFirstCustomerSignedDateByAssignmentAgreement(contractIds);

        List<Shared_Solar_System__c> updateSSS = new List<Shared_Solar_System__c>();
        for (Id sssId : sssFirstCustomerDateMap.keySet()) {
            Shared_Solar_System__c sss = new Shared_Solar_System__c(
                Id = sssId,
                Customer_Assignment_Date__c = sssFirstCustomerDateMap.get(sssId)
            );
            updateSSS.add(sss);
        }

        return updateSSS;
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