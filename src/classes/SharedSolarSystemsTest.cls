/**
 * Created by peteryao on 8/5/20.
 */
@IsTest
public with sharing class SharedSolarSystemsTest {
    @IsTest
    private static void testRecalculateMaximumSubscriptionCapacityForNonSMART() {
        SharedSolarSystems.productSelector = (ProductSelector) Test.createStub(ProductSelector.class, new MockProductSelector(true));
        List<Shared_Solar_System__c> sharedSolarSystems = new List<Shared_Solar_System__c>{new Shared_Solar_System__c()};
        try {
            new SharedSolarSystems(sharedSolarSystems).calculateMaximumSubscriptionCapacityForSMART();
            System.assert(true, 'We should not have thrown an exception trying to calculate max capacity with null values');
        } catch (Exception e) {
            System.assert(false, e.getMessage() + '\n' + e.getStackTraceString());
        }
    }

    @IsTest
    private static void testRecalculateMaximumSubscriptionCapacityIncludingSMART() {
        SharedSolarSystems.productSelector = (ProductSelector) Test.createStub(ProductSelector.class, new MockProductSelector(false));
        Shared_Solar_System__c smartSystem = new Shared_Solar_System__c(
            Name = 'SMART',
            Product__c = Util.getFakeId(Product2.SObjectType),
            Total_System_Size_kWh_DC__c = 100,
            Total_System_Size_kW_AC__c = 50
        );
        Shared_Solar_System__c smartSystemNoDC = new Shared_Solar_System__c(
            Name = 'SMART No DC',
            Product__c = Util.getFakeId(Product2.SObjectType),
            Total_System_Size_kW_AC__c = 50
        );
        Shared_Solar_System__c nonSMARTSystem = new Shared_Solar_System__c(
            Name = 'Dumb',
            Product__c = Util.incrementFakeId(smartSystem.Product__c),
            Total_System_Size_kWh_DC__c = 100,
            Total_System_Size_kW_AC__c = 50
        );
        List<Shared_Solar_System__c> sharedSolarSystems = new List<Shared_Solar_System__c>{smartSystem, smartSystemNoDC, nonSMARTSystem};
        try {
            new SharedSolarSystems(sharedSolarSystems).calculateMaximumSubscriptionCapacityForSMART();
        } catch (Exception e) {
            System.assert(false, e.getMessage() + '\n' + e.getStackTraceString());
        }
        for (Shared_Solar_System__c sss : sharedSolarSystems) {
            if (sss.Name == 'SMART') {
                System.assertEquals(25 * (100/50), sss.Maximum_Subscription_Capacity_kWDC__c, 'Expected to set Max Capacity for SMART');
            }
            if (sss.Name == 'Dumb' || sss.Name == 'SMART No DC') {
                System.assertEquals(null, sss.Maximum_Subscription_Capacity_kWDC__c, 'Expected to have to set Max Capacity manually');
            }
        }
    }
    @IsTest
    private static void testUpdateManagementRevenueStartDate() {
        Date ptoDate = Date.newInstance(2020,1,1);
        Date codDate = Date.newInstance(2020,1,1);
        Date assignmentDate = Date.newInstance(2020,1,1);
        Date billDate = Date.newInstance(2020,2,1);
        Shared_Solar_System__c ptoSystemWithPTOTrigger = new Shared_Solar_System__c(
            Id = Util.getFakeId(Shared_Solar_System__c.SObjectType),
            Name = 'PTO System With PTO Trigger',
            Client_Management_Contract__c = Util.getFakeId(Contract.SObjectType),
            Actual_PTO_Date_MANUAL__c = ptoDate
        );
        Shared_Solar_System__c codSystemWithPTOTrigger = new Shared_Solar_System__c(
            Id = Util.incrementFakeId(ptoSystemWithPTOTrigger.Id),
            Name = 'COD System With PTO Trigger',
            Client_Management_Contract__c = Util.getFakeId(Contract.SObjectType),
            Actual_COD_Date__c = codDate
        );
        Shared_Solar_System__c firstAssignAndBillSystemWithTrigger = new Shared_Solar_System__c(
            Id = Util.incrementFakeId(codSystemWithPTOTrigger.Id),
            Name = 'First Customer Assigned and Billed with Triggers',
            Client_Management_Contract__c = Util.incrementFakeId(ptoSystemWithPTOTrigger.Client_Management_Contract__c),
            Customer_Assignment_Date__c = assignmentDate,
            First_Bill_Date__c = billDate
        );
        Shared_Solar_System__c systemWithNoManagementContract = new Shared_Solar_System__c(
            Id = Util.incrementFakeId(firstAssignAndBillSystemWithTrigger.Id),
            Name = 'No Management Contract',
            Customer_Assignment_Date__c = assignmentDate,
            First_Bill_Date__c = billDate
        );
        Shared_Solar_System__c codSystemWithCODTrigger = new Shared_Solar_System__c(
            Id = Util.incrementFakeId(systemWithNoManagementContract.Id),
            Name = 'COD System With COD Trigger',
            Client_Management_Contract__c = codSystemWithPTOTrigger.Client_Management_Contract__c,
            Actual_COD_Date__c = codDate
        );
        List<Shared_Solar_System__c> mockSharedSolarSystems = new List<Shared_Solar_System__c>{
            ptoSystemWithPTOTrigger,
            codSystemWithPTOTrigger,
            firstAssignAndBillSystemWithTrigger,
            systemWithNoManagementContract,
            codSystemWithCODTrigger
        };
        SharedSolarSystems.contractFeeDetailSelector =
            (ContractFeeDetailSelector) Test.createStub(ContractFeeDetailSelector.class, new MockContractFeeDetailSelector(codSystemWithCODTrigger.Id));
        try {
            fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
                new List<SObjectType>{Shared_Solar_System__c.SObjectType},
                new FFLibHelperTest.MockDML()
            );
            new SharedSolarSystems(mockSharedSolarSystems).updateManagementRevenueStartDate(uow);
        } catch (Exception e) {
            System.assert(false, e.getMessage() + '\n' + e.getStackTraceString());
        }
        System.assertEquals(ptoDate, ptoSystemWithPTOTrigger.Management_Revenue_Start_Date__c,
            'The mock should return a CFD with a PTO trigger for a system with a PTO date');
        System.assertEquals(null, codSystemWithPTOTrigger.Management_Revenue_Start_Date__c,
            'A system with a COD date and no PTO date should not have a CFD with that trigger');
        System.assertEquals(DateUtil.min(assignmentDate, billDate), firstAssignAndBillSystemWithTrigger.Management_Revenue_Start_Date__c,
            'If there are multiple management CFDs, we should evaluate all of them and choose the earlier date');
        System.assertEquals(null, systemWithNoManagementContract.Management_Revenue_Start_Date__c,
            'A system with no management contract should not get a revenue start date');
        System.assertNotEquals(null, codSystemWithCODTrigger.Management_Revenue_Start_Date__c,
            'COD System with COD Trigger should have a Revenue Start Date set because of a system specific CFD');
    }

    @TestVisible
    private static List<Partner_Shared_Solar_System_Eligibility__c> getPartnerEligibilities(Shared_Solar_System__c sharedSolarSystem, Account partnerAccount) {
        return getPartnerEligibilities(new List<Shared_Solar_System__c>{sharedSolarSystem}, new List<Account>{partnerAccount});
    }

    @TestVisible
    private static List<Partner_Shared_Solar_System_Eligibility__c> getPartnerEligibilities(List<Shared_Solar_System__c> sharedSolarSystems, List<Account> partnerAccounts) {
        List<Partner_Shared_Solar_System_Eligibility__c> partnerSharedSolarSystemEligibilities =
            new List<Partner_Shared_Solar_System_Eligibility__c>();
        for (Shared_Solar_System__c sss : sharedSolarSystems) {
            for (Account partnerAccount : partnerAccounts) {
                partnerSharedSolarSystemEligibilities.add(new Partner_Shared_Solar_System_Eligibility__c(
                    Shared_Solar_System__c = sss.Id,
                    Account__c = partnerAccount.Id,
                    Active__c = true
                ));
            }
        }
        return partnerSharedSolarSystemEligibilities;
    }

    /*************
      *** MOCKS ***
      *************/
    public class MockProductSelector extends MockProvider {
        private Boolean returnEmpty;
        public MockProductSelector(Boolean returnEmpty) {
            this.returnEmpty = returnEmpty;
        }
        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'selectForACToDCConversion' {
                    if (returnEmpty) {
                        return new List<Product2>();
                    } else {
                        Product2 smartProduct = new Product2(
                            Id = Util.getFakeId(Product2.SObjectType),
                            Max_Subscription_kW_AC_for_DC_calc__c = 25
                        );
                        return new List<Product2>{smartProduct};
                    }
                }
            }
            return null;
        }
    }
    public class MockContractFeeDetailSelector extends MockProvider {
        Id systemSpecificCFDId;
        public MockContractFeeDetailSelector(String sssId) {
            this.systemSpecificCFDId = sssId;
        }

        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'getContractDetailFromContract' {
                    Contract_Fee_Detail__c cfdPTO = new Contract_Fee_Detail__c(
                        Contract__c = Util.getFakeId(Contract.SObjectType),
                        Management_Fee__c = true,
                        Management_Fee_Type__c = 'Recurring',
                        Management_Fee_Trigger__c = 'Project: PTO'
                    );
                    Contract_Fee_Detail__c cfdCustomerAssigned = new Contract_Fee_Detail__c(
                        Contract__c = Util.incrementFakeId(cfdPTO.Contract__c),
                        Management_Fee__c = true,
                        Management_Fee_Type__c = 'Recurring',
                        Management_Fee_Trigger__c = 'Project: First Customer Assignment Date'
                    );
                    Contract_Fee_Detail__c cfdFirstBilled = new Contract_Fee_Detail__c(
                        Contract__c = cfdCustomerAssigned.Contract__c,
                        Management_Fee__c = true,
                        Management_Fee_Type__c = 'Recurring',
                        Management_Fee_Trigger__c = 'Project: First Customer Bill Date'
                    );
                    Contract_Fee_Detail__c cfdCODForSSS = new Contract_Fee_Detail__c(
                        Contract__c = Util.getFakeId(Contract.SObjectType),
                        Management_Fee__c = true,
                        Management_Fee_Type__c = 'Recurring',
                        Management_Fee_Trigger__c = 'Project: COD',
                        Shared_Solar_System__c = systemSpecificCFDId
                    );
                    return new List<Contract_Fee_Detail__c>{cfdPTO, cfdCustomerAssigned, cfdFirstBilled, cfdCODForSSS};
                }
            }
            return null;
        }
    }
}