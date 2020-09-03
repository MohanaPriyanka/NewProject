public without sharing class ClientInvoicingFeeWaiveService {
    @TestVisible
    private static ClientInvoicingMemoSelector clientInvoicingMemoSelector = new ClientInvoicingMemoSelector();
    @TestVisible
    private static SubscriptionOrderSelector subscriptionOrderSelector = new SubscriptionOrderSelector();

    private Map<Id,Decimal> sssIdToTotalWaivedkWMap;
    private Map<Id,Decimal> uasToAssignedCapacityMap;

    public static ClientInvoicingFeeAssignmentService assignmentService;

    @TestVisible
    private fflib_SObjectUnitOfWork uow;

    public ClientInvoicingFeeWaiveService(ClientInvoicingFeeAssignmentService assignment){
        assignmentService = assignment;
    }

    public void waiveFeesIfNecessary(List<Subscription_Order__c> subOrders, fflib_SObjectUnitOfWork uowParam){
        uow = uowParam;
        setFeesToWaive(subOrders);
    }

    public void setFeesToWaive(List<Subscription_Order__c> subOrders){
        queryData(subOrders);
        for (Subscription_Order__c order : subOrders){
            if (order.Contract_Fee_Detail__r.Acquisition_Type_Reacquisition__c){
                waiveFeeBasedOnDate(order);
                waiveFeeBasedOnProjectAttrition(order);
            }
        }
    }

    private void queryData(List<Subscription_Order__c> subOrders){
        Set<Id> sssIds = new Set<Id>();
        Set<Id> uasIds = new Set<Id>();

        for (Subscription_Order__c order : subOrders){
            if (order.Contract_Fee_Detail__r.Acquisition_Type_Reacquisition__c
                && order.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Max_Project__c != null){
                sssIds.add(order.Utility_Account_Subscription__r.Shared_Solar_System__c);
                uasIds.add(order.Utility_Account_Subscription__c);
            } else if (order.Contract_Fee_Detail__r.Acquisition_Type_Reacquisition__c){
                uasIds.add(order.Utility_Account_Subscription__c);
            }
        }

        sssIdToTotalWaivedkWMap = clientInvoicingMemoSelector.getWaivedFeesBySSS(sssIds);
        uasToAssignedCapacityMap = subscriptionOrderSelector.getSubscriptionOrdersAssignedToClient(uasIds);
    }

    private void waiveFeeBasedOnDate(Subscription_Order__c order){
        Integer numberOfMonths = (Integer)order.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Number_Months__c;
        String sssDateType = order.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Project_Date__c;

        if (numberOfMonths == null || sssDateType == null){
            return;
        }

        Date milestoneDate = getMilestoneDate(order,sssDateType);
        milestoneDate = milestoneDate.addMonths(numberOfMonths);

        /* Allow negative subscription orders for Customer: Assignment Date guarantees because we don't use the SO
           amount, we use the customer size at assignment. (The fee waive is triggered by a cancelled customer
           decreasing in size, so we want to allow negative values)
           Otherwise, there is no need to waive a negative fee.
        */

        if (sssDateType == 'Customer: Assignment Date'){
            waiveFeeBasedOnCustomerDate(order,milestoneDate);
        } else if (order.Approved_Change_in_Subscription__c > 0) {
            waiveFeeBasedOnProjectDate(order,milestoneDate);
        }
    }

    private void waiveFeeBasedOnCustomerDate(Subscription_Order__c order, Date milestoneDate){
        if (order.System_Change_kW_DC_Rounded__c == 0 && order.Effective_Date__c <= milestoneDate){
            Decimal reacFee = assignmentService.getCancellationFee(order);
            Decimal assignmentAgreementSize = uasToAssignedCapacityMap.get(order.Utility_Account_Subscription__c);
            Decimal amountToWaive = -1 * (assignmentAgreementSize*1000) * reacFee;
            createInvoiceMemo(order, amountToWaive);
        }
    }

    private void waiveFeeBasedOnProjectDate(Subscription_Order__c order, Date milestoneDate){
        if (order.Effective_Date__c <= milestoneDate) {
            Decimal amountToWaive = -1 * (order.Approved_Change_in_Subscription__c*1000) * order.Contract_Fee_Detail__r.Fee__c;
            createInvoiceMemo(order, amountToWaive);
        }
    }

    private void waiveFeeBasedOnProjectAttrition(Subscription_Order__c order){
        Decimal maxPercentOfProjectToWaive = order.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Max_Project__c;
        // No need to waive negative fees (ie, credits to client)
        if (maxPercentOfProjectToWaive == null || order.Approved_Change_in_Subscription__c <= 0){
            return;
        }
        maxPercentOfProjectToWaive = maxPercentOfProjectToWaive/100;
        Id sssId = order.Utility_Account_Subscription__r.Shared_Solar_System__c;

        Decimal totalSystemSize = order.Utility_Account_Subscription__r.Shared_Solar_System__r.Total_System_Size_kWh_DC__c;
        Decimal feesAlreadyWaived = Util.nullToZero(sssIdToTotalWaivedkWMap.get(sssId));

        Decimal kwLeftToWaive = Math.max((maxPercentOfProjectToWaive * totalSystemSize) - feesAlreadyWaived,0);
        Decimal kWToWaive = Math.min(kwLeftToWaive,order.Approved_Change_in_Subscription__c);

        sssIdToTotalWaivedkWMap.put(sssId, feesAlreadyWaived + kWToWaive);

        if (kWToWaive > 0){
            createInvoiceMemo(order, -1 * order.Contract_Fee_Detail__r.Fee__c * (kWToWaive*1000));
        }
    }

    private Date getMilestoneDate(Subscription_Order__c order, String milestoneDateType){
        Date milestoneDate;
        Boolean feeCharged = true;

        switch on milestoneDateType {
            when 'Contract: Effective Date' {
                milestoneDate = order.Contract_Fee_Detail__r.Contract__r.StartDate;
            }
            when 'Project: PTO' {
                milestoneDate = order.Utility_Account_Subscription__r.Shared_Solar_System__r.Actual_COD_Date__c;
            }
            when 'Project: COD' {
                milestoneDate = order.Utility_Account_Subscription__r.Shared_Solar_System__r.Actual_PTO_Date_MANUAL__c;
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
        if (feeCharged && milestoneDate == null){
            Logger.logLater(
                'ClientInvoicingFeeAssignmentService',
                'Null SSS Date for Client Invoicing, with type: ',
                milestoneDateType + 'and SSS: ' + order.Utility_Account_Subscription__r.Shared_Solar_System__c + 'SO: ' + order.Id
            );
        }
        return milestoneDate;
    }

    private void createInvoiceMemo(Subscription_Order__c order, Decimal amount){
        Client_Invoicing_Memo__c memo = new Client_Invoicing_Memo__c(
            Subscription_Order__c = order.Id,
            Amount__c = amount.setScale(2, RoundingMode.HALF_UP),
            Effective_Date__c = System.today()
        );
        uow.registerNew(memo);
    }
}