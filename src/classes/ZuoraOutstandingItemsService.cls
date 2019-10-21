/*************************************************************************************
 * Created By:  Jordan Pentaleri
 * Description: Queries Zuora for outstanding invoice items and debit memos,
 *              sorts by date and returns list of items with balance
 * Test: ZuoraCreditMemoAllocationTest
 *************************************************************************************/
@SuppressWarnings('PMD.VariableNamingConventions')
public class ZuoraOutstandingItemsService{
    public class QueryResultInvoice {
        public List<ZuoraAPI.Invoice> Records;
    }

    public class QueryResultRatePlanCharge {
        public List<RatePlanCharge> Records;
    }

    public class QueryResultInvoiceItems {
        public List<ZuoraAPI.InvoiceItem> InvoiceItems;
        String nextPage;
        Boolean success;
    }

    public class QueryResultDebitMemo {
        public List<ZuoraAPI.ZuoraDebitMemo> DebitMemos;
        String nextPage;
        Boolean success;
    }

    public class QueryResultDebitMemoItem {
        public List<ZuoraAPI.ZuoraDebitMemoItem> Items;
    }

    public class OutstandingItem implements Comparable {
        public Decimal AmountOutstanding;
        public Datetime EffectiveDate;
        public String Project;
        public String Client;
        public String Id;
        public String ParentId;
        public Boolean IsInvoiceItem; // Only DebitMemo or InvoiceItem
        public Decimal AmountToApply;

        // Compares by effective date first. If dates are the same between invoice items, sorts by project. If projects
        // are the same, then sorts by client.
        public Integer compareTo(Object compareTo) {
            OutstandingItem compareToItem = (OutstandingItem) compareTo;
            Integer returnValue = 0;
            if (EffectiveDate > compareToItem.EffectiveDate) {
                returnValue = 1;
            } else if (EffectiveDate < compareToItem.EffectiveDate) {
                returnValue = -1;
            } else if (Project > compareToItem.Project) {
                returnValue = 1;
            } else if (Project < compareToItem.Project) {
                returnValue = -1;
            } else if (Client > compareToItem.Client) {
                returnValue = 1;
            } else if (Client < compareToItem.Client) {
                returnValue = -1;
            }
            return returnValue;
        }
    }

    public class RatePlanCharge{
        public String Id;
        public String ChargeNumber;
        public String Project_Zcustom;
        public String ClientOwner_Zcustom;
    }
    
    // Can be used for payments or credit memos. Sets the amountToApply field on outstanding items:
    public static List<OutstandingItem> applyToOutstandingItems (   List<OutstandingItem> outstandingItems,
                                                                    Decimal amountToApply,
                                                                    String project,
                                                                    String client) {
        return applyToOutstandingItems(outstandingItems, amountToApply, project, client, null, null, null);
    }

    // Use this if we just have entity and not project (for instance, when importing historical payments)
    public static List<OutstandingItem> applyToOutstandingItems (List<OutstandingItem> outstandingItems, Decimal amountToApply,
        String entity, String client, Map<String, Id> projectToEntityMap, Date effectiveDate) {
        return applyToOutstandingItems(outstandingItems, amountToApply, null, client, entity, projectToEntityMap, effectiveDate);
    }

    private static List<OutstandingItem> applyToOutstandingItems (List<OutstandingItem> outstandingItems, Decimal amountToApply,
        String project, String client, String entity, Map<String, Id> projectToEntityMap, Date effectiveDate) {
        List<ZuoraOutstandingItemsService.OutstandingItem> itemsToApply = new List<ZuoraOutstandingItemsService.OutstandingItem>();

        for (ZuoraOutstandingItemsService.OutstandingItem billItem : outstandingItems) {
            if (billItem.AmountOutstanding <= 0) {
                // Not really outstanding, check the next billItem
                continue;
            }
            if (amountToApply <= 0) {
                // There's nothing left to apply
                break;
            }
            // Only apply to invoices and debit memos with same client and project:
            if (appliesTo(billItem, project, client, entity, projectToEntityMap, effectiveDate)) {
                // Clone the outstanding item so we can update the original one in the outstandingItems list
                // so that a subsequent call to apply another amount will take into account the updated amount outstanding
                ZuoraOutstandingItemsService.OutstandingItem outstandingItemToApply = billItem.clone();
                if (billItem.AmountOutstanding <= amountToApply) {
                    outstandingItemToApply.AmountToApply = billItem.AmountOutstanding;
                    amountToApply -= billItem.AmountOutstanding;
                    billItem.AmountOutstanding = 0;
                } else {
                    outstandingItemToApply.AmountToApply = amountToApply;
                    billItem.AmountOutstanding -= amountToApply;
                    amountToApply = 0;
                }
                itemsToApply.add(outstandingItemToApply);
            }
        }
        return itemsToApply;
    }

