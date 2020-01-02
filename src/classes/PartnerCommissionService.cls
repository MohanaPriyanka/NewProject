/**
 * Test: PartnerCommissionServiceTest
 */

public class PartnerCommissionService{
    @TestVisible
    private static OpportunitiesSelector oppSelector = new OpportunitiesSelector();
    @TestVisible
    private static ZuoraGLSelector glSelector = new ZuoraGLSelector();
    @TestVisible
    private Set<Opportunity> allOpsToCheck = new Set<Opportunity>();
    @TestVisible
    private Map<String, String> acctToJournalEntryMap = new Map<String, String>();

    @TestVisible
    private class PendingCommission {
        @TestVisible
        private List<Opportunity> FirstBillOpps;
        @TestVisible
        private List<Opportunity> FirstPaymentOpps;
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
            PartnerCommissionService service = new PartnerCommissionService();
            PendingCommission oppsToUpdate = service.findUninvoicedCommission(accountIds);

            if (oppsToUpdate.FirstBillOpps != null) {
                for (Opportunity invOpp : oppsToUpdate.FirstBillOpps) {
                    service.launchFlowForOpp(invOpp, 'First Bill Sent');
                }
            }
            if (oppsToUpdate.FirstPaymentOpps != null) {
                for (Opportunity payOpp : oppsToUpdate.FirstPaymentOpps) {
                    service.launchFlowForOpp(payOpp, 'First Bill Paid');
                }
            }
        } catch (Exception excep){
            Logger.LogNow(
                'PartnerCommissionService',
                'updatePendingCommission',
                excep.getMessage() + '\n' + excep.getStackTraceString() + '\n' + 'AcctIds: ' + JSON.serialize(accountIds),
                Logger.ERROR
            );
        }
    }

    public void launchFlowForOpp(Opportunity opp, String type){
        Map<String, Object> params = new Map<String, Object>();
        Decimal commissionAmount;
        if (type == 'First Bill Paid'){
            commissionAmount = opp.CS_Capacity_Allocated__c*opp.Commission_Structure__r.Cents_kW_DC_First_Bill_Paid__c *1000;
            params.put('FirstBillPaidCommission',commissionAmount);
        } else if (type == 'First Bill Sent') {
            commissionAmount = opp.CS_Capacity_Allocated__c *opp.Commission_Structure__r.Cents_kW_DC_First_Bill__c*1000;
            params.put('FirstBillCommission',commissionAmount);
        }
        params.put('ActiveCommissionStructure',opp.Commission_Structure__c);
        params.put('OpportunityID',opp.Id);
        params.put('OpportunityName',opp.Name);
        params.put('PartnerID',opp.Partner_tag_lookup__r.Id);
        params.put('PartnerName',opp.Partner_tag_lookup__r.Name);
        params.put('varCommissionPaymentType',type);
        Flow.Interview.CS_Partner_Invoice_Creation myFlow = new Flow.Interview.CS_Partner_Invoice_Creation(params);
        myFlow.start();
    }

    public PendingCommission findUninvoicedCommission(Set<Id> accountIds) {
        PendingCommission oppsPendingCommission = new PendingCommission();
        Set<String> accountsToCheck = getOpportunitiesWithoutCommission(accountIds);

        if (accountsToCheck.size() > 0) {
            setJournalEntryMap(accountsToCheck);
            String accountAndProjectKey;
            oppsPendingCommission.FirstBillOpps = new List<Opportunity>();
            oppsPendingCommission.FirstPaymentOpps = new List<Opportunity>();

            for (Opportunity opp : allOpsToCheck) {
                accountAndProjectKey = opp.Account.Account_Number__c + opp.Shared_Solar_System__r.Unique_ID__c;
                Boolean hasEntries = acctToJournalEntryMap.containsKey(accountAndProjectKey);
                String objects;
                if (hasEntries) {
                    objects = acctToJournalEntryMap.get(accountAndProjectKey);
                }
                if (hasEntries && objects.contains('InvoiceItem')) {
                    oppsPendingCommission.FirstBillOpps.add(opp);
                }
                if (hasEntries && objects.contains('PaymentPart')) {
                    oppsPendingCommission.FirstPaymentOpps.add(opp);
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
            accountsToCheck.add(opp.Account.Account_Number__c);
            allOpsToCheck.add(opp);
        }
        for (Opportunity opp : oppsWithoutPaymentCommission){
            accountsToCheck.add(opp.Account.Account_Number__c);
            allOpsToCheck.add(opp);
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
}