/**
 * @description Created by SarahRenfro on 11/7/2019.
 *
 * Tested By: BillPeriodServiceTest
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public with sharing class BillPeriodService {

    private Set<Id> verifiedBillPeriods = new Set<Id>();
    public Map<Id, Bill_Period__c> completedBillPeriods = new Map<Id, Bill_Period__c>();
    @TestVisible private OpportunityCommissionableDateSetter oppDateSetter;

    @TestVisible private static FeatureService featureService = new FeatureService();
    @TestVisible private static ProductionService productionService = new ProductionService();
    @TestVisible private static UASBSelector uasbSelector = new UASBSelector();
    @TestVisible private static OpportunitiesSelector opportunitiesSelector = new OpportunitiesSelector();
    @TestVisible private static PartnerCommissionService commissionService = new PartnerCommissionService();
    @TestVisible private static fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
        new List<SObjectType>{
            Account.SObjectType,
            Commission_Payment__c.SObjectType
        }
    );

    public void onAfterInsert(List<Bill_Period__c> bpList) {
        List<Transfer__c> transfers = assignTransfers(bpList);
        updateRecords(transfers);
    }

    public void onBeforeUpdate(List<Bill_Period__c> bpList, Map<Id, Bill_Period__c> oldMap) {
        evaluateStatus(bpList, oldMap);
        List<Production__c> productionsToUpdate = new List<Production__c>();
        if (verifiedBillPeriods.size() > 0 ) {
            productionsToUpdate = productionService.verifyProductions(verifiedBillPeriods);
        }
        if (completedBillPeriods.size() > 0) {
            productionsToUpdate = productionService.markFirstBillDate(completedBillPeriods);
        }
        updateRecords(productionsToUpdate);
    }

    private void evaluateStatus(List<Bill_Period__c> bpList, Map<Id, Bill_Period__c> oldMap) {
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
                        bp.Date_Generated__c = Date.today();
                    } when 'Bill Run Complete' {
                        completedBillPeriods.put(bp.Id, bp);
                    }
                }

                if (checkIfVerified(bp) && !checkIfVerified(oldMap.get(bp.Id))) {
                    verifiedBillPeriods.add(bp.Id);
                }
            }
        }
    }

    public Boolean checkIfVerified(Bill_Period__c billPeriod) {
        String status = billPeriod.Bill_Status__c;
        if (status == null || status == 'Production Uploaded') {
            return false;
        } else {
            return true;
        }
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
            if (sssToBillPeriod.get(transfer.Shared_Solar_System__c).Bill_Date__c - 30 > transfer.Date_of_Transfer__c) {
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

    /**
     * @description Sets Bill Periods to "Bill Run Complete", update First Bill Date on SSS, and for UCB bill periods,
     * potentially generates partner commissions and updates First Bill Date on property accounts.
     * @param invoiceDate Invoice date, to select the appropriate BIll Periods
     * @return Number of Bill Periods updated
     */
    public Integer markBillPeriodsAsBillRunComplete(Date invoiceDate) {
        List<Bill_Period__c> billPeriodsToUpdate;
        try {
            billPeriodsToUpdate = BillPeriodSelector.getBillPeriodsByMonth(invoiceDate.month(), invoiceDate.year());
            List<Transfer__c> ucbTransfersThisPeriod = new List<Transfer__c>();
            for (Bill_Period__c billPeriod : billPeriodsToUpdate) {
                billPeriod.Bill_Status__c = 'Bill Run Complete';
                if (billPeriod.Shared_Solar_System__r.UCB__c) {
                    ucbTransfersThisPeriod.addAll(billPeriod.Transfers__r);
                }
            }
            update billPeriodsToUpdate;
            Database.executeBatch(new GenericBatchDMLOperation(
                sssToUpdateOnBillRunComplete(billPeriodsToUpdate), 'Update')
            );
            handleUCBTransfers(ucbTransfersThisPeriod);
            Logger.logNow('BillPeriodService', 'markBillPeriodsAsBillRunComplete', 'Check limits', Logger.FINE);
        } catch (Exception e){
            Logger.logNow('BillPeriodService','markBillPeriodsAsBillRunComplete',e.getMessage() + '\n' + e.getStackTraceString(), Logger.ERROR);
        }
        return billPeriodsToUpdate.size();
    }

    private List<Shared_Solar_System__c> sssToUpdateOnBillRunComplete(List<Bill_Period__c> billPeriods) {
        List<Shared_Solar_System__c> systemsToUpdate = new List<Shared_Solar_System__c>();
        for (Bill_Period__c billPeriod : billPeriods) {
            Shared_Solar_System__c sssToUpdate = new Shared_Solar_System__c(Id = billPeriod.Shared_Solar_System__c);
            Date sssFirstBillDate = billPeriod.Shared_Solar_System__r.First_Bill_Date__c;
            Date sssUcbFirstBillDate = billPeriod.Shared_Solar_System__r.UCB_First_Bill_Date__c;
            if (sssFirstBillDate == null) {
                sssToUpdate.First_Bill_Date__c = billPeriod.Bill_Date__c;
            }
            if (sssUcbFirstBillDate == null && billPeriod.Shared_Solar_System__r.UCB__c) {
                sssToUpdate.UCB_First_Bill_Date__c = billPeriod.Bill_Date__c;
            }
            if (sssFirstBillDate == null || sssUcbFirstBillDate == null) {
                systemsToUpdate.add(sssToUpdate);
            }
        }
        return systemsToUpdate;
    }

    /**
     * @description Updates First CS Bill Date for accounts that have this as their first transfer, and (legacy) generates
     * commissions for corresponding opportunities
     * @param transfers UCB Transfers
     * @return Set of opportunity Ids that are getting billed by the transfers, to be used as inputs for the
     * PartnerCommissionService
     */
    @TestVisible
    private Set<Id> handleUCBTransfers(List<Transfer__c> transfers) {
        List<UASB__c> uasbs = uasbSelector.getUasbsForUCBTransfers(transfers);
        Set<Id> opportunityIdsGettingBilled = new Set<Id>();
        for (UASB__c uasb : uasbs) {
            opportunityIdsGettingBilled.add(uasb.Utility_Account_Subscription__r.Opportunity__c);
            if (uasb.Utility_Account_Subscription__r.Opportunity__r.Account.First_CS_Bill_Date__c == null) {
                Account account = new Account(
                    Id = uasb.Utility_Account_Subscription__r.Opportunity__r.AccountId,
                    First_CS_Bill_Date__c = uasb.Date__c
                );
                uow.registerDirty(account);
            }
        }

        // LEGACY: Calculate commissions for related Opportunities. To be deprecated in the future.
        legacyCalculateCommissions(
            opportunitiesSelector.selectWithoutFirstInvoiceCommissionByOpp(opportunityIdsGettingBilled),
            PartnerCommissionService.CommissionType.FIRSTBILLSENT
        );
        legacyCalculateCommissions(
            opportunitiesSelector.selectWithoutFirstPaymentCommissionByOpp(opportunityIdsGettingBilled),
            PartnerCommissionService.CommissionType.FIRSTBILLPAID
        );

        oppDateSetter = new OpportunityCommissionableDateSetter(uasbs);
        oppDateSetter.executeForUCB();

        uow.commitWork();
        return opportunityIdsGettingBilled;
    }

    private void legacyCalculateCommissions(List<Opportunity> opps, PartnerCommissionService.CommissionType commissionType) {
        if (featureService.isEnabled('New_Partner_Commission_Generator')) {
            return;
        }
        PartnerCommissionService.PendingCommission legacyCommissionJob = new PartnerCommissionService.PendingCommission();
        legacyCommissionJob.opportunitiesToRun = opps;
        legacyCommissionJob.typeOfCommission = commissionType;
        commissionService.calculateCommissionRecords(legacyCommissionJob, uow);
    }
}