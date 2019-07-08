/*************************************************************************************
 * Created By:  Jordan Pentaleri
 * Description: Queries Zuora for outstanding invoice items and debit memos,
 *              sorts by date and returns list of items with balance
 * Test: ZuoraCreditMemoAllocationTest
 *************************************************************************************/

public class ZuoraOutstandingItemsService{
    public class QueryResultInvoice {
        public List<ZuoraAPI.Invoice> Records;
    }

    public class QueryResultRatePlanCharge {
        public List<RatePlanCharge> Records;
    }

    public class QueryResultInvoiceItems {
        public List<ZuoraAPI.InvoiceItem> InvoiceItems;
    }

    public class QueryResultDebitMemo {
        public List<ZuoraAPI.ZuoraDebitMemo> Debitmemos;
    }

    public class QueryResultDebitMemoItem {
        public List<ZuoraAPI.ZuoraDebitMemoItem> Items;
    }

    public class OutstandingItem {
        public Decimal AmountOutstanding;
        public Datetime EffectiveDate;
        public String Project;
        public String Client;
        public String Id;
        public String ParentId;
        public Boolean IsInvoiceItem; // Only DebitMemo or InvoiceItem
        public Decimal AmountToApply;
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
                                                                    String client){
        List<ZuoraOutstandingItemsService.OutstandingItem> itemsToApply = new List<ZuoraOutstandingItemsService.OutstandingItem>();

        for (ZuoraOutstandingItemsService.OutstandingItem billItem : outstandingItems) {
            // Only apply to invoices and debit memos with same client and project:
            if (billItem.Project == project
                && billItem.Client == client
                && billItem.AmountOutstanding <= amountToApply) {
                billItem.AmountToApply = billItem.AmountOutstanding;
                amountToApply -= billItem.AmountOutstanding;
                itemsToApply.add(billItem);
            } else if (billItem.Project == project
                && billItem.Client == client
                && amountToApply > 0) {
                billItem.AmountToApply = amountToApply;
                amountToApply -= amountToApply;
                itemsToApply.add(billItem);
            }
        }
        return itemsToApply;
    }

    public static List<OutstandingItem> getOutstandingItemsByDate(String zuoraAcctId){
        List<OutstandingItem> allOutstandingItems = new List<OutstandingItem>();

        List<ZuoraAPI.Invoice> invoices = getOutstandingInvoices(zuoraAcctId);
        for (ZuoraAPI.Invoice invoice : invoices){
            ZuoraAPI.InvoiceWithItems invoiceItems = getInvoiceItems(invoice);
            allOutstandingItems.addAll(convertInvoiceItems(invoiceItems));
        }

        List<ZuoraAPI.ZuoraDebitMemo> debitMemos = getOutstandingDebitMemos(zuoraAcctId);
        for (ZuoraAPI.ZuoraDebitMemo debitMemo : debitMemos){
            ZuoraAPI.DebitMemoWithItems debitMemoItems = getDebitMemoItems(debitMemo);
            allOutstandingItems.addAll(convertDebitMemoItems(debitMemoItems));
        }

        allOutstandingItems = sortItemsByDate(allOutstandingItems);

        return allOutstandingItems;
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
        HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('GET','/v1/invoices/' + invoice.id +'/items',null,false);
        QueryResultInvoiceItems itemsQuery =
            (QueryResultInvoiceItems)JSON.deserialize(response.getBody(), QueryResultInvoiceItems.class);
        ZuoraAPI.InvoiceWithItems invoiceRecord = new ZuoraAPI.InvoiceWithItems();
        invoiceRecord.invoice = invoice;
        invoiceRecord.items = itemsQuery.InvoiceItems;
        return invoiceRecord;
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
        HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('GET','/v1/debitmemos/',null,false);
        String responseBody = response.getBody();
        responseBody = ZuoraAPIHelper.cleanJSON(responseBody);
        QueryResultDebitMemo result =
            (QueryResultDebitMemo)JSON.deserialize(responseBody, QueryResultDebitMemo.class);
        List<ZuoraAPI.ZuoraDebitMemo> debitMemosWithBalance = new List<ZuoraAPI.ZuoraDebitMemo>();

        for (ZuoraAPI.ZuoraDebitMemo debitMemo : result.Debitmemos){
            if (debitMemo.Balance > 0 && debitMemo.AccountId == zAcctId){
                debitMemosWithBalance.add(debitMemo);
            }
        }
        return debitMemosWithBalance;
    }

    public static ZuoraAPI.DebitMemoWithItems getDebitMemoItems(ZuoraAPI.ZuoraDebitMemo debitMemo) {
        HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('GET','/v1/debitmemos/' + debitMemo.Id +'/items',null,false);
        String responseBody = ZuoraAPIHelper.cleanJSON(response.getBody());
        QueryResultDebitMemoItem itemsQuery =
            (QueryResultDebitMemoItem)JSON.deserialize(responseBody, QueryResultDebitMemoItem.class);
        ZuoraAPI.DebitMemoWithItems debitMemoRecord = new ZuoraAPI.DebitMemoWithItems();
        debitMemoRecord.DebitMemo = debitMemo;
        debitMemoRecord.Items = itemsQuery.Items;
        return debitMemoRecord;
    }

    public static List<OutstandingItem> convertDebitMemoItems(ZuoraAPI.DebitMemoWithItems debitMemoWithBalance){
        List<OutstandingItem> itemsWithBalance = new List<OutstandingItem>();
        for (ZuoraAPI.ZuoraDebitMemoItem debitItem : debitMemoWithBalance.Items){
            if (debitItem.Balance > 0){
                OutstandingItem newItem = new OutstandingItem();
                newItem.AmountOutstanding = debitItem.Balance;
                newItem.EffectiveDate = debitMemoWithBalance.DebitMemo.DebitMemoDate;
                newItem.Project = debitMemoWithBalance.DebitMemo.Project_Zcustom;
                newItem.Client = debitMemoWithBalance.DebitMemo.ClientOwner_Zcustom;
                newItem.Id = debitItem.Id;
                newItem.ParentId = debitMemoWithBalance.DebitMemo.Id;
                newItem.IsInvoiceItem = false;
                itemsWithBalance.add(newItem);
            }
        }
        return itemsWithBalance;
    }

    public static List<OutstandingItem> sortItemsByDate(List<OutstandingItem> allOutstandingItems){
        List<OutstandingItemWrapper> itemWrappers = new List<OutstandingItemWrapper>();
        List<OutstandingItem> sortedItems = new List<OutstandingItem>();
        for (OutstandingItem item : allOutstandingItems){
            itemWrappers.add(new OutstandingItemWrapper(item));
        }
        itemWrappers.sort();
        for (Integer wrapperIndex = 0; wrapperIndex < itemWrappers.size(); wrapperIndex++) {
            sortedItems.add(itemWrappers[wrapperIndex].item);
        }
        return sortedItems;
    }

    public class OutstandingItemWrapper implements Comparable {
        public OutstandingItem item;

        public OutstandingItemWrapper(OutstandingItem item) {
            this.item = item;
        }

        public Integer compareTo(Object compareTo) {
            OutstandingItemWrapper compareToItem = (OutstandingItemWrapper) compareTo;
            Integer returnValue = 0;
            if (item.EffectiveDate > compareToItem.item.EffectiveDate) {
                // Set return value to a positive value.
                returnValue = 1;
            } else if (item.EffectiveDate < compareToItem.item.EffectiveDate) {
                // Set return value to a negative value.
                returnValue = -1;
            }
            return returnValue;
        }
    }
}