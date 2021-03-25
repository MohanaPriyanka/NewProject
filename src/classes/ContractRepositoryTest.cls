/**
 * Created by PeterYao on 3/17/2021.
 */
@IsTest
private with sharing class ContractRepositoryTest {
    @IsTest
    private static void testUninitializedRepository() {
        try {
            ContractRepository.getProjectContractEffectiveDate(null, null, System.today());
            System.assert(false, 'Expected an uninitialized repository to throw an exception when calling getProjectContractEffectiveDate');
        } catch (Util.BWException bwe) {
            System.assert(bwe.getMessage().contains('needs to be initialized'), bwe.getMessage() + '\n' + bwe.getStackTraceString());
        }

        try {
            ContractRepository.getContractToContractFeeDetails();
            System.assert(false, 'Expected an uninitialized repository to throw an exception when calling getContractToContractFeeDetails');
        } catch (Util.BWException bwe) {
            System.assert(bwe.getMessage().contains('needs to be initialized'), bwe.getMessage() + '\n' + bwe.getStackTraceString());
        }
    }

    @IsTest
    private static void testProjectContractNotFoundInRepository() {
        ContractRepository.clientContracts = new List<Client_Contract__c>();
        Date effectiveDate = ContractRepository.getProjectContractEffectiveDate(
            Util.getFakeId(Contract.SObjectType),
            Util.getFakeId(Shared_Solar_System__c.SObjectType),
            System.today()
        );
        System.assertEquals(null, effectiveDate, 'getProjectContractEffectiveDate should return null if it finds no matching project contract');
        System.assertEquals(1, Logger.logs.values().size(), 'Expected an error to be logged for later');
    }
}