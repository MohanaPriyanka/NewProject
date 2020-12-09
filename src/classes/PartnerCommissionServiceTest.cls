@isTest
public class PartnerCommissionServiceTest {
    @IsTest
    private static void testContractExecution(){
        useMocks();

        PartnerCommissionService.PendingCommission pendingComm = new PartnerCommissionService.PendingCommission();
        pendingComm.opportunitiesToRun = getOpportunityMockForContractExecutionType();
        pendingComm.typeOfCommission = PartnerCommissionService.CommissionType.CONTRACTEXECUTION;

        /*
            10 Opportunities total:

            1 Opportunity is assigned a different Partner that does not have a Partner_Shared_Solar_System_Eligibility__c
            Will result in a case because Partner does not have access to Shared Solar System

            1 Opportunity is assigned a different SSS that has a Partner_Shared_Solar_System_Eligibility__c
            with a different Commission Structure.

            2 opportunities already have pending payments (which should update instead of insert)
            1 opportunity already has CS_Capacity_Allocated__c populated and should not be updated
        */

        System.assertEquals(10,pendingComm.opportunitiesToRun.size());
        for (Opportunity opp : pendingComm.opportunitiesToRun) {
            System.assertEquals(null,opp.Commission_Structure__c);
        }

        Test.startTest();
        PartnerCommissionService service = new PartnerCommissionService();
        service.calculateCommissionRecords(pendingComm);
        Test.stopTest();

        List<Opportunity> opportunitiesToUpdate = (List<Opportunity>)
            FFLibHelperTest.getRegisterDirtyListFromUnitOfWork(service.uow, 'Opportunity');
        List<Case> casesToInsert = (List<Case>)
            FFLibHelperTest.getRegisterNewListFromUnitOfWork(service.uow, 'Case');
        List<Commission_Payment__c> commissionPaymentRecordsToInsert = (List<Commission_Payment__c>)
            FFLibHelperTest.getRegisterNewListFromUnitOfWork(service.uow, 'Commission_Payment__c');
        List<Commission_Payment__c> commissionPaymentRecordsToUpdate = (List<Commission_Payment__c>)
            FFLibHelperTest.getRegisterDirtyListFromUnitOfWork(service.uow, 'Commission_Payment__c');

        System.assertEquals(10,opportunitiesToUpdate.size());
        System.assertEquals(1,casesToInsert.size());
        System.assertEquals(7,commissionPaymentRecordsToInsert.size());
        System.assertEquals(2,commissionPaymentRecordsToUpdate.size());

        Boolean containsOpp = false;
        for (Commission_Payment__c payment : commissionPaymentRecordsToInsert){
            System.assertEquals('Contract Execution',payment.Commission_Type__c);
            System.assert(payment.Amount_Due__c > 0);
            if (payment.Opportunity__c == '0063K000003pyqLQAQ'){
                System.assertNotEquals(1434.564,payment.Amount_Due__c);
                System.assertEquals(1434.56,payment.Amount_Due__c);
                containsOpp = true;
            } else if (payment.Opportunity__c == '0063K000003pyqIQAQ') {
                System.assertEquals('a4w3K0000000EMWQA2', payment.Commission_Structure__c, 'For Opportunity assigned to different SSS, Commission Structure is assigned via Partner Eligibility');
            }
        }
        System.assert(containsOpp);

        Integer countOfNullCommissionStructure = 0;
        for (Opportunity opp : opportunitiesToUpdate){
            System.assertNotEquals(null,opp.CS_Capacity_Allocated__c);
            if (opp.Commission_Structure__c == null){
                countOfNullCommissionStructure += 1;
            }
            if (opp.Id == '0063K000003pyqPQAQ') {
                System.assertEquals(15, opp.CS_Capacity_Allocated__c, 'CS Capacity Allocated should only be populated once on Status Complete');
            }
        }
        System.assertEquals(1, countOfNullCommissionStructure);

        Case caseToInsert = casesToInsert[0];
        System.assertEquals('Issue with Creation of Commission Payment',caseToInsert.Subject);
        System.assertEquals('0063K000003pyqJQAQ',caseToInsert.Related_Opportunity__c);
    }

