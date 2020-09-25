/*
Tested By: ClientInvoicingFeeWaiveServiceTest
 */
public without sharing class ClientInvoicingFeeWaiveService {
    @TestVisible
    private static ClientInvoicingMemoSelector clientInvoicingMemoSelector = new ClientInvoicingMemoSelector();
    @TestVisible
    private static SubscriptionOrderSelector subscriptionOrderSelector = new SubscriptionOrderSelector();
    @TestVisible
    private MultiMap sssIdToTotalWaivedkWMap;
    @TestVisible
    private Map<Id,Decimal> uasToAssignedCapacityMap;
    @TestVisible
    private static ClientInvoicingFeeAssignmentService assignmentService;

    @TestVisible
    private fflib_SObjectUnitOfWork uow;

    public ClientInvoicingFeeWaiveService(ClientInvoicingFeeAssignmentService assignment) {
        assignmentService = assignment;
    }

    public void waiveFeesIfNecessary(List<Subscription_Order__c> subOrders, fflib_SObjectUnitOfWork uowParam) {
        uow = uowParam;
        setFeesToWaive(subOrders);
    }

    public void setFeesToWaive(List<Subscription_Order__c> subOrders) {
        queryData(subOrders);
        for (Subscription_Order__c order : subOrders) {
            if (order.Contract_Fee_Detail__r.Acquisition_Type_Reacquisition__c) {
                waiveFeeBasedOnDate(order);
            }
        }
    }

    private void queryData(List<Subscription_Order__c> subOrders) {
        Set<Id> sssIds = new Set<Id>();
        Set<Id> uasIds = new Set<Id>();

        for (Subscription_Order__c order : subOrders) {
            if (order.Contract_Fee_Detail__r.Acquisition_Type_Reacquisition__c) {
                uasIds.add(order.Utility_Account_Subscription__c);
            }
            if (order.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Max_Project__c != null) {
                sssIds.add(order.Utility_Account_Subscription__r.Shared_Solar_System__c);
            }
        }

        sssIdToTotalWaivedkWMap = clientInvoicingMemoSelector.getWaivedFeesBySSS(sssIds);
        uasToAssignedCapacityMap = subscriptionOrderSelector.getSubscriptionOrdersAssignedToClient(uasIds);
    }

    @TestVisible
    private Client_Invoicing_Memo__c waiveFeeBasedOnDate(Subscription_Order__c order) {
        Integer numberOfMonths = (Integer)order.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Number_Months__c;
        String sssDateType = order.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Project_Date__c;

        Date milestoneDate = getMilestoneDate(order,sssDateType);
        if (numberOfMonths == null || milestoneDate == null) {
            return null;
        }
        milestoneDate = milestoneDate.addMonths(numberOfMonths);

        /* Allow negative subscription orders for Customer: Assignment Date guarantees because we don't use the SO
           amount, we use the customer size at assignment. (The fee waive is triggered by a cancelled customer
           decreasing in size, so we want to allow negative values)
           Otherwise, there is no need to waive a negative fee.
        */

        if (sssDateType == 'Customer: Assignment Date') {
            return waiveFeeBasedOnCustomerDate(order,milestoneDate);
        } else if (order.Approved_Change_in_Subscription__c > 0) {
            return waiveFeeBasedOnProjectDateBeforeOrAfterMilestone(order,milestoneDate);
        }
        return null;
    }

    private Client_Invoicing_Memo__c waiveFeeBasedOnCustomerDate(Subscription_Order__c order, Date milestoneDate) {
        if (order.System_Change_kW_DC_Rounded__c != 0) {
            return null;
        }
        Decimal assignmentAgreementSize = uasToAssignedCapacityMap.get(order.Utility_Account_Subscription__c);
        if (order.Effective_Date__c < milestoneDate && order.Contract_Fee_Detail__r.Waive_Reacq_Fee_In_Initial_Period__c) {
            // We don't handle Max % of Project in the initial period right now, because that includes logic includes an annual clause
            // that is only applicable after the milestone date
            return createInvoiceMemoBasedOnCustomerDate(order, milestoneDate, null, assignmentAgreementSize);
        } else if (order.Effective_Date__c >= milestoneDate && order.Contract_Fee_Detail__r.Waive_Reacq_Fee_After_Initial_Period__c) {
            return createInvoiceMemoBasedOnCustomerDate(order, milestoneDate, order.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Max_Project__c, assignmentAgreementSize);
        }
        return null;
    }

    private Client_Invoicing_Memo__c createInvoiceMemoBasedOnCustomerDate(Subscription_Order__c order, Date milestoneDate, Decimal maxPercentOfProjectToWaive, Decimal assignmentAgreementSize) {
        if (maxPercentOfProjectToWaive == null) {
            return createInvoiceMemo(order, -assignmentAgreementSize * 1000 * assignmentService.getCancellationFee(order));
        } else {
            return createInvoiceMemoUnderMaxPercent(maxPercentOfProjectToWaive, assignmentAgreementSize, order, milestoneDate);
        }
    }

    private Client_Invoicing_Memo__c waiveFeeBasedOnProjectDateBeforeOrAfterMilestone(Subscription_Order__c order, Date milestoneDate) {
        if (order.Effective_Date__c < milestoneDate && order.Contract_Fee_Detail__r.Waive_Reacq_Fee_In_Initial_Period__c) {
            // We don't handle Max % of Project in the initial period right now, because that includes logic includes an annual clause
            // that is only applicable after the milestone date
            return createInvoiceMemoBasedOnProjectDate(order, milestoneDate, null);
        } else if (order.Effective_Date__c >= milestoneDate && order.Contract_Fee_Detail__r.Waive_Reacq_Fee_After_Initial_Period__c) {
            return createInvoiceMemoBasedOnProjectDate(order, milestoneDate, order.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Max_Project__c);
        }
        return null;
    }

    private Client_Invoicing_Memo__c createInvoiceMemoBasedOnProjectDate(Subscription_Order__c order, Date milestoneDate, Decimal maxPercentOfProjectToWaive) {
        // No need to waive negative fees (ie, credits to client)
        if (order.Approved_Change_in_Subscription__c <= 0) {
            return null;
        }
        if (maxPercentOfProjectToWaive == null) {
            return createInvoiceMemo(order, -order.Contract_Fee_Detail__r.Fee__c * order.Approved_Change_in_Subscription__c * 1000);
        } else {
            return createInvoiceMemoUnderMaxPercent(maxPercentOfProjectToWaive, order.Approved_Change_in_Subscription__c, order, milestoneDate);
        }
    }

    private Client_Invoicing_Memo__c createInvoiceMemoUnderMaxPercent(Decimal maxPercentOfProjectToWaive, Decimal maxKwToWaive, Subscription_Order__c order, Date milestoneDate) {
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
        if (kWToWaive > 0) {
            sssIdToTotalWaivedkWMap.putValue(sssId, new ClientInvoicingMemo(sssId, order.Effective_Date__c, kWToWaive));
            return createInvoiceMemo(order, -1 * order.Contract_Fee_Detail__r.Fee__c * (kWToWaive * 1000));
        }
        return null;
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
    private Decimal calculateTotalkWDCWaivedForAnnualPeriod(List<ClientInvoicingMemo> waivedFees, Date milestoneDate, Date effectiveDate) {
        if (effectiveDate < milestoneDate) {
            return 0;
        }
        Date startDate = milestoneDate;
        Date endDate = milestoneDate.addMonths(12);
        while (true) {
            if (startDate <= effectiveDate && effectiveDate < endDate) {
                break;
            }
            startDate = startDate.addMonths(12);
            endDate = endDate.addMonths(12);
        }
        Decimal totalWaivedkWDC = 0;
        for (ClientInvoicingMemo clientInvoicingMemo : waivedFees) {
            if (startDate <= clientInvoicingMemo.effectiveDate && clientInvoicingMemo.effectiveDate < endDate) {
                totalWaivedkWDC += clientInvoicingMemo.approvedChangeInSubscription;
            }
        }
        return totalWaivedkWDC;
    }

    private Date getMilestoneDate(Subscription_Order__c order, String milestoneDateType) {
        if (milestoneDateType == null) {
            return null;
        }
        Date milestoneDate;
        Boolean feeCharged = true;

        switch on milestoneDateType {
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
                milestoneDate = order.Utility_Account_Subscription__r.Opportunity__r.Assignment_Agreement__r.CustomerSignedDate;
            }
            when 'Fee not Charged' {
                feeCharged = false;
            }
            when null {
                feeCharged = false;
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
        if (feeCharged && milestoneDate == null) {
            Logger.logLater(
                'ClientInvoicingFeeAssignmentService',
                'Null SSS Date for Client Invoicing, with type: ',
                milestoneDateType + 'and SSS: ' + order.Utility_Account_Subscription__r.Shared_Solar_System__c + 'SO: ' + order.Id
            );
        }
        return milestoneDate;
    }

    private Client_Invoicing_Memo__c createInvoiceMemo(Subscription_Order__c order, Decimal amount) {
        Client_Invoicing_Memo__c memo = new Client_Invoicing_Memo__c(
            Subscription_Order__c = order.Id,
            Amount__c = amount.setScale(2, RoundingMode.HALF_UP),
            Effective_Date__c = System.today()
        );
        uow.registerNew(memo);
        return memo;
    }
}