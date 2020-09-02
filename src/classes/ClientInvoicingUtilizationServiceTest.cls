/**
 * Created by peteryao on 8/30/20.
 */
@IsTest
public with sharing class ClientInvoicingUtilizationServiceTest {
    @TestSetup
    public static void setupTestData() {
        ProductionDetailSelectorTest.setupTestData();
    }

    @IsTest
    public static void testCreateMemosForUtilizationAdjustments() {
        List<Transfer_Part__c> productionDetailsNeedingContracts = [
            SELECT Id, Production__r.Shared_Solar_System__r.Name, Production__r.Shared_Solar_System__r.Client_Management_Contract__c,
                Change_in_Utilization__c
            FROM Transfer_Part__c
            WHERE Change_in_Utilization__c < 0
            AND Production__r.Shared_Solar_System__r.Name = 'Test Project'
        ];

        System.assertEquals(1, productionDetailsNeedingContracts.size(),
            'Expected setup to create one PD with utilization change, but got this: ' + productionDetailsNeedingContracts);
        System.assertEquals(null, productionDetailsNeedingContracts[0].Production__r.Shared_Solar_System__r.Client_Management_Contract__c,
            'Expected the system related to the PD to not be assigned to a Client Contract yet');

        assignManagementContractToSSS(productionDetailsNeedingContracts);

        productionDetailsNeedingContracts = [
            SELECT Id, Production__r.Shared_Solar_System__c, Production__r.Shared_Solar_System__r.Client_Management_Contract__c
            FROM Transfer_Part__c
            WHERE Change_in_Utilization__c < 0
            AND Production__r.Shared_Solar_System__r.Name = 'Test Project'
        ];

        System.assertNotEquals(null, productionDetailsNeedingContracts[0].Production__r.Shared_Solar_System__r.Client_Management_Contract__c,
            'Expected the system to be assigned to a management contract');

        Test.startTest();
        List<Client_Invoicing_Memo__c> clientInvoicingMemos =
            new ClientInvoicingUtilizationService().createMemosForUtilizationAdjustments();
        System.assertEquals(1, clientInvoicingMemos.size(),
            'Expected one client invoicing memo for the production detail with the change in utilization');
        System.assertEquals(-44.82, clientInvoicingMemos[0].Amount__c,
            'Expected to get change in utilization * monthly management fee * utilization adjustment multiplier ' + clientInvoicingMemos[0].Details__c);

        ClientInvoicingUtilizationService.uow = new fflib_SObjectUnitOfWork(
            new List<SObjectType>{Client_Invoicing_Memo__c.SObjectType}
        );
        clientInvoicingMemos =
            new ClientInvoicingUtilizationService().createMemosForUtilizationAdjustments();
        System.assertEquals(0, clientInvoicingMemos.size(),
            'Expected no new memos to be created since there is already a client memo for the production detail');
        Test.stopTest();
    }

    @IsTest
    public static void testMemosReachingFloor() {
        Contract_Fee_Detail__c cfd = getContractFeeDetail();
        cfd.Fee__c = cfd.Fee__c / 1000000; // $/MW * 1MW/1000kW * 1kW/1000W
        cfd.Fee_Unit__c ='per W';
        Transfer_Part__c productionDetail = getProductionDetail(-99.9999);

        Test.startTest();
        ClientInvoicingUtilizationService.UtilizationFeeInput utilizationFeeInput =
            new ClientInvoicingUtilizationService.UtilizationFeeInput(cfd, productionDetail);
        System.assertEquals(-429.35, utilizationFeeInput.getUtilizationFee(),
            'Expected the fee to be capped at half of the management fee because of the 50% floor');
        Test.stopTest();
    }

    @IsTest
    public static void testMemosForFixedAmount() {
        Contract_Fee_Detail__c cfd = getContractFeeDetail();
        cfd.Utilization_Adjustment_Type__c = 'Amount ($)';
        cfd.Utilization_Adjustment_Amount__c = 50;
        Transfer_Part__c productionDetail = getProductionDetail(-2);

        Test.startTest();
        ClientInvoicingUtilizationService.UtilizationFeeInput utilizationFeeInput =
            new ClientInvoicingUtilizationService.UtilizationFeeInput(cfd, productionDetail);
        System.assertEquals(-100, utilizationFeeInput.getUtilizationFee(),
            'Expected the fee to be 2 * $50');
        Test.stopTest();
    }

    @IsTest
    public static void testMemosPositiveAdjustments() {
        Contract_Fee_Detail__c cfd = getContractFeeDetail();
        cfd.Utilization_Adjustment_Type__c = 'Amount ($)';
        cfd.Utilization_Adjustment_Amount__c = 50;
        Transfer_Part__c productionDetail = getProductionDetail(100);

        Test.startTest();
        ClientInvoicingUtilizationService.UtilizationFeeInput utilizationFeeInput =
            new ClientInvoicingUtilizationService.UtilizationFeeInput(cfd, productionDetail);
        System.assertEquals(5000, utilizationFeeInput.getUtilizationFee(),
            'Expected the fee to be 100 * $50');
        Test.stopTest();
    }

    @IsTest
    public static void testInvocable() {
        InvocableClientUtilization.clientInvoicingUtilizationService =
            (ClientInvoicingUtilizationService) Test.createStub(ClientInvoicingUtilizationService.class, new MockUtilizationService());
        try {
            InvocableClientUtilization.createMemosForUtilizationAdjustments();
            System.assert(true, 'Expected to call the utilization service without exception');
        } catch (Exception e) {
            System.assert(false, e.getMessage() + '\n' + e.getStackTraceString());
        }
    }

    private static Contract_Fee_Detail__c getContractFeeDetail() {
        Contract_Fee_Detail__c cfd = new Contract_Fee_Detail__c(
            Management_Fee__c = true,
            Utilization_Adjustment_Type__c = 'Multiplier (%)',
            Fee__c = 10790,
            Fee_Unit__c = 'per MW',
            Utilization_Adjustment_Multiplier__c = 2,
            Utilization_Adjustment_Floor__c = 50
        );
        return cfd;
    }

    private static Transfer_Part__c getProductionDetail(Decimal changeInUtilization) {
        Map<SObjectField, Object> sssValues = new Map<SObjectField, Object>{
            Shared_Solar_System__c.Id => Util.getFakeId(Shared_Solar_System__c.SObjectType),
            Shared_Solar_System__c.Name => 'Test Project',
            Shared_Solar_System__c.Serviced_Capacity__c => 955
        };
        Map<SObjectField, Object> productionValues = new Map<SObjectField, Object>{
            Production__c.Id => Util.getFakeId(Production__c.SObjectType)
        };
        Map<SObjectField, Object> productionDetailValues = new Map<SObjectField, Object>{
            Transfer_Part__c.Id => Util.getFakeId(Transfer_Part__c.SObjectType),
            Transfer_Part__c.Change_in_Utilization__c => changeInUtilization
        };
        sfab_FabricatedSObject fabbedSSS = new sfab_FabricatedSObject(Shared_Solar_System__c.class, sssValues);
        sfab_FabricatedSObject fabbedProduction = new sfab_FabricatedSObject(Production__c.class, productionValues);
        sfab_FabricatedSObject fabbedProductionDetail = new sfab_FabricatedSObject(Transfer_Part__c.class, productionDetailValues);
        fabbedProductionDetail.setParent('Production__r', fabbedProduction);
        fabbedProduction.setParent('Shared_Solar_System__r', fabbedSSS);
        Transfer_Part__c productionDetail = (Transfer_Part__c) fabbedProductionDetail.toSObject();
        return productionDetail;
    }

    private static void assignManagementContractToSSS(List<Transfer_Part__c> productionDetailsNeedingContracts) {
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
            new List<SObjectType>{
                Account.SObjectType,
                Contract.SObjectType,
                Contract_Fee_Detail__c.SObjectType,
                Shared_Solar_System__c.SObjectType
            }
        );
        Account clientAccount = new Account(Name = 'Client Account');
        uow.registerNew(clientAccount);

        RecordType clientRT = [SELECT Id FROM RecordType WHERE Name = 'Client Contract' LIMIT 1];
        Contract contractA = new Contract(
            Name = 'Client Contract A',
            AccountId = clientAccount.Id,
            RecordTypeId = clientRT.Id
        );
        uow.registerNew(contractA, Contract.AccountId, clientAccount);

        Contract_Fee_Detail__c cfdAOne = new Contract_Fee_Detail__c(
            Contract__c = contractA.Id,
            Management_Fee__c = true,
            Management_Fee_Type__c = 'Recurring',
            Recurring_Frequency__c = 'Monthly',
            Utilization_Adjustment_Type__c = 'Multiplier (%)',
            Utilization_Adjustment_Multiplier__c = 2,
            Fee__c = 10790,
            Fee_Unit__c = 'per MW'
        );
        uow.registerNew(cfdAOne, Contract_Fee_Detail__c.Contract__c, contractA);

        Shared_Solar_System__c sss = new Shared_Solar_System__c(
            Id = productionDetailsNeedingContracts[0].Production__r.Shared_Solar_System__c,
            Total_System_Size_kWh_DC__c = 955,
            Client_Management_Contract__c = contractA.Id
        );
        uow.registerDirty(sss, Shared_Solar_System__c.Client_Management_Contract__c, contractA);
        uow.commitWork();
    }

    public class MockUtilizationService extends MockProvider {
    }
}