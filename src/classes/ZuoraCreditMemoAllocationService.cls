/*************************************************************************************
 * Created By:  Jordan Pentaleri
 * Test: ZuoraCreditMemoAllocationTest
 *************************************************************************************/

public class ZuoraCreditMemoAllocationService{
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
        public List<ZuoraAPI.ZuoraCreditMemo> creditmemos;
        public String nextPage;
        public String success;
    }

    public class QueryResultCreditMemoItems {
        public List<ZuoraAPI.ZuoraCreditMemoItem> items;
    }

    public static CreditMemoApplication getCreditMemoApplication(ZuoraAPI.CreditMemoWithItem creditMemo){
        List<ZuoraOutstandingItemsService.OutstandingItem> outstandingItems;
        List<ZuoraOutstandingItemsService.OutstandingItem> itemsWithApplication;

        outstandingItems = ZuoraOutstandingItemsService.getOutstandingItemsByDate(creditMemo.creditMemo.accountId);
        itemsWithApplication = ZuoraOutstandingItemsService.applyToOutstandingItems(
            outstandingItems,
            creditMemo.creditMemo.unappliedAmount,
            creditMemo.creditMemo.Project_Zcustom,
            creditMemo.creditMemo.ClientOwner_Zcustom
        );
        return groupByInvoiceAndDebitMemo(creditMemo, itemsWithApplication);
    }

    public static CreditMemoApplication groupByInvoiceAndDebitMemo( ZuoraAPI.CreditMemoWithItem creditmemo,
                                                                    List<ZuoraOutstandingItemsService.OutstandingItem> outstandingBillItems){

        Map<String,List<CreditMemoApplicationInvoiceItem>> invoiceToItemMap = new Map<String,List<CreditMemoApplicationInvoiceItem>>();
        Map<String,Decimal> invoiceToAmountMap = new Map<String,Decimal>();
        Map<String,List<CreditMemoApplicationDebitMemoItem>> debitMemoToItemMap = new Map<String,List<CreditMemoApplicationDebitMemoItem>>();
        Map<String,Decimal> debitMemoToAmountMap = new Map<String,Decimal>();

        for (ZuoraOutstandingItemsService.OutstandingItem billItem : outstandingBillItems){
            // If it is a match, create an application:
            if (billItem.isInvoiceItem){
                CreditMemoApplicationInvoiceItem invoiceItem = new CreditMemoApplicationInvoiceItem();
                invoiceItem.amount = billItem.amountToApply;
                invoiceItem.creditMemoItemId = creditMemo.item.Id;
                invoiceItem.invoiceItemId = billItem.Id;
                if (invoiceToItemMap.containsKey(billItem.parentId)){
                    List<CreditMemoApplicationInvoiceItem> itemList = invoiceToItemMap.get(billItem.parentId);
                    itemList.add(invoiceItem);
                    invoiceToItemMap.put(billItem.parentId,itemList);
                    Decimal invoiceSubTotal = invoiceToAmountMap.get(billItem.parentId);
                    invoiceSubTotal += billItem.amountToApply;
                    invoiceToAmountMap.put(billItem.parentId,invoiceSubTotal);
                } else {
                    invoiceToItemMap.put(billItem.parentId,new List<CreditMemoApplicationInvoiceItem>{invoiceItem});
                    invoiceToAmountMap.put(billItem.parentId, billItem.amountToApply);
                }
            } else {
                CreditMemoApplicationDebitMemoItem debitMemoItem = new CreditMemoApplicationDebitMemoItem();
                debitMemoItem.amount = billItem.amountToApply;
                debitMemoItem.creditMemoItemId = creditMemo.item.Id;
                debitMemoItem.debitMemoItemId = billItem.Id;
                if (debitMemoToItemMap.containsKey(billItem.parentId)){
                    List<CreditMemoApplicationDebitMemoItem> itemList = debitMemoToItemMap.get(billItem.parentId);
                    itemList.add(debitMemoItem);
                    debitMemoToItemMap.put(billItem.parentId,itemList);
                    Decimal debitSubTotal = debitMemoToAmountMap.get(billItem.parentId);
                    debitSubTotal += billItem.amountToApply;
                    debitMemoToAmountMap.put(billItem.parentId,debitSubTotal);
                } else {
                    debitMemoToItemMap.put(billItem.parentId,new List<CreditMemoApplicationDebitMemoItem>{debitMemoItem});
                    debitMemoToAmountMap.put(billItem.parentId, billItem.amountToApply);
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
        HttpResponse response = ZuoraAPIHelper.callJSONEndpoint(
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
        HttpResponse response = ZuoraAPIHelper.callJSONEndpoint('GET',urlString,null,false);
        QueryResultCreditMemoItems zResponse;
        zResponse = (QueryResultCreditMemoItems)JSON.deserialize(response.getBody(), QueryResultCreditMemoItems.class);

        ZuoraAPI.CreditMemoWithItem creditMemoRecord = new ZuoraAPI.CreditMemoWithItem();
        creditMemoRecord.creditMemo = creditMemo;
        creditMemoRecord.item = zResponse.items[0];
        return creditMemoRecord;
    }
}