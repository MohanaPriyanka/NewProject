/**
 * Test: PartnerInvoiceSelectorTest
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public inherited sharing class PartnerInvoiceSelector {
    public List<Invoice__c> getPendingPartnerInvoices(Set<Id> partnerIds) {
        List<Invoice__c> partnerInvoices = [
            SELECT Id, Partner__c, Due_Date__c
            FROM Invoice__c
            WHERE Partner__c IN : partnerIds
            AND Invoice_Type__c = 'Direct'
            AND Product_Line__c = 'Community Solar'
            AND Status__c = 'Received >> QC'
            ORDER BY Due_Date__c DESC
        ];
        return partnerInvoices;
    }
}