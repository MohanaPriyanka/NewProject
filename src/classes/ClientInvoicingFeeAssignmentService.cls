/**
  @description Assigns Contract Fee Details to a Subscription Order, and generates Client Invoicing Memos, if necessary
  Tested By: ClientInvoicingFeeAssignmentServiceTest, ClientInvoicingFeeWaiveServiceTest
 */
public without sharing class ClientInvoicingFeeAssignmentService {
    @TestVisible
    private static ContractFeeDetailSelector contractFeeDetailSelector = new ContractFeeDetailSelector();
    @TestVisible
    private static SubscriptionOrderSelector subscripOrderSelector = new SubscriptionOrderSelector();

    private MultiMap contractToFeeDetailMap;
    @TestVisible
    private fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
        new List<SObjectType> {
            Subscription_Order__c.SObjectType
        }
    );

    @TestVisible
    private virtual class FeeQualification {
        @TestVisible
        private Boolean acquisition;
        @TestVisible
        private Boolean reacquisition;
        @TestVisible
        private Boolean bcsAcquired;
        @TestVisible
        private Boolean notBCSAcquired;
        @TestVisible
        private Boolean closedByBCS;
        @TestVisible
        private Boolean anchor;
        @TestVisible
        private Boolean publicOfftake;
        @TestVisible
        private Boolean notPublicOfftake;
        @TestVisible
        private Boolean residential;
        @TestVisible
        private Boolean nonResidential;
        @TestVisible
        private Boolean investmentGradeAnchor;
        @TestVisible
        private Boolean notInvestmentGradeAnchor;
        @TestVisible
        private Boolean downsizing;
        @TestVisible
        private Boolean upsizing;
        private List<Id> contractIds;
        private Id recordId;
        private Decimal amount;
        @TestVisible
        private Id sharedSolarSystemId;
    }

    @TestVisible
    private class SubscriptionOrder extends FeeQualification {
        private Id contractFeeDetailId;
        @SuppressWarnings('PMD.EmptyStatementBlock')
        @TestVisible
        private SubscriptionOrder() {
        }
        @TestVisible
        private SubscriptionOrder(Subscription_Order__c subOrder) {
            String partnerType = subOrder.Utility_Account_Subscription__r.Opportunity__r.Partner_tag_lookup__r.Account__r.RecordType.Name;
            Date reacqStartDate = subOrder.Utility_Account_Subscription__r.Shared_Solar_System__r.Reacquisition_Start_Date__c;
            List<Id> contractIds = new List<Id>{
                subOrder.Utility_Account_Subscription__r.Shared_Solar_System__r.Client_Acquisition_Contract__c,
                subOrder.Utility_Account_Subscription__r.Shared_Solar_System__r.Client_Management_Contract__c
            };
            this.recordId = subOrder.Id;
            this.contractIds = contractIds;
            this.closedByBCS = subOrder.Utility_Account_Subscription__r.Opportunity__r.Acquired_By_Client_Closed_By_BlueWave__c;
            this.bcsAcquired = partnerType != 'Client Account';
            this.notBCSAcquired = partnerType == 'Client Account';
            this.anchor = subOrder.Utility_Account_Subscription__r.Opportunity__r.Customer_Group__c == 'Anchor';
            this.publicOfftake = subOrder.Utility_Account_Subscription__r.Opportunity__r.Customer_Sub_Group__c == 'Public Offtake';
            this.notPublicOfftake = !publicOfftake;
            this.residential = subOrder.Utility_Account_Subscription__r.Opportunity__r.Customer_Group__c == 'Residential';
            this.nonResidential = subOrder.Utility_Account_Subscription__r.Opportunity__r.Customer_Group__c == 'Non-Residential';
            this.investmentGradeAnchor = subOrder.Utility_Account_Subscription__r.Opportunity__r.Underwriting_Criteria__c == 'Investment-Grade';
            this.notInvestmentGradeAnchor = !investmentGradeAnchor;
            this.downsizing = subOrder.Approved_Change_in_Subscription__c < 0;
            this.upsizing = subOrder.Approved_Change_in_Subscription__c >= 0;
            this.acquisition = reacqStartDate == null || reacqStartDate > subOrder.Effective_Date__c;
            this.reacquisition = !acquisition;
            this.contractFeeDetailId = subOrder.Contract_Fee_Detail__c;
            this.sharedSolarSystemId = subOrder.Utility_Account_Subscription__r.Shared_Solar_System__c;
        }

        @TestVisible
        private Boolean matches(ClientInvoicingFeeAssignmentService.ContractFeeDetail feeDetail){
            return (this.customerGroupMatches(feeDetail) &&
                this.customerSubGroupMatches(feeDetail) &&
                this.acqChannelMatches(feeDetail) &&
                this.anchorQualifierMatches(feeDetail) &&
                this.acquisitionTypeMatches(feeDetail) &&
                this.sssMatches(feeDetail)
            );
        }

        private Boolean acquisitionTypeMatches(ClientInvoicingFeeAssignmentService.ContractFeeDetail feeDetail){
            return (this.acquisition && feeDetail.acquisition ||
                this.reacquisition && feeDetail.reacquisition
            );
        }

        private Boolean customerGroupMatches(ClientInvoicingFeeAssignmentService.ContractFeeDetail feeDetail){
            return (this.anchor && feeDetail.anchor ||
                this.residential && feeDetail.residential ||
                this.nonResidential && feeDetail.nonResidential
            );
        }

        private Boolean customerSubGroupMatches(ClientInvoicingFeeAssignmentService.ContractFeeDetail feeDetail) {
            return (this.publicOfftake && feeDetail.publicOfftake ||
                this.notPublicOfftake && feeDetail.notPublicOfftake);
        }

        private Boolean anchorQualifierMatches(ClientInvoicingFeeAssignmentService.ContractFeeDetail feeDetail) {
            return (!this.anchor ||
                (this.investmentGradeAnchor && feeDetail.investmentGradeAnchor ||
                    this.notInvestmentGradeAnchor && feeDetail.notInvestmentGradeAnchor)
            );
        }

        private Boolean acqChannelMatches(ClientInvoicingFeeAssignmentService.ContractFeeDetail feeDetail) {
            return (this.closedByBCS == feeDetail.closedByBCS &&
                (this.bcsAcquired && feeDetail.bcsAcquired ||
                    this.notBCSAcquired && feeDetail.notBCSAcquired)
            );
        }

        private Boolean sssMatches(ClientInvoicingFeeAssignmentService.ContractFeeDetail feeDetail) {
            return (this.sharedSolarSystemId == feeDetail.sharedSolarSystemId ||
                feeDetail.sharedSolarSystemId == null);
        }
    }

    @TestVisible
    private class ContractFeeDetail extends FeeQualification {
        @SuppressWarnings('PMD.EmptyStatementBlock')
        @TestVisible
        private ContractFeeDetail() {
        }
        private ContractFeeDetail(Contract_Fee_Detail__c feeDetail) {
            this.recordId = feeDetail.Id;
            this.contractIds = new List<Id>{feeDetail.Contract__c};
            this.closedByBCS = feeDetail.Acquisition_Channels_Closed_by_BCS__c;
            this.bcsAcquired = feeDetail.Acquisition_Channels_BCS_Acquired__c;
            this.notBCSAcquired = feeDetail.Acquisition_Channels_Non_BCS_Acquired__c;
            this.anchor = feeDetail.Acquisition_Cust_Group_Anchor__c;
            this.publicOfftake = feeDetail.Acquisition_Cust_Group_Public_Offtake__c;
            this.notPublicOfftake = feeDetail.Acquisition_Cust_Group_Not_Specified__c;
            this.residential = feeDetail.Acquisition_Cust_Group_Residential__c;
            this.nonResidential = feeDetail.Acquisition_Cust_Group_Non_Residential__c;
            this.investmentGradeAnchor = feeDetail.Acq_Anchor_Qualif_Investment_Grade__c;
            this.notInvestmentGradeAnchor = feeDetail.Acq_Anchor_Qualif_Not_Investment_Grade__c;
            this.downsizing = feeDetail.Acquisition_Sizing_Type_Downsizing__c;
            this.upsizing = feeDetail.Acquisition_Sizing_Type_Upsizing__c;
            this.acquisition = feeDetail.Acquisition_Type_Acquisition__c;
            this.reacquisition = feeDetail.Acquisition_Type_Reacquisition__c;
            this.amount = feeDetail.Fee__c;
            this.sharedSolarSystemId = feeDetail.Shared_Solar_System__c;
        }
    }

    /**
     * @description Future method to assign CFDs and generate CIMs outside of the SO approval transaction
     * @param subscriptionOrderIds Set of Subscription Order Ids to assign
     */
    @Future
    public static void setSubOrderContractFeeDetailInFuture(Set<Id> subscriptionOrderIds){
        ClientInvoicingFeeAssignmentService feeJob = new ClientInvoicingFeeAssignmentService();
        feeJob.setSubOrderContractFeeDetail(subscriptionOrderIds);
    }

    /**
     * @description Instance method to assign CFDs and generate CIMs for use in anonymous apex
     * @param subscriptionOrderIds Set of Subscription Order Ids to assign
     */
    public void setSubOrderContractFeeDetail(Set<Id> subscriptionOrderIds){
        try {
            List<Subscription_Order__c> queriedSOs = subscripOrderSelector.selectByIds(subscriptionOrderIds);
            setSubscriptionOrderAcquisitionFee(queriedSOs);
            uow.commitWork();
            Logger.flushLogs();

            uow = new fflib_SObjectUnitOfWork(new List<SObjectType> {Client_Invoicing_Memo__c.SObjectType});

            List<Subscription_Order__c> ordersAfterFeesAreSet = subscripOrderSelector.selectByIds(subscriptionOrderIds);
            ClientInvoicingFeeWaiveService waiveService = new ClientInvoicingFeeWaiveService(this);
            waiveService.waiveFeesIfNecessary(ordersAfterFeesAreSet, uow);
            uow.commitWork();
            Logger.flushLogs();
        } catch (Exception excep){
            Logger.logNow('ClientInvoicingFeeAssignmentService', 'setSubOrderContractFeeDetail', excep, JSON.serialize(subscriptionOrderIds), 'ERROR');
        }
    }

    /**
     * @description Finds a matching CFD for each Subscription Order and registers the SO for update
     * @param subOrders List of Subscription Orders to get assigned to a CFD
     */
    public void setSubscriptionOrderAcquisitionFee(List<Subscription_Order__c> subOrders){
        List<SubscriptionOrder> subOrdersAsFeeQualifications = new List<SubscriptionOrder>();
        Set<Id> contractIds = new Set<Id>();

        for (Subscription_Order__c subOrder : subOrders) {
            if (hasRequiredFieldsForAssignment(subOrder)) {
                SubscriptionOrder feeQualifier = new SubscriptionOrder(subOrder);
                subOrdersAsFeeQualifications.add(feeQualifier);
                contractIds.add(subOrder.Utility_Account_Subscription__r.Shared_Solar_System__r.Client_Acquisition_Contract__c);
                contractIds.add(subOrder.Utility_Account_Subscription__r.Shared_Solar_System__r.Client_Management_Contract__c);
            }
        }

        List<Contract_Fee_Detail__c> feeDetailList = contractFeeDetailSelector.getContractDetailFromContract(contractIds);
        contractToFeeDetailMap = convertContractFeeListToFeeDetailMap(feeDetailList);
        for (SubscriptionOrder subOrder : subOrdersAsFeeQualifications) {
            matchSubscriptionOrderToFee(subOrder, contractToFeeDetailMap);
        }
    }

    /**
     * @description Registers a Subscription Order with a CFD update with this service's UOW.
     * @param subscriptionOrder The Subscription Order to get assigned a Contract Fee Detail
     * @param contractToFeeDetailMap A MultiMap of Contract Ids to CFDs, to be used to find potential CFDs for that SO
     * @return A Subscription Order with a potentially populated CFD
     */
    @TestVisible
    private Subscription_Order__c matchSubscriptionOrderToFee(SubscriptionOrder subscriptionOrder, MultiMap contractToFeeDetailMap) {
        List<ClientInvoicingFeeAssignmentService.ContractFeeDetail> contractFeeDetails = getContractFeeDetailsFromContracts(subscriptionOrder, contractToFeeDetailMap);
        Subscription_Order__c orderToUpdate;
        MultiMap multiMapForDuplicateCFDCheck = MultiMap.newListInstance();
        for (ClientInvoicingFeeAssignmentService.ContractFeeDetail cfd : contractFeeDetails) {
            if (!subscriptionOrder.matches(cfd) || subscriptionOrder.contractFeeDetailId == cfd.recordId) {
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
        ClientInvoicingFeeAssignmentService.ContractFeeDetail cfd, MultiMap multiMapForDuplicateCFDCheck) {
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

    private List<ClientInvoicingFeeAssignmentService.ContractFeeDetail> getContractFeeDetailsFromContracts(SubscriptionOrder subOrder, MultiMap contractToFeeDetailMap) {
        List<ContractFeeDetail> contractDetails = new List<ContractFeeDetail>();
        // Max 2 contracts per Subscription Order (1 Acq, 1 Mgmt)
        for (Id contractId : subOrder.contractIds) {
            CollectionUtil.toTypedList(contractToFeeDetailMap.getValues(contractId), contractDetails);
        }
        return contractDetails;
    }

    @TestVisible
    private MultiMap convertContractFeeListToFeeDetailMap(List<Contract_Fee_Detail__c> contractFeeDetail) {
        MultiMap feeDetailMap = MultiMap.newListInstance();

        for (Contract_Fee_Detail__c feeDetail : contractFeeDetail){
            ContractFeeDetail feeQualifier = new ContractFeeDetail(feeDetail);
            feeDetailMap.putValue(feeDetail.Contract__c, feeQualifier);
        }

        return feeDetailMap;
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

    /**
     * @description Returns the upsizing reacquisition fee is relevant for this customer type (ie, the fee at which a customer will be replaced)
     * @param order The Subscription Order for which this gets the cancellation fee
     * @return Cancellation Rate for the Subscription Order
     */
    public Decimal getCancellationFee(Subscription_Order__c order){
        SubscriptionOrder subOrder = new SubscriptionOrder(order);
        subOrder.upsizing = true;
        subOrder.downsizing = false;
        subOrder.acquisition = false;
        subOrder.reacquisition = true;

        Set<Object> contractDetails = new Set<Object>();
        // Max 2 contracts per Subscription Order (1 Acq, 1 Mgmt)
        for (Id contractId : subOrder.contractIds){
            contractDetails.addAll(contractToFeeDetailMap.getValues(contractId));
        }

        for (Object feeDetailObj : contractDetails){
            ContractFeeDetail feeDetail = (ContractFeeDetail)feeDetailObj;
            if (subOrder.matches(feeDetail)) {
                return feeDetail.amount;
            }
        }
        Logger.logNow(
            'ClientInvoicingFeeAssignmentService',
            'getCancellationRate',
            'Sub Order: ' + JSON.serialize(order) + ' and contract fee details: ' + JSON.serialize(contractDetails)
        );
        throw new Util.BWException('Could not get cancellation rate for Sub Order: ' + JSON.serialize(order));
    }
}