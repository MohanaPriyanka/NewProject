/**
 * @description Descriptor Class to represent a Shared Solar System for use in the DatatableV2 component
 * (https://ericsplayground.wordpress.com/how-to-use-an-apex-defined-object-with-my-datatable-flow-component/)
 * Tested By: ClientInvoiceGeneratorTest
 */

public without sharing class SharedSolarSystem {
    @InvocableVariable(Description='Shared Solar System Id')
    @AuraEnabled
    public Id id;

    @InvocableVariable(Description='Shared Solar System Assignment Entity Name')
    @AuraEnabled
    public String assignmentEntityName;

    @InvocableVariable(Description='Shared Solar System Name')
    @AuraEnabled
    public String sharedSolarSystemName;

    @InvocableVariable(Description='Uninvoiced Subscription Orders and Client Invoicing Memos')
    @AuraEnabled
    public Decimal totalChangesToInvoice;

    @InvocableVariable(Description='Uninvoiced Subscription Orders and Client Invoicing Memos')
    @AuraEnabled
    public Decimal totalAssignmentsToInvoice;

    @InvocableVariable(Description='Number of uninvoiced Subscription Orders and Client Invoicing Memos')
    @AuraEnabled
    public Integer uninvoicedRecords;

    /**
     * @description Required no-argument constructor to use in DatatableV2
     */
    @SuppressWarnings('PMD.EmptyStatementBlock')
    public SharedSolarSystem() {}

    /**
     * @description Constructor required to use in DatatableV2
     * @param sharedSolarSystemId Shared Solar System Id
     * @param name Shared Solar System Name
     * @param assignmentEntityName Shared Solar System's Contact Assignment Entity
     * @param totalChangesToInvoice Total uninvoiced SOs and CIMs on the SSS not related to a AA
     * @param totalAssignmentsToInvoice Total uninvoiced SOs and CIMs on the SSS related to a AA
     * @param uninvoicedRecords Total uninvoiced SOs and CIMs on the AA
     */
    public SharedSolarSystem(Id sharedSolarSystemId,
        String name,
        String assignmentEntityName,
        Decimal totalChangesToInvoice,
        Decimal totalAssignmentsToInvoice,
        Integer uninvoicedRecords) {
        this.id = sharedSolarSystemId;
        this.sharedSolarSystemName = name;
        this.assignmentEntityName = assignmentEntityName;
        this.totalChangesToInvoice = totalChangesToInvoice;
        this.totalAssignmentsToInvoice = totalAssignmentsToInvoice;
        this.uninvoicedRecords = uninvoicedRecords;
    }

    /**
     * @description Constructor setting defaults and updating total amount
     * @param aggregateResult An Aggregate Result from SubscriptionOrderSelector.getUninvoicedByClientAccount or
     *  ClientInvoicingMemoSelector.getUninvoicedByClientAccount
     */
    public SharedSolarSystem(AggregateResult aggregateResult) {
        this.id = (Id) aggregateResult.get('Id');
        this.sharedSolarSystemName = (String) aggregateResult.get('SSSName');
        this.assignmentEntityName = (String) aggregateResult.get('ENTITYNAME');
        this.totalChangesToInvoice = 0;
        this.totalAssignmentsToInvoice = 0;
        this.uninvoicedRecords = 0;
        updateTotals(aggregateResult);
    }
    /**
     * @description Takes an Aggregate Result (see SubscriptionOrderSelector.getUninvoicedByClientAccount or
     *  ClientInvoicingMemoSelector.getUninvoicedByClientAccount) and adds to this SharedSolarSystem instance,
     *  either in Total Assignments or Total Changes, and the record count
     * @param aggregateResult The AggregateResult from the SO or CIMSelector
     */
    public void updateTotals(AggregateResult aggregateResult) {
        addAmountToInvoice(aggregateResult);
        addToUninvoicedRecords((Integer) aggregateResult.get('NUM'));
    }
    private void addAmountToInvoice(AggregateResult aggregateResult) {
        if (aggregateResult.get('ASSIGNMENTAGREEMENT') != null) {
            totalAssignmentsToInvoice += (Decimal) aggregateResult.get('TOTAL');
        } else {
            totalChangesToInvoice += (Decimal) aggregateResult.get('TOTAL');
        }
    }
    private void addToUninvoicedRecords(Integer numberOfRecords) {
        uninvoicedRecords += numberOfRecords;
    }
}