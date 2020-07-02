public without sharing class ClientInvoicingFeeWaiveService {
    @TestVisible
    private static ClientInvoicingMemoSelector clientInvoicingMemoSelector = new ClientInvoicingMemoSelector();

    private Map<Id,Decimal> sssIdToTotalWaivedkWMap;

    public fflib_SObjectUnitOfWork uow;

    public void waiveFeesIfNecessary(List<Subscription_Order__c> subOrders){
        setFeesToWaive(subOrders);
        uow.commitWork();
        Logger.flushLogs();
    }

    public void setFeesToWaive(List<Subscription_Order__c> subOrders){
        if (uow == null){
            uow = new fflib_SObjectUnitOfWork(
                new List<SObjectType> {
                    Client_Invoicing_Memo__c.SObjectType
                }
            );
        }
        setSSSMap(subOrders);
        for (Subscription_Order__c order : subOrders){
            if (order.Contract_Fee_Detail__r.Acquisition_Type_Reacquisition__c){
                waiveFeeBasedOnProjectDate(order);
                waiveFeeBasedOnProjectAttrition(order);
            }
        }
    }

    private void setSSSMap(List<Subscription_Order__c> subOrders){
        Set<Id> sssIds = new Set<Id>();

        for (Subscription_Order__c order : subOrders){
            if (order.Contract_Fee_Detail__r.Acquisition_Type_Reacquisition__c
                && order.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Max_Project__c != null){
                sssIds.add(order.Utility_Account_Subscription__r.Shared_Solar_System__c);
            }
        }

        sssIdToTotalWaivedkWMap = clientInvoicingMemoSelector.getWaivedFeesBySSS(sssIds);
    }

    private void waiveFeeBasedOnProjectDate(Subscription_Order__c order){
        Integer numberOfMonths = (Integer)order.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Number_Months__c;
        String sssDateType = order.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Project_Date__c;

        if (numberOfMonths == null || sssDateType == null){
            return;
        }

        Date sssDate = getSSSMilestoneDate(order,sssDateType);
        sssDate = sssDate.addMonths(numberOfMonths);

        if (order.Effective_Date__c <= sssDate) {
            Decimal amountToWaive = -1 * Math.ABS(order.Approved_Change_in_Subscription__c*100) * order.Contract_Fee_Detail__r.Fee__c;
            createInvoiceMemo(order, amountToWaive);
        }
    }

    private void waiveFeeBasedOnProjectAttrition(Subscription_Order__c order){
        Decimal maxPercentOfProjectToWaive = order.Contract_Fee_Detail__r.Waive_Reacquisition_Fee_Max_Project__c;
        if (maxPercentOfProjectToWaive == null || order.Approved_Change_in_Subscription__c < 0){
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
            createInvoiceMemo(order, -1 * order.Contract_Fee_Detail__r.Fee__c * (kWToWaive*100));
        }
    }

    private Date getSSSMilestoneDate(Subscription_Order__c order, String sssDateType){
        Date sssDate;
        Boolean feeCharged = true;

        switch on sssDateType {
            when 'Contract Effective Date' {
                sssDate = order.Contract_Fee_Detail__r.Contract__r.StartDate;
            }
            when 'PTO' {
                sssDate = order.Utility_Account_Subscription__r.Shared_Solar_System__r.Actual_COD_Date__c;
            }
            when 'COD' {
                sssDate = order.Utility_Account_Subscription__r.Shared_Solar_System__r.Actual_PTO_Date_MANUAL__c;
            }
            when 'First Customer Bill Date' {
                sssDate = order.Utility_Account_Subscription__r.Shared_Solar_System__r.First_Bill_Date__c;
            }
            when 'Fee not Charged' {
                feeCharged = false;
            }
            when null {
                feeCharged = false;
            }
            when else {
                // As of June 2020, only 'First Customer Assignment Date' isn't handled, since we don't have
                // a field to track that on the SSS or client
                Logger.logLater(
                    'ClientInvoicingFeeAssignmentService',
                    'Unhandled value for Waive_Reacquisition_Fee_Project_Date__c',
                    sssDateType
                );
            }
        }
        if (feeCharged && sssDate == null){
            Logger.logLater(
                'ClientInvoicingFeeAssignmentService',
                'Null SSS Date for Client Invoicing, with type: ',
                sssDateType + 'and SSS: ' + order.Utility_Account_Subscription__r.Shared_Solar_System__c + 'SO: ' + order.Id
            );
        }
        return sssDate;
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