// Tested by: TransferServiceTest

@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class TransferService {
    @TestVisible
    private static ProductionSelector prodSelector = new ProductionSelector();
    @TestVisible
    private static ProductionDetailSelector prodDetailSelector = new ProductionDetailSelector();
    @TestVisible
    private static SharedSolarSystemsSelector sssSelector = new SharedSolarSystemsSelector();
    @TestVisible
    private List<Shared_Solar_System__c> sssToUpdate = new List<Shared_Solar_System__c>();

    public void changeInBillsGenerated(List<Transfer__c> newTransfers, Map<Id, Transfer__c> oldTransferMap){
        Set<Id> sssIds = new Set<Id>();

        for (Transfer__c newTransfer : newTransfers) {
            Transfer__c oldTransfer = oldTransferMap.get(newTransfer.Id);
            if (oldTransfer.Bills_Generated__c != newTransfer.Bills_Generated__c) {
                sssIds.add(newTransfer.Shared_Solar_System__c);
            }
        }
        if (sssIds.size() > 0){
            updateSSSBilledProductionCount(sssIds);
        }
    }

    public void updatePartsOnCreditValueUpdate(List<Transfer__c> newTransfers, Map<Id, Transfer__c> oldTransferMap) {
        List<Transfer_Part__c> partsToUpdate = findPartsOnCreditValueUpdate(newTransfers,oldTransferMap);
        update partsToUpdate;
    }

    public void onDeleteTransfers(List<Transfer__c> deletedTransfers) {
        for (Transfer__c transfer : deletedTransfers) {
            if (transfer.Bills_Generated__c == true) {
                throw new Util.FatalBWException('Transfer cannot be deleted if bills have been generated: ' + transfer.Id);
            }
        }
    }

    @TestVisible
    private List<Transfer_Part__c> findPartsOnCreditValueUpdate(List<Transfer__c> newTransfers, Map<Id, Transfer__c> oldTransferMap){
        Set<Id> transferIds = new Set<Id>();
        List<Transfer_Part__c> partsToUpdate = new List<Transfer_Part__c>();

        for (Transfer__c newTransfer : newTransfers) {
            if (newTransfer.Transfer_Type__c != 'Main'){
                continue;
            }
            Transfer__c oldTransfer = oldTransferMap.get(newTransfer.Id);
            if (oldTransfer.Default_Credit_Value__c != newTransfer.Default_Credit_Value__c) {
                transferIds.add(newTransfer.Id);
            }
        }
        if (transferIds.size() > 0){
            partsToUpdate = prodDetailSelector.getPartsFromTransfer(transferIds);

            for (Transfer_Part__c part : partsToUpdate) {
                part.Main_Transfer_Default_Credit_Value__c = part.Transfer__r.Default_Credit_Value__c;
            }
        }
        return partsToUpdate;
    }

    private void updateSSSBilledProductionCount(Set<Id> sssIds){
        Map<Id,Integer> billedTransfersBySSSMap = prodSelector.getBilledProductionBySSS(sssIds);
        Map<Id, Shared_Solar_System__c> sssMap = sssSelector.getSSSMap(sssIds);

        for (Id sssId : billedTransfersBySSSMap.keySet()){
            Integer newBilledProductionCount = billedTransfersBySSSMap.get(sssId);
            Integer oldBilledProductionCount = (Integer)sssMap.get(sssId).Number_of_Billed_Production_Periods__c;
            if (newBilledProductionCount != oldBilledProductionCount){
                Shared_Solar_System__c sss = new Shared_Solar_System__c(
                    Id = sssId,
                    Number_of_Billed_Production_Periods__c = newBilledProductionCount
                );
                sssToUpdate.add(sss);
            }
        }
        try {
            update sssToUpdate;
        } catch (Exception excep){
            Logger.logNow(
                'TransferService',
                'updateSSSBilledProductionCount',
                'For SSSes: ' + JSON.serialize(sssMap) + ' ' + excep.getMessage()+ ' ' + excep.getStackTraceString());
        }
    }
}