/**
 * Created by SarahRenfro on 8/28/2019.
 *
 * TestedBy: TransferPartServiceTest
 */

@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class TransferPartService {
    public static Map<Id, List<ProductionCredits>> sssToProductionMap = new Map<Id, List<ProductionCredits>>();

    public class ProductionCredits {
        public Production__c production;
        public String type;
        public Decimal creditsTransferred;
        public Decimal untransferredCredits;
        //credits are the updated total number of credits/kwh that have been transferred for a production
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

        if (transferList.size() > 0) {
            createPartsFromTransfer(transferList);
        }
        if (casesToInsert.size() > 0 ){
            insert casesToInsert;
        }
    }


    public void onAfterTransferParts(List<Transfer_Part__c> allTransferParts) {
        System.debug('Is the onAfterTransferParts called? ');
        List<Transfer__c> transfersToUpdate = rollupTransferPartsToTransfer(allTransferParts);

        if (transfersToUpdate != null){
            update transfersToUpdate;
        }
    }


    public List<Transfer__c> rollupTransferPartsToTransfer(List<Transfer_Part__c> allTransferParts){
        //When transfer parts are inserted or updated, they need to write back to their Transfer records
        Set<Id> transferIds = new Set<Id>();
        for (Transfer_Part__c part : allTransferParts){

            if (part.Type__c == 'Transfer'){
                transferIds.add(part.Transfer__c);
            } else {
                return null;
            }
        }

        List<AggregateResult> results = [
            SELECT Transfer__c, SUM(Amount__c) partsAmount, SUM(kWh_Amount__c) kwhTotal
            FROM Transfer_Part__c
            WHERE Transfer__c IN : transferIds
            GROUP BY Transfer__c
        ];


        List<Transfer__c> updatedTransfers = new List<Transfer__c>();

        for (AggregateResult result : results) {
            Transfer__c transferRec = new Transfer__c();
            transferRec.Id = (Id)result.get('Transfer__c');
            transferRec.Total_Transferred__c = (Decimal)result.get('partsAmount');
            transferRec.Total_kWh_Transferred__c = (Decimal)result.get('kwhTotal');
            updatedTransfers.add(transferRec);
        }
        return updatedTransfers;


    }

    public void createPartsFromTransfer(List<Transfer__c> transferList) {
        List<Transfer__c> excessTransfers = new List<Transfer__c>();
        List<Transfer__c> onTimeTransfers = new List<Transfer__c>();
        List<Transfer__c> returnedTransfers = new List<Transfer__c>();

        for (Transfer__c transfer : transferList) {
            if (transfer.Transfer_Type__c == 'Excess Credit') {
                excessTransfers.add(transfer);
            } else if (transfer.Transfer_Type__c == 'Main') {
                onTimeTransfers.add(transfer);
            } else if (transfer.Transfer_Type__c == 'One-Off') {
                returnedTransfers.add(transfer);
            }
        }

        List<Production__c> allProductions = [
            SELECT Id, Name, Shared_Solar_System__c, CreatedDate, Credits_Transferred__c, Untransferred_Credits__c,
                Credits_Available_for_Allocation__c, Billing_Method__c, Untransferred_kWh__c, kWh_Transferred__c
            FROM Production__c
            WHERE (Credits_Transferred__c = 0 OR Untransferred_Credits__c != 0) AND Production_kWh__c != 0
            ORDER BY Start_Date__c ASC
        ];


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


            if (sssToProductionMap.containsKey(prod.Shared_Solar_System__c)) {
                List<ProductionCredits> prodList = sssToProductionMap.get(prod.Shared_Solar_System__c);
                prodList.add(prodCredit);
                sssToProductionMap.put(prod.Shared_Solar_System__c, prodList);
            } else {
                sssToProductionMap.put(prod.Shared_Solar_System__c, new List<ProductionCredits> {prodCredit});
            }
        }


        if (excessTransfers.size() > 0 ){
            List<Transfer_Part__c> excessTransferParts =  createExcessTransferParts(excessTransfers);

            insertTransferParts(excessTransferParts);
        }

        if (onTimeTransfers.size() > 0 ) {
            List<Transfer_Part__c> onTimeTransferParts = createOnTimeTransferParts(onTimeTransfers);

            insertTransferParts(onTimeTransferParts);
        }

        if (returnedTransfers.size() > 0 ) {
            //TODO: write code for returned transfers - do we know what we want to do with One-Off Transfers yet?
            // Waiting to create case until after historical data has been loaded (408 records)
        }
    }



    public static List<Transfer_Part__c> createOnTimeTransferParts(List<Transfer__c> onTimeTransfers) {
        List<Transfer_Part__c> partsToInsert = new List<Transfer_Part__c>();

        for (Transfer__c transfer : onTimeTransfers) {
            //want to grab the first from the production list because it is the oldest
            if (sssToProductionMap.containsKey(transfer.Shared_Solar_System__c)){
                for (ProductionCredits prodCredit : sssToProductionMap.get(transfer.Shared_Solar_System__c)){

                    if(prodCredit.creditsTransferred == 0){
                        Production__c production = prodCredit.production;

                        Transfer_Part__c part = new Transfer_Part__c (
                            Name = 'Main Transfer - ' + production.Name,
                            Type__c = 'Transfer',
                            Production__c = production.Id,
                            Transfer__c = transfer.Id,
                            Amount__c = transfer.Transfer_Amount__c,
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
        }

        return partsToInsert;

    }



    public static List<Transfer_Part__c> createExcessTransferParts(List<Transfer__c> excessTransfers) {

        List<Transfer_Part__c> partsToInsert = new List<Transfer_Part__c>();

        for (Transfer__c transfer : excessTransfers) {
            Decimal amountToTransfer;
            if (transfer.Billing_Method__c == 'kWh'){
                amountToTransfer = transfer.Transfer_kWh__c;
            } else {
                amountToTransfer = transfer.Transfer_Amount__c;
            }

            for (ProductionCredits prodCredit : sssToProductionMap.get(transfer.Shared_Solar_System__c)) {
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