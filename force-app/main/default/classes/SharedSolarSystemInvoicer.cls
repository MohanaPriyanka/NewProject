/**
 * @description Sets SSS fields used for Client Invoicing
 * Tested By: SharedSolarSystemsTest
 */
public without sharing class SharedSolarSystemInvoicer {
    @TestVisible private static ContractFeeDetailSelector contractFeeDetailSelector = new ContractFeeDetailSelector();

    public void updateManagementRevenueStartDateBeforeTrigger(List<Shared_Solar_System__c> records) {
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(new List<SObjectType>{
            Shared_Solar_System__c.SObjectType
        });
        updateManagementRevenueStartDate(uow, records);
    }

    public void updateManagementRevenueStartDate(fflib_SObjectUnitOfWork uow, List<Shared_Solar_System__c> records) {
        MultiMap contractsToCFDs = getContractsToCFDs(records);
        for (Shared_Solar_System__c sss : records) {
            List<Object> untypedCFDs = contractsToCFDs.getValues(sss.Client_Management_Contract__c);
            List<Contract_Fee_Detail__c> contractFeeDetails =
                (List<Contract_Fee_Detail__c>) CollectionUtil.toTypedList(untypedCFDs, new List<Contract_Fee_Detail__c>());
            Date managementRevenueStartDate = getRevenueStartDate(sss, contractFeeDetails);
            if (sss.Management_Revenue_Start_Date__c == null && managementRevenueStartDate != null) {
                sss.Management_Revenue_Start_Date__c = managementRevenueStartDate;
                uow.registerDirty(sss, new List<SObjectField>{
                    Shared_Solar_System__c.Management_Revenue_Start_Date__c
                });
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
            }
            // else: must be cfd.SSS != sss.Id, so we can skip it
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

    private MultiMap getContractsToCFDs(List<Shared_Solar_System__c> records) {
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