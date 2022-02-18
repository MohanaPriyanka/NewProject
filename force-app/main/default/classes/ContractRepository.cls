/**
 * @description Convenience class to get data about Contracts for client invoicing
 * Tested By: ContractRepositoryTest, ClientInvoicingFeeAssignmentServiceTest, ClientInvoicingFeeWaiveServiceTest
 */
public without sharing class ContractRepository {
    @TestVisible private static ClientContractSelector clientContractSelector = new ClientContractSelector();
    @TestVisible private static ContractFeeDetailSelector contractFeeDetailSelector = new ContractFeeDetailSelector();
    @TestVisible private static List<Client_Contract__c> clientContracts;
    @TestVisible private static MultiMap contractToFeeDetailMap;

    /**
     * @description Initializes the repository with Contract Fee Details from a set of Contract Ids
     * @param subscriptionOrders List of Subscription Orders from which to find contracts
     */
    public static void initFromSubscriptionOrders(List<Subscription_Order__c> subscriptionOrders) {
        Set<Id> contractIds = new Set<Id>();
        Set<Id> sssIds = new Set<Id>();
        for (Subscription_Order__c subOrder : subscriptionOrders) {
            sssIds.add(subOrder.Utility_Account_Subscription__r.Shared_Solar_System__c);
        }

        clientContracts = clientContractSelector.getClientContracts(sssIds);
        for (Client_Contract__c clientContract : clientContracts) {
            contractIds.add(clientContract.Contract__c);
        }
        List<Contract_Fee_Detail__c> contractFeeDetails = contractFeeDetailSelector.getContractDetailFromContract(contractIds);
        setContractToCFDMap(contractFeeDetails);
    }

    /**
     * @description Used after initializing the repository with Contract Ids to get a MultiMap of Contract to Contract Fee Details
     * @return MultiMap
     */
    public static MultiMap getContractToContractFeeDetails() {
        if (contractToFeeDetailMap == null) {
            throw new Util.BWException('ContractRepository needs to be initialized before getting contract fee details');
        }
        return contractToFeeDetailMap;
    }

    @TestVisible
    private static void setContractToCFDMap(List<Contract_Fee_Detail__c> contractFeeDetail) {
        contractToFeeDetailMap = MultiMap.newListInstance();

        for (Contract_Fee_Detail__c feeDetail : contractFeeDetail){
            ContractFeeDetail feeQualifier = new ContractFeeDetail(feeDetail);
            contractToFeeDetailMap.putValue(feeDetail.Contract__c, feeQualifier);
        }
    }

    /**
     * @description Used after the repository is initialized from Shared Solar Systems to get the Effective Date for
     * a System
     * @param contractId The Management or Acquisition Contract Id for the client
     * @param sssId The Shared Solar System Id
     * @param asOfDate The effective date (of the subscription order)
     * @return The Effective Date for the Project Contract (Client_Contract__c), or null, if a Contract/System was not
     * effective for that Contract and System as of the asOfDate
     */
    public static Date getProjectContractEffectiveDate(Id contractId, Id sssId, Date asOfDate) {
        if (clientContracts == null) {
            throw new Util.BWException('ContractRepository needs to be initialized before getting client contracts');
        }
        for (Client_Contract__c clientContract : clientContracts) {
            if (contractId == clientContract.Contract__c &&
                sssId == clientContract.Shared_Solar_System__c &&
                DateUtil.between(clientContract.Effective_Date__c, asOfDate, clientContract.End_Date__c)) {
                return clientContract.Effective_Date__c;
            }
        }
        Logger.logLater(
            'ContractRepository',
            'getProjectContractEffectiveDate',
            'Could not find Project Contract for ' +
                'Contract ' + contractId + ' and System ' + sssId + ' that was effective on ' + asOfDate,
            Logger.ERROR
        );
        return null;
    }

    public static List<Id> getActiveContractsForSystem(Id sssId, Datetime effectiveDate) {
        if (clientContracts == null) {
            throw new Util.BWException('ContractRepository needs to be initialized before getting contracts for a system');
        }
        List<Id> contractIds = new List<Id>();
        for (Client_Contract__c clientContract : clientContracts) {
            if (clientContract.Shared_Solar_System__c == sssId &&
                clientContract.Effective_Date__c <= effectiveDate &&
                clientContract.End_Date__c >= effectiveDate) {
                contractIds.add(clientContract.Contract__c);
            }
        }
        return contractIds;
    }
}