/**
 * @description
 * Tested by: PartnerInvoiceSelectorTest, PartnerCommissionGenerationTest
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public inherited sharing class PartnerInvoiceSelector {

    public List<Invoice__c> getPartnerInvoicesForCurrentSalesPeriod(Id partnerId, Date startOfSalesPeriod) {
        return [
            SELECT Id, Partner__c, Due_Date__c, Account__c
            FROM Invoice__c
            WHERE Partner__c =: partnerId
            AND Status__c = 'Received >> QC'
            AND Start_Date__c >=: startOfSalesPeriod
            ORDER BY Due_Date__c ASC
        ];
    }

    public List<Invoice__c> getPendingPartnerInvoices(Set<Id> partnerIds, Date dueDate) {
        List<Invoice__c> partnerInvoices = [
            SELECT Id, Partner__c, Due_Date__c, Account__c
            FROM Invoice__c
            WHERE Partner__c IN : partnerIds
            AND Product_Line__c = 'Community Solar'
            AND Status__c = 'Received >> QC'
            AND Due_Date__c >= : dueDate
            ORDER BY Due_Date__c
        ];
        return partnerInvoices;
    }

}