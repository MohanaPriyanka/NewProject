/**
 * @description Created by jeffparlin on 2/25/22. Abstract class for partner commission generation to be extended by
 * a respective type implementation, e.g. VariableRateCommissionProcessor
  * Tested By: PartnerCommissionGenerationTest
 */
public abstract class PartnerCommissionProcessor {

    @TestVisible private static AccountsSelector accountsSelector = new AccountsSelector();
    @TestVisible private static PartnerInvoiceSelector partnerInvoiceSelector = new PartnerInvoiceSelector();
    public Map<Id,Opportunity> opportunities;
    public List<DealSummary> deals = new List<DealSummary>();
    public fflib_SObjectUnitOfWork unitOfWork;
    public Id currentPartner;
    private Invoice__c invoice;
    private Account currentPartnerAccount;

    public abstract void retrieveDependencies();
    public abstract void generateCommissionPayments();

    public class DealSummary {
        public Opportunity opportunity;
        public List<Subscription_Order__c> subscriptionOrders;
        public List<Utility_Account_Log__c> utilityAccountLogs;
        public List<Commission_Payment__c> commissionPayments;
    }

    public Invoice__c getInvoiceForPartner() {
        if (invoice == null) {
            locatePartnerInvoice();
        }
        return invoice;
    }

    private void locatePartnerInvoice() {
        currentPartnerAccount = accountsSelector.getPartnerAccountDetails(currentPartner);
        Id legacyPartnerId = currentPartnerAccount.Partner__c;
        List<Invoice__c> existingInvoices = partnerInvoiceSelector.getPendingPartnerInvoices(
            new Set<Id>{legacyPartnerId}, getDueDate()
        );
        invoice = !existingInvoices.isEmpty() ? existingInvoices[0] : createPartnerInvoice();
    }

    private Invoice__c createPartnerInvoice() {
        Date dueDate = getDueDate();
        Id recordTypeId = SObjectType.Invoice__c.getRecordTypeInfosByDeveloperName().get('Partner_Invoice').getRecordTypeId();
        Date dueToAccountingDate = Date.newInstance(dueDate.year(), dueDate.month(), 3);
        Datetime dueDatetime = Datetime.newInstance(dueDate.year(), dueDate.month(), dueDate.day());

        Invoice__c invoice = new Invoice__c(
            Name = currentPartnerAccount.Name + ' ' + dueDatetime.format('MMMM dd, yyyy'),
            Due_Date__c = dueDate,
            Due_to_Accounting__c = dueToAccountingDate,
            Invoice_Type__c = 'Direct',
            Partner__c = currentPartnerAccount.Partner__c,
            Product_Line__c = 'Community Solar',
            Status__c = 'Received >> QC',
            RecordTypeId = recordTypeId,
            Account__c = currentPartnerAccount.Id
        );
        insert invoice;
        return invoice;
    }

    private Date getDueDate() {
        Date monthFromToday = System.today().addMonths(1);
        return Date.newInstance(monthFromToday.year(), monthFromToday.month(), 15);
    }
}