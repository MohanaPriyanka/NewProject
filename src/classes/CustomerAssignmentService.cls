/**
 * Created by peteryao on 6/17/20.
 * Tested By: CustomerAssignmentServiceTest
 */

public without sharing class CustomerAssignmentService {
    @TestVisible private static SubscriptionOrderSelector subscriptionOrderSelector = new SubscriptionOrderSelector();
    @TestVisible private static OpportunitiesSelector opportunitiesSelector = new OpportunitiesSelector();
    @TestVisible private static FeatureService featureService = new FeatureService();
    @TestVisible private static ContractSelector contractSelector = new ContractSelector();
    @TestVisible private static Id aaTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Assignment Agreement').getRecordTypeId();

    public void updateInvoicedSubscriptionOrders(Map<Id, Contract> oldMap, Map<Id, Contract> newMap) {
        Set<Id> invoicedAAIds = new Set<Id>();
        for (Contract aa : newMap.values()) {
            if (aa.RecordTypeId == aaTypeId && aa.Date_Invoiced__c != null &&
                aa.Date_Invoiced__c != oldMap.get(aa.Id).Date_Invoiced__c) {
                invoicedAAIds.add(aa.Id);
            }
        }

        if (invoicedAAIds.size() > 0) {
            List<Subscription_Order__c> soUpdateList = setInvoiceDateOnSubscriptionOrders(invoicedAAIds, newMap);
            GenericBatchDMLOperation batchSOs = new GenericBatchDMLOperation(soUpdateList, 'Update');
            Database.executeBatch(batchSOs);
        }
    }

    public void updateSignedAssignmentAgreements(Map<Id, Contract> oldMap, Map<Id, Contract> newMap) {
        Set<Id> signedAAIds = new Set<Id>();
        for (Contract aa : newMap.values()) {
            if (aa.RecordTypeId == aaTypeId && (aa.CompanySignedDate != null && oldMap.get(aa.Id).CompanySignedDate == null)) {
                signedAAIds.add(aa.Id);
            }
        }

        if (signedAAIds.size() > 0 ) {
            List<Shared_Solar_System__c> sssList = populateFirstCustomerAssignmentDate(signedAAIds);
            Util.updateSObjs(sssList);
        }
    }

    /**
     * @description Updates Subscription Orders that are effective on or before the cutoff date with the associated
     * Assignment Agreement (from the UAS.Opportunity.Contract).
     * @param assignmentBundles The list of Contracts to assign, and the cutoff date
     */
    @InvocableMethod(Label='assignSOsAssignmentAgreement')
    public static void assignSOsAssignmentAgreement(List<ContractAssignmentBundle> assignmentBundles) {
        if (assignmentBundles[0].contracts == null) {
            return;
        }
        List<Subscription_Order__c> approvedSubscriptionOrdersByContract =
            subscriptionOrderSelector.selectApprovedByContractIds(CollectionUtil.getIdSet(assignmentBundles[0].contracts), assignmentBundles[0].cutoffDate);
        Map<Id, Id> contractsToAssignmentAgreementMap = new Map<Id, Id>();
        for (Subscription_Order__c so : approvedSubscriptionOrdersByContract) {
            contractsToAssignmentAgreementMap.put(
                so.Utility_Account_Subscription__r.Opportunity__r.ContractId,
                so.Utility_Account_Subscription__r.Opportunity__r.Contract.Assignment_Agreement__c
            );
        }
        List<Subscription_Order__c> sosWithUpdatedAssignmentAgreements =
            getSOsToUpdateFromContracts(approvedSubscriptionOrdersByContract, contractsToAssignmentAgreementMap);
        Util.updateSObjs(sosWithUpdatedAssignmentAgreements);
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    public void handleRejectedAssignmentAgreement(Map<Id, Contract> oldMap, Map<Id, Contract> newMap) {
        Set<Id> rejectedAAIds = new Set<Id>();
        for (Contract aa : newMap.values()) {
            if (aa.RecordTypeId == aaTypeId && (aa.Status == 'Rejected' && oldMap.get(aa.Id).Status != 'Rejected')) {
                rejectedAAIds.add(aa.Id);
            }
        }
        if (rejectedAAIds.isEmpty()) {
            return;
        }
        List<Contract> contractsOnRejectedAA = contractSelector.getCustomerContractsByAssignmentAgreement(rejectedAAIds);
        for (Contract rejectedContract : contractsOnRejectedAA) {
            rejectedContract.Assignment_Agreement__c = null;
        }
        update contractsOnRejectedAA;

        List<Subscription_Order__c> subscriptionsOrdersOnRejectedAA =
            subscriptionOrderSelector.getSubscriptionOrdersByAssignmentAgreement(rejectedAAIds);
        for (Subscription_Order__c subscriptionOrder : subscriptionsOrdersOnRejectedAA) {
            subscriptionOrder.Client_Assignment_Agreement__c = null;
        }
        update subscriptionsOrdersOnRejectedAA;
    }

    @TestVisible
    private List<Subscription_Order__c> setInvoiceDateOnSubscriptionOrders(Set<Id> invoicedAAIds, Map<Id, Contract> assignmentAgreementMap) {
        List<Subscription_Order__c> subscriptionOrdersToUpdate = subscriptionOrderSelector.getSubscriptionOrdersByAssignmentAgreement(invoicedAAIds);
        for (Subscription_Order__c so : subscriptionOrdersToUpdate) {
            so.Invoice_Date__c = assignmentAgreementMap.get(so.Client_Assignment_Agreement__c).Date_Invoiced__c;
        }
        return subscriptionOrdersToUpdate;
    }

    private List<Shared_Solar_System__c> populateFirstCustomerAssignmentDate(Set<Id> contractIds) {
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

    private static List<Subscription_Order__c> getSOsToUpdateFromContracts(List<Subscription_Order__c> approvedSubscriptionOrdersByContract, Map<Id, Id> contractsToAssignmentAgreementMap) {
        List<Subscription_Order__c> sosWithUpdatedAssignmentAgreements = new List<Subscription_Order__c>();
        for (Subscription_Order__c so : approvedSubscriptionOrdersByContract) {
            Id clientAssignmentAgreementId =
                contractsToAssignmentAgreementMap.get(so.Utility_Account_Subscription__r.Opportunity__r.ContractId);
            so.Client_Assignment_Agreement__c = clientAssignmentAgreementId;
            sosWithUpdatedAssignmentAgreements.add(so);
        }
        return sosWithUpdatedAssignmentAgreements;
    }

    /**
     * @description: User Defined Type used by the Assign Customers to Client Agreement Flow to related Subscription Orders
     * with Assignment Agreements
     */
    public with sharing class ContractAssignmentBundle {
        @InvocableVariable
        public List<Contract> contracts;

        @InvocableVariable
        public Date cutoffDate;
    }
}