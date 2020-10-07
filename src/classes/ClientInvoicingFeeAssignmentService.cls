/*
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

    private virtual class FeeQualification {
        private Boolean acquisition;
        private Boolean reacquisition;
        private Boolean bcsAcquired;
        private Boolean notBCSAcquired;
        private Boolean closedByBCS;
        private Boolean anchor;
        private Boolean publicOfftake;
        private Boolean residential;
        private Boolean nonResidential;
        private Boolean investmentGradeAnchor;
        private Boolean notInvestmentGradeAnchor;
        private Boolean downsizing;
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

        private Boolean matches(ContractFeeDetail feeDetail){
            return (this.customerGroupMatches(feeDetail) &&
                this.acqChannelMatches(feeDetail) &&
                this.anchorQualifierMatches(feeDetail) &&
                this.acquisitionTypeMatches(feeDetail)
            );
        }

        private Boolean acquisitionTypeMatches(ContractFeeDetail feeDetail){
            return (this.acquisition && feeDetail.acquisition ||
                this.reacquisition && feeDetail.reacquisition
            );
        }

        private Boolean customerGroupMatches(ContractFeeDetail feeDetail){
            return (this.anchor && feeDetail.anchor ||
                this.publicOfftake && feeDetail.publicOfftake ||
                this.residential && feeDetail.residential ||
                this.nonResidential && feeDetail.nonResidential
            );
        }

        private Boolean anchorQualifierMatches(ContractFeeDetail feeDetail){
            return (!this.anchor ||
                    (this.investmentGradeAnchor && feeDetail.investmentGradeAnchor ||
                    this.notInvestmentGradeAnchor && feeDetail.notInvestmentGradeAnchor)
            );
        }

        private Boolean acqChannelMatches(ContractFeeDetail feeDetail){
            return (this.closedByBCS == feeDetail.closedByBCS &&
                    (this.bcsAcquired && feeDetail.bcsAcquired ||
                this.notBCSAcquired && feeDetail.notBCSAcquired)
            );
        }
    }

    private class ContractFeeDetail extends FeeQualification {
        private ContractFeeDetail(Contract_Fee_Detail__c feeDetail) {
            this.recordId = feeDetail.Id;
            this.contractIds = new List<Id>{feeDetail.Contract__c};
            this.closedByBCS = feeDetail.Acquisition_Channels_Closed_by_BCS__c;
            this.bcsAcquired = feeDetail.Acquisition_Channels_BCS_Acquired__c;
            this.notBCSAcquired = feeDetail.Acquisition_Channels_Non_BCS_Acquired__c;
            this.anchor = feeDetail.Acquisition_Cust_Group_Anchor__c;
            this.publicOfftake = feeDetail.Acquisition_Cust_Group_Public_Offtake__c;
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

    @Future
    public static void setSubOrderContractFeeDetailInFuture(Set<Id> subscriptionOrderIds){
        ClientInvoicingFeeAssignmentService feeJob = new ClientInvoicingFeeAssignmentService();
        feeJob.setSubOrderContractFeeDetail(subscriptionOrderIds);
    }

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
     * Registers a Subscription Order with a CFD update with this service's UOW.
     * @param subscriptionOrder The Subscription Order to get assigned a Contract Fee Detail
     * @param contractToFeeDetailMap A MultiMap of Contract Ids to CFDs, to be used to find potential CFDs for that SO
     *
     * @return A Subscription Order with a potentially populated CFD
     */
    @TestVisible
    private Subscription_Order__c matchSubscriptionOrderToFee(SubscriptionOrder subscriptionOrder, MultiMap contractToFeeDetailMap) {
        List<ContractFeeDetail> contractFeeDetails = getContractFeeDetailsFromContracts(subscriptionOrder, contractToFeeDetailMap);
        Subscription_Order__c orderToUpdate;
        MultiMap multiMapForDuplicateCFDCheck = MultiMap.newListInstance();
        for (ContractFeeDetail cfd : contractFeeDetails) {
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
     * Initializes or updates the subscriptionOrderSObj with the matching CFD, honoring the Shared Solar System override on the CFD.
     * @param subscriptionOrderSObj The Subscription Order SObject used to update the SO with a CFD.
     * @param subscriptionOrder The apex class that represents the Subscription Order SObject to be compared to the CFD
     * @param cfd The apex class that represents the Contract Fee Detail SObject to be compared to the SO
     * @param multiMapForDuplicateCFDCheck A MultiMap used to report if there are duplicate CFDs (with SSS specifications and without)
     * @returns The subscriptionOrderSObj, which might be initialized to a new SO.
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
        } else {
            // The feeDetail must have a null or not matching SSS. Because there's already a CFD assigned to the SO (either a SSS
            // specific one or a duplicate), we'll skip assigning this.
        }
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

    public Decimal getCancellationFee(Subscription_Order__c order){
        // Returns the upsizing reacquisition fee is relevant for this customer type
        // (ie, the fee at which a customer will be replaced)
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