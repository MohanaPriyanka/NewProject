/**
 * Created by peteryao on 7/15/20.
 */
@IsTest
private with sharing class ClientContractSelectorTest {
    @TestSetup
    public static void testDataSetup() {
        ClientContractServiceTest.testDataSetup();
    }
    @IsTest
    private static void testGetClientContracts() {
        Contract c = [SELECT Id FROM Contract WHERE Name = 'Test Contract' LIMIT 1];
        Shared_Solar_System__c sss = [SELECT Id FROM Shared_Solar_System__c WHERE Name = 'Project A' LIMIT 1];
        Client_Contract__c clientContract = new Client_Contract__c(
            Contract__c = c.Id,
            Shared_Solar_System__c = sss.Id,
            CS_Services_Type__c = 'Management Only',
            Effective_Date__c = System.today(),
            End_Date__c = System.today() + 60
        );
        insert clientContract;
        ClientContractSelector clientContractSelector = new ClientContractSelector();
        System.assertEquals(1, clientContractSelector.getClientContracts(new Set<Id>{sss.Id}).size(),
            'Should be one client contract for Project A');
        System.assertEquals(1, clientContractSelector.getActiveClientContracts().size(),
            'Should be one active client contract');
    }
}