    @IsTest
    private static void testFirstBillorPayCommissionPayment() {
        useMocks();
        PartnerCommissionService.PendingCommission pendingComm = new PartnerCommissionService.PendingCommission();
        pendingComm.opportunitiesToRun = getOpportunityMockForBilledType();
        pendingComm.typeOfCommission = PartnerCommissionService.CommissionType.FIRSTBILLPAID;

        System.assertEquals(10,pendingComm.opportunitiesToRun.size());

        PartnerCommissionService service = new PartnerCommissionService();
        service.calculateCommissionRecords(pendingComm);

        List<Opportunity> opportunitiesToUpdate = (List<Opportunity>)
            FFLibHelperTest.getRegisterDirtyListFromUnitOfWork(service.uow, 'Opportunity');
        List<Case> casesToInsert = (List<Case>)
            FFLibHelperTest.getRegisterNewListFromUnitOfWork(service.uow, 'Case');
        List<Commission_Payment__c> commissionPaymentRecordsToInsert = (List<Commission_Payment__c>)
            FFLibHelperTest.getRegisterNewListFromUnitOfWork(service.uow, 'Commission_Payment__c');
        List<Commission_Payment__c> commissionPaymentRecordsToUpdate = (List<Commission_Payment__c>)
            FFLibHelperTest.getRegisterDirtyListFromUnitOfWork(service.uow, 'Commission_Payment__c');


        // Only Contract Execution Type should update opportunities, update comm. payments or insert cases:
        System.assertEquals(0,opportunitiesToUpdate.size());
        System.assertEquals(0,casesToInsert.size());
        System.assertEquals(0,commissionPaymentRecordsToUpdate.size());

        System.assertEquals(10,commissionPaymentRecordsToInsert.size());
    }

    @IsTest
    private static void testPartnerInvoiceCreation(){
        PartnerCommissionService service = new PartnerCommissionService();
        Invoice__c partnerInvoice = service.createPartnerInvoice('a0s3K0000006wCMQAY','Partner One', '0013K000006yKHOQA2');
        System.assertEquals('a0s3K0000006wCMQAY',partnerInvoice.Partner__c);
        System.assertEquals(15,partnerInvoice.Due_Date__c.day());
        System.assertEquals('0013K000006yKHOQA2', partnerInvoice.Account__c);
    }

    private static void useMocks() {
        PartnerCommissionService.utilityaccountSelector = (UASSelector) Test.createStub(UASSelector.class, new MockUASSelector());
        PartnerCommissionService.commissionStructureSelector = (CommissionStructureSelector) Test.createStub(CommissionStructureSelector.class, new MockCommStructureSelector());
        PartnerCommissionService.commissionPaySelector = (CommissionPaymentSelector) Test.createStub(CommissionPaymentSelector.class, new MockCommPaySelector());
        PartnerCommissionService.partnerInvoiceSelector = (PartnerInvoiceSelector) Test.createStub(PartnerInvoiceSelector.class, new MockPartnerInvoiceSelector());
        PartnerCommissionService.eligibilitySelector = (PartnerSSSEligibilitySelector) Test.createStub(PartnerSSSEligibilitySelector.class, new MockPartnerSSSEligibilitySelector());
    }

