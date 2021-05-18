/**
  @description Assigns Contract Fee Details to a Subscription Order, and generates Client Invoicing Memos, if necessary
  Tested By: ClientInvoicingFeeAssignmentServiceTest, ClientInvoicingFeeWaiveServiceTest
 */
public without sharing class ClientInvoicingFeeAssignmentService {
    @TestVisible private static SubscriptionOrderSelector subscriptionOrderSelector = new SubscriptionOrderSelector();
    private List<SubscriptionOrder> subOrdersAsFeeQualifications = new List<SubscriptionOrder>();
    private Set<Id> subscriptionOrderIds;
    private List<Subscription_Order__c> queriedSOs;
    @TestVisible
    private fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
        new List<SObjectType> {
            Subscription_Order__c.SObjectType
        }
    );

    public ClientInvoicingFeeAssignmentService(Set<Id> subscriptionOrderIds) {
        this.subscriptionOrderIds = subscriptionOrderIds;
        init();
    }

    public void init(Set<Id> subscriptionOrderIds) {
        this.subscriptionOrderIds = subscriptionOrderIds;
        init();
    }

    private void init() {
        queriedSOs = subscriptionOrderSelector.selectByIds(subscriptionOrderIds);
        ContractRepository.initFromSubscriptionOrders(queriedSOs);
        for (Subscription_Order__c subOrder : queriedSOs) {
            if (hasRequiredFieldsForAssignment(subOrder)) {
                SubscriptionOrder feeQualifier = new SubscriptionOrder(subOrder);
                subOrdersAsFeeQualifications.add(feeQualifier);
            }
        }
    }

    /**
     * @description Future method to assign CFDs and generate CIMs outside of the SO approval transaction
     * @param subscriptionOrderIds Set of Subscription Order Ids to assign
     */
    @Future
    public static void setSubOrderContractFeeDetailInFuture(Set<Id> subscriptionOrderIds){
        try {
            ClientInvoicingFeeAssignmentService feeJob = new ClientInvoicingFeeAssignmentService(subscriptionOrderIds);
            feeJob.setSubOrderContractFeeDetail();
        } catch (Exception e) {
            Logger.logNow('ClientInvoicingFeeAssignmentService', 'setSubOrderContractFeeDetailInFuture', e.getMessage() + '\n' + e.getStackTraceString(), Logger.ERROR);
        }
    }

    /**
     * @description Instance method to assign CFDs and generate CIMs for use in anonymous apex
     */
    public void setSubOrderContractFeeDetail() {
        try {
            setSubscriptionOrderAcquisitionFee();
            uow.commitWork();
            Logger.flushLogs();

            uow = new fflib_SObjectUnitOfWork(new List<SObjectType> {Client_Invoicing_Memo__c.SObjectType});

            List<Subscription_Order__c> ordersAfterFeesAreSet = subscriptionOrderSelector.selectByIds(subscriptionOrderIds);
            ClientInvoicingFeeWaiveService waiveService = new ClientInvoicingFeeWaiveService();
            waiveService.waiveFeesIfNecessary(ordersAfterFeesAreSet, uow);
            uow.commitWork();
            Logger.flushLogs();
        } catch (Exception e){
            Logger.logNow(
                'ClientInvoicingFeeAssignmentService',
                'setSubOrderContractFeeDetail',
                e.getMessage() + '\n' + e.getStackTraceString() + '\n' + JSON.serialize(subscriptionOrderIds),
                Logger.ERROR
            );
        }
    }

    /**
     * @description Finds a matching CFD for each Subscription Order and registers the SO for update
     */
    @TestVisible
    private void setSubscriptionOrderAcquisitionFee() {
        for (SubscriptionOrder subOrder : subOrdersAsFeeQualifications) {
            matchSubscriptionOrderToFee(subOrder);
        }
    }

    /**
     * @description Registers a Subscription Order with a CFD update with this service's UOW.
     * @param subscriptionOrder The Subscription Order to get assigned a Contract Fee Detail
     * @return A Subscription Order with a potentially populated CFD
     */
    @TestVisible
    private Subscription_Order__c matchSubscriptionOrderToFee(SubscriptionOrder subscriptionOrder) {
        List<ContractFeeDetail> contractFeeDetails = getContractFeeDetailsFromContracts(subscriptionOrder, ContractRepository.getContractToContractFeeDetails());
        Subscription_Order__c orderToUpdate;
        MultiMap multiMapForDuplicateCFDCheck = MultiMap.newListInstance();
        for (ContractFeeDetail cfd : contractFeeDetails) {
            if (!cfd.matches(subscriptionOrder) || subscriptionOrder.contractFeeDetailId == cfd.recordId) {
                continue;
            }
            orderToUpdate = handleMatchingCFD(orderToUpdate, subscriptionOrder, cfd, multiMapForDuplicateCFDCheck);
        }
        if (orderToUpdate != null) {
            uow.registerDirty(orderToUpdate);
        }
        for (Object sharedSolarSystemId : multiMapForDuplicateCFDCheck.keySet()) {
            if (multiMapForDuplicateCFDCheck.getValues(sharedSolarSystemId).size() > 1) {
                Logger.logLater(
                    'ClientInvoicingFeeAssignmentService',
                    'matchSubscriptionOrderToFee',
                    'Multiple CFDs found for SO:\n' + JSON.serialize(subscriptionOrder),
                    Logger.ERROR
                );
            }
        }
        return orderToUpdate;
    }

    /**
     * @description Initializes or updates the subscriptionOrderSObj with the matching CFD, honoring the Shared Solar System override on the CFD.
     * @param subscriptionOrderSObj The Subscription Order SObject used to update the SO with a CFD.
     * @param subscriptionOrder The apex class that represents the Subscription Order SObject to be compared to the CFD
     * @param cfd The apex class that represents the Contract Fee Detail SObject to be compared to the SO
     * @param multiMapForDuplicateCFDCheck A MultiMap used to report if there are duplicate CFDs (with SSS specifications and without)
     * @return The subscriptionOrderSObj, which might be initialized to a new SO.
     */
    private Subscription_Order__c handleMatchingCFD(Subscription_Order__c subscriptionOrderSObj, SubscriptionOrder subscriptionOrder,
        ContractFeeDetail cfd, MultiMap multiMapForDuplicateCFDCheck) {
        multiMapForDuplicateCFDCheck.putValue(cfd.sharedSolarSystemId, cfd);
        if (subscriptionOrderSObj == null) {
            // This must be the first matching CFD, so we'll assign it to the SO independent of whether there's a
            // SSS override or not.
            subscriptionOrderSObj = new Subscription_Order__c(
                Id = subscriptionOrder.recordId,
                Contract_Fee_Detail__c = cfd.recordId
            );
        } else if (cfd.sharedSolarSystemId != null && cfd.sharedSolarSystemId == subscriptionOrder.sharedSolarSystemId) {
            // There's already a CFD that matches this SO, but it could be one that didn't have a SSS override.
            // Because this CFD is SSS specific and it matches the SO's SSS, we'll use it.
            subscriptionOrderSObj.Contract_Fee_Detail__c = cfd.recordId;
        }
        // Otherwise, the feeDetail must have a null or not matching SSS. Because there's already a CFD assigned to the SO (either a SSS
        // specific one or a duplicate), we'll skip assigning this.
        return subscriptionOrderSObj;
    }

    private List<ContractFeeDetail> getContractFeeDetailsFromContracts(SubscriptionOrder subOrder, MultiMap contractToFeeDetailMap) {
        List<ContractFeeDetail> contractDetails = new List<ContractFeeDetail>();
        // Max 2 contracts per Subscription Order (1 Acq, 1 Mgmt)
        for (Id contractId : subOrder.contractIds) {
            CollectionUtil.toTypedList(contractToFeeDetailMap.getValues(contractId), contractDetails);
        }
        return contractDetails;
    }

    private Boolean hasRequiredFieldsForAssignment(Subscription_Order__c subOrder){
        if (subOrder.Utility_Account_Subscription__r.Opportunity__r.Customer_Group__c != null &&
            subOrder.Utility_Account_Subscription__r.Opportunity__r.Partner_tag_lookup__r.Account__r.RecordType.Name != null &&
            subOrder.Approved_Change_in_Subscription__c != null &&
            subOrder.Effective_Date__c != null &&
            subOrder.Utility_Account_Subscription__r.Shared_Solar_System__c != null &&
            (subOrder.Utility_Account_Subscription__r.Shared_Solar_System__r.Client_Acquisition_Contract__c != null ||
                subOrder.Utility_Account_Subscription__r.Shared_Solar_System__r.Client_Management_Contract__c != null)) {
            return true;
        } else {
            return false;
        }
    }
}