    @TestVisible
    private static Boolean appliesTo(OutstandingItem outstandingItem, String project, String client, String entity,
        Map<String, Id> projectUniqueIdToEntityMap, Date effectiveDate) {
        // We can use effective date to only find outstanding items that were effective before a certain date (for instance
        // when applying historical payments)
        if (effectiveDate != null && effectiveDate < outstandingItem.EffectiveDate) {
            return false;
        }
        if (project != null && client != null) {
            return (outstandingItem.Project == project && outstandingItem.Client == client);
        }
        if (entity != null && client != null && projectUniqueIdToEntityMap != null) {
            return (projectUniqueIdToEntityMap.get(outstandingItem.Project) == entity && outstandingItem.Client == client);
        }
        throw new Util.BWException('Check an Outstanding Item against a Project and Client, or Entity and ProjectEntityMap');
    }

    public static ZuoraOutstandingItemsAsyncService processOutstandingItemsByDate(String zuoraAcctId, ProcessingParameter processingParameter) {
        List<ZuoraAPI.Invoice> invoices = getOutstandingInvoices(zuoraAcctId);
        List<ZuoraAPI.ZuoraDebitMemo> debitMemos = getOutstandingDebitMemos(zuoraAcctId);

        ZuoraOutstandingItemsAsyncService asyncService =
            new ZuoraOutstandingItemsAsyncService(invoices, debitMemos, processingParameter);
        if (!Test.isRunningTest()) {
            System.enqueueJob(asyncService);
        }
        return asyncService;
    }

    public static List<ZuoraAPI.Invoice> getOutstandingInvoices(String zuoraAcctId) {
        String queryString = 'SELECT ' +
            'id, accountId, amount, invoiceDate, balance ' +
            'FROM Invoice ' +
            'WHERE accountId = \'' + zuoraAcctId + '\' ' +
            'AND balance > 0';
        String response = ZuoraAPIHelper.query(queryString,false);
        QueryResultInvoice queriedInvoices = (QueryResultInvoice)JSON.deserialize(response, QueryResultInvoice.class);
        return queriedInvoices.Records;
    }

    public static ZuoraAPI.InvoiceWithItems getInvoiceItems(ZuoraAPI.Invoice invoice) {
        ZuoraAPI.InvoiceWithItems invoiceRecord = new ZuoraAPI.InvoiceWithItems();
        invoiceRecord.invoice = invoice;
        invoiceRecord.items = getAllInvoiceItems(invoice.id);
        return invoiceRecord;
    }

    public static List<ZuoraAPI.InvoiceItem> getAllInvoiceItems(String invoiceItemId) {
        return getAllInvoiceItems('/v1/invoices/' + invoiceItemId +'/items', new List<ZuoraAPI.InvoiceItem>());
    }

    private static List<ZuoraAPI.InvoiceItem> getAllInvoiceItems(String url, List<ZuoraAPI.InvoiceItem> invoiceItems) {
        HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('GET',url,null,false);
        QueryResultInvoiceItems itemsQuery =
            (QueryResultInvoiceItems)JSON.deserialize(response.getBody(), QueryResultInvoiceItems.class);
        if (!itemsQuery.success) {
            throw new Util.BWException('Caught exception getting invoice items:\n' + response.getBody());
        }
        invoiceItems.addAll(itemsQuery.InvoiceItems);
        if (itemsQuery.nextPage != null) {
            return getAllInvoiceItems(itemsQuery.nextPage, invoiceItems);
        }
        return invoiceItems;
    }

    public static List<OutstandingItem> convertInvoiceItems(ZuoraAPI.InvoiceWithItems invoiceWithBalance){
        List<OutstandingItem> itemsWithBalance = new List<OutstandingItem>();
        for (ZuoraAPI.InvoiceItem invItem : invoiceWithBalance.items){
            if (invItem.balance > 0){
                String ratePlan = ZuoraAPIHelper.query(
                    'SELECT Id, Name, ChargeNumber, ClientOwner__c, Project__c ' +
                    'FROM RatePlanCharge '+
                    'WHERE Id = \'' + invItem.chargeId + '\'',
                    false
                );
                ratePlan = ratePlan.replace('__c','_Zcustom');
                QueryResultRatePlanCharge queryResult =
                    (QueryResultRatePlanCharge)JSON.deserialize(ratePlan, QueryResultRatePlanCharge.class);
                RatePlanCharge invRatePlanCharge = queryResult.Records[0];
                OutstandingItem newItem = new OutstandingItem();
                newItem.AmountOutstanding = invItem.balance;
                newItem.EffectiveDate = invoiceWithBalance.invoice.invoiceDate;
                newItem.Project = invRatePlanCharge.Project_Zcustom;
                newItem.Client = invRatePlanCharge.ClientOwner_Zcustom;
                newItem.Id = invItem.id;
                newItem.ParentId = invoiceWithBalance.invoice.id;
                newItem.IsInvoiceItem = true;
                itemsWithBalance.add(newItem);
            }
        }
        return itemsWithBalance;
    }