    public static List<Opportunity> getOpportunityMockForContractExecutionType(){
        //First opp has a different SSS from the rest (same partner)
        //Second opp has a different Partner from the rest (same SSS)
        String queryData = '[' +
            '{"Id":"0063K000003pyqIQAQ","StageName":"Complete","Name":"Ashley Smith","AccountId":"0013K000006yKHDQA2","Shared_Solar_System__c":"a1J3K0000005hM0UAI","Product__c":"01t3K000000Rb2VQAS","Partner_tag_lookup__c":"a0s3K0000006wCRQAY","Partner_Account__c":"0010a00001Ljv4ZAAR","Account":{"Id":"0013K000006yKHDQA2","Account_Number__c":"BW-0035450"},"Shared_Solar_System__r":{"Id":"a1J3K0000005hM0UAI","Unique_ID__c":"SSS-000181", "Name": "Test SSS B"},"Partner_tag_lookup__r": {"Id":"a0s3K0000006wCRQAY","Name":"Test Partner", "Account__c":"0010a00001Ljv4ZAAR"},"Partner_Account__r": {"Id":"0010a00001Ljv4ZAAR","Name":"Test Partner Account"}},' +
            '{"Id":"0063K000003pyqJQAQ","StageName":"Complete","Name":"Steven Ward","AccountId":"0013K000006yKHEQA2","Shared_Solar_System__c":"a1J3K0000005hM1UAI","Product__c":"01t3K000000Rb2VQAS","Partner_tag_lookup__c":"a0s3K0000006wCMQAY","Partner_Account__c":"0010a00001Ljv4ZAAL","Account":{"Id":"0013K000006yKHEQA2","Account_Number__c":"BW-0035451"},"Shared_Solar_System__r":{"Id":"a1J3K0000005hM1UAI","Unique_ID__c":"SSS-000182", "Name": "Test SSS A"},"Partner_tag_lookup__r": {"Id":"a0s3K0000006wCMQAY","Name":"Test Partner 2", "Account__c":"0010a00001Ljv4ZAAL"},"Partner_Account__r": {"Id":"0010a00001Ljv4ZAAL","Name":"Test Partner Account 2"}},' +
            '{"Id":"0063K000003pyqKQAQ","StageName":"Complete","Name":"Marie Mitchell","AccountId":"0013K000006yKHFQA2","Shared_Solar_System__c":"a1J3K0000005hM1UAI","Product__c":"01t3K000000Rb2VQAS","Partner_tag_lookup__c":"a0s3K0000006wCRQAY","Partner_Account__c":"0010a00001Ljv4ZAAR","Account":{"Id":"0013K000006yKHFQA2","Account_Number__c":"BW-0035452"},"Shared_Solar_System__r":{"Id":"a1J3K0000005hM1UAI","Unique_ID__c":"SSS-000182", "Name": "Test SSS A"},"Partner_tag_lookup__r": {"Id":"a0s3K0000006wCRQAY","Name":"Test Partner", "Account__c":"0010a00001Ljv4ZAAR"},"Partner_Account__r": {"Id":"0010a00001Ljv4ZAAR","Name":"Test Partner Account"}},' +
            '{"Id":"0063K000003pyqLQAQ","StageName":"Complete","Name":"Justin Jenkins","AccountId":"0013K000006yKHGQA2","Shared_Solar_System__c":"a1J3K0000005hM1UAI","Product__c":"01t3K000000Rb2UQAS","Partner_tag_lookup__c":"a0s3K0000006wCRQAY","Partner_Account__c":"0010a00001Ljv4ZAAR","Account":{"Id":"0013K000006yKHGQA2","Account_Number__c":"BW-0035453"},"Shared_Solar_System__r":{"Id":"a1J3K0000005hM1UAI","Unique_ID__c":"SSS-000182", "Name": "Test SSS A"},"Partner_tag_lookup__r": {"Id":"a0s3K0000006wCRQAY","Name":"Test Partner", "Account__c":"0010a00001Ljv4ZAAR"},"Partner_Account__r": {"Id":"0010a00001Ljv4ZAAR","Name":"Test Partner Account"}},' +
            '{"Id":"0063K000003pyqNQAQ","StageName":"Complete","Name":"Cobie Croft","AccountId":"0013K000006yKHIQA2","Shared_Solar_System__c":"a1J3K0000005hM1UAI","Product__c":"01t3K000000Rb2UQAS","Partner_tag_lookup__c":"a0s3K0000006wCRQAY","Partner_Account__c":"0010a00001Ljv4ZAAR","Account":{"Id":"0013K000006yKHIQA2","Account_Number__c":"BW-0035455"},"Shared_Solar_System__r":{"Id":"a1J3K0000005hM1UAI","Unique_ID__c":"SSS-000182", "Name": "Test SSS A"},"Partner_tag_lookup__r": {"Id":"a0s3K0000006wCRQAY","Name":"Test Partner", "Account__c":"0010a00001Ljv4ZAAR"},"Partner_Account__r": {"Id":"0010a00001Ljv4ZAAR","Name":"Test Partner Account"}},' +
            '{"Id":"0063K000003pyqOQAQ","StageName":"Complete","Name":"Ridwan Conner","AccountId":"0013K000006yKHJQA2","Shared_Solar_System__c":"a1J3K0000005hM1UAI","Product__c":"01t3K000000Rb2UQAS","Partner_tag_lookup__c":"a0s3K0000006wCRQAY","Partner_Account__c":"0010a00001Ljv4ZAAR","Account":{"Id":"0013K000006yKHJQA2","Account_Number__c":"BW-0035456"},"Shared_Solar_System__r":{"Id":"a1J3K0000005hM1UAI","Unique_ID__c":"SSS-000182", "Name": "Test SSS A"},"Partner_tag_lookup__r": {"Id":"a0s3K0000006wCRQAY","Name":"Test Partner", "Account__c":"0010a00001Ljv4ZAAR"},"Partner_Account__r": {"Id":"0010a00001Ljv4ZAAR","Name":"Test Partner Account"}},' +
            '{"Id":"0063K000003pyqPQAQ","StageName":"Complete","Name":"Margaux Maldonado","CS_Capacity_Allocated__c": "15.0", "AccountId":"0013K000006yKHKQA2","Shared_Solar_System__c":"a1J3K0000005hM1UAI","Product__c":"01t3K000000Rb2UQAS","Partner_tag_lookup__c":"a0s3K0000006wCRQAY","Partner_Account__c":"0010a00001Ljv4ZAAR","Account":{"Id":"0013K000006yKHKQA2","Account_Number__c":"BW-0035457"},"Shared_Solar_System__r":{"Id":"a1J3K0000005hM1UAI","Unique_ID__c":"SSS-000182", "Name": "Test SSS A"},"Partner_tag_lookup__r": {"Id":"a0s3K0000006wCRQAY","Name":"Test Partner", "Account__c":"0010a00001Ljv4ZAAR"},"Partner_Account__r": {"Id":"0010a00001Ljv4ZAAR","Name":"Test Partner Account"}},' +
            '{"Id":"0063K000003pyqQQAQ","StageName":"Complete","Name":"Conor Schmitt", "AccountId":"0013K000006yKHLQA2","Shared_Solar_System__c":"a1J3K0000005hM1UAI","Product__c":"01t3K000000Rb2UQAS","Partner_tag_lookup__c":"a0s3K0000006wCRQAY","Partner_Account__c":"0010a00001Ljv4ZAAR","Account":{"Id":"0013K000006yKHLQA2","Account_Number__c":"BW-0035458"},"Shared_Solar_System__r":{"Id":"a1J3K0000005hM1UAI","Unique_ID__c":"SSS-000182", "Name": "Test SSS A"},"Partner_tag_lookup__r": {"Id":"a0s3K0000006wCRQAY","Name":"Test Partner", "Account__c":"0010a00001Ljv4ZAAR"},"Partner_Account__r": {"Id":"0010a00001Ljv4ZAAR","Name":"Test Partner Account"}},' +
            '{"Id":"0063K000003pyqRQAQ","StageName":"Complete","Name":"Akbar Boyce","AccountId":"0013K000006yKHMQA2","Shared_Solar_System__c":"a1J3K0000005hM1UAI","Product__c":"01t3K000000Rb2UQAS","Partner_tag_lookup__c":"a0s3K0000006wCRQAY","Partner_Account__c":"0010a00001Ljv4ZAAR","Account":{"Id":"0013K000006yKHMQA2","Account_Number__c":"BW-0035459"},"Shared_Solar_System__r":{"Id":"a1J3K0000005hM1UAI","Unique_ID__c":"SSS-000182", "Name": "Test SSS A"},"Partner_tag_lookup__r": {"Id":"a0s3K0000006wCRQAY","Name":"Test Partner", "Account__c":"0010a00001Ljv4ZAAR"},"Partner_Account__r": {"Id":"0010a00001Ljv4ZAAR","Name":"Test Partner Account"}},' +
            '{"Id":"0063K000003pyqSQAQ","StageName":"Complete","Name":"Viaan Faulkner","AccountId":"0013K000006yKHNQA2","Shared_Solar_System__c":"a1J3K0000005hM1UAI","Product__c":"01t3K000000Rb2UQAS","Partner_tag_lookup__c":"a0s3K0000006wCRQAY","Partner_Account__c":"0010a00001Ljv4ZAAR","Account":{"Id":"0013K000006yKHNQA2","Account_Number__c":"BW-0035460"},"Shared_Solar_System__r":{"Id":"a1J3K0000005hM1UAI","Unique_ID__c":"SSS-000182", "Name": "Test SSS A"},"Partner_tag_lookup__r": {"Id":"a0s3K0000006wCRQAY","Name":"Test Partner", "Account__c":"0010a00001Ljv4ZAAR"},"Partner_Account__r": {"Id":"0010a00001Ljv4ZAAR","Name":"Test Partner Account"}}' +
            ']';
        return (List<Opportunity>) JSON.deserialize(queryData, List<Opportunity>.class);
    }

