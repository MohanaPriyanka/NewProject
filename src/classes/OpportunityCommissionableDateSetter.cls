/**
 * @description Created by jeffparlin on 2/11/22. Sets fields on Opportunity related to Partner Commission checkpoints.
 * Tested By: OppCommissionableDateSetterTest, BillPeriodServiceTest
 */
public without sharing class OpportunityCommissionableDateSetter {

    private static final String FIRST_BILL_SENT_JOURNAL_TYPE = 'InvoiceItem';
    private static final String FIRST_BILL_PAID_JOURNAL_TYPE = 'PaymentPart';

    @TestVisible private static JournalEntrySelector glSelector = new JournalEntrySelector();
    @TestVisible private static OpportunitiesSelector oppSelector = new OpportunitiesSelector();
    @TestVisible private Map<String, JournalSummary> acctToJournalEntryMap = new Map<String, JournalSummary>();
    @TestVisible private List<Opportunity> opportunitiesToUpdate = new List<Opportunity>();
    private Set<Id> accountIds = new Set<Id>();
    private List<UASB__c> ucbUASBs = new List<UASB__c>();
    private List<Opportunity> firstBillSentOpps = new List<Opportunity>();
    private List<Opportunity> firstBillPaidOpps = new List<Opportunity>();

    /**
     * @description Intended for Opportunities which are paid
     * @param accountIds Account Ids to check all Opportunities where first bill dates are not yet set
     */
    public OpportunityCommissionableDateSetter(Set<Id> accountIds) {
        this.accountIds = accountIds;
    }

    /**
     * @description Intended for UCB only
     * @param ucbUASBs UCB UASBs where First Bill dates need to be set on respective Opportunities
     */
    public OpportunityCommissionableDateSetter(List<UASB__c> ucbUASBs) {
        this.ucbUASBs = ucbUASBs;
    }

    public void execute() {
        try {
            retrieveEligibleOpportunities();
            generateOppUpdateList();
            update opportunitiesToUpdate;
        } catch (Exception e) {
            String message = 'Error encountered when setting Opportunity First Bill dates for Accounts: ' + accountIds
                + '\n\n' + e.getMessage() + '\n\n' + e.getStackTraceString();
            Logger.postLog('OpportunityCommissionableDateSetter', 'execute', message, System.now(), Logger.ERROR);
        }
    }

    public void executeForUCB() {
        try {
            generateUCBOppUpdateList();
            update opportunitiesToUpdate;
        } catch (Exception e) {
            String message = 'Error encountered when setting Opportunity First Bill dates for UCB UASBs: ' + ucbUASBs
                + '\n\n' + e.getMessage() + '\n\n' + e.getStackTraceString();
            Logger.postLog('OpportunityCommissionableDateSetter', 'executeForUCB', message, System.now(), Logger.ERROR);
        }
    }

    private void generateUCBOppUpdateList() {
        Map<Id,Opportunity> oppsToUpdate = new Map<Id,Opportunity>();
        for (UASB__c uasb : ucbUASBs) {
            Date uasbDate = uasb.Date__c;
            Id opportunityId = uasb.Utility_Account_Subscription__r.Opportunity__c;
            Datetime currentFirstBillSentDate = uasb.Utility_Account_Subscription__r.Opportunity__r.First_Bill_Sent_Date__c;
            Datetime currentFirstBillPaidDate = uasb.Utility_Account_Subscription__r.Opportunity__r.First_Bill_Paid_Date__c;
            if (currentFirstBillSentDate != null || currentFirstBillPaidDate != null) {
                continue;
            }

            oppsToUpdate.put(opportunityId, new Opportunity(
                Id = opportunityId,
                First_Bill_Sent_Date__c = uasbDate,
                First_Bill_Paid_Date__c = uasbDate
            ));
        }
        opportunitiesToUpdate = oppsToUpdate.values();
    }

    /**
     * @description Takes retrieved (eligible) opportunities and if criteria is met, buckets them in the appropriate list
     * for updating the first bill date specified
     */
    private void retrieveEligibleOpportunities() {
        List<Opportunity> eligibleFirstBillSentOpps = oppSelector.selectWithoutFirstBillSentStamped(accountIds);
        List<Opportunity> eligibleFirstBillPaidOpps = oppSelector.selectWithoutFirstBillPaidStamped(accountIds);

        setJournalEntryMap();

        processEligibleOpps(eligibleFirstBillSentOpps, FIRST_BILL_SENT_JOURNAL_TYPE, firstBillSentOpps);
        processEligibleOpps(eligibleFirstBillPaidOpps, FIRST_BILL_PAID_JOURNAL_TYPE, firstBillPaidOpps);
    }

    /**
     * @description Compares input Opportunities to what exists in the journal entry map, and if passes criteria,
     * buckets the opportunity appropriately for update later
     * @param eligibleList Eligible opportunities to be checked
     * @param journalType Journal entry type to check map against, either 'InvoiceItem' (first bill sent) or 'PaymentPart'
     * (first bill paid)
     * @param resultList Bucket to put opportunity in for future update
     */
    private void processEligibleOpps(List<Opportunity> eligibleList, String journalType, List<Opportunity> resultList) {
        for (Opportunity opp : eligibleList) {
            String accountAndProjectKey = getMapKey(opp);
            Set<String> journalTypes = acctToJournalEntryMap.get(accountAndProjectKey)?.journalTypes;
            if (journalTypes != null && journalTypes.contains(journalType)) {
                resultList.add(opp);
            }
        }
    }

    /**
     * @description Takes existing Opportunity buckets and merges them. Requires some more advanced merging due to
     * prevent overriding field information.
     */
    private void generateOppUpdateList() {
        Map<Id,Opportunity> oppsToUpdate = new Map<Id,Opportunity>();
        for (Opportunity firstBillSentOpp : firstBillSentOpps) {
            Opportunity opp = (Opportunity) Util.retrieveOrCreateFromMap(firstBillSentOpp.Id, oppsToUpdate);
            opp.First_Bill_Sent_Date__c = acctToJournalEntryMap.get(getMapKey(firstBillSentOpp)).firstBillSentDate;
            oppsToUpdate.put(opp.Id, opp);
        }
        for (Opportunity firstBillPaidOpp : firstBillPaidOpps) {
            Opportunity opp = (Opportunity) Util.retrieveOrCreateFromMap(firstBillPaidOpp.Id, oppsToUpdate);
            opp.First_Bill_Paid_Date__c = acctToJournalEntryMap.get(getMapKey(firstBillPaidOpp)).firstBillPaidDate;
            oppsToUpdate.put(opp.Id, opp);
        }
        opportunitiesToUpdate = oppsToUpdate.values();
    }

    private void setJournalEntryMap() {
        List<Journal_Entry__c> zuoraJournalEntries = glSelector.getCommissionableEntriesFromToday();
        for (Journal_Entry__c journalEntry : zuoraJournalEntries) {
            String accountAndProjectKey = journalEntry.Customer_Account__c + journalEntry.Project__c;
            String journalType = journalEntry.Object_Type__c;

            JournalSummary summary = acctToJournalEntryMap.get(accountAndProjectKey);
            if (summary == null) {
                summary = new JournalSummary();
            }
            summary.journalTypes.add(journalType);
            setDates(summary, journalEntry);

            acctToJournalEntryMap.put(accountAndProjectKey, summary);
        }
    }

    /**
     * @description Sets dates in JournalSummary wrapper object to use later. Note that if a value already exists in the
     * JournalSummary, this method does not override the data. The Journal Entry records used in the parent loop are
     * queried by Date__c ASC, so the first Date set indicates the true value.
     * @param summary JournalSummary wrapper
     * @param journalEntry Current Journal_Entry__c record
     */
    private void setDates(JournalSummary summary, Journal_Entry__c journalEntry) {
        String journalType = journalEntry.Object_Type__c;
        if (summary.firstBillSentDate == null && journalType == FIRST_BILL_SENT_JOURNAL_TYPE) {
            summary.firstBillSentDate = journalEntry.Date__c;
        }
        if (summary.firstBillPaidDate == null && journalType == FIRST_BILL_PAID_JOURNAL_TYPE) {
            summary.firstBillPaidDate = journalEntry.Date__c;
        }
    }

    private String getMapKey(Opportunity opp) {
        return opp.Account.Account_Number__c + opp.Shared_Solar_System__r.Unique_ID__c;
    }

    private class JournalSummary {
        public Date firstBillSentDate;
        public Date firstBillPaidDate;
        public Set<String> journalTypes = new Set<String>();
    }
}