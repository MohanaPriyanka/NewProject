/**
 * Created by peteryao on 9/6/20.
 * Tested By: ClientInvoicingUtilizationServiceTest
 */

public class ContractFeeDetail {
    public Id contractFeeDetailId;
    private String utilizationAdjustmentType;
    private Decimal managementFee;
    private String managementFeeUnits;
    private Decimal monthlyManagementFeeDollars;
    private Decimal utilizationAdjustmentMultiplier;
    private Decimal utilizationAdjustmentAmount;
    private Decimal utilizationAdjustmentFloor;
    private Decimal floorDollars;

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