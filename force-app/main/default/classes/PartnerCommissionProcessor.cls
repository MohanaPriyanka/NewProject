/**
 * Created by jeffparlin on 2/25/22.
 */
public abstract class PartnerCommissionProcessor {

    public Map<Id,Opportunity> opportunities;
    public List<DealSummary> deals = new List<DealSummary>();
    public fflib_SObjectUnitOfWork unitOfWork;
    public Invoice__c invoice;

    public abstract void retrieveDependencies();
    public abstract void generateCommissionPayments();

    public class DealSummary {
        public Opportunity opportunity;
        public List<Subscription_Order__c> subscriptionOrders;
        public List<Utility_Account_Log__c> utilityAccountLogs;
        public List<Commission_Payment__c> commissionPayments;
    }

}