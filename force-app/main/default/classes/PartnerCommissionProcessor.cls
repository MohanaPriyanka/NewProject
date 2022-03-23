/**
 * @description Created by jeffparlin on 2/25/22. Abstract class for partner commission generation to be extended by
 * a respective type implementation, e.g. VariableRateCommissionProcessor
  * Tested By: PartnerCommissionGenerationTest
 */
public abstract class PartnerCommissionProcessor {

    public Map<Id,Opportunity> opportunities;
    public List<DealSummary> deals = new List<DealSummary>();
    public fflib_SObjectUnitOfWork unitOfWork;
    public Id currentPartner;
    public PartnerInvoice invoice;

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
            invoice = new PartnerInvoice(currentPartner);
            invoice.construct();
        }
        return invoice.record;
    }
}