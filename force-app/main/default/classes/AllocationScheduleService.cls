// Tested By: AllocationScheduleServiceTest

public without sharing class AllocationScheduleService implements Queueable {
    public static AllocationScheduleSelector alsSelector = new AllocationScheduleSelector();
    public static TransferSelector transferSelector = new TransferSelector();
    public List<Id> transfersWithNewBills;

    public void populateAllocationScheduleOnTransfer(List<Transfer__c> transfers) {
        Set<Id> sssIds = new Set<Id>();
        Map<Id, List<Schedule_Z__c>> sssMap = new Map<Id, List<Schedule_Z__c>>();

        for (Transfer__c transfer : transfers) {
            if (requiresALSUpdate(transfer)) {
                sssIds.add(transfer.Shared_Solar_System__c);
            }
        }

        if (sssIds.size() == 0) {
            return;
        }
        sssMap = alsSelector.getEnactedAndBillingALSFromSSS(sssIds);
        for (Transfer__c transferToUpdate : transfers) {
            Id sssKey = transferToUpdate.Shared_Solar_System__c;
            if (requiresALSUpdate(transferToUpdate) && sssMap.containsKey(sssKey)) {
                transferToUpdate.Allocation_Schedule__c = getBillingALS(transferToUpdate, sssMap.get(sssKey));
            }
        }
    }

    private Boolean requiresALSUpdate(Transfer__c transfer) {
        return (transfer.Allocation_Schedule__c == null
            && transfer.Shared_Solar_System__c != null
            && transfer.Date_of_Transfer__c != null);
    }

    private Id getBillingALS(Transfer__c transfer, List<Schedule_Z__c> szList) {
        Id billingAllocationScheduleId;
        for (Schedule_Z__c sz : szList) {
            if (sz.Date_Enacted_by_Utility__c <= transfer.Date_of_Transfer__c) {
                billingAllocationScheduleId = sz.Id;
                break;
            }
        }
        return billingAllocationScheduleId;
    }

    public void queueUpdateALSStatuses(List<Transfer__c> allTransfers, Map<Id, Transfer__c> oldTransferMap) {
        List<Id> transfersMarkedAsBilling = new List<Id>();
        for (Transfer__c transfer : allTransfers) {
            Transfer__c oldTransfer = oldTransferMap.get(transfer.Id);
            if (!oldTransfer.Bills_Generated__c && transfer.Bills_Generated__c) {
                transfersMarkedAsBilling.add(transfer.Id);
            }
        }
        if (transfersMarkedAsBilling.size() > 0){
            AllocationScheduleService alsService = new AllocationScheduleService();
            alsService.transfersWithNewBills = transfersMarkedAsBilling;
            System.enqueueJob(alsService);
        }
    }

    public void execute(QueueableContext context) {
        try {
            List<Transfer__c> transfers = transferSelector.getAllTransfersById(transfersWithNewBills);
            List<Schedule_Z__c> alsToUpdate = updateALSStatuses(transfers);
            update alsToUpdate;
        } catch (Exception excep){
            Logger.logNow('AllocationScheduleService','markALSAsBilling',excep.getMessage() + excep.getStackTraceString());
        }
    }

    @TestVisible
    private List<Schedule_Z__c> updateALSStatuses(List<Transfer__c> transfers) {
        // If multiple month transfer (more than 1 transfer billed in a month for a given SSS) we want the most
        // recently enacted allocation schedule to be marked 'Billing' and older ones marked as 'Replaced'
        Map<Id,Date> sssToLatestALSMap = getLatestALSBySSSMap(transfers);
        List<Schedule_Z__c> allALSToUpdate = new List<Schedule_Z__c>();

        Map<Id, List<Schedule_Z__c>> enactedBillingSZMap = alsSelector.getEnactedAndBillingALSFromSSS(sssToLatestALSMap.keySet());
        for (Id sssId : enactedBillingSZMap.keySet()){
            List<Schedule_Z__c> alsToUpdate = updateStatuses(enactedBillingSZMap.get(sssId),sssToLatestALSMap.get(sssId));
            allALSToUpdate.addAll(alsToUpdate);
        }
        return allALSToUpdate;
    }

    private Map<Id,Date> getLatestALSBySSSMap(List<Transfer__c> transfers){
        Map<Id,Date> sssToLatestALSMap = new Map<Id,Date>();
        for (Transfer__c transfer : transfers){
            Id sssKey = transfer.Shared_Solar_System__c;
            Date alsDate = transfer.Allocation_Schedule__r.Date_Enacted_by_Utility__c;
            if (!sssToLatestALSMap.containsKey(sssKey)) {
                sssToLatestALSMap.put(transfer.Shared_Solar_System__c, alsDate);
            } else if (sssToLatestALSMap.get(sssKey) < alsDate){
                sssToLatestALSMap.put(transfer.Shared_Solar_System__c, alsDate);
            }
        }
        return sssToLatestALSMap;
    }

    private List<Schedule_Z__c> updateStatuses(List<Schedule_Z__c> billingAndEnactedSZList, Date cutoffDate){
        List<Schedule_Z__c> szToUpdate = new List<Schedule_Z__c>();
        for (Schedule_Z__c schedule : billingAndEnactedSZList){
            if (schedule.Date_Enacted_by_Utility__c < cutoffDate && schedule.Status__c != 'Replaced'){
                schedule.Status__c = 'Replaced';
                szToUpdate.add(schedule);
            } else if (schedule.Date_Enacted_by_Utility__c == cutoffDate && schedule.Status__c != 'Billing'){
                schedule.Status__c = 'Billing';
                szToUpdate.add(schedule);
            }
        }
        return szToUpdate;
    }
}