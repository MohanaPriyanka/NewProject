/**
 * Used with PartnerCommissionService. This class handles the triggering events, while the service handles the
 * core logic of creating commission and invoice records.
 * Test: PartnerCommissionServiceTest, UtilityAccountSubscriptionHandlerTest
 */

public class PartnerCommissionHandler{
    @TestVisible
    private static OpportunitiesSelector oppSelector = new OpportunitiesSelector();
    @TestVisible
    private static JournalEntrySelector glSelector = new JournalEntrySelector();
    @TestVisible
    private Set<Opportunity> allOpsToCheck = new Set<Opportunity>();
    @TestVisible
    private Map<String, String> acctToJournalEntryMap = new Map<String, String>();

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

    public static void onAfterInvoiceInsert(List<Zuora__ZInvoice__c> zInvoices) {
        Set<Id> accountIds = new Set<Id>();
        for (Zuora__ZInvoice__c inv : zInvoices){
            accountIds.add(inv.Zuora__Account__c);
        }
        updatePendingCommission(accountIds);
    }

    public static void onAfterPaymentInsert(List<Zuora__Payment__c> zPayments) {
        Set<Id> accountIds = new Set<Id>();
        for (Zuora__Payment__c pay : zPayments){
            accountIds.add(pay.Zuora__Account__c);
        }
        updatePendingCommission(accountIds);
    }

    @Future
    public static void updatePendingCommission(Set<Id> accountIds) {
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
            String accountAndProjectKey;

            for (Opportunity opp : allOpsToCheck) {
                accountAndProjectKey = opp.Account.Account_Number__c + opp.Shared_Solar_System__r.Unique_ID__c;
                Boolean hasEntries = acctToJournalEntryMap.containsKey(accountAndProjectKey);
                String objects;
                if (hasEntries) {
                    objects = acctToJournalEntryMap.get(accountAndProjectKey);
                }
                if (hasEntries && objects.contains('InvoiceItem')) {
                    oppsPendingCommission.firstBillOpps.add(opp);
                }
                if (hasEntries && objects.contains('PaymentPart')) {
                    oppsPendingCommission.firstPaymentOpps.add(opp);
                }
            }
        }
        return oppsPendingCommission;
    }

    @TestVisible
    private Set<String> getOpportunitiesWithoutCommission(Set<Id> accountIds) {
        List<Opportunity> oppsWithoutInvoiceCommission = oppSelector.selectWithoutFirstInvoiceCommission(accountIds);
        List<Opportunity> oppsWithoutPaymentCommission = oppSelector.selectWithoutFirstPaymentCommission(accountIds);
        Set<String> accountsToCheck = new Set<String>();

        for (Opportunity opp : oppsWithoutInvoiceCommission){
            if (isCompleteCSOppWithPartner(opp)){
                accountsToCheck.add(opp.Account.Account_Number__c);
                allOpsToCheck.add(opp);
            }
        }
        for (Opportunity opp : oppsWithoutPaymentCommission){
            if (isCompleteCSOppWithPartner(opp)){
                accountsToCheck.add(opp.Account.Account_Number__c);
                allOpsToCheck.add(opp);
            }
        }
        return accountsToCheck;
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
        queuedIds = opportunityIds;
        PartnerCommissionHandler.calculatePartnerCommission(opportunityIds);
    }

    @InvocableMethod(Label='CommissionStructureChange' Description='Receives opportunity that is having a Commission Structure update' )
    public static void invokeCommissionStructureChange(List<Id> opportunityList ) {
        Set<Id> opportunityIds = new Set<Id>(opportunityList);
        calculatePartnerCommission(opportunityIds);
    }

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
        return (opp.StageName == 'Complete'
            && opp.Product_Line__c == 'Community Solar'
            && opp.Partner_tag_lookup__c != null
            && opp.Partner_tag_lookup__r.Name != 'Placeholder Partner'
            && opp.Partner_tag_lookup__r.Name != 'Bluewave Test Partner'
            && opp.Partner_tag_lookup__r.Name != 'BlueWave Inside Sales');
    }

    private static void callPartnerCommissionService(List<Opportunity> oppList, PartnerCommissionService.CommissionType type){
        PartnerCommissionService newService = new PartnerCommissionService();
        PartnerCommissionService.PendingCommission contractExecution = new PartnerCommissionService.PendingCommission();
        contractExecution.opportunitiesToRun = oppList;
        contractExecution.typeOfCommission = type;
        newService.createCommissionRecords(contractExecution);
    }
}