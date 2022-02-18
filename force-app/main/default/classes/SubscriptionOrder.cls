/**
 * @description Created by PeterYao on 3/12/2021.
 * Tested By: ClientInvoicingFeeAssignmentServiceTest, ClientInvoicingFeeWaiveServiceTest
 */

public without sharing class SubscriptionOrder extends FeeQualification {
    public Id contractFeeDetailId;
    public Subscription_Order__c order;
    private String milestoneDateType;
    private Date milestoneDate;
    private Map<Id,Decimal> uasToAssignedCapacityMap;
    private MultiMap sssIdToTotalWaivedkWMap;
    private fflib_SObjectUnitOfWork uow;

    public SubscriptionOrder(Subscription_Order__c subOrder) {
        String partnerType = subOrder.Utility_Account_Subscription__r.Opportunity__r.Partner_tag_lookup__r.Account__r.RecordType.Name;
        Date reacqStartDate = subOrder.Utility_Account_Subscription__r.Shared_Solar_System__r.Reacquisition_Start_Date__c;
        List<Id> contractIds =
            ContractRepository.getActiveContractsForSystem(subOrder.Utility_Account_Subscription__r.Shared_Solar_System__c, subOrder.Effective_Date__c);
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
        this.order = subOrder;
        this.milestoneDateType = subOrder.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Project_Date__c;
        this.milestoneDate = getMilestoneDate();
    }

    public Client_Invoicing_Memo__c registerClientInvoicingMemo(
        fflib_SObjectUnitOfWork uow,
        Map<Id,Decimal> uasToAssignedCapacityMap,
        MultiMap sssIdToTotalWaivedkWMap)
    {
        this.uow = uow;
        this.uasToAssignedCapacityMap = uasToAssignedCapacityMap;
        this.sssIdToTotalWaivedkWMap = sssIdToTotalWaivedkWMap;
        // Allow negative subscription orders for Customer: Assignment Date guarantees because we don't use the SO
        // amount, we use the customer size at assignment. (The fee waive is triggered by a cancelled customer
        // decreasing in size, so we want to allow negative values)
        if (milestoneDateType == 'Customer: Assignment Date' ||
            milestoneDateType == 'Project: Estimated COD or Customer: Assignment Date') {
            // Since we're giving the client a customer guarantee, for instance, if the customer cancels within a year,
            // we'll won't charge them a reacquisition fee for that customer.
            // So, we don't want to credit the client (i.e. waive the fee) for downsizing subscription orders, just the
            // order that brings the customer to 0. So if the System Change is anything but 0, we move on.
            if (order.System_Change_kW_DC_Rounded__c != 0) {
                return null;
            }
            Decimal assignmentAgreementSize = uasToAssignedCapacityMap.get(order.Utility_Account_Subscription__c);
            return registerInvoiceMemoBasedOnCustomerDate(
                order.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Max_Project__c,
                assignmentAgreementSize
            );
        } else {
            if (shouldWaiveInInitialPeriod()) {
                // We don't handle Max % of Project in the initial period right now, because that includes logic includes
                // an annual clause that is only applicable after the milestone date
                return registerInvoiceMemoBasedOnProjectDate(null);
            } else if (shouldWaiveAfterInitialPeriod()) {
                return registerInvoiceMemoBasedOnProjectDate(order.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Max_Project__c);
            }
        }
        return null;
    }

    private Client_Invoicing_Memo__c registerInvoiceMemoBasedOnCustomerDate(
        Decimal maxPercentOfProjectToWaive,
        Decimal assignmentAgreementSize)
    {
        if (shouldWaiveInInitialPeriod()) {
            // We don't handle Max % of Project in the initial period right now, because that includes logic includes an annual clause
            // that is only applicable after the milestone date
            return registerClientInvoiceMemo(-assignmentAgreementSize * 1000 * getCancellationFee());
        } else if (shouldWaiveAfterInitialPeriod()) {
            return registerInvoiceMemoUnderMaxPercent(maxPercentOfProjectToWaive, assignmentAgreementSize);
        }
        return null;
    }

    private Client_Invoicing_Memo__c registerInvoiceMemoBasedOnProjectDate(Decimal maxPercentOfProjectToWaive) {
        // Don't create a CIM if there's no invoicing fee, but per W-022613, we can create a positive CIM to charge the
        // customer for downsizing that is included in an acquisition agreement (otherwise, the client could get too much
        // of a credit)
        if (order.Client_Invoicing_Fee__c == null || order.Client_Invoicing_Fee__c == 0) {
            return null;
        }
        if (maxPercentOfProjectToWaive == null) {
            return registerClientInvoiceMemo(-order.Contract_Fee_Detail__r.Fee__c * order.Approved_Change_in_Subscription__c * 1000);
        } else {
            return registerInvoiceMemoUnderMaxPercent(maxPercentOfProjectToWaive, order.Approved_Change_in_Subscription__c);
        }
    }

    private Client_Invoicing_Memo__c registerInvoiceMemoUnderMaxPercent(Decimal maxPercentOfProjectToWaive, Decimal maxKwToWaive) {
        maxPercentOfProjectToWaive = maxPercentOfProjectToWaive / 100;
        Id sssId = order.Utility_Account_Subscription__r.Shared_Solar_System__c;
        Decimal totalSystemSize = order.Utility_Account_Subscription__r.Shared_Solar_System__r.Total_System_Size_kWh_DC__c;
        List<ClientInvoicingMemo> clientInvoicingMemosForSSS = new List<ClientInvoicingMemo>();
        CollectionUtil.toTypedList(sssIdToTotalWaivedkWMap.getValues(sssId), clientInvoicingMemosForSSS);
        Decimal kwAlreadyWaived = calculateTotalkWDCWaivedForAnnualPeriod(
            clientInvoicingMemosForSSS,
            milestoneDate,
            DateUtil.convertGmtToDate(order.Effective_Date__c)
        );
        Decimal kwLeftToWaive = Math.max((maxPercentOfProjectToWaive * totalSystemSize) - kwAlreadyWaived, 0);
        Decimal kWToWaive = Math.min(kwLeftToWaive, maxKwToWaive);
        sssIdToTotalWaivedkWMap.putValue(sssId, new ClientInvoicingMemo(sssId, order.Effective_Date__c, kWToWaive));
        return registerClientInvoiceMemo(-1 * order.Contract_Fee_Detail__r.Fee__c * (kWToWaive * 1000));
    }

    private Boolean shouldWaiveInInitialPeriod() {
        return order.Effective_Date__c < milestoneDate && order.Contract_Fee_Detail__r.Waive_Reacq_Fee_In_Initial_Period__c;
    }

    private Boolean shouldWaiveAfterInitialPeriod() {
        return order.Effective_Date__c >= milestoneDate && order.Contract_Fee_Detail__r.Waive_Reacq_Fee_After_Initial_Period__c;
    }

    /*
      This handles contract terms like: "After the first eighteen (18) months of the Term, AES shall pay BCS-CM
      $0.09/W DC as the Customer Replacement Fee only for any Customers replaced beyond the first 5% of total Customer
      capacity lost (whether by way of termination, cancellation, and/or expiration) for the Generating Facility in
       any given year, including during any extension of the Term. "

      "Any given year" is left up to interpretation, we interpret it as the we months after the initial period ends
      that the SO is in. For instance:
      Milestone Date: 4/1/2020 (e.g. COD + 18 Months)
      SO Effective Date: 5/1/2020
      The year to evaluate the total kW already waived: 4/1/2020 -> 4/1/2021

      Milestone Date: 4/1/2020 (e.g. COD + 18 Months)
      SO Effective Date: 1/1/2022
      The year to evaluate the total kW already waived: 4/1/2021 -> 3/30/2022
     */
    private Decimal calculateTotalkWDCWaivedForAnnualPeriod(
        List<ClientInvoicingMemo> waivedFees,
        Date milestoneDate,
        Date effectiveDate)
    {
        if (effectiveDate < milestoneDate) {
            return 0;
        }
        Date startDate = milestoneDate;
        Date endDate = milestoneDate.addMonths(12);
        while (true) {
            if (between(startDate, effectiveDate, endDate)) {
                break;
            }
            startDate = startDate.addMonths(12);
            endDate = endDate.addMonths(12);
        }
        Decimal totalWaivedkWDC = 0;
        for (ClientInvoicingMemo clientInvoicingMemo : waivedFees) {
            if (between(startDate, DateUtil.convertGmtToDate(clientInvoicingMemo.effectiveDate), endDate)) {
                totalWaivedkWDC += clientInvoicingMemo.approvedChangeInSubscription;
            }
        }
        return totalWaivedkWDC;
    }

    private Boolean between(Date startDate, Date effectiveDate, Date endDate) {
        return startDate <= effectiveDate && effectiveDate < endDate;
    }

    /**
     * @description Returns the upsizing reacquisition fee is relevant for this customer type (ie, the fee at which a
     * customer will be replaced)
     * @return Cancellation Rate for the Subscription Order
     */
    public Decimal getCancellationFee(){
        SubscriptionOrder subOrder = new SubscriptionOrder(order);
        // Set attributes to find the CFD that was used for reacquisition, which is the cancellation fee
        subOrder.upsizing = true;
        subOrder.downsizing = false;
        subOrder.acquisition = false;
        subOrder.reacquisition = true;

        Set<Object> contractFeeDetails = new Set<Object>();
        // Max 2 contracts per Subscription Order (1 Acq, 1 Mgmt)
        for (Id contractId : subOrder.contractIds) {
            contractFeeDetails.addAll(ContractRepository.getContractToContractFeeDetails().getValues(contractId));
        }

        for (Object feeDetailObj : contractFeeDetails) {
            ContractFeeDetail feeDetail = (ContractFeeDetail) feeDetailObj;
            if (feeDetail.matches(subOrder)) {
                return feeDetail.amount;
            }
        }
        Logger.logNow(
            'ClientInvoicingFeeAssignmentService',
            'getCancellationRate',
            'Sub Order: ' + JSON.serialize(order) + ' and contract fee details: ' + JSON.serialize(contractFeeDetails)
        );
        throw new Util.BWException('Could not get cancellation rate for Sub Order: ' + JSON.serialize(order));
    }

    private Client_Invoicing_Memo__c registerClientInvoiceMemo(Decimal amount) {
        Client_Invoicing_Memo__c memo = new Client_Invoicing_Memo__c(
            Subscription_Order__c = order.Id,
            Amount__c = amount.setScale(2, RoundingMode.HALF_UP),
            Effective_Date__c = DateUtil.convertGmtToDate(order.Effective_Date__c),
            Type__c = 'Waived Acquisition / Reacquisition Fee'
        );
        uow.registerNew(memo);
        return memo;
    }

    /**
      * @description Calculates the milestone date (if populated) for a Subscription Order.
      * @return The milestone date for this Subscription Order, or null if the milestone date has not been reached yet.
    */
    @SuppressWarnings('PMD.EmptyStatementBlock')
    public Date getMilestoneDate() {
        Date milestoneDate;

        switch on milestoneDateType {
            when 'Project Contract: Effective Date' {
                milestoneDate = ContractRepository.getProjectContractEffectiveDate(
                    order.Contract_Fee_Detail__r.Contract__c,
                    order.Utility_Account_Subscription__r.Shared_Solar_System__c,
                    DateUtil.convertGmtToDate(order.Effective_Date__c)
                );
            }
            when 'Contract: Effective Date' {
                milestoneDate = order.Contract_Fee_Detail__r.Contract__r.StartDate;
            }
            when 'Project: PTO' {
                milestoneDate = order.Utility_Account_Subscription__r.Shared_Solar_System__r.Actual_PTO_Date_MANUAL__c;
            }
            when 'Project: COD' {
                milestoneDate = order.Utility_Account_Subscription__r.Shared_Solar_System__r.Actual_COD_Date__c;
            }
            when 'Project: First Customer Bill Date' {
                milestoneDate = order.Utility_Account_Subscription__r.Shared_Solar_System__r.First_Bill_Date__c;
            }
            when 'Customer: Assignment Date' {
                milestoneDate = order.Utility_Account_Subscription__r.Opportunity__r.Contract.Assignment_Agreement__r.CustomerSignedDate;
            }
            when 'Project: Estimated COD or Customer: Assignment Date' {
                milestoneDate = DateUtil.max(
                    order.Contract_Fee_Detail__r.Waive_Reacq_Fee_Estimated_COD__c,
                    order.Utility_Account_Subscription__r.Opportunity__r.Contract.Assignment_Agreement__r.CustomerSignedDate
                );
            }
            when 'Fee not Charged', null {
                // There's no milestone date to set
            }
            when else {
                // As of June 2020, only 'Project: First Customer Assignment Date' isn't handled, since we don't have
                // a field to track that on the SSS or client, and it isn't (yet) being used in a client contract
                Logger.logLater(
                    'ClientInvoicingFeeAssignmentService',
                    'Unhandled value for Waive_Reacquisition_Fee_Project_Date__c',
                    milestoneDateType
                );
            }
        }
        Integer numberOfMonths = (Integer) order.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Number_Months__c;
        if (numberOfMonths == null || milestoneDate == null) {
            return null;
        }
        return milestoneDate.addMonths(numberOfMonths);
    }
}