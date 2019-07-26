/*************************************************************************************
 * Created By:  Jordan Pentaleri
 * Test: ZuoraCreditMemoAllocationTest
 *************************************************************************************/

public class ZuoraCreditMemoAllocationService implements ZuoraOutstandingItemsService.Processor {
    public class CreditMemoApplication {
        public List<CreditMemoApplicationInvoice> invoices;
        public List<CreditMemoApplicationDebitMemo> debitMemos;
    }

    public class CreditMemoApplicationInvoice {
        public String invoiceId;
        public List<CreditMemoApplicationInvoiceItem> items;
        public Decimal amount;
    }

    public class CreditMemoApplicationInvoiceItem {
        public String invoiceItemId;
        public String creditMemoItemId;
        public Decimal amount;
    }

    public class CreditMemoApplicationDebitMemo {
        public String debitMemoId;
        public List<CreditMemoApplicationDebitMemoItem> items;
        public Decimal amount;
    }

    public class CreditMemoApplicationDebitMemoItem {
        public String debitMemoItemId;
        public String creditMemoItemId;
        public Decimal amount;
    }

    public class QueryResultCreditMemo {
        public List<ZuoraAPI.ZuoraCreditMemo> CreditMemos;
        public String NextPage;
        public String Success;
    }

    public class QueryResultCreditMemoItems {
        public List<ZuoraAPI.ZuoraCreditMemoItem> Items;
    }

    public static void applyCreditMemo(ZuoraAPI.CreditMemoWithItem creditMemo) {
        ZuoraOutstandingItemsService.ProcessingParameter processingParameter =
            new ZuoraOutstandingItemsService.ProcessingParameter('ZuoraCreditMemoAllocationService', creditMemo);

        ZuoraOutstandingItemsService.processOutstandingItemsByDate(creditMemo.CreditMemo.accountId, processingParameter);
    }

    // Called when ZuoraOutstandingItemsAsyncService gets all of the outstanding items
    public void processOutstandingItems(List<ZuoraOutstandingItemsService.OutstandingItem> outstandingItems,
        ZuoraOutstandingItemsService.ProcessingParameter processingParameter) {
        List<ZuoraOutstandingItemsService.OutstandingItem> itemsWithApplication =
            ZuoraOutstandingItemsService.applyToOutstandingItems(
                outstandingItems,
                processingParameter.creditMemo.CreditMemo.unappliedAmount,
                processingParameter.creditMemo.CreditMemo.Project_Zcustom,
                processingParameter.creditMemo.CreditMemo.ClientOwner_Zcustom
            );
        CreditMemoApplication creditMemoApplication = groupByInvoiceAndDebitMemo(processingParameter.creditMemo, itemsWithApplication);
        String urlString = '/v1/creditmemos/' + processingParameter.creditMemo.CreditMemo.id +'/apply';
        Logger.logLater('ZuoraCreditMemoAllocationService', 'processOutstandingItems',
            'Request Endpoint: ' + urlString + '\n' +
            'Request Body: ' + JSON.serialize(creditMemoApplication),
            Logger.INFO);
        HttpResponse response = ZuoraAPIHelper.callJsonEndpoint( 'PUT', urlString, creditMemoApplication, false);
        Logger.logLater('ZuoraCreditMemoAllocationService', 'processOutstandingItems',
            'Response Body: ' + response.getBody(),
            Logger.INFO);
        Logger.flushLogs();
    }

