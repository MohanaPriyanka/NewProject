/*************************************************************************************
 * Created By:  Jordan Pentaleri
 * Test: ZuoraCreditMemoAllocationTest
 *************************************************************************************/

@SuppressWarnings('PMD.VariableNamingConventions')
public class ZuoraCreditMemoAllocationService implements ZuoraOutstandingItemsService.Processor {
    public class CreditMemoApplication {
        public Date effectiveDate;
        public List<CreditMemoApplicationInvoice> invoices;
        public List<CreditMemoApplicationDebitMemo> debitMemos;
        public CreditMemoApplication(Date effectiveDate) {
            this.effectiveDate = effectiveDate;
            this.invoices = new List<CreditMemoApplicationInvoice>();
            this.debitMemos = new List<CreditMemoApplicationDebitMemo>();
        }
    }

    public class CreditMemoApplicationInvoice {
        public String invoiceId;
        public List<CreditMemoApplicationInvoiceItem> items;
        public Decimal amount;
        public CreditMemoApplicationInvoice(String invoiceId, List<CreditMemoApplicationInvoiceItem> items, Decimal amount) {
            this.invoiceId = invoiceId;
            this.items = items;
            this.amount = amount;
        }
    }

    public class CreditMemoApplicationInvoiceItem {
        public String invoiceItemId;
        public String creditMemoItemId;
        public Decimal amount;
        public CreditMemoApplicationInvoiceItem(ZuoraOutstandingItemsService.OutstandingItem billItem, ZuoraAPI.CreditMemoWithItem creditMemo) {
            this.amount = billItem.AmountToApply;
            this.creditMemoItemId = creditMemo.Item.id;
            this.invoiceItemId = billItem.Id;
        }
    }

    public class CreditMemoApplicationDebitMemo {
        public String debitMemoId;
        public List<CreditMemoApplicationDebitMemoItem> items;
        public Decimal amount;
        public CreditMemoApplicationDebitMemo(String debitMemoId, List<CreditMemoApplicationDebitMemoItem> items, Decimal amount) {
            this.debitMemoId = debitMemoId;
            this.items = items;
            this.amount = amount;
        }
    }

    public class CreditMemoApplicationDebitMemoItem {
        public String debitMemoItemId;
        public String creditMemoItemId;
        public Decimal amount;
        public CreditMemoApplicationDebitMemoItem(ZuoraOutstandingItemsService.OutstandingItem billItem, ZuoraAPI.CreditMemoWithItem creditMemo) {
            this.amount = billItem.AmountToApply;
            this.creditMemoItemId = creditMemo.Item.id;
            this.debitMemoItemId = billItem.Id;
        }
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

    public static CreditMemoApplication groupByInvoiceAndDebitMemo( ZuoraAPI.CreditMemoWithItem creditMemo,
                                                                    List<ZuoraOutstandingItemsService.OutstandingItem> outstandingBillItems){

        Map<String,List<CreditMemoApplicationInvoiceItem>> invoiceToItemMap = new Map<String,List<CreditMemoApplicationInvoiceItem>>();
        Map<String,Decimal> invoiceToAmountMap = new Map<String,Decimal>();
        Map<String,List<CreditMemoApplicationDebitMemoItem>> debitMemoToItemMap = new Map<String,List<CreditMemoApplicationDebitMemoItem>>();
        Map<String,Decimal> debitMemoToAmountMap = new Map<String,Decimal>();

        // It doesn't seem to work to post-date an application before today:
        // Request Endpoint: https://rest.apisandbox.zuora.com/v1/creditmemos/2c92c0fa6dcf208a016dd62bf97f53f3/apply
        // Request Body: {"invoices":[{"items":[{"invoiceItemId":"2c92c0fa6dd8a849016dda4351ad2fa8","creditMemoItemId":"2c92c0fa6dcf208a016dd62bf99953f4","amount":0.170000000}],"invoiceId":"2c92c0fa6dd8a849016dda43519d2fa6","amount":0.170000000}],"effectiveDate":"2018-06-15","debitMemos":[]}
        // "message" : "The effective date in the request must be later than or equal to the latest effective date 10/18/2019 of application."
        // But 10/18/2019 (the date on which the application was attempted) isn't found anywhere.
        // The effectiveDate of the application must also be after the credit memo date and all of the applied items.
        Date effectiveDate =  Util.maxTwoDates(Date.today(), creditMemo.CreditMemo.creditMemoDate);

        for (ZuoraOutstandingItemsService.OutstandingItem billItem : outstandingBillItems) {
            if (billItem.EffectiveDate > effectiveDate) {
                effectiveDate = Date.parse(billItem.EffectiveDate.formatGmt('MM/dd/YYYY'));
            }
            // If it is a match, create an application:
            if (billItem.IsInvoiceItem){
                CreditMemoApplicationInvoiceItem invoiceItem = new CreditMemoApplicationInvoiceItem(billItem, creditMemo);
                addToInvoiceMaps(invoiceToItemMap, billItem, invoiceItem, invoiceToAmountMap);
            } else {
                CreditMemoApplicationDebitMemoItem debitMemoItem = new CreditMemoApplicationDebitMemoItem(billItem, creditMemo);
                addToDebitMemoMaps(debitMemoToItemMap, billItem, debitMemoItem, debitMemoToAmountMap);
            }
        }

        CreditMemoApplication application = new CreditMemoApplication(effectiveDate);

        for (String invoiceId : invoiceToItemMap.keySet()){
            CreditMemoApplicationInvoice invoiceToApply = new CreditMemoApplicationInvoice(invoiceId, invoiceToItemMap.get(invoiceId), invoiceToAmountMap.get(invoiceId));
            application.invoices.add(invoiceToApply);
        }

        for (String debitMemoId : debitMemoToItemMap.keySet()){
            CreditMemoApplicationDebitMemo debitToApply = new CreditMemoApplicationDebitMemo(debitMemoId, debitMemoToItemMap.get(debitMemoId), debitMemoToAmountMap.get(debitMemoId));
            application.debitMemos.add(debitToApply);
        }

        if (application.invoices.size() == 0 && application.debitMemos.size() == 0) {
            throw new Util.FatalBWException('Could not find anything to apply this credit memo to. Credit Memo\n' + creditMemo + '\n' +
                'Outstanding items:\n' + JSON.serializePretty(outstandingBillItems));
        }
        return application;
    }

