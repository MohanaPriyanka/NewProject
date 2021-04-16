/**
 * Created by SarahRenfro on 8/28/2019.
 *
 * TestedBy: TransferPartServiceTest
 */

@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class TransferPartService {
    @TestVisible
    private static ProductionSelector productionSelector = new ProductionSelector();
    public static MultiMap sssToProductionCreditsMap = MultiMap.newListInstance();
    public class ProductionCredits {
        public Production__c production;
        public String type;
        public Decimal creditsTransferred;
        public Decimal untransferredCredits;
        //credits are the updated total number of credits/kwh that have been transferred for a production
    }

    private void generateProductionCredits(List<Production__c> allProductions) {
        for (Production__c prod : allProductions) {
            ProductionCredits prodCredit = new ProductionCredits();
            prodCredit.production = prod;
            prodCredit.type = prod.Billing_Method__c;
            if (prod.Billing_Method__c == 'kWh'){
                prodCredit.creditsTransferred = prod.kWh_Transferred__c;
                prodCredit.untransferredCredits = prod.Untransferred_kWh__c;
            } else {
                prodCredit.creditsTransferred = prod.Credits_Transferred__c;
                prodCredit.untransferredCredits = prod.Untransferred_Credits__c;
            }
            sssToProductionCreditsMap.putValue(prod.Shared_Solar_System__c, prodCredit);
        }
    }

    public void onAfterTransferUpdate(List<Transfer__c> allTransfers, Map<Id, Transfer__c> oldTransferMap){
        List<Transfer__c> transferList = new List<Transfer__c>();
        List<Case> casesToInsert = new List<Case>();
        Group dataOps = [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName = 'Data_Ops' LIMIT 1];

        for (Transfer__c transfer : allTransfers) {
            //Data Ops marks the Transfer as QCed by assigning the Transfer_Type
            if (transfer.Transfer_Type__c != null && oldTransferMap.get(transfer.Id).Transfer_Type__c == null) {
                transferList.add(transfer);
            } else if (transfer.Total_Transferred__c != transfer.Transfer_Amount__c) {
                //Update to an existing Transfer Type that has already been QCed and had Transfer parts created
                Case amountCase = new Case(
                    Subject = 'Untransferred/Overtransferred Credits for Transfer: ' + transfer.Id,
                    Status = 'New',
                    Origin = 'Other',
                    Shared_Solar_System__c = transfer.Shared_Solar_System__c,
                    OwnerId = dataOps.Id,
                    Description = 'The transfer parts that were created for the Transfer: ' + transfer.Id +
                        ' are either more or less than the Transfer Amount. Please investigate.'
                );
                casesToInsert.add(amountCase);
            } else {
                return;
            }
        }

        createPartsFromTransfer(transferList);
        if (casesToInsert.size() > 0 ){
            insert casesToInsert;
        }
    }


    public void onAfterTransferParts(List<Transfer_Part__c> allTransferParts) {
        Set<Id> transferIds = new Set<Id>();
        for (Transfer_Part__c part : allTransferParts){
            if (part.Type__c == 'Transfer'){
                transferIds.add(part.Transfer__c);
            }
        }
        List<Transfer__c> transfersToUpdate = rollupTransferPartsToTransfer(transferIds);
        update transfersToUpdate;
    }

    public void onBeforeDelete(Map<Id, Transfer_Part__c> deletedProductionDetails) {
        List<Transfer_Part__c> deletedDetails = ProductionDetailSelector.getDetailsForDeletion(deletedProductionDetails);
        for (Transfer_Part__c detail : deletedDetails) {
            if (detail.Production__r.Verification_Status__c == 'Verified') {
                Transfer_Part__c triggerDetail = deletedProductionDetails.get(detail.Id);
                triggerDetail.addError('Production Detail cannot be deleted if Production is "Verified"');
            }
        }
    }

    /**
     * @description Summarizes total amount of credits/kwh transferred for a Transfer record after
     * production details have been inserted, updated, or deleted
     * @param transferIds Parent Transfer record to the related production details
     * @return Updated Transfer
     */
    public List<Transfer__c> rollupTransferPartsToTransfer(Set<Id> transferIds){
        List<AggregateResult> results = [
            SELECT Transfer__c, SUM(Amount__c) partsAmount, SUM(kWh_Amount__c) kwhTotal
            FROM Transfer_Part__c
            WHERE Transfer__c IN : transferIds
            AND Type__c = 'Transfer'
            GROUP BY Transfer__c
        ];
        Map<Id, Transfer__c> updatedTransferMap = new Map<Id, Transfer__c>();
        for (Id transferId : transferIds) {
            Transfer__c transfer = new Transfer__c(
                Id = transferId,
                Total_Transferred__c = 0,
                Total_kWh_Transferred__c = 0
            );
            updatedTransferMap.put(transferId, transfer);
        }

        for (AggregateResult result : results) {
            Transfer__c transferRec = updatedTransferMap.get((Id)result.get('Transfer__c'));
            transferRec.Id = (Id)result.get('Transfer__c');
            transferRec.Total_Transferred__c = (Decimal)result.get('partsAmount');
            transferRec.Total_kWh_Transferred__c = (Decimal)result.get('kwhTotal');
        }
        return updatedTransferMap.values();
    }



    public void createPartsFromTransfer(List<Transfer__c> transferList) {
        List<Transfer__c> excessTransfers = new List<Transfer__c>();
        List<Transfer__c> onTimeTransfers = new List<Transfer__c>();

        for (Transfer__c transfer : transferList) {
            switch on transfer.Transfer_Type__c {
                when 'Excess Credit' {
                    excessTransfers.add(transfer);
                } when 'Main' {
                    onTimeTransfers.add(transfer);
                }
            }
        }

        generateProductionCredits(productionSelector.getProductionsForTransfers());
        insertTransferParts(createExcessTransferParts(excessTransfers));
        insertTransferParts(createOnTimeTransferParts(onTimeTransfers));
    }

    /**
     * @description The "Main" Transfer represents the monthly transfer of production credits to customers. It creates
     * one Production Detail for the oldest Production record that has had 0 credits transferred yet
     * @param onTimeTransfers Transfer records that will have their credits transferred to a single production
     * @return Main transfer production details to be inserted
     */
    public static List<Transfer_Part__c> createOnTimeTransferParts(List<Transfer__c> onTimeTransfers) {
        List<Transfer_Part__c> partsToInsert = new List<Transfer_Part__c>();

        for (Transfer__c transfer : onTimeTransfers) {
            //want to grab the first from the production list because it is the oldest
            List<Object> productionCreditObjects = sssToProductionCreditsMap.getValues(transfer.Shared_Solar_System__c);
            for (Object value : productionCreditObjects){
                ProductionCredits prodCredit = (ProductionCredits) value;
                if(prodCredit.creditsTransferred == 0){
                    Production__c production = prodCredit.production;

                    Transfer_Part__c part = new Transfer_Part__c (
                        Name = 'Main Transfer - ' + production.Name,
                        Type__c = 'Transfer',
                        Production__c = production.Id,
                        Transfer__c = transfer.Id,
                        Amount__c = transfer.Transfer_Amount__c,
                        Transfer_Transferred_To__c = transfer.Transferred_To__c,
                        kWh_Amount__c = transfer.Transfer_kWh__c
                    );

                    if (prodCredit.type == 'kWh'){
                        prodCredit.creditsTransferred += transfer.Transfer_kWh__c;
                    } else {
                        prodCredit.creditsTransferred += transfer.Transfer_Amount__c;
                    }

                    partsToInsert.add(part);
                    break;
                } else {
                    //not a production record that qualifies for Main transfers
                    continue;
                }
            }

        }
        return partsToInsert;
    }

    /**
     * @description Excess Transfers are the transfers paid out by the Utility to "true-up" any old Transfers or credits
     * The Excess Transfer will generate multiple Production Details that will fill in any remained "untransferred credits"
     * on production records, filling up the oldest record first
     * @param excessTransfers Transfer record that will have its credits transferred to multiple production records
     * @return Production Details to be inserted
     */
    public static List<Transfer_Part__c> createExcessTransferParts(List<Transfer__c> excessTransfers) {
        List<Transfer_Part__c> partsToInsert = new List<Transfer_Part__c>();
        for (Transfer__c transfer : excessTransfers) {
            Decimal amountToTransfer;
            if (transfer.Billing_Method__c == 'kWh'){
                amountToTransfer = transfer.Transfer_kWh__c;
            } else {
                amountToTransfer = transfer.Transfer_Amount__c;
            }

            List<Object> productionCreditObjects = sssToProductionCreditsMap.getValues(transfer.Shared_Solar_System__c);
            for (Object value : productionCreditObjects){
                ProductionCredits prodCredit = (ProductionCredits) value;
                if(prodCredit.creditsTransferred != 0 && prodCredit.untransferredCredits != 0) {
                    Production__c production = prodCredit.production;
                    if (amountToTransfer > 0){
                        Decimal partAmount = Math.min(prodCredit.untransferredCredits, amountToTransfer);
                        Transfer_Part__c part = new Transfer_Part__c(
                            Name = 'Excess Transfer - ' + production.Name,
                            Type__c = 'Transfer',
                            Production__c = production.Id,
                            Transfer__c = transfer.Id
                        );

                        if (prodCredit.type == 'kWh') {
                            part.kWh_Amount__c = partAmount;
                        } else {
                            part.Amount__c = partAmount;
                        }
                        amountToTransfer -= partAmount;
                        prodCredit.creditsTransferred += partAmount;
                        prodCredit.untransferredCredits -= partAmount;
                        partsToInsert.add(part);
                    }
                } else {
                    //not a production record that is qualified for excess credits
                    continue;
                }
            }
        }
        return partsToInsert;

    }

    public void insertTransferParts(List<Transfer_Part__c> transferParts){
        try {
            insert transferParts;
        } catch (Exception e) {
            Logger.logNow('TransferPartService', 'insertTransferParts', 'Unable to insert Transfer Parts: ' + e.getMessage());
        }
    }
}