    public static List<Opportunity> getOpportunityMockForBilledType(){
        String queryData = '[' +
            '{"Id":"0063K000003pyqIQAQ","Name":"Ashley Smith","AccountId":"0013K000006yKHDQA2","Shared_Solar_System__c":"a1J3K0000005hM0UAI","CS_Capacity_Allocated__c":11.6550,"Commission_Structure__c":"a4w3K0000000EMXQA2","Partner_tag_lookup__c":"a0s3K0000006wCRQAY","Account":{"Id":"0013K000006yKHDQA2","Account_Number__c":"BW-0035450"},"Shared_Solar_System__r":{"Id":"a1J3K0000005hM0UAI","Unique_ID__c":"SSS-000181"},"Commission_Structure__r":{"Id":"a4w3K0000000EMXQA2","Cents_kW_DC_First_Bill_Paid__c":0.2400},"Partner_tag_lookup__r":{"Id":"a0s3K0000006wCRQAY","Name":"Test Partner 2"}},' +
            '{"Id":"0063K000003pyqJQAQ","Name":"Steven Ward","AccountId":"0013K000006yKHEQA2","Shared_Solar_System__c":"a1J3K0000005hM1UAI","CS_Capacity_Allocated__c":5.8275,"Commission_Structure__c":"a4w3K0000000EMXQA2","Partner_tag_lookup__c":"a0s3K0000006wCRQAY","Account":{"Id":"0013K000006yKHEQA2","Account_Number__c":"BW-0035451"},"Shared_Solar_System__r":{"Id":"a1J3K0000005hM1UAI","Unique_ID__c":"SSS-000182"},"Commission_Structure__r":{"Id":"a4w3K0000000EMXQA2","Cents_kW_DC_First_Bill_Paid__c":0.2400},"Partner_tag_lookup__r":{"Id":"a0s3K0000006wCRQAY","Name":"Test Partner 2"}},' +
            '{"Id":"0063K000003pyqKQAQ","Name":"Marie Mitchell","AccountId":"0013K000006yKHFQA2","Shared_Solar_System__c":"a1J3K0000005hM1UAI","CS_Capacity_Allocated__c":5.8275,"Commission_Structure__c":"a4w3K0000000EMXQA2","Partner_tag_lookup__c":"a0s3K0000006wCRQAY","Account":{"Id":"0013K000006yKHFQA2","Account_Number__c":"BW-0035452"},"Shared_Solar_System__r":{"Id":"a1J3K0000005hM1UAI","Unique_ID__c":"SSS-000182"},"Commission_Structure__r":{"Id":"a4w3K0000000EMXQA2","Cents_kW_DC_First_Bill_Paid__c":0.2400},"Partner_tag_lookup__r":{"Id":"a0s3K0000006wCRQAY","Name":"Test Partner 2"}},' +
            '{"Id":"0063K000003pyqLQAQ","Name":"Justin Jenkins","AccountId":"0013K000006yKHGQA2","Shared_Solar_System__c":"a1J3K0000005hM1UAI","CS_Capacity_Allocated__c":5.8275,"Commission_Structure__c":"a4w3K0000000EMXQA2","Partner_tag_lookup__c":"a0s3K0000006wCRQAY","Account":{"Id":"0013K000006yKHGQA2","Account_Number__c":"BW-0035453"},"Shared_Solar_System__r":{"Id":"a1J3K0000005hM1UAI","Unique_ID__c":"SSS-000182"},"Commission_Structure__r":{"Id":"a4w3K0000000EMXQA2","Cents_kW_DC_First_Bill_Paid__c":0.2400},"Partner_tag_lookup__r":{"Id":"a0s3K0000006wCRQAY","Name":"Test Partner 2"}},' +
            '{"Id":"0063K000003pyqNQAQ","Name":"Cobie Croft","AccountId":"0013K000006yKHIQA2","Shared_Solar_System__c":"a1J3K0000005hM1UAI","CS_Capacity_Allocated__c":5.8275,"Commission_Structure__c":"a4w3K0000000EMVQA2","Partner_tag_lookup__c":"a0s3K0000006wCRQAY","Account":{"Id":"0013K000006yKHIQA2","Account_Number__c":"BW-0035455"},"Shared_Solar_System__r":{"Id":"a1J3K0000005hM1UAI","Unique_ID__c":"SSS-000182"},"Commission_Structure__r":{"Id":"a4w3K0000000EMVQA2","Cents_kW_DC_First_Bill_Paid__c":0.2500},"Partner_tag_lookup__r":{"Id":"a0s3K0000006wCRQAY","Name":"Test Partner 2"}},' +
            '{"Id":"0063K000003pyqOQAQ","Name":"Ridwan Conner","AccountId":"0013K000006yKHJQA2","Shared_Solar_System__c":"a1J3K0000005hM1UAI","CS_Capacity_Allocated__c":5.8275,"Commission_Structure__c":"a4w3K0000000EMVQA2","Partner_tag_lookup__c":"a0s3K0000006wCRQAY","Account":{"Id":"0013K000006yKHJQA2","Account_Number__c":"BW-0035456"},"Shared_Solar_System__r":{"Id":"a1J3K0000005hM1UAI","Unique_ID__c":"SSS-000182"},"Commission_Structure__r":{"Id":"a4w3K0000000EMVQA2","Cents_kW_DC_First_Bill_Paid__c":0.2500},"Partner_tag_lookup__r":{"Id":"a0s3K0000006wCRQAY","Name":"Test Partner 2"}},' +
            '{"Id":"0063K000003pyqPQAQ","Name":"Margaux Maldonado","AccountId":"0013K000006yKHKQA2","Shared_Solar_System__c":"a1J3K0000005hM1UAI","CS_Capacity_Allocated__c":5.8275,"Commission_Structure__c":"a4w3K0000000EMVQA2","Partner_tag_lookup__c":"a0s3K0000006wCRQAY","Account":{"Id":"0013K000006yKHKQA2","Account_Number__c":"BW-0035457"},"Shared_Solar_System__r":{"Id":"a1J3K0000005hM1UAI","Unique_ID__c":"SSS-000182"},"Commission_Structure__r":{"Id":"a4w3K0000000EMVQA2","Cents_kW_DC_First_Bill_Paid__c":0.2500},"Partner_tag_lookup__r":{"Id":"a0s3K0000006wCRQAY","Name":"Test Partner 2"}},' +
            '{"Id":"0063K000003pyqQQAQ","Name":"Conor Schmitt","AccountId":"0013K000006yKHLQA2","Shared_Solar_System__c":"a1J3K0000005hM1UAI","CS_Capacity_Allocated__c":5.8275,"Commission_Structure__c":"a4w3K0000000EMVQA2","Partner_tag_lookup__c":"a0s3K0000006wCRQAY","Account":{"Id":"0013K000006yKHLQA2","Account_Number__c":"BW-0035458"},"Shared_Solar_System__r":{"Id":"a1J3K0000005hM1UAI","Unique_ID__c":"SSS-000182"},"Commission_Structure__r":{"Id":"a4w3K0000000EMVQA2","Cents_kW_DC_First_Bill_Paid__c":0.2500},"Partner_tag_lookup__r":{"Id":"a0s3K0000006wCRQAY","Name":"Test Partner 2"}},' +
            '{"Id":"0063K000003pyqRQAQ","Name":"Akbar Boyce","AccountId":"0013K000006yKHMQA2","Shared_Solar_System__c":"a1J3K0000005hM1UAI","CS_Capacity_Allocated__c":5.8275,"Commission_Structure__c":"a4w3K0000000EMVQA2","Partner_tag_lookup__c":"a0s3K0000006wCRQAY","Account":{"Id":"0013K000006yKHMQA2","Account_Number__c":"BW-0035459"},"Shared_Solar_System__r":{"Id":"a1J3K0000005hM1UAI","Unique_ID__c":"SSS-000182"},"Commission_Structure__r":{"Id":"a4w3K0000000EMVQA2","Cents_kW_DC_First_Bill_Paid__c":0.2500},"Partner_tag_lookup__r":{"Id":"a0s3K0000006wCRQAY","Name":"Test Partner 2"}},' +
            '{"Id":"0063K000003pyqSQAQ","Name":"Viaan Faulkner","AccountId":"0013K000006yKHNQA2","Shared_Solar_System__c":"a1J3K0000005hM1UAI","CS_Capacity_Allocated__c":5.8275,"Commission_Structure__c":"a4w3K0000000EMVQA2","Partner_tag_lookup__c":"a0s3K0000006wCRQAY","Account":{"Id":"0013K000006yKHNQA2","Account_Number__c":"BW-0035460"},"Shared_Solar_System__r":{"Id":"a1J3K0000005hM1UAI","Unique_ID__c":"SSS-000182"},"Commission_Structure__r":{"Id":"a4w3K0000000EMVQA2","Cents_kW_DC_First_Bill_Paid__c":0.2500},"Partner_tag_lookup__r":{"Id":"a0s3K0000006wCRQAY","Name":"Test Partner 2"}}' +
            ']';
        return (List<Opportunity>) JSON.deserialize(queryData, List<Opportunity>.class);
    }