    private static void addToDebitMemoMaps(Map<String, List<CreditMemoApplicationDebitMemoItem>> debitMemoToItemMap, ZuoraOutstandingItemsService.OutstandingItem billItem, CreditMemoApplicationDebitMemoItem debitMemoItem, Map<String, Decimal> debitMemoToAmountMap) {
        if (debitMemoToItemMap.containsKey(billItem.ParentId)) {
            List<CreditMemoApplicationDebitMemoItem> itemList = debitMemoToItemMap.get(billItem.ParentId);
            itemList.add(debitMemoItem);
            debitMemoToItemMap.put(billItem.ParentId, itemList);
            Decimal debitSubTotal = debitMemoToAmountMap.get(billItem.ParentId);
            debitSubTotal += billItem.AmountToApply;
            debitMemoToAmountMap.put(billItem.ParentId, debitSubTotal);
        } else {
            debitMemoToItemMap.put(billItem.ParentId, new List<CreditMemoApplicationDebitMemoItem>{
                debitMemoItem
            });
            debitMemoToAmountMap.put(billItem.ParentId, billItem.AmountToApply);
        }
    }

    private static void addToInvoiceMaps(Map<String, List<CreditMemoApplicationInvoiceItem>> invoiceToItemMap, ZuoraOutstandingItemsService.OutstandingItem billItem, CreditMemoApplicationInvoiceItem invoiceItem, Map<String, Decimal> invoiceToAmountMap) {
        if (invoiceToItemMap.containsKey(billItem.ParentId)) {
            List<CreditMemoApplicationInvoiceItem> itemList = invoiceToItemMap.get(billItem.ParentId);
            itemList.add(invoiceItem);
            invoiceToItemMap.put(billItem.ParentId, itemList);
            Decimal invoiceSubTotal = invoiceToAmountMap.get(billItem.ParentId);
            invoiceSubTotal += billItem.AmountToApply;
            invoiceToAmountMap.put(billItem.ParentId, invoiceSubTotal);
        } else {
            invoiceToItemMap.put(billItem.ParentId, new List<CreditMemoApplicationInvoiceItem>{
                invoiceItem
            });
            invoiceToAmountMap.put(billItem.ParentId, billItem.AmountToApply);
        }
    }

    public static QueryResultCreditMemo getCreditMemosByPage(String urlString) {
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

    public static QueryResultCreditMemo getFirstPageCreditMemos(String zuoraAccountId) {
        return getFirstPageCreditMemos(40, zuoraAccountId);
    }

    public static QueryResultCreditMemo getFirstPageCreditMemos(Integer numberOfMemos) {
        return getFirstPageCreditMemos(numberOfMemos, null);
    }

    private static QueryResultCreditMemo getFirstPageCreditMemos(Integer numberOfMemos, String zuoraAccountId) {
        if (numberOfMemos > 40){
            numberOfMemos = 40;
        }
        String urlString = '/v1/creditmemos?status=Posted&sort=-creditMemoDate&pageSize=' + numberOfMemos;
        if (zuoraAccountId != null) {
            urlString += '&accountId=' + zuoraAccountId;
        }
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