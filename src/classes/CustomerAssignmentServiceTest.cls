/**
 * Created by peteryao on 6/17/20.
 */

@IsTest
@SuppressWarnings('PMD.AvoidHardcodingId')
public with sharing class CustomerAssignmentServiceTest {
    private static String newContractMapJson = '{' +
        '"800000000000007":{"Id":"800000000000007","Assignment_Agreement__c":"800000000000000AAA"},' + // added
        '"800000000000008":{"Id":"800000000000008","Assignment_Agreement__c":"800000000000001AAA"},' + // no change
        '"800000000000009":{"Id":"800000000000009","Assignment_Agreement__c":"800000000000003AAA"},' + // changed AA
        '"800000000000000":{"Id":"800000000000000"}' + // removed AA
        '}';
    private static String signedAssignmentAgreementNewMap = '{' +
        '"800000000000000AAA" : {"Id":"800000000000000AAA", "RecordTypeId":"0120a0000010S8hAAE", "CompanySignedDate":"2020-03-19"}}'; //signed
    private static String signedAssignmentAgreementOldMap = '{' +
        '"800000000000000AAA" : {"Id":"800000000000000AAA", "RecordTypeId":"0120a0000010S8hAAE", "CompanySignedDate": ' + null + '}}'; //not signed

    @IsTest
    private static void testSignedAssignmentAgreement() {
        Contact contact1 = new Contact(
            Title = 'testContact1',
            LastName = 'testContact1LastName'
        );
        insert contact1;
        
        Account account1 = new Account(
            Name = 'testAccount1',
            Send_Bills_Contact__c = contact1.Id
        );
        insert account1;
        
        Shared_Solar_System__c sss1 = new Shared_Solar_System__c(
            Name = 'testSSS1',
            Address__c = 'test address',
            City__c = 'Atlanta',
            State__c = 'GA',
            Zip_Code__c = '54321',
            Total_System_Size_kWh_DC__c = 1.1
        );
        insert sss1;
        
        Opportunity opp1 = new Opportunity(
            Name = 'testOpp1',
            Shared_Solar_System__c = sss1.Id,
            StageName = 'testOpp1StageName',
            CloseDate = Date.today()
        );
    	insert opp1;
        
        Contract contract1 = new Contract(
            AccountId = account1.Id,
            Addendum_Sent_Date__c = NULL,
            Name = 'testCon1',
            Opportunity__c = opp1.Id,
            RecordTypeId = '0120a0000010S8hAAE',
            CompanySignedDate = null
        );
        insert contract1;
        
        Contract contract2 = contract1.clone(true, true, true, true);
        System.assertEquals(contract1, contract2);
        contract2.CompanySignedDate = Date.today();
        
        Map<Id, Contract> oldContractMap = new Map<Id, Contract>();
        Map<Id, Contract> newContractMap = new Map<Id, Contract>();
        
        oldContractMap.put(contract1.Id, contract1);
        newContractMap.put(contract2.Id, contract2);
        
        Util.mockDML = true;
        CustomerAssignmentService.opportunitiesSelector =
            (OpportunitiesSelector) Test.createStub(OpportunitiesSelector.class, new MockOppSelector());
        
        CustomerAssignmentService service = new CustomerAssignmentService();
        service.updateSignedAssignmentAgreements(oldContractMap, newContractMap);

        List<Shared_Solar_System__c> sssToUpdate = (List<Shared_Solar_System__c>) Util.objectsUpdatedIfMockingDML;
        System.assertEquals(2, sssToUpdate.size());
    }

    @IsTest
    private static void systemTestInvoicedAssignmentAgreements() {
        Util.disableTrigger('Disable_SubscriptionOrder_Trigger__c');
        Id aaTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Assignment Agreement').getRecordTypeId();
        Account clientAccount = new Account(
            Name = 'Client Account'
        );
        insert clientAccount;

        Contract invoicedAA = new Contract(
            RecordTypeId = aaTypeId,
            AccountId = clientAccount.Id
        );

        Contract invoicedAA2 = new Contract(
            RecordTypeId = aaTypeId,
            AccountId = clientAccount.Id,
            Date_Invoiced__c = System.today()
        );

        insert new List<Contract>{invoicedAA, invoicedAA2};

        Utility_Account_Log__c ual = new Utility_Account_Log__c(
            Name = 'Utility Account'
        );
        insert ual;
        Utility_Account_Subscription__c uas = new Utility_Account_Subscription__c(
            Name = 'Utility Account Subscription',
            Utility_Account_Log__c = ual.Id
        );
        insert uas;

        Subscription_Order__c so1 = new Subscription_Order__c(
            Utility_Account_Subscription__c = uas.Id,
            Client_Assignment_Agreement__c = invoicedAA.Id
        );
        Subscription_Order__c so2 = new Subscription_Order__c(
            Utility_Account_Subscription__c = uas.Id,
            Client_Assignment_Agreement__c = invoicedAA.Id
        );
        Subscription_Order__c so3 = new Subscription_Order__c(
            Utility_Account_Subscription__c =uas.Id,
            Client_Assignment_Agreement__c = invoicedAA2.Id
        );

        insert new List<Subscription_Order__c> {so1, so2, so3};

        //Update should populate Invoiced on 2 SOs
        invoicedAA.Date_Invoiced__c = System.today();
        //Setting Date_Invoiced to null should not cause changes on SOs
        invoicedAA2.Date_Invoiced__c = null;

        Test.startTest();
        update new List<Contract>{invoicedAA, invoicedAA2};
        Test.stopTest();

        List<Subscription_Order__c> sOrders = [
            SELECT Id, Invoice_Date__c, Client_Assignment_Agreement__c
            FROM Subscription_Order__c
        ];

        System.assertEquals(3, sOrders.size(), 'Total of 3 SO records');
        for (Subscription_Order__c so : sOrders) {
            if (so.Client_Assignment_Agreement__c == invoicedAA.Id) {
                System.assertEquals(System.today(), so.Invoice_Date__c, 'Invoice Date should be populated with invoiceAA date');
            } else {
                System.assertEquals(null, so.Invoice_Date__c, 'Invoice Date should not be populated for invoicedAA2');
            }
        }
    }

    @IsTest
    private static void testUpdateAssignmentAgreementsFromContract() {
        CustomerAssignmentService.subscriptionOrderSelector =
            (SubscriptionOrderSelector) Test.createStub(SubscriptionOrderSelector.class, new MockSubscriptionOrderSelector());
        Util.mockDML = true;

        Map<Id, Contract> newContractMap = (Map<Id, Contract>) JSON.deserialize(newContractMapJson, Map<Id, Contract>.class);
        CustomerAssignmentService.ContractAssignmentBundle assignmentBundle = new CustomerAssignmentService.ContractAssignmentBundle();
        assignmentBundle.contracts = newContractMap.values();
        assignmentBundle.cutoffDate = Date.newInstance(2021,1,1);
        CustomerAssignmentService.assignSOsAssignmentAgreement(new List<CustomerAssignmentService.ContractAssignmentBundle>{assignmentBundle});
        List<Subscription_Order__c> subscriptionOrdersToUpdate = (List<Subscription_Order__c>) Util.objectsUpdatedIfMockingDML;

        System.assertEquals(3, subscriptionOrdersToUpdate.size(), 'Expected to update three orders');
        for (Subscription_Order__c so : subscriptionOrdersToUpdate) {
            switch on (String) so.Id {
                when 'a9W0v0000000000AAA' {
                    System.assertEquals('800000000000000AAA', so.Client_Assignment_Agreement__c);
                } when 'a9W0v0000000002AAA' {
                    System.assertEquals('800000000000003AAA', so.Client_Assignment_Agreement__c);
                } when 'a9W0v0000000003AAA' {
                    System.assertEquals(null, so.Client_Assignment_Agreement__c);
                } when else {
                    System.assert(false, 'Did not expect SO ' + so.Id + ' to be updated');
                }
            }
        }
    }

    @IsTest
    private static void testUpdateAssignmentAgreementsForNoContracts() {
        CustomerAssignmentService.subscriptionOrderSelector =
            (SubscriptionOrderSelector) Test.createStub(SubscriptionOrderSelector.class, new MockSubscriptionOrderSelector());
        Util.mockDML = true;

        CustomerAssignmentService.ContractAssignmentBundle assignmentBundle = new CustomerAssignmentService.ContractAssignmentBundle();
        assignmentBundle.contracts = null; // If the user proceeds with the flow and there are no contracts to assign
        assignmentBundle.cutoffDate = Date.newInstance(2021,1,1);
        CustomerAssignmentService.assignSOsAssignmentAgreement(new List<CustomerAssignmentService.ContractAssignmentBundle>{assignmentBundle});
        List<Subscription_Order__c> subscriptionOrdersToUpdate = (List<Subscription_Order__c>) Util.objectsUpdatedIfMockingDML;
        System.assertEquals(null, subscriptionOrdersToUpdate, 'Expected no errors, and no updates');
    }


    @IsTest
    static void testGenerateAddendumsFromSubscriptions() {
        CustomerAssignmentService.contractSelector =
            (ContractSelector) Test.createStub(ContractSelector.class, new MockContractSelector());

        CustomerAssignmentService service = new CustomerAssignmentService();
        List<Utility_Account_Subscription__c> uasList = new List<Utility_Account_Subscription__c>();
        Test.startTest();
        List<Contract> contracts = service.generateAddendumsFromSubscriptions(uasList);
        Test.stopTest();

        for (Contract contract : contracts ) {
            System.assert(contract.Generate_Addendum__c, 'Contract should have an Addendum generated');
        }
    }

    @IsTest
    private static void systemTestAssignmentAgreementRejection() {
        Util.disableTrigger('Disable_SubscriptionOrder_Trigger__c');
        Account clientAccount = new Account(
            Name = 'Client Account'
        );
        insert clientAccount;

        Contract assignmentAgreement = new Contract(
            RecordTypeId = CustomerAssignmentService.aaTypeId,
            AccountId = clientAccount.Id,
            Status = 'Draft'
        );
        insert assignmentAgreement;
        assignmentAgreement.Status  = 'Executed';
        update assignmentAgreement;

        Account customerAccount = new Account(
            Name = 'Customer',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Property').getRecordTypeId()
        );
        insert customerAccount;

        Contract customerContract = new Contract(
            RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Customer Contract').getRecordTypeId(),
            AccountId = customerAccount.Id,
            Assignment_Agreement__c = assignmentAgreement.Id
        );
        insert customerContract;

        Utility_Account_Log__c ual = new Utility_Account_Log__c(
            Name = 'Utility Account'
        );
        insert ual;
        Utility_Account_Subscription__c uas = new Utility_Account_Subscription__c(
            Name = 'Utility Account Subscription',
            Utility_Account_Log__c = ual.Id
        );
        insert uas;

        Subscription_Order__c so1 = new Subscription_Order__c(
            Utility_Account_Subscription__c = uas.Id,
            Client_Assignment_Agreement__c = assignmentAgreement.Id
        );
        Subscription_Order__c so2 = new Subscription_Order__c(
            Utility_Account_Subscription__c = uas.Id,
            Client_Assignment_Agreement__c = assignmentAgreement.Id
        );
        insert new List<Subscription_Order__c> {so1, so2};

        List<Contract> customerContracts = [
            SELECT Id
            FROM Contract
            WHERE RecordTypeId = :Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Customer Contract').getRecordTypeId()
            AND Assignment_Agreement__c = NULL
        ];
        System.assertEquals(0, customerContracts.size(), 'Expected all customer contracts to have an Assignment Agreement');

        List<Subscription_Order__c> sOrders = [
            SELECT Id, Invoice_Date__c, Client_Assignment_Agreement__c
            FROM Subscription_Order__c
            WHERE Client_Assignment_Agreement__c = NULL
        ];
        System.assertEquals(0, sOrders.size(), 'Expected all subscription orders to have an Assignment Agreement');

        Test.startTest();
        assignmentAgreement.Status = 'Rejected';
        update assignmentAgreement;
        Test.stopTest();

        customerContracts = [
            SELECT Id
            FROM Contract
            WHERE RecordTypeId = :Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Customer Contract').getRecordTypeId()
            AND Assignment_Agreement__c = NULL
        ];
        System.assertEquals(1, customerContracts.size(), 'After setting the Assignment Agreement to Rejected, there should be 1 unassigned Customer Contract');

        sOrders = [
            SELECT Id, Invoice_Date__c, Client_Assignment_Agreement__c
            FROM Subscription_Order__c
            WHERE Client_Assignment_Agreement__c = NULL
        ];
        System.assertEquals(2, sOrders.size(), 'After setting the Assignment Agreement to Rejected, there should be 2 unassigned SOs');
    }

    public class MockOppSelector extends MockProvider {
        public override Object handleMethodCall(MethodCall methodCall) {
            String queryData = '{"a1J3F000000vM0EUAU":"2020-01-01", "a1J3F000000vM0AUAU":"2020-02-02"}';
            Map<Id, Date> sssFirstCustomerDateMap = (Map<Id, Date>) JSON.deserialize(queryData, Map<Id, Date>.class);
            switch on methodCall.stubbedMethodName {
                when 'selectFirstCustomerSignedDateByAssignmentAgreement' {
                    return sssFirstCustomerDateMap;
                }
            }
            return null;
        }
    }

    public class MockContractSelector extends MockProvider {
        public override Object handleMethodCall(MethodCall methodCall) {
            String contractsAsString = '[' +
                '{"Id":"8002f000000GebbAAC", "Generate_Addendum__c" : ' + false + '},' +
                '{"Id":"8002f000000GevzAAC", "Generate_Addendum__c" : ' + false + '},' +
                '{"Id":"8002f000000Gew0AAC", "Generate_Addendum__c" : ' + false + '},' +
                '{"Id":"8002f000000GewNAAS", "Generate_Addendum__c" : ' + false + '}]';


            switch on methodCall.stubbedMethodName {
                when 'getCustomerContractsForAddendum' {
                    return (List<Contract>) JSON.deserialize(contractsAsString, List<Contract>.class);
                }
            }
            return null;
        }
    }


    public class MockSubscriptionOrderSelector extends MockProvider {
        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'selectApprovedByOppIds' {
                    String json = '[' +
                        '{"Id":"a9W0v0000000000AAA",' +
                        '"Client_Assignment_Agreement__c":"8000v000000EXYLAA4",' +
                        '"Utility_Account_Subscription__r":{"Id":"a1d0v000003Y3AxAAK","Opportunity__c":"006000000000000AAA"}},' +
                        '{"Id":"a9W0v0000000002AAA",' +
                        '"Client_Assignment_Agreement__c":"8000v000000EXYLAA4",' +
                        '"Utility_Account_Subscription__r":{"Id":"a1d0v000003Y3AyAAK","Opportunity__c":"006000000000002AAA"}},' +
                        '{"Id":"a9W0v0000000003AAA",' +
                        '"Client_Assignment_Agreement__c":"8000v000000EXYLAA4",' +
                        '"Utility_Account_Subscription__r":{"Id":"a1d0v000003Y3AyAAK","Opportunity__c":"006000000000003AAA"}}' +
                        ']';
                    return (List<Subscription_Order__c>) System.JSON.deserialize(json, List<Subscription_Order__c>.class);
                } when 'selectApprovedByContractIds' {
                    String json = '[' +
                        '{"Id":"a9W0v0000000000AAA",' +
                        '"Client_Assignment_Agreement__c":"8000v000000EXYLAA4",' +
                        '"Utility_Account_Subscription__r":{"Id":"a1d0v000003Y3B1AAK","Opportunity__r":{"Id":"006000000000000AAA","ContractId":"800000000000007", "Contract" : {"Id" : "800000000000007", "Assignment_Agreement__c" : "800000000000000AAA"}}}},' +
                        '{"Id":"a9W0v0000000002AAA",' +
                        '"Client_Assignment_Agreement__c":"8000v000000EXYLAA4",' +
                        '"Utility_Account_Subscription__r":{"Id":"a1d0v000003Y3B2AAK","Opportunity__r":{"Id":"006000000000002AAA","ContractId":"800000000000009", "Contract" : {"Id" : "800000000000009", "Assignment_Agreement__c" : "800000000000003AAA"}}}},' +
                        '{"Id":"a9W0v0000000003AAA",' +
                        '"Client_Assignment_Agreement__c":"8000v000000EXYLAA4",' +
                        '"Utility_Account_Subscription__r":{"Id":"a1d0v000003Y3B2AAK","Opportunity__r":{"Id":"006000000000003AAA","ContractId":"800000000000000", "Contract" : {"Id" : "800000000000000"}}}}' +
                        ']';
                    return (List<Subscription_Order__c>) System.JSON.deserialize(json, List<Subscription_Order__c>.class);
                } when 'getSubscriptionOrdersByAssignmentAgreement' {
                    String json = '[' +
                        '{"Id":"a9W0v0000000000AAA",' +
                        '"Client_Assignment_Agreement__c":"800000000000000AAA",' +
                        '"Date_Invoiced__c": ' + null +
                        '},' +
                        '{"Id":"a9W0v0000000002AAA",' +
                        '"Client_Assignment_Agreement__c":"800000000000000AAA",' +
                        '"Date_Invoiced__c": ' + null +
                        '},' +
                        '{"Id":"a9W0v0000000003AAA",' +
                        '"Client_Assignment_Agreement__c":"800000000000000AAA",' +
                        '"Date_Invoiced__c": ' + null +
                        '}' +
                        ']';
                    return (List<Subscription_Order__c>) System.JSON.deserialize(json, List<Subscription_Order__c>.class);
                }
            }
            return null;
        }
    }
    
    @IsTest
    private static void testSendDisclosureFormEmail() {
        Contact contact1 = new Contact(
            Title = 'testContact01',
            LastName = 'testContactLastName'
        );
        insert contact1;
        
        Account account1 = new Account(
            Name = 'testAccount1',
            Send_Bills_Contact__c = contact1.Id
        );
        insert account1;
        
        Product2 product1 = new Product2(
            Addendum_Template_Id__c = 'AddendumTestId',
            Name = 'testProd1'
        );
        insert product1;
        
        Shared_Solar_System__c sss1 = new Shared_Solar_System__c(
            Name = 'testSSS1',
            Address__c = 'testAddress',
            City__c = 'Boston',
            State__c = 'MA',
            Zip_Code__c = '12345',
            Total_System_Size_kWh_DC__c = 1.1
        );
        insert sss1;
        
        Opportunity opp1 = new Opportunity(
            Product__c = product1.Id,
            StageName = 'opp1StageName',
            Name = 'opp1Name',
            CloseDate = Date.today(),
            Shared_Solar_System__c = sss1.Id
        );
        insert opp1;
        
        Contract contract1 = new Contract(
            AccountId = account1.Id,
            Addendum_Sent_Date__c = NULL,
            Name = 'testContract1',
            Opportunity__c = opp1.Id
        );
        insert contract1;
        
        opp1.ContractId = contract1.Id;
        update opp1;
        
        ContentVersion cv1 = new ContentVersion(
            Title = 'cv1Title.pdf',
            VersionData = EncodingUtil.base64Decode('df'),
            PathOnClient = '/Disclosure_Form.pdf',
            Signing_Status__c = 'Countersigned'
        );
        insert cv1;
        
        Map<Id,Contract> contractMap = new Map<Id,Contract>();
        contractMap.put(contract1.Id, contract1);
        
        CustomerAssignmentService.sendDisclosureFormEmail(contractMap, 'Welcome Email');
        
        System.assertEquals(1, MessagingService.emailsSent.size());
    }

    
}