    public class MockUASSelector extends MockProvider {
        public MockUASSelector() {
        }

        public override Object handleMethodCall(MethodCall methodCall) {
            String queryData = '{' +
                '"0063K000003pyqPQAQ":10.0,' +
                '"0063K000003pyqJQAQ":25.0,' +
                '"0063K000003pyqIQAQ":25.0,' +
                '"0063K000003pyqQQAQ":25.0,' +
                '"0063K000003pyqLQAQ":14.3456,' +
                '"0063K000003pyqKQAQ":33.3333,' +
                '"0063K000003pyqNQAQ":12.0,' +
                '"0063K000003pyqSQAQ":12.34,' +
                '"0063K000003pyqRQAQ":45.45,' +
                '"0063K000003pyqOQAQ":10000.0' +
                '}';
            switch on methodCall.stubbedMethodName {
                when 'getUASSummaryByOpportunity' {
                    return (Map<Id,Decimal>) JSON.deserialize(queryData, Map<Id,Decimal>.class);
                }
            }
            return null;
        }
    }

    public class MockCommStructureSelector extends MockProvider {
        public MockCommStructureSelector() {
        }

        public override Object handleMethodCall(MethodCall methodCall) {
            //Same Partner
                // 2 are for same product
                // 1 for different product
            String queryData = '[' +
                '{"Id":"a4w3K0000000EMVQA2","Partner__c":"a0s3K0000006wCRQAY","Product__c":"01t3K000000Rb2UQAS","Cents_kW_DC_Up_Front__c":0.1000},' +
                '{"Id":"a4w3K0000000EMWQA2","Partner__c":"a0s3K0000006wCRQAY","Product__c":"01t3K000000Rb2UQAS","Cents_kW_DC_Up_Front__c":0.1400},' +
                '{"Id":"a4w3K0000000EMXQA2","Partner__c":"a0s3K0000006wCRQAY","Product__c":"01t3K000000Rb2VQAS","Cents_kW_DC_Up_Front__c":0.1600}' +
                ']';
            switch on methodCall.stubbedMethodName {
                when 'getCommissionStructureMapByIds' {
                    Map<Id, Commission_Structure__c> csMap = new Map<Id, Commission_Structure__c>();
                    List<Commission_Structure__c> csList = (List<Commission_Structure__c>) JSON.deserialize(queryData, List<Commission_Structure__c>.class);
                    for (Commission_Structure__c cs : csList) {
                        csMap.put(cs.Id, cs);
                    }
                    return csMap;
                }
            }
            return null;
        }
    }

