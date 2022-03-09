/**
 * @description Created by peteryao on 8/5/20.
 */
@IsTest
public with sharing class SharedSolarSystemsTest {

    @IsTest
    private static void testRecalculateMaximumSubscriptionCapacityForNonSMART() {
        SharedSolarSystemCapacityCalculator.productSelector = (ProductSelector) Test.createStub(ProductSelector.class, new MockProductSelector(true));
        List<Shared_Solar_System__c> sharedSolarSystems = new List<Shared_Solar_System__c>{
            new Shared_Solar_System__c()
        };
        try {
            new SharedSolarSystemCapacityCalculator().calculateMaximumSubscriptionCapacityForSMART(sharedSolarSystems);
            System.assert(true, 'We should not have thrown an exception trying to calculate max capacity with null values');
        } catch (Exception e) {
            System.assert(false, e.getMessage() + '\n' + e.getStackTraceString());
        }
    }

    @IsTest
    private static void testRecalculateMaximumSubscriptionCapacityIncludingSMART() {
        SharedSolarSystemCapacityCalculator.productSelector = (ProductSelector) Test.createStub(ProductSelector.class, new MockProductSelector(false));
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
        List<Shared_Solar_System__c> sharedSolarSystems = new List<Shared_Solar_System__c>{
            smartSystem, smartSystemNoDC, nonSMARTSystem
        };
        try {
            new SharedSolarSystemCapacityCalculator().calculateMaximumSubscriptionCapacityForSMART(sharedSolarSystems);
        } catch (Exception e) {
            System.assert(false, e.getMessage() + '\n' + e.getStackTraceString());
        }
        for (Shared_Solar_System__c sss : sharedSolarSystems) {
            if (sss.Name == 'SMART') {
                System.assertEquals(25 * (100 / 50), sss.Maximum_Subscription_Capacity_kWDC__c, 'Expected to set Max Capacity for SMART');
            }
            if (sss.Name == 'Dumb' || sss.Name == 'SMART No DC') {
                System.assertEquals(null, sss.Maximum_Subscription_Capacity_kWDC__c, 'Expected to have to set Max Capacity manually');
            }
        }
    }

    @IsTest
    private static void testUpdateManagementRevenueStartDate() {
        Date ptoDate = Date.newInstance(2020, 1, 1);
        Date codDate = Date.newInstance(2020, 1, 1);
        Date assignmentDate = Date.newInstance(2020, 1, 1);
        Date billDate = Date.newInstance(2020, 2, 1);
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
        SharedSolarSystemInvoicer.contractFeeDetailSelector =
            (ContractFeeDetailSelector) Test.createStub(ContractFeeDetailSelector.class, new MockContractFeeDetailSelector(codSystemWithCODTrigger.Id));
        try {
            fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
                new List<SObjectType>{
                    Shared_Solar_System__c.SObjectType
                },
                new FFLibHelperTest.MockDML()
            );
            new SharedSolarSystemInvoicer().updateManagementRevenueStartDate(uow, mockSharedSolarSystems);
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

    @IsTest
    private static void testMeetsUnderwritingCriteria() {
        SharedSolarSystemQualifier sharedSolarSystemQualifier = new SharedSolarSystemQualifier();
        Shared_Solar_System__c sss = new Shared_Solar_System__c(
            Available_SMB_Underwriting_Method_FICO__c = true,
            Available_SMB_Underwriting_Method_Docs__c = true,
            Credit_Score_Requirement__c = 750,
            RiskCalc_Minimum__c = 'Ba3'
        );

        // 800 FICO Lead
        Lead fico800Lead = getLead('FICO', '800', null);
        Boolean fico800LeadQualifies = sharedSolarSystemQualifier.meetsUnderwritingCriteria(
            fico800Lead, sss, fico800Lead.LASER_Credit_Score__c
        );
        System.assertEquals(true, fico800LeadQualifies,
            'lead with FICO of 800 should meet underwriting for a system with FICO min of 750');

        // 700 FICO Lead
        Lead fico700Lead = getLead('FICO', '700', null);
        Boolean fico700LeadQualifies = sharedSolarSystemQualifier.meetsUnderwritingCriteria(
            fico700Lead, sss, fico700Lead.LASER_Credit_Score__c
        );
        System.assertEquals(false, fico700LeadQualifies,
            'lead with FICO of 700 should NOT meet underwriting for a system with FICO min of 750'
        );

        sss.Available_SMB_Underwriting_Method_FICO__c = false;

        // 800 FICO Lead on System with Fin Docs Underwriting (not FICO)
        fico800LeadQualifies = sharedSolarSystemQualifier.meetsUnderwritingCriteria(
            fico800Lead, sss, fico800Lead.LASER_Credit_Score__c);
        System.assertEquals(false, fico800LeadQualifies,
            'lead with FICO of 800 should not meet underwriting for a system that is not available to qualify for FICO'
        );

        // Moody Aaa Lead
        Lead moodysAaaLead = getLead('Financial Review', null, 'Aaa');
        Boolean moodysAaaQualifies = sharedSolarSystemQualifier.meetsUnderwritingCriteria(
            moodysAaaLead, sss, moodysAaaLead.LASER_Credit_Score__c
        );
        System.assertEquals(true, moodysAaaQualifies,
            'Finanical Review lead with a Moody\'s of Aaa should meet underwriting for a system with RiskCalc min of Ba3'
        );

        // Moody Ba3 Lead
        Lead moodysBa3Lead = getLead('Financial Review', null, 'Ba3');
        Boolean moodysBa3LeadQualifies = sharedSolarSystemQualifier.meetsUnderwritingCriteria(
            moodysBa3Lead, sss, moodysBa3Lead.LASER_Credit_Score__c
        );
        System.assertEquals(true, moodysBa3LeadQualifies,
            'Finanical Review lead with a Moody\'s of Ba3 should meet underwriting for a system with RiskCalc min of Ba3'
        );

        // Moody C1 Lead
        Lead moodysC1Lead = getLead('Financial Review', null, 'C1');
        Boolean moodysC1LeadQualifies = sharedSolarSystemQualifier.meetsUnderwritingCriteria(
            moodysC1Lead, sss, moodysC1Lead.LASER_Credit_Score__c
        );
        System.assertEquals(false, moodysC1LeadQualifies,
            'Finanical Review lead with a Moody\'s of C1 should not meet underwriting for a system with RiskCalc min of Ba3'
        );

        sss.Available_SMB_Underwriting_Method_Docs__c = false;

        // Disable Financial Docs Underwriting
        moodysAaaQualifies = sharedSolarSystemQualifier.meetsUnderwritingCriteria(
            moodysAaaLead, sss, moodysAaaLead.LASER_Credit_Score__c
        );
        System.assertEquals(false, moodysAaaQualifies,
            'Finanical Review lead with a Moody\'s of Aaa should not meet underwriting for a system that is not available to qualify');
    }

    /**
     * @description MOCKS AND HELPER METHODS ***
     **/
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
                        return new List<Product2>{
                            smartProduct
                        };
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
                    return new List<Contract_Fee_Detail__c>{
                        cfdPTO, cfdCustomerAssigned, cfdFirstBilled, cfdCODForSSS
                    };
                }
            }
            return null;
        }
    }

    private static Lead getLead(String underwritingCriteria, String creditScore, String moodys) {
        sfab_FabricatedSObject fabbedLead = new sfab_FabricatedSObject(Lead.class);
        fabbedLead.setField(Lead.Underwriting_Criteria__c, underwritingCriteria);
        fabbedLead.setField(Lead.LASER_Credit_Score__c, creditScore);
        fabbedLead.setField(Lead.Moody_s_Risk_Calc__c, moodys);
        return (Lead) fabbedLead.toSObject();
    }

    @TestVisible
    private static List<Partner_Shared_Solar_System_Eligibility__c> getPartnerEligibilities(
        Shared_Solar_System__c sharedSolarSystem, Account partnerAccount)
    {
        return getPartnerEligibilities(new List<Shared_Solar_System__c>{
            sharedSolarSystem
        }, new List<Account>{
            partnerAccount
        });
    }

    @TestVisible
    private static List<Partner_Shared_Solar_System_Eligibility__c> getPartnerEligibilities(
        List<Shared_Solar_System__c> sharedSolarSystems, List<Account> partnerAccounts)
    {
        Map<String, Commission_Structure__c> commissionStructureMap = getCommissionStructures(sharedSolarSystems, partnerAccounts);
        List<Partner_Shared_Solar_System_Eligibility__c> partnerSharedSolarSystemEligibilities =
            new List<Partner_Shared_Solar_System_Eligibility__c>();
        for (Shared_Solar_System__c sss : sharedSolarSystems) {
            for (Account partnerAccount : partnerAccounts) {
                String csKey = partnerAccount.Id + '-' + sss.Product__c;
                partnerSharedSolarSystemEligibilities.add(new Partner_Shared_Solar_System_Eligibility__c(
                    Shared_Solar_System__c = sss.Id,
                    Account__c = partnerAccount.Id,
                    Commission_Structure__c = commissionStructureMap.get(csKey).Id,
                    Start_Date__c = Date.newInstance(2020, 1, 1)
                ));
            }
        }
        return partnerSharedSolarSystemEligibilities;
    }

    @TestVisible
    private static Map<String, Commission_Structure__c> getCommissionStructures(
        List<Shared_Solar_System__c> sharedSolarSystems, List<Account> partnerAccounts)
    {
        Map<String, Commission_Structure__c> commissionStructureMap = new Map<String, Commission_Structure__c>();
        Set<Id> productIds = new Set<Id>();
        for (Shared_Solar_System__c sss : sharedSolarSystems) {
            productIds.add(sss.Product__c);
        }

        for (Account partner : partnerAccounts) {
            for (Id product : productIds) {
                String mapKey = partner.Id + '-' + product;
                Commission_Structure__c commissionStructure = new Commission_Structure__c(
                    Name = 'Test Commission Structure',
                    Cents_kW_DC_First_Bill__c = 0.03,
                    Cents_kW_DC_Up_Front__c = 0.08,
                    Cents_kW_DC_First_Bill_Paid__c = 0.02,
                    Partner_Account__c = partner.Id,
                    Product__c = product,
                    Type__c = 'Variable by kW'
                );
                commissionStructureMap.put(mapKey, commissionStructure);
            }
        }

        insert commissionStructureMap.values();
        return commissionStructureMap;
    }

    @IsTest
    private static void systemsShouldSortByApplicationTypeThenByCODOrAssignmentOrder() {
        sfab_FabricatedSObject fabbedSSS1 = new sfab_FabricatedSObject(Shared_Solar_System__c.class);
        fabbedSSS1.setField(Shared_Solar_System__c.Name, 'SSS1');
        fabbedSSS1.setField(Shared_Solar_System__c.Assignment_Order__c, 1);
        fabbedSSS1.setField(Shared_Solar_System__c.Estimated_COD_Date_Manual__c, Date.newInstance(2022,1,1));
        fabbedSSS1.setField(Shared_Solar_System__c.Project_Capacity_Available_kW_DC__c, 1000);
        fabbedSSS1.setField(Shared_Solar_System__c.Capacity_Available_to_be_Reserved__c, 100);
        fabbedSSS1.setField(Shared_Solar_System__c.Perch_Acq_Available_LMI_Capacity__c, 1000);

        sfab_FabricatedSObject fabbedSSS2 = new sfab_FabricatedSObject(Shared_Solar_System__c.class);
        fabbedSSS2.setField(Shared_Solar_System__c.Name, 'SSS2');
        fabbedSSS2.setField(Shared_Solar_System__c.Assignment_Order__c, 2);
        fabbedSSS2.setField(Shared_Solar_System__c.Estimated_COD_Date_Manual__c, Date.newInstance(2022,1,1));
        fabbedSSS2.setField(Shared_Solar_System__c.Project_Capacity_Available_kW_DC__c, 100);
        fabbedSSS2.setField(Shared_Solar_System__c.Capacity_Available_to_be_Reserved__c, 100);
        fabbedSSS2.setField(Shared_Solar_System__c.Perch_Acq_Available_LMI_Capacity__c, 100);


        sfab_FabricatedSObject fabbedSSS3 = new sfab_FabricatedSObject(Shared_Solar_System__c.class);
        fabbedSSS3.setField(Shared_Solar_System__c.Name, 'SSS3');
        fabbedSSS3.setField(Shared_Solar_System__c.Assignment_Order__c, 3);
        fabbedSSS3.setField(Shared_Solar_System__c.Estimated_COD_Date_Manual__c, Date.newInstance(2021,12,1));
        fabbedSSS3.setField(Shared_Solar_System__c.Project_Capacity_Available_kW_DC__c, 100);
        fabbedSSS3.setField(Shared_Solar_System__c.Capacity_Available_to_be_Reserved__c, 100);
        fabbedSSS3.setField(Shared_Solar_System__c.Perch_Acq_Available_LMI_Capacity__c, 0);

        List<SharedSolarSystemQualifier.SortedSystem> systemsToSort = new List<SharedSolarSystemQualifier.SortedSystem>();
        systemsToSort.add(new SharedSolarSystemQualifier.SortedSystem((Shared_Solar_System__c) fabbedSSS2.toSObject(), 'Automatic - Assignment Order'));
        systemsToSort.add(new SharedSolarSystemQualifier.SortedSystem((Shared_Solar_System__c) fabbedSSS1.toSObject(), 'Automatic - Assignment Order'));
        systemsToSort.sort();

        System.assertEquals('SSS1', systemsToSort[0].sss.Name, 'Expected SSS1 to be sorted first by assignment order');
        System.assertEquals('SSS2', systemsToSort[1].sss.Name, 'Expected SSS2 to be sorted second by assignment order');

        systemsToSort = new List<SharedSolarSystemQualifier.SortedSystem>();
        systemsToSort.add(new SharedSolarSystemQualifier.SortedSystem((Shared_Solar_System__c) fabbedSSS1.toSObject(), 'Automatic - COD Date/Available Capacity'));
        systemsToSort.add(new SharedSolarSystemQualifier.SortedSystem((Shared_Solar_System__c) fabbedSSS2.toSObject(), 'Automatic - COD Date/Available Capacity'));
        systemsToSort.add(new SharedSolarSystemQualifier.SortedSystem((Shared_Solar_System__c) fabbedSSS3.toSObject(), 'Automatic - COD Date/Available Capacity'));
        systemsToSort.sort();

        System.assertEquals('SSS3', systemsToSort[0].sss.Name, 'Expected SSS3 to be sorted first because it has the oldest COD');
        System.assertEquals('SSS2', systemsToSort[1].sss.Name, 'Expected SSS2 to be sorted second because it has the smallest Available Capacity');
        System.assertEquals('SSS1', systemsToSort[2].sss.Name, 'Expected SSS1 to be sorted last because it has the largest Available Capacity');
    }
}