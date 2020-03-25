// Tested By: ProductionToBillServiceTest
public without sharing class ProductionToBillScheduler implements Schedulable{
    public void execute(SchedulableContext sc) {
        ProductionToBillService productionService = new ProductionToBillService();
        productionService.batchSize = 200;
        productionService.opType = ProductionToBillService.OperationType.BILL;
        productionService.genericExecute();
    }
}