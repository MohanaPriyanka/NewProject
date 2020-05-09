@IsTest
public with sharing class PartnerInvoiceSelectorTest {
    @TestSetup public static void testSetup() {
        CommissionStructureSelectorTest.testSetup();
        List<Partner__c> partners = [
            SELECT Id
            FROM Partner__c
        ];

        Invoice__c partnerInvoiceOne = new Invoice__c(
            Name = 'Partner One January 2020',
            Due_Date__c = Date.newInstance(2020,03,14),
            Due_to_Accounting__c = Date.newInstance(2020,03,14),
            Invoice_Type__c = 'Direct',
            Partner__c = partners[0].Id,
            Product_Line__c = 'Community Solar',
            Status__c = 'Received >> QC'
        );
        Invoice__c partnerInvoiceTwo = new Invoice__c(
            Name = 'Partner One January 2020',
            Due_Date__c = Date.newInstance(2020,03,14),
            Due_to_Accounting__c = Date.newInstance(2020,03,14),
            Invoice_Type__c = 'Direct',
            Partner__c = partners[1].Id,
            Product_Line__c = 'Community Solar',
            Status__c = 'Received >> QC'
        );
        insert partnerInvoiceOne;
        insert partnerInvoiceTwo;
    }

    @isTest
    public static void testGetPendingPartnerInvoices() {
        List<Partner__c> partners = [
            SELECT Id
            FROM Partner__c
        ];

        PartnerInvoiceSelector selector = new PartnerInvoiceSelector();
        List<Invoice__c> invoices = selector.getPendingPartnerInvoices(
            new Set<Id>{partners[0].Id, partners[1].Id}
        );

        System.assertEquals(2,invoices.size());
    }
}