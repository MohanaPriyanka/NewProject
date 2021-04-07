/**
 * Used with PartnerCommissionService. This class handles the triggering events, while the service handles the
 * core logic of creating commission and invoice records.
 * Test: PartnerCommissionServiceTest, UtilityAccountSubscriptionHandlerTest
 */

public without sharing class PartnerCommissionHandler{
    @TestVisible
    private static OpportunitiesSelector oppSelector = new OpportunitiesSelector();
    @TestVisible
    private static JournalEntrySelector glSelector = new JournalEntrySelector();
    @TestVisible
    private List<Opportunity> oppsWithoutInvoiceCommission = new List<Opportunity>();
    @TestVisible
    private List<Opportunity> oppsWithoutPaymentCommission = new List<Opportunity>();
    @TestVisible
    private Map<String, String> acctToJournalEntryMap = new Map<String, String>();
    @TestVisible
    private static FeatureService featureService = new FeatureService();
    @TestVisible
    private static Set<Id> accountIdsFromJournalEntries = new Set<Id>();

    public Set<Id> queuedIds = new Set<Id>();

    public class PendingBillCommission {
        @TestVisible
        private List<Opportunity> firstBillOpps;
        @TestVisible
        private List<Opportunity> firstPaymentOpps;
        public PendingBillCommission() {
            this.firstBillOpps = new List<Opportunity>();
            this.firstPaymentOpps = new List<Opportunity>();
        }
    }

    @Future
    public static void upsertCommissions(Set<Id> accountIds) {
        try {
            PartnerCommissionHandler service = new PartnerCommissionHandler();
            PendingBillCommission oppsToUpdate = service.findUninvoicedCommission(accountIds);
            if (oppsToUpdate.firstBillOpps.size() > 0) {
                callPartnerCommissionService(oppsToUpdate.firstBillOpps, PartnerCommissionService.CommissionType.FIRSTBILLSENT);
            }
            if (oppsToUpdate.firstPaymentOpps.size() > 0) {
                callPartnerCommissionService(oppsToUpdate.firstPaymentOpps, PartnerCommissionService.CommissionType.FIRSTBILLPAID);
            }
        } catch (Exception excep){
            Logger.LogNow(
                'PartnerCommissionHandler',
                'updatePendingCommission',
                excep.getMessage() + '\n' + excep.getStackTraceString() + '\n' + 'AcctIds: ' + JSON.serialize(accountIds),
                Logger.ERROR
            );
        }
    }

    public PendingBillCommission findUninvoicedCommission(Set<Id> accountIds) {
        PendingBillCommission oppsPendingCommission = new PendingBillCommission();
        Set<String> accountsToCheck = getOpportunitiesWithoutCommission(accountIds);
        if (accountsToCheck.size() > 0) {
            setJournalEntryMap(accountsToCheck);
            addEligibleOppToPending(oppsWithoutInvoiceCommission, 'InvoiceItem', oppsPendingCommission.firstBillOpps);
            addEligibleOppToPending(oppsWithoutPaymentCommission, 'PaymentPart', oppsPendingCommission.firstPaymentOpps);
        }
        return oppsPendingCommission;
    }
    private void addEligibleOppToPending(List<Opportunity> oppsWithoutCommission, String journalType, List<Opportunity> opportunitiesToCommission) {
        for (Opportunity opp : oppsWithoutCommission) {
            String accountAndProjectKey = opp.Account.Account_Number__c + opp.Shared_Solar_System__r.Unique_ID__c;
            String journalTypesForCustomerProject = acctToJournalEntryMap.get(accountAndProjectKey);
            if (journalTypesForCustomerProject != null && journalTypesForCustomerProject.contains(journalType)) {
                opportunitiesToCommission.add(opp);
            }
        }
    }

    @TestVisible
    private Set<String> getOpportunitiesWithoutCommission(Set<Id> accountIds) {
        oppsWithoutInvoiceCommission = oppSelector.selectWithoutFirstInvoiceCommission(accountIds);
        oppsWithoutPaymentCommission = oppSelector.selectWithoutFirstPaymentCommission(accountIds);
        Set<String> accountsToCheck = new Set<String>();
        addToAccountsToCheck(oppsWithoutInvoiceCommission, accountsToCheck);
        addToAccountsToCheck(oppsWithoutPaymentCommission, accountsToCheck);

        return accountsToCheck;
    }

    private void addToAccountsToCheck(List<Opportunity> oppsWithoutCommission, Set<String> accountsToCheck) {
        for (Opportunity opp : oppsWithoutCommission) {
            if (isCompleteCSOppWithPartner(opp)) {
                accountsToCheck.add(opp.Account.Account_Number__c);
            }
        }
    }

    @TestVisible
    private void setJournalEntryMap(Set<String> accountsToCheck) {
        List<AggregateResult> journalEntries = glSelector.getCommissionEntriesByAccount(accountsToCheck);
        String accountAndProjectKey;

        for (AggregateResult aggResult : journalEntries){
            String accountNumber = (String) aggResult.get('Customer_Account__c');
            String objectType = (String) aggResult.get('Object_Type__c');
            String sssId =  (String) aggResult.get('Project__c');
            accountAndProjectKey = accountNumber + sssId;

            if (acctToJournalEntryMap.containsKey(accountAndProjectKey)){
                String oldValue = acctToJournalEntryMap.get(accountAndProjectKey);
                acctToJournalEntryMap.put(accountAndProjectKey, oldValue += objectType);
            } else {
                acctToJournalEntryMap.put(accountAndProjectKey, objectType);
            }
        }
    }

    public void queueCalculatePartnerCommission(Set<Id> opportunityIds){
        if (opportunityIds != null && opportunityIds.size() > 0) {
            queuedIds = opportunityIds;
            PartnerCommissionHandler.calculatePartnerCommission(opportunityIds);
        }
    }

    @InvocableMethod(
        Label='CommissionStructureChange'
        Description='Receives opportunity that is having a Commission Structure update from Change Commission Structure flow' )
    public static void invokeCommissionStructureChange(List<Id> opportunityList ) {
        Set<Id> opportunityIds = new Set<Id>(opportunityList);
        calculatePartnerCommission(opportunityIds);
    }

    /**
            Future method that filters opportunities that have undergone a milestone change to ensure they are equipped
            for appropriate Commission Payment.

           @param opportunityIds Opportunities that have experienced some milestone change that requires a Partner Commission
       **/
    @Future
    public static void calculatePartnerCommission(Set<Id> opportunityIds){
        try {
            List<Opportunity> opportunitiesPendingCommission = new List<Opportunity>();
            for (Opportunity opportunity : oppSelector.selectByIdWithCommissionPayment(opportunityIds)){
                if (isCompleteCSOppWithPartner(opportunity) &&
                    (opportunity.Commission_Payments__r.isEmpty() || hasPendingCommissionPayment(opportunity.Commission_Payments__r) )) {
                    opportunitiesPendingCommission.add(opportunity);
                }
            }
            if (opportunitiesPendingCommission.size() > 0){
                callPartnerCommissionService(opportunitiesPendingCommission, PartnerCommissionService.CommissionType.CONTRACTEXECUTION);
            }
        } catch (Exception excep){
            Logger.LogNow(
                'PartnerCommissionHandler',
                'recalculatePartnerCommission',
                excep.getMessage() + '\n' + excep.getStackTraceString() + '\n' + 'OppIds: ' + JSON.serialize(opportunityIds),
                Logger.ERROR
            );
        }
    }

    @TestVisible
    private static Boolean hasPendingCommissionPayment(List<Commission_Payment__c> commissionPayments) {
        for (Commission_Payment__c cp : commissionPayments) {
            if (cp.Status__c == 'Pending Approval') {
                return true;
            }
        }
        return false;
    }

    public static Boolean isCompleteCSOppWithPartner(Opportunity opp){
        if (featureService.isEnabled('Switch_New_Partner_Data_Model') && opp.Partner_Account__c != null) {
            return (opp.StageName == 'Complete'
                && opp.Product_Line__c == 'Community Solar'
                && opp.Partner_Account__r?.Name != 'Placeholder Partner'
                && opp.Partner_Account__r?.Name != 'Bluewave Test Partner'
                && opp.Partner_Account__r?.Name != 'BlueWave Inside Sales'
                && opp.Partner_Account__r?.RecordType.Name != 'Client Account'
            );
        } else {
            return (opp.StageName == 'Complete'
                && opp.Product_Line__c == 'Community Solar'
                && opp.Partner_tag_lookup__r?.Name != 'Placeholder Partner'
                && opp.Partner_tag_lookup__r?.Name != 'Bluewave Test Partner'
                && opp.Partner_tag_lookup__r?.Name != 'BlueWave Inside Sales'
                && opp.Partner_tag_lookup__r?.Account__r.RecordType.Name != 'Client Account'
            );
        }
    }

    private static void callPartnerCommissionService(List<Opportunity> oppList, PartnerCommissionService.CommissionType type){
        PartnerCommissionService newService = new PartnerCommissionService();
        PartnerCommissionService.PendingCommission contractExecution = new PartnerCommissionService.PendingCommission();
        contractExecution.opportunitiesToRun = oppList;
        contractExecution.typeOfCommission = type;
        newService.createCommissionRecords(contractExecution);
    }

    public static void createCommissionPaymentsFromJournalEntries() {
        List<Journal_Entry__c> commissionableJournalEntries = glSelector.getCommissionableEntriesFromToday();
        accountIdsFromJournalEntries = CollectionUtil.mapByIdField(commissionableJournalEntries, Journal_Entry__c.Customer_Lookup__r.Id).keySet();
        upsertCommissions(accountIdsFromJournalEntries);
    }
}