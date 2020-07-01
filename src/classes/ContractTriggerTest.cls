/**
 * Created by peteryao on 6/17/20.
 */
@IsTest
public with sharing class ContractTriggerTest {
    @IsTest
    private static void testContractTriggerDisabled() {
        Map<String, Boolean> featureFlagMap = new Map<String, Boolean>{'Customer_Contract_Object'=>true};
        CustomerAssignmentService.featureService =
            (FeatureService) Test.createStub(FeatureService.class, new FeatureService.Mock(featureFlagMap));
        Util.mockDML = true;
        Util.disableTrigger('Disable_ContractTrigger__c');

        System.assertEquals(null, Util.objectsUpdatedIfMockingDML);
        Account a = new Account(Name = 'Foo');
        insert a;
        Contract c = new Contract(AccountId = a.Id);
        insert c;
        System.assertEquals(null, Util.objectsUpdatedIfMockingDML,
            'Did not expect any updated to be attempted yet');
        update c;
        System.assertEquals(null, Util.objectsUpdatedIfMockingDML,
            'Still did not expect any updates to be attempted since the trigger is disabled');
    }

    @IsTest
    private static void testContractTriggerEnabled() {
        Map<String, Boolean> featureFlagMap = new Map<String, Boolean>{'Customer_Contract_Object'=>true};
        CustomerAssignmentService.featureService =
            (FeatureService) Test.createStub(FeatureService.class, new FeatureService.Mock(featureFlagMap));
        Util.mockDML = true;

        System.assertEquals(null, Util.objectsUpdatedIfMockingDML);
        Account a = new Account(Name = 'Foo');
        insert a;
        Contract customerContract = new Contract(
            AccountId = a.Id,
            Status = 'Draft'
        );
        Contract assignmentAgreement = new Contract(
            AccountId = a.Id,
            RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Assignment Agreement').getRecordTypeId(),
            Status = 'Draft'
        );
        Contract clientContract = new Contract(
            AccountId = a.Id,
            Status = 'Draft',
            RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Client Contract').getRecordTypeId()
        );

        List<Contract> contracts = new List<Contract>{customerContract, assignmentAgreement, clientContract};
        insert contracts;
        assertNumberOfActiveContracts(clientContract, 'insert');
        System.assertEquals(null, Util.objectsUpdatedIfMockingDML,
            'Did not expect any updated to be attempted yet');
        customerContract.Assignment_Agreement__c = assignmentAgreement.Id;
        clientContract.Status = 'Activated';

        update new List<Contract>{customerContract, clientContract};
        System.assertEquals(0, Util.objectsUpdatedIfMockingDML.size(),
            'Expected customerAssignmentService.updateAssignmentAgreements trigger to call an update with no rows');
        assertNumberOfActiveContracts(clientContract, 'update');

        delete contracts;
        assertNumberOfActiveContracts(clientContract, 'delete');

        undelete contracts;
        assertNumberOfActiveContracts(clientContract, 'undelete');
    }

    private static void assertNumberOfActiveContracts(Contract clientContract, String operation) {
        List<Account> clientAccounts = new AccountsSelector().selectAll(new Set<Id>{
            clientContract.AccountId
        });
        System.assertEquals(1, clientAccounts.size());
        System.assertEquals(clientAccounts[0].Contracts.size(), clientAccounts[0].Number_of_Active_Contracts__c,
            'The Client Account should have ' + clientAccounts[0].Contracts.size() +
                ' Number of Active Contracts after '+operation+', but has ' + clientAccounts[0].Number_of_Active_Contracts__c);
    }
}