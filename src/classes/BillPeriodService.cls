/**
 * Created by SarahRenfro on 11/7/2019.
 *
 * Tested By: BillPeriodServiceTest
 */

@SuppressWarnings('PMD.ApexCRUDViolation')
public with sharing class BillPeriodService {

    public void onAfterInsert(List<Bill_Period__c> bpList) {
        List<Transfer__c> transfers = assignTransfers(bpList);
        updateRecords(transfers);
    }

    public void onBeforeUpdate(List<Bill_Period__c> bpList, Map<Id, Bill_Period__c> oldMap) {
        List<Bill_Period__c> billPeriods = evaluateStatus(bpList, oldMap);
    }

    private List<Bill_Period__c> evaluateStatus(List<Bill_Period__c> bpList, Map<Id, Bill_Period__c> oldMap) {
        List<Bill_Period__c> updatedBPs = new List<Bill_Period__c>();

        for (Bill_Period__c bp : bpList) {
            if (bp.Bill_Status__c != oldMap.get(bp.Id).Bill_Status__c) {
                switch on bp.Bill_Status__c {
                    when 'Production Uploaded' {
                        bp.Date_Host_Bill_Uploaded__c = Date.today();
                    } when 'Production QCed' {
                        bp.Date_Host_Account_Bill_QCed__c = Date.today();
                    } when 'Credit Transfers QCed' {
                        bp.Date_Credit_Transfers_QCed__c = Date.today();
                    } when 'Generated' {
                        bp.Date_Generated__c = Date.Today();
                    }
                }
                updatedBPs.add(bp);
            }
        }

        return updatedBPs;
    }


    public List<Transfer__c> assignTransfers(List<Bill_Period__c> bpList) {
        Map<Id, Bill_Period__c> sssToBillPeriod = new Map<Id, Bill_Period__c>();
        for (Bill_Period__c bp : bpList ) {
            sssToBillPeriod.put(bp.Shared_Solar_System__c, bp);
        }

        Set<Id> sssIds = sssToBillPeriod.keySet();

        List<Transfer__c> allTransfers = TransferSelector.getTransfersForBillPeriods(sssIds);
        List<Transfer__c> updatedTransfers = new List<Transfer__c>();

        for (Transfer__c transfer : allTransfers) {
            if (sssToBillPeriod.get(transfer.Shared_Solar_System__c).Bill_Date__c - 30 > transfer.Date_of_Transfer__c ) {
                transfer.Bill_Period__c = sssToBillPeriod.get(transfer.Shared_Solar_System__c).Id;
                updatedTransfers.add(transfer);
            }
        }

        return updatedTransfers;
    }


    public void updateRecords(List<SObject> records) {
        try {
            update records;
        } catch (Exception e ) {
            Logger.logNow('BillPeriodService', 'updateRecords',
                'Unable to update records: ' + JSON.serialize(records) + '\n'+  e.getMessage() + '\n' + e.getStackTraceString());
        }
    }

    public static Integer markBillPeriodsAsBillRunComplete(Date invoiceDate){
        try {
            List<Bill_Period__c> billPeriodsToUpdate;
            billPeriodsToUpdate = BillPeriodSelector.getBillPeriodsByMonth(invoiceDate.Month(), invoiceDate.Year());

            for (Bill_Period__c billPeriod : billPeriodsToUpdate){
                billPeriod.Bill_Status__c = 'Bill Run Complete';
            }
            update billPeriodsToUpdate;
            return billPeriodsToUpdate.size();
        } catch (Exception excep){
            Logger.logNow('BillPeriodService','markBillPeriodsAsBillRunComplete',excep.getMessage() + '__' + excep.getStackTraceString());
            return 0;
        }
    }
}