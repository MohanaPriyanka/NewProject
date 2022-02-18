/**
 * Created by peteryao on 9/6/20.
 * Tested By: ClientInvoicingUtilizationServiceTest, ClientInvoicingFeeAssignmentServiceTest, ClientInvoicingFeeWaiveServiceTest
 */

public class ContractFeeDetail extends FeeQualification {
    public Id contractFeeDetailId;
    private String utilizationAdjustmentType;
    private Decimal managementFee;
    private String managementFeeUnits;
    private Decimal monthlyManagementFeeDollars;
    private Decimal utilizationAdjustmentMultiplier;
    private Decimal utilizationAdjustmentAmount;
    private Decimal utilizationAdjustmentFloor;
    private Decimal floorDollars;

    @SuppressWarnings('PMD.EmptyStatementBlock')
    @TestVisible
    private ContractFeeDetail() {
    }

    public ContractFeeDetail(Contract_Fee_Detail__c feeDetail) {
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

    public ContractFeeDetail(Contract_Fee_Detail__c cfd, Decimal servicedCapacity) {
        this.contractFeeDetailId = cfd.Id;
        this.utilizationAdjustmentType = cfd.Utilization_Adjustment_Type__c;
        this.managementFee = cfd.Fee__c;
        this.managementFeeUnits = cfd.Fee_Unit__c;
        this.utilizationAdjustmentMultiplier = cfd.Utilization_Adjustment_Multiplier__c; // a true multiplier, not a percent
        this.utilizationAdjustmentAmount = cfd.Utilization_Adjustment_Amount__c;
        if (cfd.Utilization_Adjustment_Floor__c != null) {
            this.utilizationAdjustmentFloor = cfd.Utilization_Adjustment_Floor__c/100;
        }
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
    }

    public Boolean matches(SubscriptionOrder so) {
        return (customerGroupMatches(so) &&
            customerSubGroupMatches(so) &&
            acqChannelMatches(so) &&
            anchorQualifierMatches(so) &&
            acquisitionTypeMatches(so) &&
            sssMatches(so)
        );
    }

    private Boolean acquisitionTypeMatches(SubscriptionOrder so) {
        return (so.acquisition && this.acquisition ||
            so.reacquisition && this.reacquisition
        );
    }

    private Boolean customerGroupMatches(SubscriptionOrder so) {
        return (so.anchor && this.anchor ||
            so.residential && this.residential ||
            so.nonResidential && this.nonResidential
        );
    }

    private Boolean customerSubGroupMatches(SubscriptionOrder so) {
        return (so.publicOfftake && this.publicOfftake ||
            so.notPublicOfftake && this.notPublicOfftake);
    }

    private Boolean anchorQualifierMatches(SubscriptionOrder so) {
        return (!so.anchor ||
            (so.investmentGradeAnchor && this.investmentGradeAnchor ||
                so.notInvestmentGradeAnchor && this.notInvestmentGradeAnchor)
        );
    }

    private Boolean acqChannelMatches(SubscriptionOrder so) {
        return (so.closedByBCS == this.closedByBCS &&
            (so.bcsAcquired && this.bcsAcquired ||
                so.notBCSAcquired && this.notBCSAcquired)
        );
    }

    private Boolean sssMatches(SubscriptionOrder so) {
        return (so.sharedSolarSystemId == this.sharedSolarSystemId ||
            this.sharedSolarSystemId == null);
    }

    public Decimal getUtilizationFee(Decimal changeInUtilization) {
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
}