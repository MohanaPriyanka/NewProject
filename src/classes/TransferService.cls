// Tested by: TransferServiceTest

@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class TransferService {
    @TestVisible
    private static ProductionSelector prodSelector = new ProductionSelector();
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