    public class MockPartnerSSSEligibilitySelector extends MockProvider {
        public MockPartnerSSSEligibilitySelector() {
        }

        public override Object handleMethodCall(MethodCall methodCall) {
            //Same partner, different SSS, different Commission Structure
            String queryData = '[' +
                '{"Id":"a0he0000007mR0mAAA","Account__c":"0010a00001Ljv4ZAAR","Shared_Solar_System__c":"a1J3K0000005hM1UAI","Commission_Structure__c":"a4w3K0000000EMVQA2"},' +
                '{"Id":"a0he0000007mR0mBBB","Account__c":"0010a00001Ljv4ZAAR","Shared_Solar_System__c":"a1J3K0000005hM0UAI","Commission_Structure__c":"a4w3K0000000EMWQA2"}' +
                ']';
            switch on methodCall.stubbedMethodName {
                when 'getSSSByPartner' {
                    return (List<Partner_Shared_Solar_System_Eligibility__c>) JSON.deserialize(queryData, List<Partner_Shared_Solar_System_Eligibility__c>.class);
                }
            }
            return null;
        }
    }

    public class MockCommPaySelector extends MockProvider {
        public MockCommPaySelector() {
        }

        public override Object handleMethodCall(MethodCall methodCall) {
            String queryData = '[' +
                '{"Id":"a4v3K0000000HLKQA2","Opportunity__c":"0063K000003pyqPQAQ", "Future_Customer_Subscription_kW_DC__c": "15.0"},' +
                '{"Id":"a4v3K0000000HMSQA2","Opportunity__c":"0063K000003pyqQQAQ", "Future_Customer_Subscription_kW_DC__c": "25.0"}' +
                ']';
            switch on methodCall.stubbedMethodName {
                when 'getPendingCommissionPayments' {
                    return (List<Commission_Payment__c>) JSON.deserialize(queryData, List<Commission_Payment__c>.class);
                }
            }
            return null;
        }
    }

