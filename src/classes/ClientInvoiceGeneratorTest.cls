/**
 * @description
 * Created by peteryao on 10/19/20.
 */
@IsTest
public with sharing class ClientInvoiceGeneratorTest {
    private static Id soId = Util.getFakeId(Subscription_Order__c.SObjectType);

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
            Acquisition_Cust_Group_Residential__c = true,
            Acquisition_Channels_BCS_Acquired__c = false,
            Acquisition_Channels_Non_BCS_Acquired__c = true,
            Acquisition_Sizing_Type_Upsizing__c = true,
            Acquisition_Sizing_Type_Downsizing__c = true,
            Acquisition_Cust_Group_Not_Specified__c = true,
            Approval_Status__c = 'Approved'
        );
        insert cfd;
        Contract_Fee_Detail__c cfd2 = new Contract_Fee_Detail__c(
            Contract__c = contractA.Id,
            Fee__c = 0.10,
            Fee_Unit__c = 'per W',
            Acquisition_Type_Acquisition__c = true,
            Acquisition_Cust_Group_Residential__c = true,
            Acquisition_Channels_BCS_Acquired__c = false,
            Acquisition_Channels_Non_BCS_Acquired__c = true,
            Acquisition_Sizing_Type_Upsizing__c = true,
            Acquisition_Sizing_Type_Downsizing__c = true,
            Acquisition_Cust_Group_Not_Specified__c = true,
            Approval_Status__c = 'Approved'
        );
        insert cfd2;

        Shared_Solar_System__c sss = [
            SELECT Id, (SELECT Id FROM Opportunities__r LIMIT 1)
            FROM Shared_Solar_System__c
            WHERE Name = 'SSS 1'
        ];
        Client_Contract__c clientContract = new Client_Contract__c(
            Contract__c = contractA.Id,
            Shared_Solar_System__c = sss.Id,
            Effective_Date__c = Date.today().addYears(-1),
            End_Date__c = Date.today().addYears(1),
            CS_Services_Type__c = 'Acquisition & Management'
        );
        insert clientContract;
        sss.Reacquisition_Start_Date__c = System.today().addYears(-1);
        update sss;

        Utility_Account_Subscription__c uas = [
            SELECT Id, Opportunity__c, Opportunity__r.AccountId, (SELECT Id, New_Annual_kWh__c FROM Subscription_Orders__r)
            FROM Utility_Account_Subscription__c
            WHERE Opportunity__c = :sss.Opportunities__r[0].Id
            AND Shared_Solar_System__r.Name = 'SSS 1'
            LIMIT 1
        ];
        Contract customerContract = new Contract(
            AccountId = uas.Opportunity__r.AccountId,
            Assignment_Agreement__c = assignmentAgreement.Id
        );
        insert customerContract;
        Opportunity customerOpportunity = new Opportunity(
            Id = uas.Opportunity__c,
            ContractId = customerContract.Id
        );
        update customerOpportunity;
        Subscription_Order__c so = new Subscription_Order__c(
            Id = uas.Subscription_Orders__r[0].Id,
            Client_Assignment_Agreement__c = assignmentAgreement.Id
        );
        update so;

        Subscription_Order__c soReverted = new Subscription_Order__c(
            Effective_Date__c = System.today(),
            Utility_Account_Subscription__c = uas.Id,
            Approval_Status__c = 'Approved',
            New_Annual_kWh__c = 0,
            Previous_Annual_kwh__c = uas.Subscription_Orders__r[0].New_Annual_kWh__c,
            Comments__c = 'soReverted'
        );
        insert soReverted;
    }

    @IsTest
    private static void systemTest() {
        Test.startTest();
        List<Subscription_Order__c> subscriptionOrders = [
            SELECT Id, Utility_Account_Subscription__r.Shared_Solar_System__r.Name, Utility_Account_Subscription__r.Opportunity__r.StageName,
                Invoice_Line_Item__c, Effective_Date__c, Client_Invoicing_Fee__c, Potential_Client_Invoicing_Fee__c, Client_Assignment_Agreement__c,
                Utility_Account_Subscription__r.Shared_Solar_System__r.Client_Account__r.Name, Previous_Annual_kwh__c, New_Annual_kWh__c, Comments__c,
                Utility_Account_Subscription__r.Shared_Solar_System__r.Contract_Assignment_Entity__c
            FROM Subscription_Order__c
            WHERE Client_Invoicing_Fee__c != NULL
        ];
        // We want to generate some Client Invoicing Memos to test invoicing those records, but can't use the Waive Reacq Fee
        // function on the CFD, because we also want to generate some SOs for downsizing, to test netting to zero. So,
        // we'll just create some CIMs manually.
        List<Client_Invoicing_Memo__c> clientInvoicingMemos = new List<Client_Invoicing_Memo__c>();
        for (Subscription_Order__c so : subscriptionOrders) {
            clientInvoicingMemos.add(new Client_Invoicing_Memo__c(
                Subscription_Order__c = so.Id,
                Amount__c = -so.Client_Invoicing_Fee__c,
                Effective_Date__c = System.today()
            ));
        }
        insert clientInvoicingMemos;

        System.assertEquals(2, subscriptionOrders.size(),
            'Unexpected number of Subscription Orders in testSetup');
        System.assertEquals(2, clientInvoicingMemos.size(),
            'Unexpected Client Invoicing Memos in testSetup');

        InvocableCSFeeSelector.FeeRequest feeRequest = new InvocableCSFeeSelector.FeeRequest();
        feeRequest.clientAccountId = subscriptionOrders[0].Utility_Account_Subscription__r.Shared_Solar_System__r.Client_Account__c;
        feeRequest.effectiveDate = System.now();
        feeRequest.forAcquisition = false;
        feeRequest.clientEntityId = subscriptionOrders[0].Utility_Account_Subscription__r.Shared_Solar_System__r.Contract_Assignment_Entity__c;
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
        generationRequest.forAcquisition = false;
        generationRequest.clientEntityId = subscriptionOrders[0].Utility_Account_Subscription__r.Shared_Solar_System__r.Contract_Assignment_Entity__c;

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
        System.assertEquals(4, invoiceLineItems.size(),
            'Expected 4 invoice line items for the generated invoice');
        invoiceLineItems = [
            SELECT Id, Amount__c, Subscription_Order__c, Client_Invoicing_Memo__c
            FROM Invoice_Line_Item__c
            WHERE Nets_to_Zero__c = TRUE
        ];
        System.assertEquals(2, invoiceLineItems.size(),
            'Two line items should have Nets to Zero checked');

        subscriptionOrders = [
            SELECT Id, Invoice_Line_Item__c
            FROM Subscription_Order__c
            WHERE Id IN :subscriptionOrders
            AND Invoice_Line_Item__c = NULL
        ];
        System.assertEquals(0, subscriptionOrders.size(),
            'Expected all Subscription Orders to get invoiced');
        subscriptionOrders = [
            SELECT Id, Invoice_Line_Item__c
            FROM Subscription_Order__c
            WHERE Invoice_Date__c = NULL
            AND Invoice_Line_Item__c != NULL
        ];
        System.assertEquals(0, subscriptionOrders.size(),
            'Expected all Subscription Orders to have an Invoice Date');
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
        Test.stopTest();

        // Tests InvocableClientInvoiceLineItemGenerator.generateLineItem
        InvocableClientInvoiceLineItemGenerator.generateLineItem(lineItemRequests);
        invoiceLineItems = [SELECT Id FROM Invoice_Line_Item__c WHERE Invoice__c = :invoice.Id];
        System.assertEquals(3, invoiceLineItems.size(),
            'Unexpected invoice line items left after deleting one invoice line item (via flow)');
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

    @IsTest
    private static void testGetSubscriptionOrdersNettingToZero() {
        ClientInvoiceGenerator clientInvoiceGenerator = new ClientInvoiceGenerator();
        List<Subscription_Order__c> subscriptionOrders = new List<Subscription_Order__c>();
        Id sssId = Util.getFakeId(Shared_Solar_System__c.SObjectType);
        subscriptionOrders.add(getSO('12345', sssId, 10));
        subscriptionOrders.add(getSO('12345', sssId, -10));
        System.assertEquals(2, clientInvoiceGenerator.getSubscriptionOrdersNettingToZero(subscriptionOrders).size(),
            'Expected two SOs to net each other out');
        subscriptionOrders.add(getSO('12345', sssId, -10));
        System.assertEquals(0, clientInvoiceGenerator.getSubscriptionOrdersNettingToZero(subscriptionOrders).size(),
            'Since invoicing fees do not net out for the UAN and System, should not get any SOs to net');
        subscriptionOrders.add(getSO('123-45', sssId, 10));
        System.assertEquals(0, clientInvoiceGenerator.getSubscriptionOrdersNettingToZero(subscriptionOrders).size(),
            'Since the latest SO does not have the same utility account number, it will not net out');
        subscriptionOrders.add(getSO('123-45', Util.incrementFakeId(sssId), -10));
        System.assertEquals(0, clientInvoiceGenerator.getSubscriptionOrdersNettingToZero(subscriptionOrders).size(),
            'Since the latest SO does not have the same project, it will not net out');
        subscriptionOrders.add(getSO('123-45', Util.incrementFakeId(sssId), 10));
        System.assertEquals(2, clientInvoiceGenerator.getSubscriptionOrdersNettingToZero(subscriptionOrders).size(),
            'Since the latest SO has the same UAN and project, it should net out');
    }

    @IsTest
    private static void netsToZeroShouldRespectAssignmentsVsChanges() {
        Subscription_Order__c assignmentSO = getSO('01234', Util.getFakeId(Shared_Solar_System__c.SObjectType), 10);
        assignmentSO.Client_Assignment_Agreement__c = Util.getFakeId(Contract.SObjectType);
        Subscription_Order__c changeSO = getSO('01234', Util.getFakeId(Shared_Solar_System__c.SObjectType), -10);

        MockSubscriptionOrderSelector mockSubscriptionOrderSelector = new MockSubscriptionOrderSelector(
            new List<Subscription_Order__c>{
                assignmentSO, changeSO
            }
        );
        ClientInvoiceGenerator.subscriptionOrderSelector =
            (SubscriptionOrderSelector) Test.createStub(SubscriptionOrderSelector.class, mockSubscriptionOrderSelector);

        new ClientInvoiceGenerator().generateInvoiceForClient(
            Util.getFakeId(Account.SObjectType),
            'Test Client',
            new List<Shared_Solar_System__c>(),
            true, // includeAssignment
            true, // includeChanges
            System.now(),
            true, // forAcquisition
            Util.getFakeId(Entity__c.SObjectType)
        );
        List<Invoice_Line_Item__c> invoiceLineItems =
            (List<Invoice_Line_Item__c>) FFLibHelperTest.getRegisterNewListFromUnitOfWork(ClientInvoiceGenerator.uow, 'Invoice_Line_Item__c');
        System.assertEquals(2, invoiceLineItems.size(), 'There should be a line item for the assignment SO and one for the change');
        System.assertEquals(true, invoiceLineItems[0].Nets_to_Zero__c,
            'The first line item should have Nets_To_Zero__c checked');
        System.assertEquals(true, invoiceLineItems[1].Nets_to_Zero__c,
            'The second line item should have Nets_To_Zero__c checked');

        ClientInvoiceGenerator.uow = new fflib_SObjectUnitOfWork(
            new List<SObjectType> {
                Invoice__c.SObjectType,
                Invoice_Line_Item__c.SObjectType,
                Subscription_Order__c.SObjectType,
                Client_Invoicing_Memo__c.SObjectType
            }
        );
        new ClientInvoiceGenerator().generateInvoiceForClient(
            Util.getFakeId(Account.SObjectType),
            'Test Client',
            new List<Shared_Solar_System__c>(),
            true, // includeAssignment
            false, // includeChanges
            System.now(),
            true, // forAcquisition
            Util.getFakeId(Entity__c.SObjectType)
        );
        invoiceLineItems =
            (List<Invoice_Line_Item__c>) FFLibHelperTest.getRegisterNewListFromUnitOfWork(ClientInvoiceGenerator.uow, 'Invoice_Line_Item__c');
        System.assertEquals(1, invoiceLineItems.size(), 'There should be one line item for the assignment SO');
        System.assertEquals(false, invoiceLineItems[0].Nets_to_Zero__c, 'Since there is only one invoice line item, ' +
            'and it does not net to zero with anything else, Nets_To_Zero__c should not be checked');

        ClientInvoiceGenerator.uow = new fflib_SObjectUnitOfWork(
            new List<SObjectType> {
                Invoice__c.SObjectType,
                Invoice_Line_Item__c.SObjectType,
                Subscription_Order__c.SObjectType,
                Client_Invoicing_Memo__c.SObjectType
            }
        );
        new ClientInvoiceGenerator().generateInvoiceForClient(
            Util.getFakeId(Account.SObjectType),
            'Test Client',
            new List<Shared_Solar_System__c>(),
            false, // includeAssignment
            true, // includeChanges
            System.now(),
            true, // forAcquisition
            Util.getFakeId(Entity__c.SObjectType)
        );
        invoiceLineItems =
            (List<Invoice_Line_Item__c>) FFLibHelperTest.getRegisterNewListFromUnitOfWork(ClientInvoiceGenerator.uow, 'Invoice_Line_Item__c');
        System.assertEquals(1, invoiceLineItems.size(), 'There should be one line item for the change SO');
        System.assertEquals(false, invoiceLineItems[0].Nets_to_Zero__c, 'Since there is only one invoice line item, ' +
            'and it does not net to zero with anything else, Nets_To_Zero__c should not be checked');
    }

    private static Subscription_Order__c getSO(String utilityAccountNumber, Id sssId, Decimal clientInvoicingFee) {
        sfab_FabricatedSObject fabbedUAL = new sfab_FabricatedSObject(Utility_Account_Log__c.class);
        fabbedUAL.setField(Utility_Account_Log__c.Name, utilityAccountNumber);
        sfab_FabricatedSObject fabbedUAS = new sfab_FabricatedSObject(Utility_Account_Subscription__c.class);
        fabbedUAS.setParent('Utility_Account_Log__r', fabbedUAL);
        fabbedUAS.setField(Utility_Account_Subscription__c.Shared_Solar_System__c, sssId);
        sfab_FabricatedSObject fabbedSO = new sfab_FabricatedSObject(Subscription_Order__c.class);
        fabbedSO.setField(Subscription_Order__c.Id, soId);
        soId = Util.incrementFakeId(soId);
        fabbedSO.setField(Subscription_Order__c.Client_Invoicing_Fee__c, clientInvoicingFee);
        fabbedSO.setParent('Utility_Account_Subscription__r', fabbedUAS);
        return (Subscription_Order__c) fabbedSO.toSObject();
    }

    public class MockClientInvoiceGenerator extends MockProvider {
        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'commitWork' {
                    return null;
                } when 'generateLineItemFromCIM' {
                    return null;
                }
            }
            return null;
        }
    }

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

    public class MockSubscriptionOrderSelector extends MockProvider {
        private List<Subscription_Order__c> subscriptionOrders;
        public MockSubscriptionOrderSelector(List<Subscription_Order__c> subscriptionOrdersToReturn) {
            this.subscriptionOrders = subscriptionOrdersToReturn;
        }
        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'getUninvoicedBySSS' {
                    return subscriptionOrders;
                }
            }
            return null;
        }
    }

}