/**
 * @description Created by jeffparlin on 9/28/21.
 */
@IsTest
public without sharing class CSLeadsConverterTest {

    @IsTest
    private static void systemTestSuccessfulFlowInvocation() {
        // Setup environment
        setupSystemTestEnvironment();
        Utility_Account_Log__c ual = [
            SELECT Id, Lead__r.Product__c, Lead__c, Lead__r.IsConverted
            FROM Utility_Account_Log__c
            LIMIT 1
        ];
        System.assertEquals(false, ual.Lead__r.IsConverted, 'Lead should not be converted yet');
        Shared_Solar_System__c sss = [SELECT Id FROM Shared_Solar_System__c WHERE Name = 'Project A Oak Road' LIMIT 1];

        // Ensure all UALs are Complete
        ual.QC_Status__c = 'Complete';
        ual.Annual_kWh__c = 10000;
        update ual;

        // Ensure Lead has passed Qualification and is now in 'Qualified' status
        Lead leadToQualify = new Lead(
            Id = ual.Lead__c,
            Status = 'Qualified',
            LastName = 'Doe',
            Application_Complete_Date__c = System.now()
        );
        update leadToQualify;

        // Build data structure (as Flow does) to send Lead Conversion request into Apex
        LeadConvertDetail detail = new LeadConvertDetail();
        detail.leadId = ual.Lead__c;
        detail.selectedProductId = ual.Lead__r.Product__c;
        detail.selectedSystemIds = new List<Id>{
            sss.Id
        };

        // Run Conversion invocable method call
        LeadConvertDetail results;
        Test.startTest();
        results = CSLeadsConverter.invocableConvertLead(new List<LeadConvertDetail>{
            detail
        })[0];
        Test.stopTest();

        // Verify results
        System.assertEquals(null, results.errorMessage, 'No error message should be present from conversion');
        System.assert(results.errorsEncountered.isEmpty(), detail.errorsEncountered);
        System.assertEquals(null, results.error, 'No error code should be present for conversion');
        Lead leadAfterConversion = [SELECT IsConverted, Product__c FROM Lead WHERE Id = :ual.Lead__c];
        System.assertEquals(true, leadAfterConversion.IsConverted, 'Lead not successfully converted from Flow invocation');
        System.assertEquals(detail.selectedProductId, leadAfterConversion.Product__c, 'Invalid product after conversion');
    }

    @IsTest
    private static void mockTestPassingValidationOnFlowInvocation() {
        setupMockEnvironment(true);
        LeadConvertDetail detail = new LeadConvertDetail();

        // Set variables on detail object as would be injected from Lead Qualification/Conversion flow
        detail.leadId = Util.getFakeId(Lead.SObjectType);
        detail.selectedSystemIds = new List<Id>{
            Util.getFakeId(Shared_Solar_System__c.SObjectType)
        };
        detail.selectedProductId = Util.getFakeId(Product2.SObjectType);

        // Unit test validation and construction methods and verify that no errors were encountered
        CSLeadsConverter leadsConverter = new CSLeadsConverter(new List<LeadConvertDetail>{
            detail
        });
        leadsConverter.retrieveDependencies();
        leadsConverter.validateInputs();
        leadsConverter.constructConversionData();
        System.assert(detail.errorsEncountered.isEmpty(), 'Error encountered during validation');
        System.assertEquals(detail.error, null, 'Error encountered during validation');
        System.assertEquals(detail.errorMessage, null, 'Error encountered during validation');

        // Unit test getSelectedSystemIds() on CSLeadsConverter
        String parsedSystemIdsForLeadField = leadsConverter.getSelectedSystemIds(detail);
        System.assertEquals(detail.selectedSystemIds[0] + '/', parsedSystemIdsForLeadField, 'Invalid parsed system ids for lead field');
    }

    @IsTest
    private static void mockTestFailingValidationOnFlowInvocation() {
        setupMockEnvironment(false);
        LeadConvertDetail detail = new LeadConvertDetail();

        // Set variables on detail object as would be injected from Lead Qualification/Conversion flow
        detail.leadId = Util.getFakeId(Lead.SObjectType);
        detail.selectedSystemIds = new List<Id>{
            Util.getFakeId(Shared_Solar_System__c.SObjectType)
        };
        detail.selectedProductId = Util.getFakeId(Product2.SObjectType).left(14) + 1; // Mismatch on product

        // Unit test validation and construction methods and verify that no errors were encountered
        CSLeadsConverter leadsConverter = new CSLeadsConverter(new List<LeadConvertDetail>{
            detail
        });
        leadsConverter.retrieveDependencies();
        leadsConverter.validateInputs();
        leadsConverter.constructConversionData();
        System.assert(!detail.errorsEncountered.isEmpty(), 'Errors not encountered during validation');
        System.assert(detail.errorsEncountered.contains(CSLeadConversionValidator.PRODUCT_MISMATCH),
            'Should have found product mismatch error code');
        System.assert(detail.errorsEncountered.contains(CSLeadConversionValidator.INCOMPLETE_UALS),
            'Should have found UAL incomplete error code');
        System.assertEquals(detail.error, CSLeadConversionValidator.INCOMPLETE_UALS,
            'INCOMPLETE_UALS error should be present due to last error encountered during validation');
        System.assertEquals(detail.errorMessage, null, 'No extra error message should be present');
    }

    private static void setupSystemTestEnvironment() {
        CSLeadsConverter.QUEUEABLE_BATCH_SIZE = 1;
        insert new Product2(Name = 'CS Product');
        insert new Utility__c(
            Name = 'Utility with EIA ID',
            EIA_ID__c = '1234',
            Utility_Data_Collection_Mechanism__c = 'File Upload'
        );
        CSTestDataFactory dataFactory = new CSTestDataFactory();
        dataFactory.insertOpenUCBSystem();
        dataFactory.insertLeadViaAPI(false, 'None', true);
    }

    private static void setupMockEnvironment(Boolean setUalsAsComplete) {
        CSLeadsConverter.QUEUEABLE_BATCH_SIZE = 1;
        MockLeadSelector mockLeadSelector = new MockLeadSelector();
        mockLeadSelector.setUalsAsComplete = setUalsAsComplete; // set mock provider to include Incomplete UALs
        CSLeadsConverter.leadSelector = (LeadSelector) Test.createStub(LeadSelector.class, mockLeadSelector);
        CSLeadsConverter.systemsSelector = (SharedSolarSystemsSelector) Test.createStub(SharedSolarSystemsSelector.class, new MockSystemsSelector());
        CSLeadsConverter.utilitySelector = (UtilitySelector) Test.createStub(UtilitySelector.class, new MockUtilitySelector());
    }

    public class MockLeadSelector implements StubProvider {
        public Boolean setUalsAsComplete = true;
        public Map<Id, Lead> leadsToReturn = new Map<Id, Lead>();
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, System.Type returnType,
            List<System.Type> listOfParamTypes, List<String> listOfParamNames, List<Object> listOfArgs) {
            switch on stubbedMethodName {
                when 'getLeadsForConversion' {
                    Lead lead = getMockLead();
                    this.leadsToReturn.put(lead.Id, lead);
                }
            }
            return leadsToReturn;
        }
        private Lead getMockLead() {
            sfab_FabricatedSObject mockUal = new sfab_FabricatedSObject(Utility_Account_Log__c.class);
            mockUal.setField(Utility_Account_Log__c.Name, '012345678');
            mockUal.setField(Utility_Account_Log__c.Id, Util.getFakeId(Utility_Account_Log__c.SObjectType));
            mockUal.setField(Utility_Account_Log__c.QC_Status__c, setUalsAsComplete ? 'Complete' : 'Pending Utility Data');
            mockUal.setField(Utility_Account_Log__c.Annual_kWh__c, 10000);

            sfab_FabricatedSObject mockLead = new sfab_FabricatedSObject(Lead.class);
            mockLead.setField(Lead.Id, Util.getFakeId(Lead.SObjectType));
            mockLead.setField(Lead.Utility_relationship__c, Util.getFakeId(Utility__c.SObjectType));
            mockLead.setField(Lead.IsConverted, false);
            mockLead.setField(Lead.LastName, 'Doe');
            mockLead.setField(Lead.Application_Complete_Date__c, System.now());
            mockLead.setChildren('Utility_Account_Logs__r', new List<sfab_FabricatedSObject>{
                mockUal
            });

            return (Lead) mockLead.toSObject();
        }
    }

    public class MockSystemsSelector implements StubProvider {
        public List<Shared_Solar_System__c> systems = new List<Shared_Solar_System__c>();
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, System.Type returnType,
            List<System.Type> listOfParamTypes, List<String> listOfParamNames, List<Object> listOfArgs) {
            switch on stubbedMethodName {
                when 'getSharedSolarSystemsForEnrollment' {
                    systems.add(getMockSystem());
                }
            }
            return systems;
        }
        private Shared_Solar_System__c getMockSystem() {
            Id productId = Util.getFakeId(Product2.SObjectType);

            sfab_FabricatedSObject mockProduct = new sfab_FabricatedSObject(Product2.class);
            mockProduct.setField(Product2.Id, productId);
            mockProduct.setField(Product2.Customer_Subscription_Type__c, 'kWh');

            sfab_FabricatedSObject mockSystem = new sfab_FabricatedSObject(Shared_Solar_System__c.class);
            mockSystem.setField(Shared_Solar_System__c.Id, Util.getFakeId(Shared_Solar_System__c.SObjectType));
            mockSystem.setField(Shared_Solar_System__c.Name, 'Project A Oak Road');
            mockSystem.setField(Shared_Solar_System__c.Product__c, productId);
            mockSystem.setParent('Product__r', mockProduct);

            return (Shared_Solar_System__c) mockSystem.toSObject();
        }
    }

    public class MockUtilitySelector implements StubProvider {
        Map<Id, Utility__c> utilityMap = new Map<Id, Utility__c>();
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, System.Type returnType,
            List<System.Type> listOfParamTypes, List<String> listOfParamNames, List<Object> listOfArgs) {
            switch on stubbedMethodName {
                when 'getAllUtilitiesMap' {
                    sfab_FabricatedSObject mockUtility = new sfab_FabricatedSObject(Utility__c.class);
                    mockUtility.setField(Utility__c.Id, Util.getFakeId(Utility__c.SObjectType));
                    mockUtility.setField(Utility__c.Average_Demand_Threshold__c, 25);
                    mockUtility.setField(Utility__c.Auto_Qualify_Convert_Active__c, true);
                    Utility__c utility = (Utility__c) mockUtility.toSObject();
                    utilityMap.put(utility.Id, utility);
                }
            }
            return utilityMap;
        }
    }
}