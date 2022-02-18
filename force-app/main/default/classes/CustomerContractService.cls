/**
 * @description Created by Lindsay Holmes (Gears CRM) on 5/15/2020. Service for the Contract object.
 * Tested By: CustomerContractServiceTest, CSLeadsRESTControllerV2Test, ClientFileCopierServiceTest
 */
public without sharing class CustomerContractService {

    public static final Id RECORD_TYPE_ID =
        Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('Customer_Contract').getRecordTypeId();
    private CustomerContractSelector customerContractSelector = new CustomerContractSelector();

    public Contract setContractFields(Lead lead, Integer numberOfContractDocs) {
        Contract contract = new Contract(
            Lead__c = lead.Id,
            Product__c = lead.Product__c,
            RecordTypeId = RECORD_TYPE_ID,
            Generate_Review_Version__c = true,
            Generate_Disclosure_Form__c = (numberOfContractDocs == 2)
        );
        if (lead.Product__r.Generic_Terms_Conga_Template__c != null) {
            contract.Contract_Type__c = 'Generic';
        } else {
            contract.Contract_Type__c = 'Project Specific';
        }
        return contract;
    }

    public void regenerateDocuments(Id leadId) {
        List<Contract> contracts = customerContractSelector.selectByRelatedLead(leadId);
        for (Contract c : contracts) {
            c.Generate_Review_Version__c = true;
        }
        Util.updateAndLog(contracts, 'CustomerContractService', 'regenerateDocuments');
    }

    public Boolean signCustomerContracts(Id leadId) {
        List<Contract> contracts = customerContractSelector.selectByRelatedLead(leadId);
        if (contracts == null || contracts.isEmpty()) {
            throw new Util.BWException('There are no existing contracts associated with lead id ' + leadId);
        }
        for (Contract c : contracts) {
            c.Customer_Signature_Date_Time__c = Datetime.now();
            c.Generate_Signed_Version__c = true;
            c.Override_Countersign_Template_Id__c = c.Conga_Template_ID_Countersigned__c;
        }
        return Util.updateAndLog(contracts, 'SimpleSignupFormController', 'signCustomerContracts');
    }

    public static Contract createForOpportunity(Opportunity opp, Contract parentContract) {
        return new Contract(
            Lead__c = opp.Lead__c,
            Product__c = opp.Product__c,
            RecordTypeId = RECORD_TYPE_ID,
            AccountId = opp.AccountId,
            Contract_Type__c = 'Project Specific',
            Parent_Contract__c = parentContract.Id
        );
    }

    /**
     * @description Ensures that the Product on the Contract and Lead are in sync. However, we do not want to change
     * the product on the "Generic" Contract when the lead is updated to the "Project Specific" Product upon conversion
     * @param contracts List of contracts
     * @param leadMap Map of related Leads
     */
    public void updateProductForCustomerContract(List<Contract> contracts, Map<Id, Lead> leadMap) {
        List<Contract> contractsToUpdate = new List<Contract>();
        for (Contract c : contracts) {
            if (c.Contract_Type__c == 'Generic' && c.Product__c == leadMap.get(c.Lead__c).Product__r.Parent_Product__c) {
                continue;
            } else {
                c.Product__c = leadMap.get(c.Lead__c).Product__c;
                contractsToUpdate.add(c);
            }
        }
        Util.updateAndLog(contractsToUpdate, 'LeadService', 'updateRelatedContracts');
    }

    public static Id locateCustomerAgreementContract(Utility_Account_Subscription__c uas) {
        if (uas.Opportunity__r.Contract.Parent_Contract__c != null) {
            return uas.Opportunity__r.Contract.Parent_Contract__c;
        }
        return uas.Opportunity__r.ContractId;
    }

    public static Id locateCustomerAgreementContract(Contract contract) {
        if (contract.Parent_Contract__c != null) {
            return contract.Parent_Contract__c;
        }
        return contract.Id;
    }
}