/**
 * Description: Starts unrelated transactions (PartnerCommissions and P2B) after the GL Download.
 * Tested By: PostGLDownloadServiceTest
 */

public without sharing class PostGLDownloadService implements GenericBatchDMLOperation.PostBatchOperation {

    public Object executePostBatch() {
        new PartnerCommissionHandler().executePostBatch();

        ProductionToBillService productionService = new ProductionToBillService();
        productionService.opType = ProductionToBillService.OperationType.BILL;
        productionService.execute(null);
        return null;
    }
}