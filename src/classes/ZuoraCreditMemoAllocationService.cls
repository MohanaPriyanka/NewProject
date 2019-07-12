/*************************************************************************************
 * Created By:  Jordan Pentaleri
 * Test: ZuoraCreditMemoAllocationTest
 *************************************************************************************/

public class ZuoraCreditMemoAllocationService{
    public class CreditMemoApplication {
        public List<CreditMemoApplicationInvoice> Invoices;
        public List<CreditMemoApplicationDebitMemo> DebitMemos;
    }

    public class CreditMemoApplicationInvoice {
        public String InvoiceId;
        public List<CreditMemoApplicationInvoiceItem> Items;
        public Decimal Amount;
    }

    public class CreditMemoApplicationInvoiceItem {
        public String InvoiceItemId;
        public String CreditMemoItemId;
        public Decimal Amount;
    }

    public class CreditMemoApplicationDebitMemo {
        public String DebitMemoId;
        public List<CreditMemoApplicationDebitMemoItem> Items;
        public Decimal Amount;
    }

    public class CreditMemoApplicationDebitMemoItem {
        public String DebitMemoItemId;
        public String CreditMemoItemId;
        public Decimal Amount;
    }

    public class QueryResultCreditMemo {
        public List<ZuoraAPI.ZuoraCreditMemo> CreditMemos;
        public String NextPage;
        public String Success;
    }

    public class QueryResultCreditMemoItems {
        public List<ZuoraAPI.ZuoraCreditMemoItem> Items;
    }

    public static CreditMemoApplication getCreditMemoApplication(ZuoraAPI.CreditMemoWithItem creditMemo){
        List<ZuoraOutstandingItemsService.OutstandingItem> outstandingItems;
        List<ZuoraOutstandingItemsService.OutstandingItem> itemsWithApplication;

        outstandingItems = ZuoraOutstandingItemsService.getOutstandingItemsByDate(creditMemo.CreditMemo.accountId);
        itemsWithApplication = ZuoraOutstandingItemsService.applyToOutstandingItems(
            outstandingItems,
            creditMemo.CreditMemo.unappliedAmount,
            creditMemo.CreditMemo.Project_Zcustom,
            creditMemo.CreditMemo.ClientOwner_Zcustom
        );
        return groupByInvoiceAndDebitMemo(creditMemo, itemsWithApplication);
    }

    public static CreditMemoApplication groupByInvoiceAndDebitMemo( ZuoraAPI.CreditMemoWithItem creditMemo,
                                                                    List<ZuoraOutstandingItemsService.OutstandingItem> outstandingBillItems){

        Map<String,List<CreditMemoApplicationInvoiceItem>> invoiceToItemMap = new Map<String,List<CreditMemoApplicationInvoiceItem>>();
        Map<String,Decimal> invoiceToAmountMap = new Map<String,Decimal>();
        Map<String,List<CreditMemoApplicationDebitMemoItem>> debitMemoToItemMap = new Map<String,List<CreditMemoApplicationDebitMemoItem>>();
        Map<String,Decimal> debitMemoToAmountMap = new Map<String,Decimal>();

        for (ZuoraOutstandingItemsService.OutstandingItem billItem : outstandingBillItems){
            // If it is a match, create an application:
            if (billItem.IsInvoiceItem){
                CreditMemoApplicationInvoiceItem invoiceItem = new CreditMemoApplicationInvoiceItem();
                invoiceItem.Amount = billItem.AmountToApply;
                invoiceItem.CreditMemoItemId = creditMemo.Item.id;
                invoiceItem.InvoiceItemId = billItem.Id;
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
                debitMemoItem.Amount = billItem.AmountToApply;
                debitMemoItem.CreditMemoItemId = creditMemo.Item.id;
                debitMemoItem.DebitMemoItemId = billItem.Id;
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
        application.Invoices = new List<CreditMemoApplicationInvoice>();
        application.DebitMemos = new List<CreditMemoApplicationDebitMemo>();

        for (String invoiceId : invoiceToItemMap.keySet()){
            CreditMemoApplicationInvoice invoiceToApply = new CreditMemoApplicationInvoice();
            invoiceToApply.InvoiceId = invoiceId;
            invoiceToApply.Amount = invoiceToAmountMap.get(invoiceId);
            invoiceToApply.Items = invoiceToItemMap.get(invoiceId);
            application.Invoices.add(invoiceToApply);
        }

        for (String debitMemoId : debitMemoToItemMap.keySet()){
            CreditMemoApplicationDebitMemo debitToApply = new CreditMemoApplicationDebitMemo();
            debitToApply.DebitMemoId = debitMemoId;
            debitToApply.Amount = debitMemoToAmountMap.get(debitMemoId);
            debitToApply.Items = debitMemoToItemMap.get(debitMemoId);
            application.DebitMemos.add(debitToApply);
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