/**
 * Tested By: ProductionDetailUnservicedServiceTest, ClientReportingServiceTest
 */

public without sharing class ProductionDetailUnservicedService {
    @TestVisible private ProductionDetailBillService billService = new ProductionDetailBillService();
    @TestVisible private static ProductionDetailSelector productionDetailSelector = new ProductionDetailSelector();
    @TestVisible private static fflib_SObjectUnitOfWork unservicedPDDeletionUOW = new fflib_SObjectUnitOfWork(
        new List<SObjectType>{
            Transfer_Part__c.SObjectType
        }
    );

    public void setUnservicedUASBReadyForProdDetailBeforeInsert(List<UASB__c> uasbs) {
        for (UASB__c uasb : uasbs) {
            if (uasb.Externally_Serviced__c && uasb.Credits_Allocated__c != null && uasb.Credits_Allocated__c != 0){
                uasb.Ready_For_Production_Detail__c = true;
            }
        }
    }

    /**
     * @description If Externally Serviced changes, we need to mark the UASB Ready for Production Detail or delete the
     * Production Details
     * @param oldMap Trigger.oldMap
     * @param triggerNew Trigger.new
     */
    public void handleUnservicedUASBUpdateBeforeUpdate(Map<Id, UASB__c> oldMap, List<UASB__c> triggerNew) {
        List<UASB__c> uasbsWithChangedExternallyServiced = (List<UASB__c>) new SObjectFilter(
            oldMap, triggerNew, UASB__c.Externally_Serviced__c, SObjectFilter.ANY_VALUE, SObjectFilter.ANY_VALUE)
            .get(SObjectFilter.SOBJECT_LIST);

        List<UASB__c> uasbsToHavePDsDeleted = new List<UASB__c>();
        for (UASB__c uasb : uasbsWithChangedExternallyServiced) {
            if (uasb.Externally_Serviced__c) {
                uasb.Ready_For_Production_Detail__c = true;
            } else {
                uasb.Ready_For_Production_Detail__c = false;
                uasbsToHavePDsDeleted.add(uasb);
            }
        }
        unservicedPDDeletionUOW.registerDeleted(productionDetailSelector.selectByUASBs(uasbsToHavePDsDeleted));
        unservicedPDDeletionUOW.commitWork();
    }

    public void deletePDsBeforeUASBDelete(List<UASB__c> triggerOld) {
        unservicedPDDeletionUOW.registerDeleted(productionDetailSelector.selectByUASBs(triggerOld));
        unservicedPDDeletionUOW.commitWork();
    }

    public void createProductionDetailFromUnservicedUASB(List<UASB__c> unservicedUASBs) {
        calculateProductionDetailFromUnservicedUASB(unservicedUASBs);
        insert billService.productionDetailToInsert;
    }

    @TestVisible
    private void calculateProductionDetailFromUnservicedUASB(List<UASB__c> unservicedUASBs) {
        billService.transferToDetailMap = 
            productionDetailSelector.getTransferPartMap(CollectionUtil.getIdSet(unservicedUASBs, UASB__c.Transfer__c));

        for (UASB__c externalBill : unservicedUASBs){
            billService.createBillProductionDetail(externalBill.Transfer__c, externalBill.Credits_Allocated__c, null, 'Externally Serviced', externalBill.Id);
        }
    }

    /**
     *  @description When an adjustment is approved, if it externally serviced, the ProductionToBillService should create
        * Production Details for it.
        * @param triggerNew Trigger.new
        */
    public void setUnservicedAdjustReadyForProdDetailBeforeInsert(List<Bill_Adjustment__c> triggerNew) {
        List<Bill_Adjustment__c> approvedBillAdjustments = (List<Bill_Adjustment__c>) new SObjectFilter(
            triggerNew, Bill_Adjustment__c.Approval_Status__c, SObjectFilter.EQUAL_TO, 'Approved')
            .addFilterCriteria(Bill_Adjustment__c.Externally_Serviced__c, SObjectFilter.EQUAL_TO, true)
            .get(SObjectFilter.SOBJECT_LIST);
        CollectionUtil.setField(approvedBillAdjustments, Bill_Adjustment__c.Ready_For_Production_Detail__c, true);
    }

    /**
     * @description When an adjustment is approved, if it externally serviced, the ProductionToBillService should create
     * Production Details for it.
     * @param oldMap Trigger.oldMap
     * @param triggerNew Trigger.new
     */
    public void setUnservicedAdjustReadyForProdDetailBeforeUpdate(Map<Id, Bill_Adjustment__c> oldMap, List<Bill_Adjustment__c> triggerNew) {
        List<Bill_Adjustment__c> approvedBillAdjustments = (List<Bill_Adjustment__c>) new SObjectFilter(
            oldMap, triggerNew, Bill_Adjustment__c.Approval_Status__c, SObjectFilter.ANY_VALUE, 'Approved')
            .addFilterCriteria(Bill_Adjustment__c.Externally_Serviced__c, SObjectFilter.EQUAL_TO, true)
            .get(SObjectFilter.SOBJECT_LIST);
        CollectionUtil.setField(approvedBillAdjustments, Bill_Adjustment__c.Ready_For_Production_Detail__c, true);
    }

    /**
         * @description Adjustments that are not externally serviced should not have any Production Details since adjustments
         * that we service get Journal Entries with related PDs. Adjustments that are externally serviced should registered for PDs as
         * long as the adjustment is approved and unapproved Bill Adjustments should not have PDs
         * @param oldMap Trigger.oldMap
         * @param triggerNew Trigger.new
         */
    public void handleUnservicedAndApprovalUpdateBeforeUpdate(Map<Id, Bill_Adjustment__c> oldMap, List<Bill_Adjustment__c> triggerNew) {
        List<Bill_Adjustment__c> billAdjustmentsWithExternallyServiceUpdated = (List<Bill_Adjustment__c>) new SObjectFilter(
            oldMap, triggerNew, Bill_Adjustment__c.Externally_Serviced__c, SObjectFilter.ANY_VALUE, SObjectFilter.ANY_VALUE)
            .get(SObjectFilter.SOBJECT_LIST);
        List<Bill_Adjustment__c> unservicedBillAdjustmentsWithPDsToDelete = new List<Bill_Adjustment__c>();
        for (Bill_Adjustment__c billAdjustment : billAdjustmentsWithExternallyServiceUpdated) {
            if (billAdjustment.Externally_Serviced__c) {
                if (billAdjustment.Approval_Status__c == 'Approved') {
                    billAdjustment.Ready_For_Production_Detail__c = true;
                } // If the adjustment is not approved yet, don't make it Ready for PD yet, that will happen when it's approved
            } else {
                // It's not Externally Serviced, so whether it's approved or not, we should uncheck Ready for PD and delete PDs if they exist
                billAdjustment.Ready_For_Production_Detail__c = false;
                unservicedBillAdjustmentsWithPDsToDelete.add(billAdjustment);
            }
        }

        List<Bill_Adjustment__c> billAdjustmentsWithApprovalStatusUpdated = (List<Bill_Adjustment__c>) new SObjectFilter(
            oldMap, triggerNew, Bill_Adjustment__c.Approval_Status__c, 'Approved', SObjectFilter.ANY_VALUE)
            .get(SObjectFilter.SOBJECT_LIST);
        for (Bill_Adjustment__c billAdjustment : billAdjustmentsWithApprovalStatusUpdated) {
            unservicedBillAdjustmentsWithPDsToDelete.add(billAdjustment);
        }

        unservicedPDDeletionUOW.registerDeleted(productionDetailSelector.selectByBillAdjustments(unservicedBillAdjustmentsWithPDsToDelete));
        unservicedPDDeletionUOW.commitWork();
    }

    public void deletePDsBeforeAdjustmentDelete(List<Bill_Adjustment__c> triggerOld) {
        unservicedPDDeletionUOW.registerDeleted(productionDetailSelector.selectByBillAdjustments(triggerOld));
        unservicedPDDeletionUOW.commitWork();
    }

    public void createProductionDetailFromUnservicedAdjustment(List<Bill_Adjustment__c> unservicedAdjusts) {
        calculateProductionDetailFromUnservicedAdjustment(unservicedAdjusts);
        insert billService.productionDetailToInsert;
    }

    @TestVisible
    private void calculateProductionDetailFromUnservicedAdjustment(List<Bill_Adjustment__c> adjustments) {
        billService.transferToDetailMap = 
            productionDetailSelector.getTransferPartMap( CollectionUtil.getIdSet(adjustments, Bill_Adjustment__c.Transfer__c));

        for (Bill_Adjustment__c adjustment : adjustments){
            billService.createBillProductionDetail(adjustment.Transfer__c, adjustment.Credits_Allocated__c, null, 'Externally Serviced', adjustment.Id);
        }
    }

}