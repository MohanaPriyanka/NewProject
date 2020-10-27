/**
 * @description Generates a Client Invoice for a list of SharedSolarSystem records (from DatatableV2 output)
 * Created by peteryao on 10/19/20.
 * Tested By: ClientInvoiceGeneratorTest
 */

public without sharing class InvocableClientInvoiceGenerator {
    private static ClientInvoiceGenerator invoiceGenerator = new ClientInvoiceGenerator();

    /**
     * @description Generates an Invoice and Invoice Line Items for the selected Shared Solar Systems, to be called from a Flow
     * @param requests The requested SSSes to invoice, with toggles for Assignments and/or changes
     * @return The Invoices that it inserted
     */
    @InvocableMethod(Label='InvocableClientInvoiceGenerator' Description='Generates an Invoice and Invoice Line Items for the selected Shared Solar Systems')
    public static List<List<Invoice__c>> generateInvoice(List<InvoiceGenerationRequest> requests) {
        if (requests.size() != 1) {
            throw new Util.BWException('We only support one request at a time');
        }
        InvoiceGenerationRequest request = requests[0];
        List<SharedSolarSystem> sharedSolarSystems =
            (List<SharedSolarSystem>) JSON.deserialize(request.sharedSolarSystemJSON, List<SharedSolarSystem>.class);
        Set<Id> sssIds = new Set<Id>();
        for (SharedSolarSystem sss : sharedSolarSystems) {
            sssIds.add(sss.id);
        }
        List<Invoice__c> invoices = invoiceGenerator.generateInvoices(
            sssIds,
            request.includeAssignmentFees,
            request.includeChangeFees,
            request.effectiveDate
        );
        return new List<List<Invoice__c>>{invoices};
    }

    /**
     * @description Used to pass multiple parameters from Flow to the ClientInvoiceGenerator
     */
    public class InvoiceGenerationRequest {
        @InvocableVariable(Label='Serialized list of SharedSolarSystem')
        public String sharedSolarSystemJSON;
        @InvocableVariable(Label='Include SOs and CIMs related to an Assignment Agreement')
        public Boolean includeAssignmentFees;
        @InvocableVariable(Label='Include change SOs and CIMs (those not related to an Assignment Agreement)')
        public Boolean includeChangeFees;
        @InvocableVariable(Label='Effective Date')
        public Datetime effectiveDate;
    }
}