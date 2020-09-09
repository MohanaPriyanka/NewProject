/**
 * Created by SarahRenfro on 7/6/2020.
 * Description: Domain class for SSS
 * Test: CSUtilityAccountSubscriptionFactoryTest, SharedSolarSystemsTest
 */

public inherited sharing class SharedSolarSystems {
    private List<Shared_Solar_System__c> records;
    @TestVisible
    private static FeatureService featureService = new FeatureService();
    @TestVisible
    private static ProductSelector productSelector = new ProductSelector();
    @TestVisible
    private static ContractFeeDetailSelector contractFeeDetailSelector = new ContractFeeDetailSelector();

    public SharedSolarSystems(List<Shared_Solar_System__c> records) {
        this.records = records;
    }

    public static Decimal calculateMaximumkWh(Shared_Solar_System__c sss){
        Decimal sssRemainingSubscriptionCapacity = sss.Maximum_Subscription_Capacity_kWDC__c * sss.Expected_Yield_kWh_kW__c;
        if (featureService.isEnabled('Sizing_Method') && sss.Product__r.Customer_Subscription_Type__c == 'kWh'
                && sss.Product__r.Sizing_Method__c == 'Project Ratio') {
                sssRemainingSubscriptionCapacity = sssRemainingSubscriptionCapacity/sss.Utility_NMC_Tariff__r.Size_Ratio__c;
            }
        return sssRemainingSubscriptionCapacity.setScale(2, RoundingMode.HALF_DOWN);
    }

    public void calculateMaximumSubscriptionCapacityForSMART() {
        Set<Id> productIds = new Set<Id>();
        for (Shared_Solar_System__c sss : records) {
            productIds.add(sss.Product__c);
        }
        Map<Id, Product2> productsForConversionMap =
            new Map<Id, Product2>(productSelector.selectForACToDCConversion(productIds));
        if (productsForConversionMap.isEmpty()) {
            return;
        }
        for (Shared_Solar_System__c sss : records) {
            Product2 productForConversion = productsForConversionMap.get(sss.Product__c);
            if (productForConversion == null || sss.Total_System_Size_kWh_DC__c == null || sss.Total_System_Size_kW_AC__c == null) {
                continue;
            } else {
                sss.Maximum_Subscription_Capacity_kWDC__c =
                    productForConversion.Max_Subscription_kW_AC_for_DC_calc__c *
                        (sss.Total_System_Size_kWh_DC__c/sss.Total_System_Size_kW_AC__c);
            }
        }
    }

    public void updateManagementRevenueStartDateBeforeTrigger() {
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{Shared_Solar_System__c.SObjectType});
        updateManagementRevenueStartDate(uow);
    }
    public void updateManagementRevenueStartDate(fflib_SObjectUnitOfWork uow) {
        MultiMap contractsToCFDs = getContractsToCFDs();
        for (Shared_Solar_System__c sss : records) {
            List<Object> untypedCFDs = contractsToCFDs.getValues(sss.Client_Management_Contract__c);
            List<Contract_Fee_Detail__c> contractFeeDetails =
                (List<Contract_Fee_Detail__c>) CollectionUtil.toTypedList(untypedCFDs, new List<Contract_Fee_Detail__c>());
            Date managementRevenueStartDate = getRevenueStartDate(sss, contractFeeDetails);
            if (sss.Management_Revenue_Start_Date__c == null && managementRevenueStartDate != null) {
                sss.Management_Revenue_Start_Date__c = managementRevenueStartDate;
                uow.registerDirty(sss, new List<SObjectField>{Shared_Solar_System__c.Management_Revenue_Start_Date__c});
            }
        }
    }

    private Date getRevenueStartDate(Shared_Solar_System__c sss, List<Contract_Fee_Detail__c> contractFeeDetails) {
        if (contractFeeDetails == null || contractFeeDetails.size() == 0) {
            return null;
        }
        Date startDate;
        for (Contract_Fee_Detail__c cfd : contractFeeDetails) {
            if (cfd.Shared_Solar_System__c == null) {
                startDate = getStartDateForCFD(cfd, startDate, sss);
            } else if (cfd.Shared_Solar_System__c == sss.Id) {
                return getStartDateForCFD(cfd, null, sss);
            } else {
                // must be cfd.SSS != sss.Id, so we can skip it
            }
        }
        return startDate;
    }

    private Date getStartDateForCFD(Contract_Fee_Detail__c cfd, Date startDate, Shared_Solar_System__c sss) {
        switch on cfd.Management_Fee_Trigger__c {
            when 'Project: PTO' {
                startDate = DateUtil.min(startDate, sss.Actual_PTO_Date_MANUAL__c);
            } when 'Project: COD' {
                startDate = DateUtil.min(startDate, sss.Actual_COD_Date__c);
            } when 'Project: First Customer Assignment Date' {
                startDate = DateUtil.min(startDate, sss.Customer_Assignment_Date__c);
            } when 'Project: First Customer Bill Date' {
                startDate = DateUtil.min(startDate, sss.First_Bill_Date__c);
            } when 'Contract: Effective Date' {
                startDate = DateUtil.min(startDate, cfd.Contract__r.StartDate);
            } when else {
                Logger.logLater(
                    'SharedSolarSystems',
                    'getRevenueStartDate',
                    'Management Fee Trigger for system ' + sss.Id + ' not handled: ' + cfd,
                    Logger.ERROR
                );
            }
        }
        return startDate;
    }

    private MultiMap getContractsToCFDs() {
        MultiMap contractsToCFDs = MultiMap.newSetInstance();
        Set<Id> contractIds = new Set<Id>();
        for (Shared_Solar_System__c sss : records) {
            contractIds.add(sss.Client_Management_Contract__c);
        }
        List<Contract_Fee_Detail__c> contractFeeDetails = contractFeeDetailSelector.getContractDetailFromContract(contractIds);
        for (Contract_Fee_Detail__c cfd : contractFeeDetails) {
            if (cfd.Management_Fee__c && cfd.Management_Fee_Type__c == 'Recurring') {
                contractsToCFDs.putValue(cfd.Contract__c, cfd);
            }
        }
        return contractsToCFDs;
    }

}