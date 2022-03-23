/**
 * @description Created by jeffparlin on 3/16/22.
 * Tested by: PartnerCommissionGenerationTest
 */
public without sharing class PartnerInvoice {

    @TestVisible private static AccountsSelector accountsSelector = new AccountsSelector();
    @TestVisible private static PartnerInvoiceSelector partnerInvoiceSelector = new PartnerInvoiceSelector();

    public Account partnerAccount;
    public Invoice__c record;
    private Id currentPartner;
    @TestVisible private Date startDate;
    @TestVisible private Date endDate;
    @TestVisible private Date dueDate;
    @TestVisible private Date dueToAccountingDate;
    @TestVisible private String invoiceName;

    public PartnerInvoice(Id partner) {
        this.currentPartner = partner;
        partnerAccount = accountsSelector.getPartnerAccountDetails(currentPartner);
    }

    public void construct() {
        getInvoiceDates(System.today());
        getInvoiceName();
        getInvoiceSObject();
    }

    @TestVisible
    private void getInvoiceDates(Date todaysDate) {
        switch on partnerAccount.Partner_Commission_Frequency__c {
            when 'Weekly' { // Invoice spans single Sales Week as defined as Monday through Sunday
                startDate = getStartOfSalesWeek(todaysDate); // Resolves to nearest past or current Monday
                endDate = startDate.addDays(6); // Resolves to nearest future or current Sunday
                dueToAccountingDate = endDate.addDays(12);
                dueDate = dueToAccountingDate.addDays(7);
            }
            when 'Monthly' {
                startDate = todaysDate.toStartOfMonth();
                endDate = startDate.addMonths(1).addDays(-1);
                Date due = todaysDate.addMonths(1);
                dueToAccountingDate = Date.newInstance(due.year(), due.month(), 3);
                dueDate = Date.newInstance(due.year(), due.month(), 15);
            }
            when else {
                throw new Util.BWException('Invalid Partner_Commission_Frequency__c set on Partner ' +
                    currentPartner + '. Unable to generate Partner Invoice for Partner and continue Commissions process.'
                );
            }
        }
    }

    @TestVisible
    private void getInvoiceName() {
        String name = partnerAccount.Name;
        Datetime dueDateDatetime = Datetime.newInstance(dueDate.year(), dueDate.month(), dueDate.day());
        switch on partnerAccount.Partner_Commission_Frequency__c {
            when 'Weekly' {
                name += ' - Sales Week ' + startDate.format() + ' to ' + endDate.format();
            }
            when 'Monthly' { // Default to Invoice spanning entire month
                name += ' - ' + dueDateDatetime.format('MMMM') + ' ' + String.valueOf(dueDate.year());
            }
        }
        invoiceName = name;
    }

    private void getInvoiceSObject() {
        Id legacyPartnerId = partnerAccount.Partner__c;
        List<Invoice__c> existingInvoices = partnerInvoiceSelector.getPartnerInvoicesForCurrentSalesPeriod(
            legacyPartnerId, startDate
        );
        record = existingInvoices.isEmpty() ? generateNewInvoice() : existingInvoices[0];
    }

    private Invoice__c generateNewInvoice() {
        Invoice__c invoice = new Invoice__c(
            Name = invoiceName,
            Start_Date__c = startDate,
            End_Date__c = endDate,
            Due_Date__c = dueDate,
            Due_to_Accounting__c = dueToAccountingDate,
            Partner__c = partnerAccount.Partner__c,
            Product_Line__c = 'Community Solar',
            Invoice_Type__c = 'Direct',
            Status__c = 'Received >> QC',
            RecordTypeId = SObjectType.Invoice__c.getRecordTypeInfosByDeveloperName().get('Partner_Invoice').getRecordTypeId(),
            Account__c = partnerAccount.Id
        );
        insert invoice;
        return invoice;
    }

    private Date getStartOfSalesWeek(Date today) {
        String currentDayOfWeek = Datetime.newInstance(today, Time.newInstance(0,0,0,0)).format('E');
        return currentDayOfWeek == 'Sun' ? today.addDays(-6) : today.toStartOfWeek().addDays(1);
    }
}