    public class MockPartnerInvoiceSelector extends MockProvider {
        public MockPartnerInvoiceSelector() {
        }

        public override Object handleMethodCall(MethodCall methodCall) {
            Date monthFromToday = System.today().addMonths(1);
            Date today = System.today();

            Invoice__c nextMonthsInvoice = new Invoice__c(
                Id = 'a0c3K000000F0pUQAS',
                Partner__c = 'a0s3K0000006wCRQAY',
                Due_Date__c = Date.newInstance(monthFromToday.Year(), monthFromToday.month(), 15)
            );
            Invoice__c thisMonthsInvoicePartner1 = new Invoice__c(
                Id = 'a0c3K000000F0pUQAS',
                Partner__c = 'a0s3K0000006wCRQAY',
                Due_Date__c = Date.newInstance(today.Year(), today.month(), 15)
            );
            Invoice__c thisMonthsInvoicePartner2 = new Invoice__c(
                Id = 'a0c3K000000F0pUQAT',
                Partner__c = 'a0s3K0000006wCMQAY',
                Due_Date__c = Date.newInstance(today.Year(), today.month(), 15)
            );

            switch on methodCall.stubbedMethodName {
                when 'getPendingPartnerInvoices' {
                    return new List<Invoice__c>{
                        nextMonthsInvoice, thisMonthsInvoicePartner1, thisMonthsInvoicePartner2
                    };
                }
            }
            return null;
        }
    }
}