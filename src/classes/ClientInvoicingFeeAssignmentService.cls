public without sharing class ClientInvoicingFeeAssignmentService {
    @TestVisible
    private static ContractFeeDetailSelector contractFeeDetailSelector = new ContractFeeDetailSelector();
    @TestVisible
    private static SubscriptionOrderSelector subscripOrderSelector = new SubscriptionOrderSelector();

    private virtual class FeeQualification {
        private Boolean acquisition;
        private Boolean reacquisition;
        private Boolean bcsAcquired;
        private Boolean notBCSAcquired;
        private Boolean anchor;
        private Boolean publicOfftake;
        private Boolean residential;
        private Boolean nonResidential;
        private Boolean downsizing;
        private Boolean upsizing;
        private List<Id> contractIds;
        private Id recordId;
    }

    private class SubscriptionOrder extends FeeQualification {
        private SubscriptionOrder(Subscription_Order__c subOrder) {
            String partnerType = subOrder.Utility_Account_Subscription__r.Opportunity__r.Partner_tag_lookup__r.Account__r.RecordType.Name;
            Date reacqStartDate = subOrder.Utility_Account_Subscription__r.Shared_Solar_System__r.Reacquisition_Start_Date__c;
            List<Id> contractIds = new List<Id>{
                subOrder.Utility_Account_Subscription__r.Shared_Solar_System__r.Client_Acquisition_Contract__c,
                subOrder.Utility_Account_Subscription__r.Shared_Solar_System__r.Client_Management_Contract__c
            };
            this.recordId = subOrder.Id;
            this.contractIds = contractIds;
            this.bcsAcquired = partnerType != 'Client Account';
            this.notBCSAcquired = partnerType == 'Client Account';
            this.anchor = subOrder.Utility_Account_Subscription__r.Opportunity__r.Customer_Group__c == 'Anchor';
            this.publicOfftake = subOrder.Utility_Account_Subscription__r.Opportunity__r.Customer_Group__c == 'Public Offtake';
            this.residential = subOrder.Utility_Account_Subscription__r.Opportunity__r.Customer_Group__c == 'Residential';
            this.nonResidential = subOrder.Utility_Account_Subscription__r.Opportunity__r.Customer_Group__c == 'Non-Residential';
            this.downsizing = subOrder.Approved_Change_in_Subscription__c < 0;
            this.upsizing = subOrder.Approved_Change_in_Subscription__c >= 0;
            this.acquisition = reacqStartDate == null || reacqStartDate > subOrder.Effective_Date__c;
            this.reacquisition = !acquisition;
        }

        private Boolean matches(ContractFeeDetail feeDetail){
            return (this.customerGroupMatches(feeDetail) &&
                this.acqChannelMatches(feeDetail) &&
                this.sizingMethodMatches(feeDetail) &&
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

        private Boolean acqChannelMatches(ContractFeeDetail feeDetail){
            return (this.bcsAcquired && feeDetail.bcsAcquired ||
                this.notBCSAcquired && feeDetail.notBCSAcquired
            );
        }

        private Boolean sizingMethodMatches(ContractFeeDetail feeDetail){
            return (this.upsizing && feeDetail.upsizing ||
                this.downsizing && feeDetail.downsizing
            );
        }
    }

    private class ContractFeeDetail extends FeeQualification {
        private ContractFeeDetail(Contract_Fee_Detail__c feeDetail) {
            this.recordId = feeDetail.Id;
            this.contractIds = new List<Id>{feeDetail.Contract__c};
            this.bcsAcquired = feeDetail.Acquisition_Channels_BCS_Acquired__c;
            this.notBCSAcquired = feeDetail.Acquisition_Channels_Non_BCS_Acquired__c;
            this.anchor = feeDetail.Acquisition_Cust_Group_Anchor__c;
            this.publicOfftake = feeDetail.Acquisition_Cust_Group_Public_Offtake__c;
            this.residential = feeDetail.Acquisition_Cust_Group_Residential__c;
            this.nonResidential = feeDetail.Acquisition_Cust_Group_Non_Residential__c;
            this.downsizing = feeDetail.Acquisition_Sizing_Type_Downsizing__c;
            this.upsizing = feeDetail.Acquisition_Sizing_Type_Upsizing__c;
            this.acquisition = feeDetail.Acquisition_Type_Acquisition__c;
            this.reacquisition = feeDetail.Acquisition_Type_Reacquisition__c;
        }
    }

    public fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
        new List<SObjectType> {
            Subscription_Order__c.SObjectType,
            Client_Invoicing_Memo__c.SObjectType
        }
    );

    @Future
    public static void setSubOrderContractFeeDetailInFuture(Set<Id> subscriptionOrderIds){
        ClientInvoicingFeeAssignmentService feeJob = new ClientInvoicingFeeAssignmentService();
        feeJob.setSubOrderContractFeeDetail(subscriptionOrderIds);
    }

    public void setSubOrderContractFeeDetail(Set<Id> subscriptionOrderIds){
        List<Subscription_Order__c> queriedSOs = subscripOrderSelector.selectByIds(subscriptionOrderIds);
        setSubscriptionOrderAcquisitionFee(queriedSOs);
        uow.commitWork();
        Logger.flushLogs();

        List<Subscription_Order__c> ordersAfterFeesAreSet = subscripOrderSelector.selectByIds(subscriptionOrderIds);
        ClientInvoicingFeeWaiveService waiveService = new ClientInvoicingFeeWaiveService();
        waiveService.waiveFeesIfNecessary(ordersAfterFeesAreSet, uow);
        uow.commitWork();
        Logger.flushLogs();
    }

    public void setSubscriptionOrderAcquisitionFee(List<Subscription_Order__c> subOrders){
        List<SubscriptionOrder> subOrdersAsFeeQualifications = new List<SubscriptionOrder>();
        Set<Id> contractIds = new Set<Id>();

        for (Subscription_Order__c subOrder : subOrders){
            if (hasRequiredFields(subOrder)){
                SubscriptionOrder feeQualifier = new SubscriptionOrder(subOrder);
                subOrdersAsFeeQualifications.add(feeQualifier);
                contractIds.add(subOrder.Utility_Account_Subscription__r.Shared_Solar_System__r.Client_Acquisition_Contract__c);
                contractIds.add(subOrder.Utility_Account_Subscription__r.Shared_Solar_System__r.Client_Management_Contract__c);
            }
        }

        List<Contract_Fee_Detail__c> feeDetailList = contractFeeDetailSelector.getContractDetailFromContract(contractIds);
        MultiMap contractToFeeDetailMap = convertContractFeeListToFeeDetailMap(feeDetailList);
        matchSubscriptionOrderToFee(subOrdersAsFeeQualifications,contractToFeeDetailMap);
    }

    private void matchSubscriptionOrderToFee(List<SubscriptionOrder> subscriptionOrders,
                                             MultiMap contractToFeeDetailMap){
        for (SubscriptionOrder subOrder : subscriptionOrders){
            Set<Object> contractDetails = new Set<Object>();
            // Max 2 contracts per Subscription Order (1 Acq, 1 Mgmt)
            for (Id contractId : subOrder.contractIds){
                contractDetails.addAll(contractToFeeDetailMap.getValues(contractId));
            }
            Integer matchCount = 0;
            Subscription_Order__c orderToUpdate;

            for (Object feeDetailObj : contractDetails){
                ContractFeeDetail feeDetail = (ContractFeeDetail)feeDetailObj;
                if (subOrder.matches(feeDetail)){
                    orderToUpdate = new Subscription_Order__c(
                        Id = subOrder.recordId,
                        Contract_Fee_Detail__c = feeDetail.recordId
                    );
                    matchCount += 1;
                }
            }

            if (matchCount == 1){
                uow.registerDirty(orderToUpdate);
            } else if (matchCount == 0){
                Logger.logLater('ClientInvoicingFeeAssignmentService','matchSubscriptionOrderToFee','No matches found : ' + JSON.serialize(subOrder),'INFO');
            } else {
                uow.registerDirty(orderToUpdate);
                Logger.logLater('ClientInvoicingFeeAssignmentService','matchSubscriptionOrderToFee','Multiple matches found : ' + JSON.serialize(subOrder),'INFO');
            }
        }
    }

    private MultiMap convertContractFeeListToFeeDetailMap(List<Contract_Fee_Detail__c> contractFeeDetail){
        MultiMap feeDetailMap = MultiMap.newListInstance();

        for (Contract_Fee_Detail__c feeDetail : contractFeeDetail){
            ContractFeeDetail feeQualifier = new ContractFeeDetail(feeDetail);
            feeDetailMap.putValue(feeDetail.Contract__c, feeQualifier);
        }

        return feeDetailMap;
    }

    private Boolean hasRequiredFields(Subscription_Order__c subOrder){
        if (subOrder.Utility_Account_Subscription__r.Opportunity__r.Customer_Group__c != null &&
            subOrder.Utility_Account_Subscription__r.Opportunity__r.Partner_tag_lookup__r.Account__r.RecordType.Name != null &&
            subOrder.Approved_Change_in_Subscription__c != null &&
            subOrder.Effective_Date__c != null &&
            subOrder.Utility_Account_Subscription__r.Shared_Solar_System__c != null &&
            subOrder.Utility_Account_Subscription__r.Shared_Solar_System__r.Client_Acquisition_Contract__c != null &&
            subOrder.Utility_Account_Subscription__r.Shared_Solar_System__r.Client_Management_Contract__c != null){
            return true;
        } else {
            Logger.logLater('ClientInvoicingFeeAssignmentService', 'hasRequiredFields', JSON.serialize(subOrder), 'INFO');
            return false;
        }
    }
}