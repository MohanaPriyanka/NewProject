@isTest
public class ContractFeeDetailSelectorTest {
    @testSetup public static void setupTestData() {
        Account clientAccount = new Account(Name = 'Client Account');
        insert clientAccount;

        RecordType clientRT = [SELECT Id FROM RecordType WHERE Name = 'Client Contract' LIMIT 1];

        Contract contractA = new Contract(
            Name = 'Client Contract A',
            AccountId = clientAccount.Id,
            RecordTypeId = clientRT.Id
        );
        Contract contractB = new Contract(
            Name = 'Client Contract B',
            AccountId = clientAccount.Id,
            RecordTypeId = clientRT.Id
        );
        Contract contractC = new Contract(
            Name = 'Client Contract C',
            AccountId = clientAccount.Id,
            RecordTypeId = clientRT.Id
        );
        insert new List<Contract>{contractA, contractB, contractC};

        Contract_Fee_Detail__c cfdAOne = new Contract_Fee_Detail__c(
            Contract__c = contractA.Id,
            Acquisition_Channels_BCS_Acquired__c = true,
            Acquisition_Channels_Non_BCS_Acquired__c = false,
            Acquisition_Cust_Group_Anchor__c = false,
            Acquisition_Cust_Group_Public_Offtake__c = false,
            Acquisition_Cust_Group_Residential__c = true,
            Acquisition_Cust_Group_Non_Residential__c = true,
            Acquisition_Sizing_Type_Downsizing__c = false,
            Acquisition_Sizing_Type_Upsizing__c = true,
            Acquisition_Type_Acquisition__c = true,
            Acquisition_Type_Reacquisition__c = false,
            Fee__c = 0.10
        );
        Contract_Fee_Detail__c cfdATwo = new Contract_Fee_Detail__c(
            Contract__c = contractA.Id,
            Acquisition_Channels_BCS_Acquired__c = false,
            Acquisition_Channels_Non_BCS_Acquired__c = true,
            Acquisition_Cust_Group_Anchor__c = false,
            Acquisition_Cust_Group_Public_Offtake__c = false,
            Acquisition_Cust_Group_Residential__c = true,
            Acquisition_Cust_Group_Non_Residential__c = true,
            Acquisition_Sizing_Type_Downsizing__c = false,
            Acquisition_Sizing_Type_Upsizing__c = true,
            Acquisition_Type_Acquisition__c = true,
            Acquisition_Type_Reacquisition__c = false,
            Fee__c = 0.11
        );
        Contract_Fee_Detail__c cfdBOne = new Contract_Fee_Detail__c(
            Contract__c = contractB.Id,
            Acquisition_Channels_BCS_Acquired__c = false,
            Acquisition_Channels_Non_BCS_Acquired__c = true,
            Acquisition_Cust_Group_Anchor__c = false,
            Acquisition_Cust_Group_Public_Offtake__c = false,
            Acquisition_Cust_Group_Residential__c = true,
            Acquisition_Cust_Group_Non_Residential__c = true,
            Acquisition_Sizing_Type_Downsizing__c = false,
            Acquisition_Sizing_Type_Upsizing__c = true,
            Acquisition_Type_Acquisition__c = true,
            Acquisition_Type_Reacquisition__c = false,
            Fee__c = 0.11
        );
        Contract_Fee_Detail__c cfdCOne = new Contract_Fee_Detail__c(
            Contract__c = contractC.Id,
            Acquisition_Channels_BCS_Acquired__c = false,
            Acquisition_Channels_Non_BCS_Acquired__c = true,
            Acquisition_Cust_Group_Anchor__c = false,
            Acquisition_Cust_Group_Public_Offtake__c = false,
            Acquisition_Cust_Group_Residential__c = true,
            Acquisition_Cust_Group_Non_Residential__c = true,
            Acquisition_Sizing_Type_Downsizing__c = false,
            Acquisition_Sizing_Type_Upsizing__c = true,
            Acquisition_Type_Acquisition__c = true,
            Acquisition_Type_Reacquisition__c = false,
            Fee__c = 0.11
        );
        insert new List<Contract_Fee_Detail__c>{
            cfdAone, cfdATwo, cfdBOne, cfdCOne
        };
    }

    @IsTest
    public static void testGetContractDetailFromContract() {
        List<Contract> contracts = [
            SELECT Id
            FROM Contract
            WHERE (Name = 'Client Contract A' OR Name = 'Client Contract B')
        ];
        Set<Id> idSet = new Set<Id>();
        for (Contract contractRecord : contracts){
            idSet.add(contractRecord.Id);
        }

        ContractFeeDetailSelector selector = new ContractFeeDetailSelector();
        List<Contract_Fee_Detail__c> detail = selector.getContractDetailFromContract(idSet);

        System.assertEquals(3,detail.size());
    }
}