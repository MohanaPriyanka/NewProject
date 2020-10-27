/**
 * @description Relates a Subscription Order or Client Invoicing Memo to an Invoice (if it's not already related)
 * Created by peteryao on 10/21/20.
 * Tested by: ClientInvoiceGeneratorTest
 */

public without sharing class InvocableClientInvoiceLineItemGenerator {
    @TestVisible
    private static ClientInvoiceGenerator clientInvoiceGenerator = new ClientInvoiceGenerator();
    @TestVisible
    private static SubscriptionOrderSelector subscriptionOrderSelector = new SubscriptionOrderSelector();
    @TestVisible
    private static ClientInvoicingMemoSelector clientInvoicingMemoSelector = new ClientInvoicingMemoSelector();

    /**
     * @description Generates an Invoice Line Item relating the SO or CIM to the Invoice, intended to be called from a Flow
     * @param lineItemRequests The requested Subscription Order or Client Invoicing Memo, and the Invoice it should be related to
     * @return The Invoice Line Item inserted
     */
    @InvocableMethod(Label='InvocableClientInvoiceLineItemGenerator' Description='Associates a SO or CIM to an Invoice through a new Invoice Line Item')
    public static List<Invoice_Line_Item__c> generateLineItem(List<LineItemRequest> lineItemRequests) {
        if (lineItemRequests.size() != 1) {
            throw new Util.BWException('We only support associating a single SO or CIM to a single invoice at this time');
        }
        Id soOrCIMId = lineItemRequests[0].soOrCIMId;
        Id invoiceId = lineItemRequests[0].invoiceId;
        Invoice__c invoice = new Invoice__c(Id = invoiceId);
        Invoice_Line_Item__c invoiceLineItem;
        if (soOrCIMId.getSobjectType().getDescribe().getName() == 'Subscription_Order__c') {
            invoiceLineItem = insertLineItemForSO(soOrCIMId, invoice);
        } else if (soOrCIMId.getSobjectType().getDescribe().getName() == 'Client_Invoicing_Memo__c') {
            invoiceLineItem = insertLineItemForCIM(soOrCIMId, invoice);
        }
        return new List<Invoice_Line_Item__c>{invoiceLineItem};
    }

    private static Invoice_Line_Item__c insertLineItemForCIM(Id cimId, Invoice__c invoice) {
        List<Client_Invoicing_Memo__c> clientInvoicingMemos = clientInvoicingMemoSelector.selectByIds(new Set<Id>{cimId});
        if (clientInvoicingMemos[0].Invoice_Line_Item__c == null) {
            Invoice_Line_Item__c invoiceLineItem = clientInvoiceGenerator.generateLineItemFromCIM(clientInvoicingMemos[0], invoice, true, true);
            clientInvoiceGenerator.commitWork();
            return invoiceLineItem;
        }
        return null;
    }

    private static Invoice_Line_Item__c insertLineItemForSO(Id soId, Invoice__c invoice) {
        List<Subscription_Order__c> subscriptionOrders = subscriptionOrderSelector.selectByIds(new Set<Id>{soId});
        if (subscriptionOrders[0].Invoice_Line_Item__c == null) {
            Invoice_Line_Item__c invoiceLineItem =
                clientInvoiceGenerator.generateLineItemFromSO(subscriptionOrders[0], invoice, true, true);
            clientInvoiceGenerator.commitWork();
            return invoiceLineItem;
        }
        return null;
    }

    /**
     * @description Used to pass multiple parameters from Flow to the ClientInvoiceGenerator
     */
    public class LineItemRequest {
        @InvocableVariable(Label='SO or Client Invoicing Memo Id to associate with Invoice')
        public Id soOrCIMId;
        @InvocableVariable(Label='Invoice Id to associate with the SO or CIM')
        public Id invoiceId;
    }
}