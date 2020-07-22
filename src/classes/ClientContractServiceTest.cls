/**
 * Created by peteryao on 7/16/20.
 */
@IsTest
public with sharing class ClientContractServiceTest {
    @TestSetup
    public static void testDataSetup() {
        Account client = new Account(Name = 'Client');
        insert client;
        Id clientContractRecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Client Contract').getRecordTypeId();
        Contract c = new Contract(
            Name = 'Test Contract',
            AccountId = client.Id,
            RecordTypeId = clientContractRecordTypeId
        );
        insert c;
        Shared_Solar_System__c sss = new Shared_Solar_System__c(Name = 'Project A');
        insert sss;
    }
    @IsTest
    private static void testTrigger() {
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
        Test.startTest();
        Client_Contract__c clientContract2 = new Client_Contract__c(
            Contract__c = c.Id,
            Shared_Solar_System__c = sss.Id,
            CS_Services_Type__c = 'Management Only',
            Effective_Date__c = System.today() + 30,
            End_Date__c = System.today() + 90
        );
        try {
            insert clientContract2;
            System.assert(false, 'Expected validation to be raised for overlapping dates for client contracts that cover the same services');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('An existing client contract'), e.getMessage());
        }
        clientContract2.CS_Services_Type__c = 'Acquisition Only';
        try {
            insert clientContract2;
            System.assert(true, 'Expected a client contract with a different service type and overlapping dates to be inserted');
        } catch (Exception e) {
            System.assert(false, 'Did not expect an exception to be thrown for a non-overlapping client contract: ' + e.getMessage());
        }
        clientContract2.CS_Services_Type__c = 'Acquisition & Management';
        try {
            update clientContract2;
            System.assert(false, 'Expected a validation to be thrown after update');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('An existing client contract'), e.getMessage());
        }
        delete clientContract2;
        clientContract.CS_Services_Type__c = 'Acquisition & Management';
        update clientContract;
        Client_Contract__c clientContractToUndelete = [SELECT Id FROM Client_Contract__c WHERE Id = :clientContract2.Id ALL ROWS];
        try {
            undelete clientContractToUndelete;
            System.assert(false, 'Expected validation to be raised for overlapping dates for client contracts that cover the same services');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('An existing client contract'), e.getMessage());
        }

        clientContract.End_Date__c = clientContract.Effective_Date__c - 10;
        try {
            update clientContract;
            System.assert(false, 'Expected validation to be raised for an end date before the effective date');
        } catch (Exception e) {
            System.assert(e.getMessage().contains('The end date should be after the effective date'), e.getMessage());
        }
        Test.stopTest();
    }

    @IsTest
    private static void testValidate() {
        Shared_Solar_System__c sss1 = new Shared_Solar_System__c(
            Id = Util.getFakeId(Shared_Solar_System__c.SObjectType)
        );
        Shared_Solar_System__c sss2 = new Shared_Solar_System__c(
            Id = Util.incrementFakeId(sss1.Id)
        );
        Contract managementContract = new Contract(
            Id = Util.getFakeId(Contract.SObjectType)
        );
        Contract acquisitionContract = new Contract(
            Id = Util.incrementFakeId(managementContract.Id)
        );

        Client_Contract__c clientContractForManagement = new Client_Contract__c(
            Id = Util.getFakeId(Client_Contract__c.SObjectType),
            Contract__c = managementContract.Id,
            Shared_Solar_System__c = sss1.Id,
            CS_Services_Type__c = 'Management Only',
            Effective_Date__c = System.today(),
            End_Date__c = System.today() + 30
        );

        Client_Contract__c clientContractForAcquisition = new Client_Contract__c(
            Id = Util.incrementFakeId(clientContractForManagement.Id),
            Contract__c = managementContract.Id,
            Shared_Solar_System__c = sss1.Id,
            CS_Services_Type__c = 'Acquisition Only',
            Effective_Date__c = System.today(),
            End_Date__c = System.today() + 30
        );
        System.assert(!ClientContracts.hasExisting(clientContractForManagement, clientContractForAcquisition),
            'The two client contracts are not the same because of different CS Services Types');

        clientContractForAcquisition.CS_Services_Type__c = 'Acquisition & Management';
        System.assert(ClientContracts.hasExisting(clientContractForManagement, clientContractForAcquisition),
            'The two client contracts are the same because of Acquisition & Management includes Management Only');

        clientContractForAcquisition.Shared_Solar_System__c = sss2.Id;
        System.assert(!ClientContracts.hasExisting(clientContractForManagement, clientContractForAcquisition),
            'The two client contracts are not the same because they are for different systems');

        clientContractForAcquisition.Shared_Solar_System__c = sss1.Id;
        clientContractForAcquisition.CS_Services_Type__c = 'Acquisition & Management';
        clientContractForAcquisition.Effective_Date__c = clientContractForManagement.End_Date__c + 1;
        clientContractForAcquisition.End_Date__c = clientContractForAcquisition.Effective_Date__c + 30;
        clientContractForManagement.CS_Services_Type__c = 'Acquisition & Management';
        System.assert(!ClientContracts.hasExisting(clientContractForManagement, clientContractForAcquisition),
            'The two client contracts are not the same because event though they have the same system and services type because they are for different dates');

        clientContractForAcquisition.Effective_Date__c = clientContractForManagement.End_Date__c - 1;
        clientContractForAcquisition.End_Date__c = clientContractForAcquisition.Effective_Date__c + 30;
        System.assert(ClientContracts.hasExisting(clientContractForManagement, clientContractForAcquisition),
            'The two client contracts overlap');

        clientContractForAcquisition.Effective_Date__c = clientContractForManagement.End_Date__c - 20;
        clientContractForAcquisition.End_Date__c = clientContractForAcquisition.Effective_Date__c + 10;
        System.assert(ClientContracts.hasExisting(clientContractForManagement, clientContractForAcquisition),
            'The Acquisition contract is fully within the management contract');

        clientContractForAcquisition.Effective_Date__c = clientContractForManagement.End_Date__c - 45;
        clientContractForAcquisition.End_Date__c = clientContractForAcquisition.Effective_Date__c + 30;
        System.assert(ClientContracts.hasExisting(clientContractForManagement, clientContractForAcquisition),
            'The two client contracts overlap');
    }

    @IsTest
    private static void testRegisterSystemForUpdate() {
        ClientContractService contractService = new ClientContractService();
        Shared_Solar_System__c sss = new Shared_Solar_System__c(
            Id = Util.getFakeId(Shared_Solar_System__c.SObjectType)
        );
        Contract managementContract = new Contract(
            Id = Util.getFakeId(Contract.SObjectType)
        );
        Contract acquisitionContract = new Contract(
            Id = Util.incrementFakeId(managementContract.Id)
        );

        Client_Contract__c clientContractForManagement = new Client_Contract__c(
            Contract__c = managementContract.Id,
            Shared_Solar_System__c = sss.Id,
            CS_Services_Type__c = 'Management Only'
        );
        Client_Contract__c clientContractForAcquisition = new Client_Contract__c(
            Contract__c = acquisitionContract.Id,
            Shared_Solar_System__c = sss.Id,
            CS_Services_Type__c = 'Acquisition Only'
        );
        ClientContractService.ClientContractsForSystem ccfs = new ClientContractService.ClientContractsForSystem(clientContractForManagement);
        ccfs.addClientContract(clientContractForAcquisition);
        System.assertEquals(acquisitionContract.Id, ccfs.acquisitionContractId, 'Expected the ClientContractForSystem to have the acquisition contract set');
        System.assertEquals(managementContract.Id, ccfs.managementContractId, 'Expected the ClientContractForSystem to have the management contract set');
        contractService.registerSystemForUpdate(ccfs, sss);
        List<SObject> dirtySSSes = FFLibHelperTest.getRegisterDirtyListFromUnitOfWork(ClientContractService.uow, 'Shared_Solar_System__c');
        System.assertEquals(1, dirtySSSes.size(),
            'Expected one SSS to be registered dirty, but got ' + dirtySSSes.size());
        Shared_Solar_System__c dirtySSS = (Shared_Solar_System__c) dirtySSSes[0];
        System.assertEquals(acquisitionContract.Id, dirtySSS.Client_Acquisition_Contract__c, 'Acquisition should be set for Acquisition & Management');
        System.assertEquals(managementContract.Id, dirtySSS.Client_Management_Contract__c, 'Management should be set for Acquisition & Management');
        System.assertEquals('Acquisition & Management', dirtySSS.CS_Services_Type__c);

        ClientContractService.uow = new fflib_SObjectUnitOfWork(new List<SObjectType> {Shared_Solar_System__c.SObjectType});
        sss.CS_Services_Type__c = 'Acquisition & Management';
        sss.Client_Acquisition_Contract__c = acquisitionContract.Id;
        sss.Client_Management_Contract__c = managementContract.Id;
        ccfs = new ClientContractService.ClientContractsForSystem(clientContractForManagement);
        contractService.registerSystemForUpdate(ccfs, sss);
        dirtySSSes = FFLibHelperTest.getRegisterDirtyListFromUnitOfWork(ClientContractService.uow, 'Shared_Solar_System__c');
        System.assertEquals(1, dirtySSSes.size(),
            'Expected one SSS to be registered dirty, but got ' + dirtySSSes.size());
        dirtySSS = (Shared_Solar_System__c) dirtySSSes[0];
        System.assertEquals(null, dirtySSS.Client_Acquisition_Contract__c, 'Acquisition contract should be been set to null because there is no active acq contract');
        System.assertEquals(managementContract.Id, dirtySSS.Client_Management_Contract__c, 'Management contract should still be set');
        System.assertEquals('Management Only', dirtySSS.CS_Services_Type__c, 'Services Type should get updated to Management Only');

        ClientContractService.uow = new fflib_SObjectUnitOfWork(new List<SObjectType> {Shared_Solar_System__c.SObjectType});
        sss.CS_Services_Type__c = 'Acquisition & Management';
        sss.Client_Acquisition_Contract__c = acquisitionContract.Id;
        sss.Client_Management_Contract__c = managementContract.Id;
        contractService.registerSystemForUpdate(null, sss);
        dirtySSSes = FFLibHelperTest.getRegisterDirtyListFromUnitOfWork(ClientContractService.uow, 'Shared_Solar_System__c');
        System.assertEquals(1, dirtySSSes.size(),
            'Expected one SSS to be registered dirty, but got ' + dirtySSSes.size());
        dirtySSS = (Shared_Solar_System__c) dirtySSSes[0];
        System.assertEquals(null, dirtySSS.Client_Acquisition_Contract__c, 'Acquisition contract should be been set to null because there is no active acq contract');
        System.assertEquals(null, dirtySSS.Client_Management_Contract__c, 'Management contract should be set to null because there is no active acq contract');
        System.assertEquals(null, dirtySSS.CS_Services_Type__c, 'Services Type should get set to null');
    }

    @IsTest
    private static void testScheduler() {
        Contract c = [SELECT Id FROM Contract WHERE Name = 'Test Contract' LIMIT 1];
        Shared_Solar_System__c sss = [
            SELECT Id, Client_Management_Contract__c, Client_Acquisition_Contract__c
            FROM Shared_Solar_System__c
            WHERE Name = 'Project A' LIMIT 1
        ];
        Client_Contract__c clientContract = new Client_Contract__c(
            Contract__c = c.Id,
            Shared_Solar_System__c = sss.Id,
            CS_Services_Type__c = 'Management Only',
            Effective_Date__c = System.today(),
            End_Date__c = System.today() + 60
        );
        Util.disableTrigger('Disable_ClientContractTrigger__c');
        insert clientContract;
        Util.enableTrigger('Disable_ClientContractTrigger__c');

        sss = [
            SELECT Id, Client_Management_Contract__c, Client_Acquisition_Contract__c
            FROM Shared_Solar_System__c
            WHERE Name = 'Project A' LIMIT 1
        ];
        System.assertEquals(null, sss.Client_Management_Contract__c,
            'Before running the ClientContractScheduler, we expect a blank management contract on the SSS');
        System.assertEquals(null, sss.Client_Acquisition_Contract__c,
            'Before running the ClientContractScheduler, we expect a blank management contract on the SSS');

        Test.startTest();
        System.schedule('Test ClientContract Scheduler', '0 0 0 ? * *', new ClientContractScheduler());
        Test.stopTest();

        sss = [
            SELECT Id, Client_Management_Contract__c, Client_Acquisition_Contract__c
            FROM Shared_Solar_System__c
            WHERE Name = 'Project A' LIMIT 1
        ];
        System.assertNotEquals(null, sss.Client_Management_Contract__c,
            'After running the ClientContractScheduler, we expect a populated management contract on the SSS');
        System.assertEquals(null, sss.Client_Acquisition_Contract__c,
            'After running the ClientContractScheduler, we still expect a blank management contract on the SSS, since the client contract was management only');

    }

    @IsTest
    private static void testSchedulerException() {
        ClientContractScheduler.clientContractService = (ClientContractService) Test.createStub(ClientContractService.class, new MockClientContractService());
        Test.startTest();
        System.schedule('Test ClientContract Scheduler', '0 0 0 ? * *', new ClientContractScheduler());
        Test.stopTest();
        List<Error_Log__c> errorLogs = [SELECT Message__c, Severity__c, Class__c, Method__c FROM Error_Log__c];
        System.assertEquals(1, errorLogs.size(), 'Expected the scheduler to log the exception thrown by the mock');
        System.assert(errorLogs[0].Message__c.contains('Unexpected exception'), errorLogs[0].Message__c);
    }

    /*************
      *** MOCKS ***
      *************/
    public class MockClientContractService extends MockProvider {
        public MockClientContractService() {
        }

        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'setActiveContractsOnAllSSSes' {
                    throw new Util.BWException('Unexpected exception');
                }
            }
            return null;
        }
    }
}