    @TestVisible
    private static CreditMemoApplication groupByInvoiceAndDebitMemo( ZuoraAPI.CreditMemoWithItem creditMemo,
                                                                    List<ZuoraOutstandingItemsService.OutstandingItem> outstandingBillItems){

        Map<String,List<CreditMemoApplicationInvoiceItem>> invoiceToItemMap = new Map<String,List<CreditMemoApplicationInvoiceItem>>();
        Map<String,Decimal> invoiceToAmountMap = new Map<String,Decimal>();
        Map<String,List<CreditMemoApplicationDebitMemoItem>> debitMemoToItemMap = new Map<String,List<CreditMemoApplicationDebitMemoItem>>();
        Map<String,Decimal> debitMemoToAmountMap = new Map<String,Decimal>();

        for (ZuoraOutstandingItemsService.OutstandingItem billItem : outstandingBillItems){
            // If it is a match, create an application:
            if (billItem.IsInvoiceItem){
                CreditMemoApplicationInvoiceItem invoiceItem = new CreditMemoApplicationInvoiceItem();
                invoiceItem.amount = billItem.AmountToApply;
                invoiceItem.creditMemoItemId = creditMemo.Item.id;
                invoiceItem.invoiceItemId = billItem.Id;
                if (invoiceToItemMap.containsKey(billItem.ParentId)){
                    List<CreditMemoApplicationInvoiceItem> itemList = invoiceToItemMap.get(billItem.ParentId);
                    itemList.add(invoiceItem);
                    invoiceToItemMap.put(billItem.ParentId,itemList);
                    Decimal invoiceSubTotal = invoiceToAmountMap.get(billItem.ParentId);
                    invoiceSubTotal += billItem.AmountToApply;
                    invoiceToAmountMap.put(billItem.ParentId,invoiceSubTotal);
                } else {
                    invoiceToItemMap.put(billItem.ParentId,new List<CreditMemoApplicationInvoiceItem>{invoiceItem});
                    invoiceToAmountMap.put(billItem.ParentId, billItem.AmountToApply);
                }
            } else {
                CreditMemoApplicationDebitMemoItem debitMemoItem = new CreditMemoApplicationDebitMemoItem();
                debitMemoItem.amount = billItem.AmountToApply;
                debitMemoItem.creditMemoItemId = creditMemo.Item.id;
                debitMemoItem.debitMemoItemId = billItem.Id;
                if (debitMemoToItemMap.containsKey(billItem.ParentId)){
                    List<CreditMemoApplicationDebitMemoItem> itemList = debitMemoToItemMap.get(billItem.ParentId);
                    itemList.add(debitMemoItem);
                    debitMemoToItemMap.put(billItem.ParentId,itemList);
                    Decimal debitSubTotal = debitMemoToAmountMap.get(billItem.ParentId);
                    debitSubTotal += billItem.AmountToApply;
                    debitMemoToAmountMap.put(billItem.ParentId,debitSubTotal);
                } else {
                    debitMemoToItemMap.put(billItem.ParentId,new List<CreditMemoApplicationDebitMemoItem>{debitMemoItem});
                    debitMemoToAmountMap.put(billItem.ParentId, billItem.AmountToApply);
                }
            }
        }

        CreditMemoApplication application = new CreditMemoApplication();
        application.invoices = new List<CreditMemoApplicationInvoice>();
        application.debitMemos = new List<CreditMemoApplicationDebitMemo>();

        for (String invoiceId : invoiceToItemMap.keySet()){
            CreditMemoApplicationInvoice invoiceToApply = new CreditMemoApplicationInvoice();
            invoiceToApply.invoiceId = invoiceId;
            invoiceToApply.amount = invoiceToAmountMap.get(invoiceId);
            invoiceToApply.items = invoiceToItemMap.get(invoiceId);
            application.invoices.add(invoiceToApply);
        }

        for (String debitMemoId : debitMemoToItemMap.keySet()){
            CreditMemoApplicationDebitMemo debitToApply = new CreditMemoApplicationDebitMemo();
            debitToApply.debitMemoId = debitMemoId;
            debitToApply.amount = debitMemoToAmountMap.get(debitMemoId);
            debitToApply.items = debitMemoToItemMap.get(debitMemoId);
            application.debitMemos.add(debitToApply);
        }
        return application;
    }

    public static QueryResultCreditMemo getCreditMemosByPage(String urlString){
        HttpResponse response = ZuoraAPIHelper.callJsonEndpoint(
            'GET',
            urlString,
            null,
            false);
        String responseBody = response.getBody();
        responseBody = ZuoraAPIHelper.cleanJSON(responseBody);
        ZuoraCreditMemoAllocationService.QueryResultCreditMemo zResponse;
        zResponse = (ZuoraCreditMemoAllocationService.QueryResultCreditMemo)JSON.deserialize(
            responseBody,
            ZuoraCreditMemoAllocationService.QueryResultCreditMemo.class
        );
        return zResponse;
    }

    public static QueryResultCreditMemo getFirstPageCreditMemos(Integer numberOfMemos) {
        if (numberOfMemos > 40){
            numberOfMemos = 40;
        }
        String urlString = '/v1/creditmemos?status=Posted&sort=-creditMemoDate&pageSize=' + numberOfMemos;
        QueryResultCreditMemo zResponse = getCreditMemosByPage(urlString);
        return zResponse;
    }

    // Assumes credit memos only have 1 item. As of 6/2019, every adjustment in SF only = 1 credit memo item in Zuora
    public static ZuoraAPI.CreditMemoWithItem getItemFromCreditMemo(ZuoraAPI.ZuoraCreditMemo creditMemo) {
        String urlString = '/v1/creditmemos/' + creditMemo.Id + '/items';
        HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('GET',urlString,null,false);
        QueryResultCreditMemoItems zResponse;
        zResponse = (QueryResultCreditMemoItems)JSON.deserialize(response.getBody(), QueryResultCreditMemoItems.class);

        ZuoraAPI.CreditMemoWithItem creditMemoRecord = new ZuoraAPI.CreditMemoWithItem();
        creditMemoRecord.CreditMemo = creditMemo;
        creditMemoRecord.Item = zResponse.Items[0];
        return creditMemoRecord;
    }
}