    public static List<ZuoraAPI.ZuoraDebitMemo> getOutstandingDebitMemos(String zAcctId) {
        List<ZuoraAPI.ZuoraDebitMemo> debitMemos = getAllOutstandingDebitMemos(zAcctId, null, null);

        List<ZuoraAPI.ZuoraDebitMemo> debitMemosWithBalance = new List<ZuoraAPI.ZuoraDebitMemo>();
        for (ZuoraAPI.ZuoraDebitMemo debitMemo : debitMemos){
            if (debitMemo.balance > 0 && debitMemo.accountId == zAcctId){
                debitMemosWithBalance.add(debitMemo);
            }
        }
        return debitMemosWithBalance;
    }

    private static List<ZuoraAPI.ZuoraDebitMemo> getAllOutstandingDebitMemos(String zAcctId, List<ZuoraAPI.ZuoraDebitMemo> debitMemos, String url) {
        if (debitMemos == null) {
            debitMemos = new List<ZuoraAPI.ZuoraDebitMemo>();
        }
        if (url == null) {
            url = '/v1/debitmemos?accountId=' + zAcctId + '&status=Posted&pageSize=40';
        }
        HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('GET',url,null,false);
        QueryResultDebitMemo result =
            (QueryResultDebitMemo) JSON.deserialize(ZuoraAPIHelper.cleanJSON(response.getBody()), QueryResultDebitMemo.class);
        if (result.success) {
            debitMemos.addAll(result.DebitMemos);
        } else {
            throw new Util.BWException('Debit Memo query failed for account: ' + zAcctId);
        }

        if (result.nextPage != null) {
            return getAllOutstandingDebitMemos(zAcctId, debitMemos, result.nextPage);
        } else {
            return debitMemos;
        }
    }

    public static ZuoraAPI.DebitMemoWithItems getDebitMemoItems(ZuoraAPI.ZuoraDebitMemo debitMemo) {
        HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('GET','/v1/debitmemos/' + debitMemo.id +'/items',null,false);
        String responseBody = ZuoraAPIHelper.cleanJSON(response.getBody());
        QueryResultDebitMemoItem itemsQuery =
            (QueryResultDebitMemoItem)JSON.deserialize(responseBody, QueryResultDebitMemoItem.class);
        ZuoraAPI.DebitMemoWithItems debitMemoRecord = new ZuoraAPI.DebitMemoWithItems();
        debitMemoRecord.debitMemo = debitMemo;
        debitMemoRecord.items = itemsQuery.Items;
        return debitMemoRecord;
    }

    public static List<OutstandingItem> convertDebitMemoItems(ZuoraAPI.DebitMemoWithItems debitMemoWithBalance){
        List<OutstandingItem> itemsWithBalance = new List<OutstandingItem>();
        for (ZuoraAPI.ZuoraDebitMemoItem debitItem : debitMemoWithBalance.items){
            if (debitItem.balance > 0){
                OutstandingItem newItem = new OutstandingItem();
                newItem.AmountOutstanding = debitItem.balance;
                newItem.EffectiveDate = debitMemoWithBalance.debitMemo.debitMemoDate;
                newItem.Project = debitMemoWithBalance.debitMemo.Project_Zcustom;
                newItem.Client = debitMemoWithBalance.debitMemo.ClientOwner_Zcustom;
                newItem.Id = debitItem.id;
                newItem.ParentId = debitMemoWithBalance.debitMemo.id;
                newItem.IsInvoiceItem = false;
                itemsWithBalance.add(newItem);
            }
        }
        return itemsWithBalance;
    }

    public interface Processor {
        void processOutstandingItems(List<ZuoraOutstandingItemsService.OutstandingItem> outstandingItems, ProcessingParameter option);
    }

    public class ProcessingParameter {
        public String processorClassName;
        public ZuoraAPI.CreditMemoWithItem creditMemo;
        public List<ZuoraHistoricalApplicationService.Payable> payables;
        public List<OutstandingItem> allOutstandingItems;

        public ProcessingParameter() {
            this.allOutstandingItems = new List<OutstandingItem>();
        }

        public ProcessingParameter(String processorClassName, ZuoraAPI.CreditMemoWithItem creditMemo) {
            this.processorClassName = processorClassName;
            this.creditMemo = creditMemo;
            this.allOutstandingItems = new List<OutstandingItem>();
        }

        public ProcessingParameter(String processorClassName, List<ZuoraHistoricalApplicationService.Payable> payables) {
            this.processorClassName = processorClassName;
            this.payables = payables;
            this.allOutstandingItems = new List<OutstandingItem>();
        }
    }
}