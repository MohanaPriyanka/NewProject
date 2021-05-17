/**
 * Created by peteryao on 6/17/20.
 * Tested By: CustomerAssignmentServiceTest
 */

public without sharing class CustomerAssignmentService {
    @TestVisible private static SubscriptionOrderSelector subscriptionOrderSelector = new SubscriptionOrderSelector();
    @TestVisible private static OpportunitiesSelector opportunitiesSelector = new OpportunitiesSelector();
    @TestVisible private static FeatureService featureService = new FeatureService();
    @TestVisible private static ContractSelector contractSelector = new ContractSelector();
    @TestVisible private static SharedSolarSystemsSelector sssSelector = new SharedSolarSystemsSelector();
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
        Map<Id,Contract> contractMap = new Map<Id, Contract>();
        for (Contract aa : newMap.values()) {
            if (aa.RecordTypeId == aaTypeId && (aa.CompanySignedDate != null && oldMap.get(aa.Id).CompanySignedDate == null)) {
                signedAAIds.add(aa.Id);
                contractMap.put(aa.Id, aa);
            }
        }

        if (signedAAIds.size() > 0 ) {
            List<Shared_Solar_System__c> sssList = populateFirstCustomerAssignmentDate(signedAAIds);
            Util.updateSObjs(sssList);
            // String emailTemplateName = 'Project Assignment (Hybrid MA Product)';
            // sendDisclosureFormEmail(contractMap, emailTemplateName);
        }
    }

    public static void sendDisclosureFormEmail(Map<Id,Contract> contractMap, String emailTemplateName){
        for(Contract aa : contractMap.values()){
            Set<Id> contractIds = new Set<Id>();
            contractIds.add(aa.Id);
            
            List<Contact> contactList = ContactSelector.selectSendBillsContactByContract(contractIds);
            Shared_Solar_System__c sss = sssSelector.getSSSForContract(aa.Id);
            List<FlowMap> emailVals = getProjectAssignmentTemplateValues(sss);
            InvocableMessagingService.EmailTemplateSendInfo sendObj = new InvocableMessagingService.EmailTemplateSendInfo(emailTemplateName, contactList, emailVals, true);
            List<InvocableMessagingService.EmailTemplateSendInfo> emailInfo = new List<InvocableMessagingService.EmailTemplateSendInfo>();
            emailInfo.add(sendObj);
            InvocableMessagingService.sendEmailTemplate(emailInfo);
        }
    }
    
    public static List<FlowMap> getProjectAssignmentTemplateValues(Shared_Solar_System__c sss){
        List<FlowMap> returnList = new List<FlowMap>();
        returnList.add(new FlowMap('%%SSSName%%', sss.Name));
        returnList.add(new FlowMap('%%SSSAddress%%', sss.Address__c));
        returnList.add(new FlowMap('%%SSSCity%%', sss.City__c));
        returnList.add(new FlowMap('%%SSSState%%', sss.State__c));
        returnList.add(new FlowMap('%%SSSZip%%', sss.Zip_Code__c));
        returnList.add(new FlowMap('%%SSSKwDC%%', sss.Total_System_Size_kWh_DC__c.toPlainString()));
        returnList.add(new FlowMap('%%SSSHomeOffset%%', sss.Home_Electricity_Offset__c.toPlainString()));
        return returnList;
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

        ClientInvoicingFeeAssignmentService assignmentService =
            new ClientInvoicingFeeAssignmentService(CollectionUtil.getIdSet(sosWithUpdatedAssignmentAgreements));
        assignmentService.setSubOrderContractFeeDetail();
        Logger.logNow('CustomerAssignmentService', 'assignSOsAssignmentAgreement', 'Check limits', Logger.FINE);
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
     * @description Searches for related Contracts that are in need of a Project Specific Addendum (sent to MA customers
     * after they have been assigned) after a Allocation Schedule has been created
     * @param uasList List of Subscriptions from an Allocation Schedule
     * @return List of Contract
     */
    public List<Contract> generateAddendumsFromSubscriptions(List<Utility_Account_Subscription__c> uasList) {
        Set<Id> contractIds = new Set<Id>();
        for (Utility_Account_Subscription__c uas : uasList) {
            contractIds.add(uas.Opportunity__r.ContractId);
        }

        List<Contract> contractsToUpdate = contractSelector.getCustomerContractsForAddendum(contractIds);
        for (Contract contract : contractsToUpdate) {
            contract.Generate_Addendum__c = true;
            contract.Customer_Signature_Date_Time__c = System.now();
        }

       return contractsToUpdate;
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