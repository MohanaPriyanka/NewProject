@IsTest
private with sharing class ProductionDetailUnservicedServiceTest {
    /**
     * @description This tests these combinations of record updates:
     * Test record	Old Values	 	        New Values
     * Name	        Ext Serviced  Approved	Ext Serviced  Approved	Expected
     * BA1	        TRUE	      TRUE	    FALSE	      TRUE	    Delete PDs
     * BA2	        TRUE	      FALSE	    FALSE	      TRUE	    Delete PDs
     * BA3	        TRUE	      TRUE	    FALSE	      FALSE	    Delete PDs
     * BA4	        TRUE	      FALSE	    FALSE	      FALSE	    Delete PDs
     * BA5	        FALSE	      TRUE	    TRUE	      FALSE	    Delete PDs
     * BA6	        FALSE	      FALSE	    TRUE	      FALSE	    No action, will be Ready for PD when approved
     * BA7	        FALSE	      TRUE	    TRUE	      TRUE	    Ready for Production Detail
     * BA8	        FALSE	      FALSE	    TRUE	      TRUE	    Ready for Production Detail
     */
    @IsTest
    private static void testExternallyServicedAdjustmentChange() {
        Bill_Adjustment__c oldBA1 = getTestBA(Util.getFakeId(Bill_Adjustment__c.SObjectType), true, true);
        Bill_Adjustment__c oldBA2 = getTestBA(Util.incrementFakeId(oldBA1.Id), true, false);
        Bill_Adjustment__c oldBA3 = getTestBA(Util.incrementFakeId(oldBA2.Id), true, true);
        Bill_Adjustment__c oldBA4 = getTestBA(Util.incrementFakeId(oldBA3.Id), true, false);
        Bill_Adjustment__c oldBA5 = getTestBA(Util.incrementFakeId(oldBA4.Id), false, true);
        Bill_Adjustment__c oldBA6 = getTestBA(Util.incrementFakeId(oldBA5.Id), false, false);
        Bill_Adjustment__c oldBA7 = getTestBA(Util.incrementFakeId(oldBA6.Id), false, true);
        Bill_Adjustment__c oldBA8 = getTestBA(Util.incrementFakeId(oldBA7.Id), false, false);
        Map<Id, Bill_Adjustment__c> oldMap = new Map<Id, Bill_Adjustment__c>{
            oldBA1.Id => oldBA1,
            oldBA2.Id => oldBA2,
            oldBA3.Id => oldBA3,
            oldBA4.Id => oldBA4,
            oldBA5.Id => oldBA5,
            oldBA6.Id => oldBA6,
            oldBA7.Id => oldBA7,
            oldBA8.Id => oldBA8
        };

        Bill_Adjustment__c newBA1 = getTestBA(oldBA1.Id, false, true);
        Bill_Adjustment__c newBA2 = getTestBA(oldBA2.Id, false, true);
        Bill_Adjustment__c newBA3 = getTestBA(oldBA3.Id, false, false);
        Bill_Adjustment__c newBA4 = getTestBA(oldBA4.Id, false, false);
        Bill_Adjustment__c newBA5 = getTestBA(oldBA5.Id, true, false);
        Bill_Adjustment__c newBA6 = getTestBA(oldBA6.Id, true, false);
        Bill_Adjustment__c newBA7 = getTestBA(oldBA7.Id, true, true);
        Bill_Adjustment__c newBA8 = getTestBA(oldBA8.Id, true, true);
        List<Bill_Adjustment__c> triggerNew = new List<Bill_Adjustment__c>{newBA1, newBA2, newBA3, newBA4, newBA5, newBA6, newBA7, newBA8};

        UniversalMocker productionDetailSelectorMock = UniversalMocker.mock(ProductionDetailSelector.class);
        UniversalMocker uowMock = UniversalMocker.mock(fflib_SObjectUnitOfWork.class);
        ProductionDetailUnservicedService.unservicedPDDeletionUOW = (fflib_SObjectUnitOfWork) uowMock.createStub();
        ProductionDetailUnservicedService.productionDetailSelector = (ProductionDetailSelector) productionDetailSelectorMock.createStub();
        new ProductionDetailUnservicedService().handleUnservicedAndApprovalUpdateBeforeUpdate(oldMap, triggerNew);

        List<Bill_Adjustment__c> billAdjustmentsWithPDsToDelete =
            (List<Bill_Adjustment__c>) productionDetailSelectorMock.forMethod('selectByBillAdjustments').getValueOf('billAdjustments');
        System.assertEquals(6, billAdjustmentsWithPDsToDelete.size(),
            'Expected first six bill adjustments to have their PDs deleted because they had Externally Serviced changed from true to false, or were unapproved');
        System.assert(billAdjustmentsWithPDsToDelete.contains(newBA1), 'BA1 should have PDs deleted');
        System.assert(billAdjustmentsWithPDsToDelete.contains(newBA2), 'BA2 should have PDs deleted');
        System.assert(billAdjustmentsWithPDsToDelete.contains(newBA3), 'BA3 should have PDs deleted');
        System.assert(billAdjustmentsWithPDsToDelete.contains(newBA4), 'BA4 should have PDs deleted');
        System.assert(billAdjustmentsWithPDsToDelete.contains(newBA5), 'BA5 should have PDs deleted because unapproved Bill Adjustments should not have PDs');
        System.assert(!billAdjustmentsWithPDsToDelete.contains(newBA6), 'BA6 should not have PDs deleted because it is unapproved');
        System.assert(!newBA6.Ready_For_Production_Detail__c,
            'BA7 should not get Ready for Production Detail set yet because it is not yet approved');
        System.assert(!billAdjustmentsWithPDsToDelete.contains(newBA7), 'BA7 should not have PDs deleted because it is an approved externally serviced adjustment');
        System.assert(newBA7.Ready_For_Production_Detail__c,
            'BA7 should get Ready for Production Detail set because Externally Serviced changed from false to true on an Approved Adjustment');
        System.assert(!billAdjustmentsWithPDsToDelete.contains(newBA8), 'BA8 should not have PDs deleted');
        System.assert(newBA8.Ready_For_Production_Detail__c,
            'BA8 should get Ready for Production Detail set because Externally Serviced changed from false to true at the same time the adjustment was Approved');

        uowMock.assertThat().method('commitWork').wasCalled(1);
    }

    private static Bill_Adjustment__c getTestBA(Id billAdjustmentId, Boolean externallyServiced, Boolean approved) {
        return new Bill_Adjustment__c(
            Id = billAdjustmentId,
            Externally_Serviced__c = externallyServiced,
            Approval_Status__c = approved?'Approved':'Pending'
        );
    }

    @IsTest
    private static void testUnservicedUASB() {
        List<UASB__c> uasbs = new List<UASB__c>();
        UASB__c uasb1 = new UASB__c(
            Externally_Serviced__c = true,
            Credits_Allocated__c = 0
        );
        uasbs.add(uasb1);
        UASB__c uasb2 = new UASB__c(
            Externally_Serviced__c = true,
            Credits_Allocated__c = 10
        );
        uasbs.add(uasb2);
        UASB__c uasb3 = new UASB__c(
            Externally_Serviced__c = false,
            Credits_Allocated__c = 10
        );
        uasbs.add(uasb3);
        new ProductionDetailUnservicedService().setUnservicedUASBReadyForProdDetailBeforeInsert(uasbs);
        System.assert(!uasb1.Ready_For_Production_Detail__c, 'UASB1 should not be Ready for PD since it has 0 Credits Allocated');
        System.assert(uasb2.Ready_For_Production_Detail__c, 'UASB2 should be Ready for PD since it is externally serviced and has >0 Credits Allocated');
        System.assert(!uasb1.Ready_For_Production_Detail__c, 'UASB3 should not be Ready for PD since it has 0 Credits Allocated');
    }

    @IsTest
    private static void testUnservicedUASBUpdate() {
        UASB__c oldUASB1 = new UASB__c(
            Id = Util.getFakeId(UASB__c.SObjectType),
            Externally_Serviced__c = false,
            Ready_For_Production_Detail__c = false
        );
        UASB__c oldUASB2 = new UASB__c(
            Id = Util.incrementFakeId(oldUASB1.Id),
            Externally_Serviced__c = true,
            Ready_For_Production_Detail__c = true
        );
        Map<Id, UASB__c> oldMap = new Map<Id, UASB__c>{
            oldUASB1.Id => oldUASB1,
            oldUASB2.Id => oldUASB2
        };
        UASB__c newUASB1 = oldUASB1.clone(true);
        newUASB1.Externally_Serviced__c = true;
        UASB__c newUASB2 = oldUASB2.clone(true);
        newUASB2.Externally_Serviced__c = false;
        List<UASB__c> triggerNew = new List<UASB__c>{newUASB1, newUASB2};

        UniversalMocker productionDetailSelectorMock = UniversalMocker.mock(ProductionDetailSelector.class);
        UniversalMocker uowMock = UniversalMocker.mock(fflib_SObjectUnitOfWork.class);
        ProductionDetailUnservicedService.unservicedPDDeletionUOW = (fflib_SObjectUnitOfWork) uowMock.createStub();
        ProductionDetailUnservicedService.productionDetailSelector = (ProductionDetailSelector) productionDetailSelectorMock.createStub();
        new ProductionDetailUnservicedService().handleUnservicedUASBUpdateBeforeUpdate(oldMap, triggerNew);

        System.assert(newUASB1.Ready_For_Production_Detail__c, 'Expected UASB1 to be Ready for PD since it is externally serviced');
        System.assert(!newUASB2.Ready_For_Production_Detail__c, 'Expected UASB2 to not be Ready for PD since it is not externally serviced');
        List<UASB__c> uasbsWithPDsToDelete =
            (List<UASB__c>) productionDetailSelectorMock.forMethod('selectByUASBs').getValueOf('uasbs');
        System.assertEquals(1, uasbsWithPDsToDelete.size(),
            'Expected UASB2 to have PDs deleted because it is no longer externally serviced');
        System.assert(uasbsWithPDsToDelete.contains(newUASB2),
            'Expected UASB2 to have PDs deleted because it is no longer externally serviced');
    }
}