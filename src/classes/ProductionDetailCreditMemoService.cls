// Tested By: ProductionToBillServiceTest
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class ProductionDetailCreditMemoService implements Database.AllowsCallouts{
    @TestVisible
    private List<Transfer_Part__c> productionDetailToInsert = new List<Transfer_Part__c>();
    @TestVisible
    private List<Transfer_Part__c> productionDetailToDelete = new List<Transfer_Part__c>();
    public List<Journal_Entry__c> incompleteEntries = new List<Journal_Entry__c>();
    @TestVisible
    private static ProductionDetailSelector productionDetailSelector = new ProductionDetailSelector();
    @TestVisible
    private static AdjustmentSelector adjustmentSelector = new AdjustmentSelector();

    public Boolean createProductionDetailFromCreditMemo(List<Journal_Entry__c> creditMemoEntries) {
        Boolean requiresRequeue = calculateProductionDetailFromCreditMemo(creditMemoEntries);
        insert productionDetailToInsert;
        delete productionDetailToDelete;
        return requiresRequeue;
    }

    @TestVisible
    private Boolean calculateProductionDetailFromCreditMemo(List<Journal_Entry__c> creditMemoEntries) {
        List<Journal_Entry__c> billItems = new List<Journal_Entry__c>();
        List<Journal_Entry__c> collectionItems = new List<Journal_Entry__c>();
        Boolean requiresRequeue = false;

        for (Journal_Entry__c creditMemo : creditMemoEntries) {
            // If a Credit Memo Journal Entry is marked as "Ready_for_Production_Detail__c" but already
            // has transfer parts, that means it could have been reallocated and we need to re-distribute:
            if (creditMemo.Transfer_Parts__r.size() > 0){
                productionDetailToDelete.addAll(creditMemo.Transfer_Parts__r);
            }
            if (creditMemo.Reason_Code__c == 'Production'){
                billItems.add(creditMemo);
            } else if (ZuoraAPIHelper.getCalloutsRemaining() > 10) {
                // There is only 1 Journal Entry per credit memo, so we need to get the parts (ie, records it is
                // applied to) before reusing the same method that is used for Payment Journal Entries
                collectionItems.addAll(splitCreditMemoIntoParts(creditMemo));
            } else {
                // If we hit the calloutLimit
                requiresRequeue = true;
            }
        }
        createBillItemForCreditMemo(billItems);
        createPaymentItemForCreditMemo(collectionItems);
        return requiresRequeue;
    }

    private void createBillItemForCreditMemo(List<Journal_Entry__c> billItems){
        Set<String> adjustmentExternalIds = new Set<String>();
        Set<Id> transferRecordIds = new Set<Id>();

        for (Journal_Entry__c entry : billItems){
            adjustmentExternalIds.add(entry.External_Id__c);
        }

        Map<String, Bill_Adjustment__c> zuoraIdToAdjustMap = new Map<String, Bill_Adjustment__c>();
        List<Bill_Adjustment__c> adjustmentList = adjustmentSelector.getAdjustmentsFromExternalIds(adjustmentExternalIds);

        for (Bill_Adjustment__c adjust : adjustmentList){
            zuoraIdToAdjustMap.put(adjust.Zuora_Id__c, adjust);
            transferRecordIds.add(adjust.Transfer__c);
        }

        ProductionDetailBillService billService = new ProductionDetailBillService();
        billService.transferToDetailMap = productionDetailSelector.getTransferPartMap(transferRecordIds);

        for (Journal_Entry__c entry : billItems){
            Bill_Adjustment__c sfAdjustment = zuoraIdToAdjustMap.get(entry.External_Id__c);
            billService.createBillProductionDetail(sfAdjustment.Transfer__c, -1 * entry.Amount__c, 'Bill', entry.Id);
            billService.createBillProductionDetail(sfAdjustment.Transfer__c, sfAdjustment.Discount__c, 'Customer Savings', entry.Id);
        }
        productionDetailToInsert.addAll(billService.productionDetailToInsert);
    }

    private void createPaymentItemForCreditMemo(List<Journal_Entry__c> collectionItems){
        ProductionDetailPaymentService payService = new ProductionDetailPaymentService();
        payService.calculateProductionDetailFromCollectionItem(collectionItems);
        productionDetailToInsert.addAll(payService.productionDetailToInsert);
    }

    private List<Journal_Entry__c> splitCreditMemoIntoParts(Journal_Entry__c creditMemo){
        HttpResponse response;
        ZuoraAPI.CreditMemoWithParts memoParts;
        ZuoraAPI.CreditMemoWithItems memoPartItems;
        List<Journal_Entry__c> journalEntriesByPart = new List<Journal_Entry__c>();

        response = ZuoraAPIHelper.callJsonEndpoint('GET', '/v1/creditmemos/'+ creditMemo.External_Id__c +'/parts', null, false);
        memoParts = (ZuoraAPI.CreditMemoWithParts) JSON.deserialize(response.getBody(), ZuoraAPI.CreditMemoWithParts.class);

        for (ZuoraAPI.CreditMemoPart memoPart : memoParts.parts){
            if (memoPart.DebitMemoId != null){
                continue;
            }
            if (memoPart.InvoiceId != null){
                String urlString = '/v1/creditmemos/'+ creditMemo.External_Id__c +'/parts/';
                urlString += memoPart.Id + '/itemparts';
                response = ZuoraAPIHelper.callJsonEndpoint('GET', urlString, null, false);
                memoPartItems = (ZuoraAPI.CreditMemoWithItems) JSON.deserialize(response.getBody(), ZuoraAPI.CreditMemoWithItems.class);
            } else {
                // If credit memo part doesn't have InvoiceId or DebitMemoId, it has an unapplied amount that
                // will need to be allocated to production later. Keep the credit memo marked with
                // 'Ready For Production Detail' until everything has been allocated
                incompleteEntries.add(creditMemo);
            }
        }

        if (memoPartItems != null) {
            for (ZuoraAPI.CreditMemoPartItem partItems : memoPartItems.itemParts) {
                Journal_Entry__c creditMemoPartEntry = new Journal_Entry__c(
                    Id = creditMemo.Id,
                    Applied_Record_Id__c = partItems.InvoiceItemId,
                    Amount__c = partItems.Amount
                );
                journalEntriesByPart.add(creditMemoPartEntry);
            }
        }
        return journalEntriesByPart;
    }
}