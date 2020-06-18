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
        Contract customerContract = new Contract(AccountId = a.Id);
        Id assignmentAgreementRecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Assignment Agreement').getRecordTypeId();
        Contract assignmentAgreement = new Contract(
            AccountId = a.Id,
            RecordTypeId = assignmentAgreementRecordTypeId
        );
        insert new List<Contract>{customerContract, assignmentAgreement};
        System.assertEquals(null, Util.objectsUpdatedIfMockingDML,
            'Did not expect any updated to be attempted yet');
        customerContract.Assignment_Agreement__c = assignmentAgreement.Id;
        update customerContract;
        System.assertEquals(0, Util.objectsUpdatedIfMockingDML.size(),
            'Expected customerAssignmentService.updateAssignmentAgreements trigger to call an update with no rows');
    }
}