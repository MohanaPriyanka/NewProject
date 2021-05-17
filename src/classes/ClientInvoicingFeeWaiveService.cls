/*
Tested By: ClientInvoicingFeeWaiveServiceTest
 */
public without sharing class ClientInvoicingFeeWaiveService {
    @TestVisible private static ClientInvoicingMemoSelector clientInvoicingMemoSelector = new ClientInvoicingMemoSelector();
    @TestVisible private static SubscriptionOrderSelector subscriptionOrderSelector = new SubscriptionOrderSelector();
    @TestVisible private MultiMap sssIdToTotalWaivedkWMap;
    @TestVisible private Map<Id,Decimal> uasToAssignedCapacityMap;

    @TestVisible
    private fflib_SObjectUnitOfWork uow;

    public void waiveFeesIfNecessary(List<Subscription_Order__c> subOrders, fflib_SObjectUnitOfWork uowParam) {
        uow = uowParam;
        setFeesToWaive(subOrders);
    }

    public void setFeesToWaive(List<Subscription_Order__c> subOrders) {
        deleteExistingCIMs(subOrders);
        queryData(subOrders);
        for (Subscription_Order__c order : subOrders) {
            if (order.Contract_Fee_Detail__r.Acquisition_Type_Reacquisition__c &&
                order.Client_Invoicing_Fee__c != null &&
                order.Client_Invoicing_Fee__c != 0) {
                waiveFeeBasedOnDate(order);
            }
        }
    }

    private void deleteExistingCIMs(List<Subscription_Order__c> subOrders) {
        for (Subscription_Order__c so : subOrders) {
            for (Client_Invoicing_Memo__c cim : so.Client_Invoicing_Memos__r) {
                if (cim.Invoice_Line_Item__c == null) {
                    uow.registerDeleted(cim);
                } else {
                    Logger.logLater('ClientInvoicingFeeWaiveService', 'deleteExistingCIMs', 'Potentially duplicate cim on SO: ' + so.Id, Logger.ERROR);
                }
            }
        }
    }

    private void queryData(List<Subscription_Order__c> subOrders) {
        Set<Id> sssIdsBeingWaivedToMaxPercent = new Set<Id>();
        Set<Id> uasIds = new Set<Id>();
        Set<Id> sssIdsRequiringProjectContracts = new Set<Id>();

        for (Subscription_Order__c order : subOrders) {
            if (order.Contract_Fee_Detail__r.Acquisition_Type_Reacquisition__c) {
                uasIds.add(order.Utility_Account_Subscription__c);
            }
            if (order.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Max_Project__c != null) {
                sssIdsBeingWaivedToMaxPercent.add(order.Utility_Account_Subscription__r.Shared_Solar_System__c);
            }
            if (order.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Project_Date__c == 'Project Contract: Effective Date') {
                sssIdsRequiringProjectContracts.add(order.Utility_Account_Subscription__r.Shared_Solar_System__c);
            }
        }

        sssIdToTotalWaivedkWMap = clientInvoicingMemoSelector.getWaivedFeesBySSS(sssIdsBeingWaivedToMaxPercent);
        uasToAssignedCapacityMap = subscriptionOrderSelector.getSubscriptionOrdersAssignedToClient(uasIds);
        ContractRepository.initFromSharedSolarSystems(sssIdsRequiringProjectContracts);
    }

    /**
     * @description If appropriate, registers a new Client Invoicing Memo with the service's Unit of Work to waive an acquisition fee.
     * Assumes the subscription order is associated with a Reacquisition CFD.
     * @param order The subscription order to evaluate for a waived reacquisition fee
     *
     * @return The new Client Invoicing Memo that was registered with the service's Unit of Work
     */
    @TestVisible
    private Client_Invoicing_Memo__c waiveFeeBasedOnDate(Subscription_Order__c order) {
        SubscriptionOrder subscriptionOrder = new SubscriptionOrder(order);

        Date milestoneDate = subscriptionOrder.getMilestoneDate();
        if (milestoneDate == null) {
            return null;
        }

        return subscriptionOrder.registerClientInvoicingMemo(uow, uasToAssignedCapacityMap, sssIdToTotalWaivedkWMap);
    }
}