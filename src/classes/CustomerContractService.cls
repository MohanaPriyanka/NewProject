/**
 * Created by Lindsay Holmes (Gears CRM) on 5/15/2020.
 * Description: Service for the Contract object
 * Test: CustomerContractServiceTest
 */

 public without sharing class CustomerContractService {
    LeadSelector leadSelector = new LeadSelector();
    CustomerContractSelector customerContractSelector = new CustomerContractSelector();

    public static final Id RECORD_TYPE_ID = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('Customer_Contract').getRecordTypeId();

    public Contract createContractFromLead(Id leadId) {
        Lead lead = leadSelector.selectOneForContractCreation(leadId);
        if(lead == null || lead.Accounts__r == null || lead.Accounts__r.isEmpty()) {
            throw new Util.BWException('Invalid lead; please make sure you have provided a valid lead ID and that the lead has at least one associated property account');
        }

        Contract contract = setContractFields(lead);
        contract.AccountId = lead.Accounts__r[0].Id;
        
        Boolean success = Util.insertAndLog(new List<sObject>{contract}, 'CustomerContractService', 'createContractFromLead');
        if(success) {
            return customerContractSelector.selectOne(contract.Id);
        }

        return null;
    }


    public Contract setContractFields(Lead lead) {
        Contract contract = new Contract();
        contract.Lead__c = lead.Id;
        contract.Product__c = lead.Product__c;
        contract.RecordTypeId = RECORD_TYPE_ID;
        contract.Generate_Review_Version__c = true;
        
        if(lead.Product__r.Generic_Terms_Conga_Template__c != null) {
            contract.Contract_Type__c = 'Generic';
        } else {
            contract.Contract_Type__c = 'Project Specific';
        }

        return contract;
    }


    public void regenerateDocuments(Id leadId) {
        List<Contract> contracts = customerContractSelector.selectByRelatedLead(leadId);
        for(Contract c : contracts) {
            c.Generate_Review_Version__c = true;
        }
        
        Util.updateAndLog(contracts, 'CustomerContractService', 'regenerateDocuments');
    }


    public Boolean signCustomerContracts(Id leadId) {
        List<Contract> contracts = customerContractSelector.selectByRelatedLead(leadId);
        if(contracts == null || contracts.isEmpty()) {
            throw new Util.BWException('There are no existing contracts associated with lead id ' + leadId);
        }
        
        for(Contract c : contracts) {
            c.Customer_Signature_Date_Time__c = Datetime.now();
            c.Generate_Signed_Version__c = true;
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
            Parent_Contract__c = parentContract.Id,
            Customer_Signature_Date_Time__c = parentContract.Customer_Signature_Date_Time__c
        );
    }
}