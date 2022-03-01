/**
 * Created by jeffparlin on 2/24/22.
 */
public without sharing class PartnerCommissionGenerator implements Queueable, Finalizer {

    @TestVisible private static OpportunitiesSelector oppSelector = new OpportunitiesSelector();
    @TestVisible private static AccountsSelector accountsSelector = new AccountsSelector();

    private Id currentPartner;
    private List<Id> partnersToProcess;
    private Map<Id,Opportunity> variableRateOpportunities;
    private fflib_SObjectUnitOfWork unitOfWork;
    private Invoice__c partnerInvoice;

    public PartnerCommissionGenerator(List<Id> partnerAccountIds) {
        this.partnersToProcess = partnerAccountIds;
        this.currentPartner = partnerAccountIds.get(partnerAccountIds.size()-1);
    }

    public void execute(QueueableContext ctx) {
        executeSynchronous();
    }

    public void execute(FinalizerContext ctx) {
        // Chain next job if any partner Ids remain to have yet be processed
        partnersToProcess.remove(partnersToProcess.size()-1);
        if (!partnersToProcess.isEmpty()) {
            System.enqueueJob(new PartnerCommissionGenerator(partnersToProcess));
        }
    }

    public void executeSynchronous() {
        unitOfWork = new fflib_SObjectUnitOfWork(new List<SObjectType> {
            Commission_Payment__c.SObjectType,
            Subscription_Order__c.SObjectType
        });
        try {
            createPartnerInvoice();
            generateCommissionPayments();
        } catch (Exception e) {
            String message = e.getMessage() + '\n\n' + e.getStackTraceString();
            Logger.postLog('PartnerCommissionGenerator', 'execute (Queueable)', message, System.now(), Logger.ERROR);
        }
    }

    private void createPartnerInvoice() {
        Account partnerAccount = accountsSelector.getPartnerAccountDetails(currentPartner);
        Date dueDate = getDueDate();
        Id recordTypeId = SObjectType.Invoice__c.getRecordTypeInfosByDeveloperName().get('Partner_Invoice').getRecordTypeId();
        Date dueToAccountingDate = Date.newInstance(dueDate.year(), dueDate.month(), 3);
        Datetime dueDatetime = Datetime.newInstance(dueDate.year(), dueDate.month(), dueDate.day());
        String monthName = dueDatetime.format('MMMMM');

        Invoice__c invoice = new Invoice__c(
            Name = (partnerAccount.Name + ' ' + monthName + ' ' + String.valueOf(dueDate.year())).left(80),
            Due_Date__c = dueDate,
            Due_to_Accounting__c = dueToAccountingDate,
            Invoice_Type__c = 'Direct',
            Partner__c = partnerAccount.Partner__c,
            Product_Line__c = 'Community Solar',
            Status__c = 'Received >> QC',
            RecordTypeId = recordTypeId,
            Account__c = partnerAccount.Id
        );
        insert invoice;
        this.partnerInvoice = invoice;
    }

    private Date getDueDate() {
        Date monthFromToday = System.today().addMonths(1);
        return Date.newInstance(monthFromToday.year(), monthFromToday.month(), 15);
    }

    private void generateCommissionPayments() {
        variableRateOpportunities = oppSelector.getVariableRateCommissionOppsForPartner(currentPartner);
        if (!variableRateOpportunities.isEmpty()) {
            new VariableRateCommissionProcessor(variableRateOpportunities, unitOfWork, partnerInvoice).generateCommissionPayments();
        }
        unitOfWork.commitWork();
    }
}