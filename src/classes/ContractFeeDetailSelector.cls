@SuppressWarnings('PMD.ApexCRUDViolation')
public inherited sharing class ContractFeeDetailSelector {

    public List<Contract_Fee_Detail__c> getContractDetailFromContract(Set<Id> contractIds) {
        List<Contract_Fee_Detail__c> cfdList = [
            SELECT Id, Contract__c, Acquisition_Channels_BCS_Acquired__c, Acquisition_Channels_Closed_by_BCS__c,
                Acquisition_Channels_Non_BCS_Acquired__c, Acquisition_Cust_Group_Anchor__c,
                Acquisition_Cust_Group_Public_Offtake__c,Acquisition_Cust_Group_Residential__c,
                Acquisition_Cust_Group_Non_Residential__c, Acquisition_Sizing_Type_Downsizing__c,
                Acquisition_Sizing_Type_Upsizing__c, Acquisition_Type_Acquisition__c, Acquisition_Type_Reacquisition__c,
                Fee__c, Fee_Unit__c
            FROM Contract_Fee_Detail__c
            WHERE Contract__c IN : contractIds
        ];
        return cfdList;
    }
}