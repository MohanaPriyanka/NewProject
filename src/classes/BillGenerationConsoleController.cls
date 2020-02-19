/* Created by Jordan Pentaleri on 2/11/19
Description: controller for BillGenerationConsole
Tests: BillGenerationAndDeliveryServiceTest, TransferSelectorTest
*/

public class BillGenerationConsoleController {

    @AuraEnabled
    public static List<Transfer__c> getThisMonthsTransfers() {
        Date today = System.Today();
        return TransferSelector.getTransfersByMonth(today.month(),today.year());
    }

    @AuraEnabled
    public static List<Shared_Solar_System__c> getSSSWithoutTransfer(List<Transfer__c> transferList) {
        List<Id> transferIdList = new List<Id>();
        for (Transfer__c transfer : transferList) {
            transferIdList.add(transfer.Id);
        }
        return SharedSolarSystemsSelector.getAllSSSWithTransfersNotInList(transferIdList);
    }

    @AuraEnabled
    public static void runThisMonthsBills() {
        Date today = System.Today();
        List<Bill_Period__c> billPeriods = BillPeriodSelector.getBillPeriodsByMonth(today.month(), today.year());
        BillGenerationAsyncService billGen = new BillGenerationAsyncService(billPeriods);
        billGen.executeBatchJob();
    }

    @AuraEnabled
    public static String getBillSummary() {
        Date today = System.Today();
        List<AggregateResult> aggregateInvoices = ZuoraInvoiceSelector.getInvoiceSummary(System.Today().addDays(-3));
        return handleAggregateResult(aggregateInvoices);
    }

    @AuraEnabled
    public static String handleAggregateResult(List<AggregateResult> aggregateBills) {
        BillStatusSummary summaryStats = new BillStatusSummary();
        summaryStats.totalCount = 0;
        summaryStats.readyForEmail = 0;
        summaryStats.readyForPaper = 0;
        summaryStats.publishedAB = 0;
        summaryStats.addedToPaper = 0;

        for (AggregateResult aggregateResult : aggregateBills)  {
            summaryStats.totalCount += (Integer)aggregateResult.get('numberOfRecords');
            if((Boolean)aggregateResult.get('Ready_For_Email_Send__c')){
                summaryStats.readyForEmail += (Integer)aggregateResult.get('numberOfRecords');
            }
            if((Boolean)aggregateResult.get('Ready_For_Paper_Bill_Queue__c')){
                summaryStats.readyForPaper += (Integer)aggregateResult.get('numberOfRecords');
            }
            if((Boolean)aggregateResult.get('CompletedBills')){
                summaryStats.publishedAB += (Integer)aggregateResult.get('numberOfRecords');
            }
            if((Boolean)aggregateResult.get('Added_To_Paper_Bill_Queue__c')){
                summaryStats.addedToPaper += (Integer)aggregateResult.get('numberOfRecords');
            }
        }

        String percentReadyEmail = getPercentOfTotal(summaryStats.readyForEmail, summaryStats.totalCount);
        String percentReadyPaper = getPercentOfTotal(summaryStats.readyForPaper, summaryStats.totalCount);
        String percentReadyPublished = getPercentOfTotal(summaryStats.publishedAB, summaryStats.totalCount);
        String percentReadyAddedToPaper = getPercentOfTotal(summaryStats.addedToPaper, summaryStats.totalCount);

        String response =
            'Generated Bills: ' + summaryStats.totalCount + ' / ' +
            'Ready for Email Send: ' + summaryStats.readyForEmail + ' bills ' + percentReadyEmail + ' / ' +
            'Ready for Paper Send: ' + summaryStats.readyForPaper + ' bills ' + percentReadyPaper + ' / ' +
            'Sent via Email: ' + summaryStats.publishedAB + ' bills ' + percentReadyPublished + ' / ' +
            'Sent via Paper: ' + summaryStats.addedToPaper + ' bills ' + percentReadyAddedToPaper;
        return response;
    }

    public static String getPercentOfTotal(Decimal dividend, Decimal divisor) {
        if (divisor == null || divisor == 0){
            return '(0%)';
        } else {
            return '(' + (dividend.divide(divisor, 4)*100).setScale(0) + '%)';
        }
    }

    public class BillStatusSummary {
        public Decimal totalCount;
        public Decimal readyForEmail;
        public Decimal readyForPaper;
        public Decimal publishedAB;
        public Decimal addedToPaper;
    }
}