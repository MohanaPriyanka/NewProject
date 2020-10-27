/**
 * @description
 * Created by peteryao on 10/19/20.
 */
@IsTest
public with sharing class ClientInvoiceGeneratorTest {
    @TestSetup
    private static void setupData() {
        SharedSolarSystemHandlerTest.setupData();
        Account account = [SELECT Id FROM Account WHERE Name = 'Test Client' LIMIT 1];
        Id clientContractRecordTypeId =
            Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Client Contract').getRecordTypeId();
        Id assignmentAgreementRecordTypeId =
            Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Assignment Agreement').getRecordTypeId();

        Contract contractA = new Contract(
            Name = 'Client Contract A',
            AccountId = account.Id,
            RecordTypeId = clientContractRecordTypeId,
            StartDate = System.today()
        );
        Contract assignmentAgreement = new Contract(
            Name = 'Client Contract A',
            AccountId = account.Id,
            RecordTypeId = assignmentAgreementRecordTypeId,
            StartDate = System.today()
        );
        insert new List<Contract>{contractA, assignmentAgreement};
        Contract_Fee_Detail__c cfd = new Contract_Fee_Detail__c(
            Contract__c = contractA.Id,
            Fee__c = 0.10,
            Fee_Unit__c = 'per W',
            Acquisition_Type_Reacquisition__c = true,
            Waive_Reacquisition_Fee_Project_Date__c = 'Contract: Effective Date',
            Waive_Reacquisition_Fee_Number_Months__c = 0,
            Waive_Reacq_Fee_After_Initial_Period__c = true,
            Acquisition_Cust_Group_Residential__c = true,
            Acquisition_Channels_BCS_Acquired__c = false,
            Acquisition_Channels_Non_BCS_Acquired__c = true,
            Acquisition_Sizing_Type_Upsizing__c = true,
            Acquisition_Cust_Group_Not_Specified__c = true
        );
        insert cfd;

        Shared_Solar_System__c sss = [
            SELECT Id, (SELECT Id FROM Opportunities__r LIMIT 1)
            FROM Shared_Solar_System__c
            WHERE Name = 'SSS 1'
        ];
        sss.Client_Management_Contract__c = contractA.Id;
        sss.Client_Acquisition_Contract__c = contractA.Id;
        sss.Reacquisition_Start_Date__c = System.today().addYears(-1);
        update sss;

        Utility_Account_Subscription__c uas = [
            SELECT Id
            FROM Utility_Account_Subscription__c
            WHERE Opportunity__c = :sss.Opportunities__r[0].Id
            AND Shared_Solar_System__r.Name = 'SSS 1'
            LIMIT 1
        ];

        Subscription_Order__c soChange = new Subscription_Order__c(
            Effective_Date__c = System.today(),
            Utility_Account_Subscription__c = uas.Id,
            Approval_Status__c = 'Approved',
            New_Annual_kWh__c = 4800,
            Previous_Annual_kwh__c = 0
        );
        Subscription_Order__c soAssigned = new Subscription_Order__c(
            Effective_Date__c = System.today(),
            Utility_Account_Subscription__c = uas.Id,
            Approval_Status__c = 'Approved',
            New_Annual_kWh__c = 5000,
            Previous_Annual_kwh__c = 0,
            Client_Assignment_Agreement__c = assignmentAgreement.Id
        );
        insert new List<Subscription_Order__c>{soChange, soAssigned};
    }

    @IsTest
    private static void systemTest() {
        List<Subscription_Order__c> subscriptionOrders = [
            SELECT Id, Utility_Account_Subscription__r.Shared_Solar_System__r.Name, Utility_Account_Subscription__r.Opportunity__r.StageName,
                Invoice_Line_Item__c, Effective_Date__c, Client_Invoicing_Fee__c, Potential_Client_Invoicing_Fee__c, Client_Assignment_Agreement__c,
                Utility_Account_Subscription__r.Shared_Solar_System__r.Client_Account__r.Name
            FROM Subscription_Order__c
            WHERE Utility_Account_Subscription__r.Shared_Solar_System__r.Name = 'SSS 1'
        ];
        System.assertEquals(3, subscriptionOrders.size(),
            'Expected three Subscription Orders in testSetup');
        List<Client_Invoicing_Memo__c> clientInvoicingMemos = [
            SELECT Id, Subscription_Order__c, Amount__c, Effective_Date__c
            FROM Client_Invoicing_Memo__c
            WHERE Subscription_Order__r.Utility_Account_Subscription__r.Shared_Solar_System__r.Name = 'SSS 1'
        ];
        System.assertEquals(3, clientInvoicingMemos.size(),
            'Expected three Client Invoicing Memos in testSetup');

        InvocableCSFeeSelector.FeeRequest feeRequest = new InvocableCSFeeSelector.FeeRequest();
        feeRequest.clientAccountId = subscriptionOrders[0].Utility_Account_Subscription__r.Shared_Solar_System__r.Client_Account__c;
        feeRequest.effectiveDate = System.now();
        // Tests InvocableCSFeeSelector.getFeesToInvoice
        List<String> serializedSSS = InvocableCSFeeSelector.getFeesToInvoice(new List<InvocableCSFeeSelector.FeeRequest>{feeRequest});
        List<SharedSolarSystem> sharedSolarSystems =
            (List<SharedSolarSystem>) JSON.deserialize(serializedSSS[0], List<SharedSolarSystem>.class);
        System.assertEquals(1, sharedSolarSystems.size(),
            'Expected one system with charges to invoice');
        System.assert(sharedSolarSystems[0].uninvoicedRecords != 0,
            'Expected assignments and changes to invoice');
        Decimal expectedTotal =
            sharedSolarSystems[0].totalAssignmentsToInvoice +
            sharedSolarSystems[0].totalChangesToInvoice;

        InvocableClientInvoiceGenerator.InvoiceGenerationRequest generationRequest =
            new InvocableClientInvoiceGenerator.InvoiceGenerationRequest();
        generationRequest.sharedSolarSystemJSON = serializedSSS[0];
        generationRequest.includeAssignmentFees = true;
        generationRequest.includeChangeFees = true;
        generationRequest.effectiveDate = System.now();

        List<InvocableClientInvoiceGenerator.InvoiceGenerationRequest> generationRequests =
            new List<InvocableClientInvoiceGenerator.InvoiceGenerationRequest>{generationRequest};
        // Tests InvocableClientInvoiceGenerator.generateInvoice
        List<List<Invoice__c>> invoiceLists =
            InvocableClientInvoiceGenerator.generateInvoice(generationRequests);
        System.assertEquals(1, invoiceLists[0].size(),
            'Expected to generate one invoice');
        Invoice__c invoice = [
            SELECT Id, Account__c, Line_Item_Total__c
            FROM Invoice__c
            WHERE Id = :invoiceLists[0][0].Id
        ];
        System.assertEquals(expectedTotal, invoice.Line_Item_Total__c,
            'Invoice Line Item Total should be all of the expected changes in SharedSolarSystem');
        List<Invoice_Line_Item__c> invoiceLineItems = [
            SELECT Id, Amount__c, Subscription_Order__c, Client_Invoicing_Memo__c
            FROM Invoice_Line_Item__c
        ];
        System.assertEquals(6, invoiceLineItems.size(),
            'Expected 3 invoice line items for the generated invoice');
        subscriptionOrders = [
            SELECT Id, Invoice_Line_Item__c
            FROM Subscription_Order__c
            WHERE Id IN :subscriptionOrders
            AND Invoice_Line_Item__c = NULL
        ];
        System.assertEquals(0, subscriptionOrders.size(),
            'Expected all Subscription Orders to get invoiced');
        clientInvoicingMemos = [
            SELECT Id, Invoice_Line_Item__c
            FROM Client_Invoicing_Memo__c
            WHERE Id IN :clientInvoicingMemos
            AND Invoice_Line_Item__c = NULL
        ];
        System.assertEquals(0, clientInvoicingMemos.size(),
            'Expected all Client Invoicing Memos to get invoiced');

        Invoice__c newInvoice = new Invoice__c(
            Account__c = invoice.Account__c
        );
        insert newInvoice;

        delete invoiceLineItems[0];
        InvocableClientInvoiceLineItemGenerator.LineItemRequest lineItemRequest =
            new InvocableClientInvoiceLineItemGenerator.LineItemRequest();
        lineItemRequest.soOrCIMId = invoiceLineItems[0].Subscription_Order__c;
        lineItemRequest.invoiceId = newInvoice.Id;
        List<InvocableClientInvoiceLineItemGenerator.LineItemRequest> lineItemRequests =
            new List<InvocableClientInvoiceLineItemGenerator.LineItemRequest>{lineItemRequest};
        ClientInvoiceGenerator.uow = new fflib_SObjectUnitOfWork(
            new List<SObjectType> {
                Invoice__c.SObjectType,
                Invoice_Line_Item__c.SObjectType,
                Subscription_Order__c.SObjectType,
                Client_Invoicing_Memo__c.SObjectType
            }
        );

        // Tests InvocableClientInvoiceLineItemGenerator.generateLineItem
        InvocableClientInvoiceLineItemGenerator.generateLineItem(lineItemRequests);
        invoiceLineItems = [SELECT Id FROM Invoice_Line_Item__c WHERE Invoice__c = :invoice.Id];
        System.assertEquals(5, invoiceLineItems.size(),
            'Expected 2 invoice line items left after deleting one invoice line item (via flow)');
        invoiceLineItems = [SELECT Id FROM Invoice_Line_Item__c WHERE Invoice__c = :newInvoice.Id];
        System.assertEquals(1, invoiceLineItems.size(),
            'Expected 1 invoice line item on the new invoice via generateLineItem');
    }

    @IsTest
    private static void testSharedSolarSystemConstructors() {
        // These constructors are used by the DatatableV2 component, so they aren't exercised through any other apex.
        SharedSolarSystem sss = new SharedSolarSystem();
        System.assertNotEquals(null, sss, 'Expected to construct SSS with no args');
        Id sssId = Util.getFakeId(Shared_Solar_System__c.SObjectType);
        sss = new SharedSolarSystem(
            sssId,
            'Test Name',
            'Test entity name',
            0,
            0,
            0
        );
        System.assertEquals(sssId, sss.id, 'Expected the SSS Id to be set via constructor');
    }

    @IsTest
    private static void testGenerateLineItemForCIM() {
        InvocableClientInvoiceLineItemGenerator.clientInvoiceGenerator =
            (ClientInvoiceGenerator) Test.createStub(ClientInvoiceGenerator.class, new MockClientInvoiceGenerator());
        InvocableClientInvoiceLineItemGenerator.clientInvoicingMemoSelector =
            (ClientInvoicingMemoSelector) Test.createStub(ClientInvoicingMemoSelector.class, new MockClientInvoicingMemoSelector());
        InvocableClientInvoiceLineItemGenerator.LineItemRequest lineItemRequest =
            new InvocableClientInvoiceLineItemGenerator.LineItemRequest();
        lineItemRequest.soOrCIMId = Util.getFakeId(Client_Invoicing_Memo__c.SObjectType);
        lineItemRequest.invoiceId = Util.getFakeId(Invoice__c.SObjectType);
        List<InvocableClientInvoiceLineItemGenerator.LineItemRequest> lineItemRequests =
            new List<InvocableClientInvoiceLineItemGenerator.LineItemRequest>{lineItemRequest};
        List<Invoice_Line_Item__c> invoiceLineItems =
            InvocableClientInvoiceLineItemGenerator.generateLineItem(lineItemRequests);
        System.assertEquals(1, invoiceLineItems.size(),
            'Expected to generate an invoice line item for this un-invoiced Client Invoicing Memo');
    }

    /**
     * @description MOCKS ***
     **/
    public class MockClientInvoiceGenerator extends MockProvider {
        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'commitWork' {
                    return null;
                } when 'generateLineItemFromCIM' {

                }
            }
            return null;
        }
    }

    /**
     * @description MOCKS ***
     **/
    public class MockClientInvoicingMemoSelector extends MockProvider {
        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'selectByIds' {
                    Client_Invoicing_Memo__c clientInvoicingMemo = new Client_Invoicing_Memo__c(
                        Id = Util.getFakeId(Client_Invoicing_Memo__c.SObjectType),
                        Amount__c = 100
                    );
                    return new List<Client_Invoicing_Memo__c>{clientInvoicingMemo};
                }
            }
            return null;
        }
    }

}