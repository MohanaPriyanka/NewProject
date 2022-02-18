/**
 * Created by peteryao on 8/30/20.
 * Tested By: ClientInvoicingUtilizationServiceTest
 */

public without sharing class ClientInvoicingUtilizationService {
    private static ContractFeeDetailSelector cfdSelector = new ContractFeeDetailSelector();
    private static ProductionDetailSelector productionDetailSelector = new ProductionDetailSelector();
    @TestVisible
    private static fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
        new List<SObjectType>{Client_Invoicing_Memo__c.SObjectType}
    );

    public List<Client_Invoicing_Memo__c> createMemosForUtilizationAdjustments() {
        uow.registerWork(new Logger());
        List<Contract_Fee_Detail__c> utilizationCFDs = cfdSelector.getContractDetailsWithUtilizationAdjustment();
        MultiMap cfdsByContract = CollectionUtil.multiMapByField(utilizationCFDs, Contract_Fee_Detail__c.Contract__c);
        List<Transfer_Part__c> productionDetailsWithUtilizationChanges =
            productionDetailSelector.getRecentUtilizationChangesByContract(CollectionUtil.toIds(cfdsByContract.keySet()));

        List<Client_Invoicing_Memo__c> memosToInsert = new List<Client_Invoicing_Memo__c>();
        for (Transfer_Part__c productionDetail : productionDetailsWithUtilizationChanges) {
            if (!productionDetail.Client_Invoicing_Memos__r.isEmpty()) {
                // Skip it since we've already generated the utilization fee for this production detail
                continue;
            }
            Contract_Fee_Detail__c cfd = getCfdForProductionDetail(cfdsByContract, productionDetail);
            if (cfd == null) {
                // We already logged an error, we should skip this one too
                continue;
            }
            memosToInsert.add(new UtilizationFeeInput(cfd, productionDetail).registerClientInvoicingMemo());
        }
        uow.commitWork();
        return memosToInsert;
    }

    @TestVisible
    private Contract_Fee_Detail__c getCfdForProductionDetail(MultiMap cfdsByContract, Transfer_Part__c productionDetail) {
        List<Contract_Fee_Detail__c> contractFeeDetails = new List<Contract_Fee_Detail__c>();
        CollectionUtil.toTypedList(cfdsByContract.getValues(productionDetail.Production__r.Shared_Solar_System__r.Client_Management_Contract__c), contractFeeDetails);
        Contract_Fee_Detail__c cfd;
        for (Contract_Fee_Detail__c contractFeeDetail : contractFeeDetails) {
            if (contractFeeDetail.Shared_Solar_System__c == null && cfd == null) {
                cfd = contractFeeDetail;
            } else if (contractFeeDetail.Shared_Solar_System__c == productionDetail.Production__r.Shared_Solar_System__c) {
                cfd = contractFeeDetail;
            }
        }
        if (cfd == null) {
            Logger.logLater(
                'ClientInvoicingUtilizationService',
                'getCfdForProductionDetail',
                'Skipping Production Detail because we there were no contract fee details : ' + productionDetail.Id + '\n' + contractFeeDetails,
                Logger.ERROR
            );
        }
        return cfd;
    }

    @TestVisible
    private class UtilizationFeeInput {
        private Id productionDetailId;
        private Id sharedSolarSystemId;
        private Decimal servicedCapacity;
        private String sharedSolarSystemName;
        private Decimal changeInUtilization;
        @TestVisible
        private Decimal utilizationFee;
        private Date billDate;
        private ContractFeeDetail contractFeeDetail;

        @TestVisible
        private UtilizationFeeInput(Contract_Fee_Detail__c cfd, Transfer_Part__c productionDetail) {
            changeInUtilization = productionDetail.Change_in_Utilization__c/100;
            servicedCapacity = productionDetail.Production__r.Shared_Solar_System__r.Serviced_Capacity__c;
            productionDetailId = productionDetail.Id;
            sharedSolarSystemId = productionDetail.Production__r.Shared_Solar_System__c;
            sharedSolarSystemName = productionDetail.Production__r.Shared_Solar_System__r.Name;
            billDate = productionDetail.Transfer__r.Bill_Period__r.Bill_Date__c;
            this.contractFeeDetail = new ContractFeeDetail(cfd, servicedCapacity);

            utilizationFee = contractFeeDetail.getUtilizationFee(changeInUtilization).setScale(2);
        }

        private Client_Invoicing_Memo__c registerClientInvoicingMemo() {
            Client_Invoicing_Memo__c memo = new Client_Invoicing_Memo__c(
                Shared_Solar_System__c = sharedSolarSystemId,
                Production_Detail__c = productionDetailId,
                Contract_Fee_Detail__c = contractFeeDetail.contractFeeDetailId,
                Amount__c = utilizationFee,
                Type__c = 'Utilization Adjustment to Management Fee',
                Effective_Date__c = billDate,
                Details__c = JSON.serializePretty(this)
            );
            uow.registerNew(memo);
            return memo;
        }
    }
}