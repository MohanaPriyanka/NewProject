/**
 * @description Generates Client Invoices based on Subscription Orders and Client Invoicing Memos related to Shared Solar Systems
 * Created by peteryao on 10/19/20.
 * Tested By: ClientInvoiceGeneratorTest
 */

public without sharing class ClientInvoiceGenerator {
    private static SubscriptionOrderSelector subscriptionOrderSelector = new SubscriptionOrderSelector();
    private static ClientInvoicingMemoSelector clientInvoicingMemoSelector = new ClientInvoicingMemoSelector();
    private static SharedSolarSystemsSelector sharedSolarSystemsSelector = new SharedSolarSystemsSelector();
    private static Id clientInvoicingRecordTypeId =
        Schema.SObjectType.Invoice__c.getRecordTypeInfosByName().get('Client Invoice').getRecordTypeId();

    @TestVisible
    private static fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
        new List<SObjectType> {
            Invoice__c.SObjectType,
            Invoice_Line_Item__c.SObjectType,
            Subscription_Order__c.SObjectType,
            Client_Invoicing_Memo__c.SObjectType
        }
    );

    /**
     * @description Generates invoices, one per client, for the list of SSS
     * @param sssIds List of Shared Solar Systems to get invoices
     * @param includeAssignmentFees True if this should generate an Invoice Line Item for records related to Assignment Agreements
     * @param includeChangeFees True if this should generate an Invoice Line Item for records not related to Assignment Agreements
     * @param effectiveDate Cutoff date for Subscription Orders and Client Invoicing Memos
     * @return List of Invoices
     */
    public List<Invoice__c> generateInvoices(Set<Id> sssIds, Boolean includeAssignmentFees, Boolean includeChangeFees, Datetime effectiveDate) {
        List<Shared_Solar_System__c> sharedSolarSystems = sharedSolarSystemsSelector.selectAll(sssIds);
        MultiMap sssByClientAccount =
            CollectionUtil.multiMapByField(sharedSolarSystems, Shared_Solar_System__c.Client_Account__c);

        List<Invoice__c> invoices = new List<Invoice__c>();
        for (Object clientAccountId : sssByClientAccount.keySet()) {
            List<Shared_Solar_System__c> sharedSolarSystemsForClient =
                (List<Shared_Solar_System__c>) CollectionUtil.toTypedList(sssByClientAccount.getValues(clientAccountId), new List<Shared_Solar_System__c>());
            Invoice__c clientInvoice =
                generateInvoiceForClient(
                    (Id) clientAccountId,
                    sharedSolarSystemsForClient[0].Client_Account__r.Name,
                    sharedSolarSystemsForClient,
                    includeAssignmentFees,
                    includeChangeFees,
                    effectiveDate
                );
            invoices.add(clientInvoice);
        }
        uow.commitWork();
        return invoices;
    }

    /**
     * @description Exposes commitWork from the private uow
     */
    public void commitWork() {
        uow.commitWork();
    }

    private Invoice__c generateInvoiceForClient(Id clientAccountId,
        String clientName,
        List<Shared_Solar_System__c> sharedSolarSystems,
        Boolean includeAssignmentFees,
        Boolean includeChangeFees,
        Datetime effectiveDate
    ) {
        Invoice__c invoice = new Invoice__c(
            Name = clientName + ' ' + System.today().format(),
            RecordTypeId = clientInvoicingRecordTypeId,
            Account__c = clientAccountId,
            Status__c = 'Draft',
            Effective_Date__c = Date.newInstance(effectiveDate.year(), effectiveDate.month(), effectiveDate.day())
        );
        uow.registerNew(invoice);
        List<Subscription_Order__c> subscriptionOrders = subscriptionOrderSelector.getUninvoicedBySSS(sharedSolarSystems, effectiveDate);
        for (Subscription_Order__c subscriptionOrder : subscriptionOrders) {
            generateLineItemFromSO(subscriptionOrder, invoice, includeAssignmentFees, includeChangeFees);
        }
        List<Client_Invoicing_Memo__c> clientInvoicingMemos = clientInvoicingMemoSelector.getUninvoicedBySSS(sharedSolarSystems, effectiveDate);
        for (Client_Invoicing_Memo__c cim : clientInvoicingMemos) {
            generateLineItemFromCIM(cim, invoice, includeAssignmentFees, includeChangeFees);
        }
        return invoice;
    }

    /**
     * @description Registers a new Invoice Line Item with this class's UOW
     * @param subscriptionOrder The Subscription Order to relate to an Invoice
     * @param invoice The Invoice to relate to the Subscription Order
     * @param includeAssignmentFees If True, generates an Invoice Line Item if the SO is related to an Assignment Agreement
     * @param includeChangeFees If True, generates an Invoice Line Item if the SO is not related to an Assignment Agreement
     * @return The Invoice Line Item, or null if none was registered
     */
    public Invoice_Line_Item__c generateLineItemFromSO(
        Subscription_Order__c subscriptionOrder,
        Invoice__c invoice,
        Boolean includeAssignmentFees,
        Boolean includeChangeFees
    ) {
        if ((includeAssignmentFees && subscriptionOrder.Client_Assignment_Agreement__c != null) ||
            (includeChangeFees && subscriptionOrder.Client_Assignment_Agreement__c == null)) {
            LineItemDetails details = new LineItemDetails(subscriptionOrder);
            Invoice_Line_Item__c invoiceLineItem = new Invoice_Line_Item__c(
                Subscription_Order__c = subscriptionOrder.Id,
                Assignment_Agreement_Contract__c = subscriptionOrder.Client_Assignment_Agreement__c,
                Shared_Solar_System__c = subscriptionOrder.Utility_Account_Subscription__r.Shared_Solar_System__c,
                Amount__c = subscriptionOrder.Client_Invoicing_Fee__c,
                Details__c = JSON.serializePretty(details)
            );
            uow.registerNew(invoiceLineItem, Invoice_Line_Item__c.Invoice__c, invoice);
            uow.registerDirty(subscriptionOrder, Subscription_Order__c.Invoice_Line_Item__c, invoiceLineItem);
            return invoiceLineItem;
        }
        return null;
    }

    /**
     * @description Registers a new Invoice Line Item with this class's UOW
     * @param cim The Subscription Order to relate to an Invoice
     * @param invoice The Invoice to relate to the Subscription Order
     * @param includeAssignmentFees If True, generates an Invoice Line Item if the SO is related to an Assignment Agreement
     * @param includeChangeFees If True, generates an Invoice Line Item if the SO is not related to an Assignment Agreement
     * @return The Invoice Line Item, or null if none was registered
    */
    public Invoice_Line_Item__c generateLineItemFromCIM(
        Client_Invoicing_Memo__c cim,
        Invoice__c invoice,
        Boolean includeAssignmentFees,
        Boolean includeChangeFees
    ) {
        if ((includeAssignmentFees && cim.Subscription_Order__r.Client_Assignment_Agreement__c != null) ||
            (includeChangeFees && cim.Subscription_Order__r.Client_Assignment_Agreement__c == null)) {
            LineItemDetails details = new LineItemDetails(cim);
            Invoice_Line_Item__c invoiceLineItem = new Invoice_Line_Item__c(
                Client_Invoicing_Memo__c = cim.Id,
                Subscription_Order__c = cim.Subscription_Order__c,
                Assignment_Agreement_Contract__c = cim.Subscription_Order__r.Client_Assignment_Agreement__c,
                Shared_Solar_System__c = cim.Subscription_Order__r.Utility_Account_Subscription__r.Shared_Solar_System__c,
                Amount__c = cim.Amount__c,
                Details__c = JSON.serializePretty(details)
            );
            uow.registerNew(invoiceLineItem, Invoice_Line_Item__c.Invoice__c, invoice);
            uow.registerDirty(cim, Client_Invoicing_Memo__c.Invoice_Line_Item__c, invoiceLineItem);
            return invoiceLineItem;
        }
        return null;
    }

    private class LineItemDetails {
        private Decimal fee;
        private Id contractFeeDetailId;
        private Decimal approvedChange;
        private String feeType;
        private LineItemDetails(Subscription_Order__c so) {
            this.fee = so.Contract_Fee_Detail__r.Fee__c;
            this.contractFeeDetailId = so.Contract_Fee_Detail__c;
            this.approvedChange = so.Approved_Change_in_Subscription__c;
            if (so.Contract_Fee_Detail__r.Acquisition_Type_Acquisition__c) {
                feeType = 'Acquisition';
            } else if (so.Contract_Fee_Detail__r.Acquisition_Type_Reacquisition__c) {
                feeType = 'Reacqusition';
            } else {
                feeType = 'Neither Acq nor Reacq';
            }
        }
        private LineItemDetails(Client_Invoicing_Memo__c cim) {
            this.fee = cim.Subscription_Order__r.Contract_Fee_Detail__r.Fee__c;
            this.contractFeeDetailId = cim.Subscription_Order__r.Contract_Fee_Detail__c;
            this.approvedChange = cim.Subscription_Order__r.Approved_Change_in_Subscription__c;
            feeType = cim.Type__c;
        }
    }
}