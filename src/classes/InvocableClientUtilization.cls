/**
 * Created by peteryao on 9/1/20.
 * Tested By: ClientInvoicingUtilizationServiceTest
 */

public without sharing class InvocableClientUtilization {
    @TestVisible
    private static ClientInvoicingUtilizationService clientInvoicingUtilizationService = new ClientInvoicingUtilizationService();

    @InvocableMethod(Label='InvocableClientUtilization' Description='Calculates Client Invoicing Memos for Production Details with changes in utilization')
    public static List<List<Client_Invoicing_Memo__c>> createMemosForUtilizationAdjustments() {
        return new List<List<Client_Invoicing_Memo__c>>{clientInvoicingUtilizationService.createMemosForUtilizationAdjustments()};
    }
}