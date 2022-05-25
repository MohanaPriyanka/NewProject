/**
 * @description: Starts unrelated transactions (PartnerCommissions and P2B) after the GL Download.
 * Tested By: PostGLDownloadServiceTest
 */
public without sharing class PostGLDownloadService implements GenericBatchDMLOperation.PostBatchOperation {

    @TestVisible private static FeatureService featureService = new FeatureService();

    public Object executePostBatch() {
        if (featureService.isEnabled('New_Partner_Commission_Generator')) {
            new OpportunityCommissionableDateSetter().executePostBatch();
        } else {
            new PartnerCommissionHandler().executePostBatch();
        }

        ProductionToBillService productionService = new ProductionToBillService();
        productionService.opType = ProductionToBillService.OperationType.BILL;
        System.enqueueJob(productionService);
        return null;
    }
}