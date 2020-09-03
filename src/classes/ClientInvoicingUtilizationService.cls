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

    private Contract_Fee_Detail__c getCfdForProductionDetail(MultiMap cfdsByContract, Transfer_Part__c productionDetail) {
        List<Contract_Fee_Detail__c> contractFeeDetails = new List<Contract_Fee_Detail__c>();
        CollectionUtil.toTypedList(cfdsByContract.getValues(productionDetail.Production__r.Shared_Solar_System__r.Client_Management_Contract__c), contractFeeDetails);
        if (contractFeeDetails.size() != 1) {
            Logger.logLater(
                'ClientInvoicingUtilizationService',
                'createMemosForUtilizationAdjustments',
                'Skipping Production Detail because of unexpected contract fee details : ' + productionDetail.Id + '\n' + contractFeeDetails,
                Logger.ERROR
            );
            return null;
        }
        Contract_Fee_Detail__c cfd = contractFeeDetails[0];
        return cfd;
    }

    @TestVisible
    private class UtilizationFeeInput {
        private Decimal changeInUtilization;
        private String utilizationAdjustmentType;
        private Decimal managementFee;
        private String managementFeeUnits;
        private Decimal monthlyManagementFeeDollars;
        private Decimal utilizationAdjustmentMultiplier;
        private Decimal utilizationAdjustmentAmount;
        private Decimal utilizationAdjustmentFloor;
        private Decimal floorDollars;
        private Decimal servicedCapacity;
        private Id contractFeeDetailId;
        private Id productionDetailId;
        private Id sharedSolarSystemId;
        private String sharedSolarSystemName;
        private Decimal utilizationFee;
        private Date billDate;

        @TestVisible
        private UtilizationFeeInput(Contract_Fee_Detail__c cfd, Transfer_Part__c productionDetail) {
            changeInUtilization = productionDetail.Change_in_Utilization__c/100;
            utilizationAdjustmentType = cfd.Utilization_Adjustment_Type__c;
            managementFee = cfd.Fee__c;
            managementFeeUnits = cfd.Fee_Unit__c;
            utilizationAdjustmentMultiplier = cfd.Utilization_Adjustment_Multiplier__c; // a true multiplier, not a percent
            utilizationAdjustmentAmount = cfd.Utilization_Adjustment_Amount__c;
            if (cfd.Utilization_Adjustment_Floor__c != null) {
                utilizationAdjustmentFloor = cfd.Utilization_Adjustment_Floor__c/100;
            }
            servicedCapacity = productionDetail.Production__r.Shared_Solar_System__r.Serviced_Capacity__c;
            contractFeeDetailId = cfd.Id;
            productionDetailId = productionDetail.Id;
            sharedSolarSystemId = productionDetail.Production__r.Shared_Solar_System__c;
            sharedSolarSystemName = productionDetail.Production__r.Shared_Solar_System__r.Name;
            billDate = productionDetail.Transfer__r.Bill_Period__r.Bill_Date__c;

            switch on managementFeeUnits {
                when 'per W' {
                    monthlyManagementFeeDollars = managementFee * 1000 * servicedCapacity / 12; //  $/W * 1000W/kW * kW = $
                } when 'per MW' {
                    monthlyManagementFeeDollars = managementFee / 1000 * servicedCapacity / 12; //  $/MW * 1MW/1000kW * kW = $
                } when 'per project' {
                    monthlyManagementFeeDollars = managementFee * servicedCapacity / 12 ;
                } when else {
                    throw new Util.BWException('UtilizationFeeInput, fee Units not recognized for CFD: ' + JSON.serialize(cfd));
                }
            }
            monthlyManagementFeeDollars = monthlyManagementFeeDollars.setScale(2);
            if (utilizationAdjustmentFloor != null) {
                floorDollars = -(utilizationAdjustmentFloor * monthlyManagementFeeDollars).setScale(2);
            }

            utilizationFee = getUtilizationFee().setScale(2);
        }

        @TestVisible
        private Decimal getUtilizationFee() {
            Decimal utilizationFee = 0;
            switch on utilizationAdjustmentType {
                when 'Multiplier (%)' {
                    utilizationFee = changeInUtilization * monthlyManagementFeeDollars * utilizationAdjustmentMultiplier;
                } when 'Amount ($)' {
                    // Since for every 1% in utilization change, we decrease by the utilization adjustment amount, we
                    // need to bring the changeInUtilization (e.g. .02 back up to a percent)
                    utilizationFee = changeInUtilization * 100 * utilizationAdjustmentAmount;
                } when else {
                    throw new Util.BWException('UtilizationFeeService, Utilization Adjustment Type not recognized: ' + utilizationAdjustmentType);
                }
            }
            if (utilizationAdjustmentFloor != null) {
                utilizationFee = Math.max(floorDollars, utilizationFee);
            }
            return utilizationFee;
        }

        private Client_Invoicing_Memo__c registerClientInvoicingMemo() {
            Client_Invoicing_Memo__c memo = new Client_Invoicing_Memo__c(
                Shared_Solar_System__c = sharedSolarSystemId,
                Production_Detail__c = productionDetailId,
                Contract_Fee_Detail__c = contractFeeDetailId,
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