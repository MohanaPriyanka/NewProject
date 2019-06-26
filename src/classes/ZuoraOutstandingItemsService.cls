/*************************************************************************************
 * Created By:  Jordan Pentaleri
 * Description: Queries Zuora for outstanding invoice items and debit memos,
 *              sorts by date and returns list of items with balance
 * Test: ZuoraCreditMemoAllocationTest
 *************************************************************************************/

public class ZuoraOutstandingItemsService{
    public class QueryResultInvoice {
        public List<ZuoraApi.Invoice> records;
    }

    public class QueryResultRatePlanCharge {
        public List<RatePlanCharge> records;
    }

    public class QueryResultInvoiceItems {
        public List<ZuoraApi.InvoiceItem> invoiceItems;
    }

    public class QueryResultDebitMemo {
        public List<ZuoraAPI.DebitMemo> debitmemos;
    }

    public class QueryResultDebitMemoItem {
        public List<ZuoraAPI.DebitMemoItem> items;
    }

    public class OutstandingItem {
        public Decimal amountOutstanding;
        public Datetime effectiveDate;
        public String project;
        public String client;
        public String id;
        public String parentId;
        public Boolean isInvoiceItem; // Only DebitMemo or InvoiceItem
        public Decimal amountToApply;
    }

    public class RatePlanCharge{
        public String id;
        public String chargeNumber;
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
            if (billItem.project == project
                && billItem.client == client
                && billItem.amountOutstanding <= amountToApply) {
                billItem.amountToApply = billItem.amountOutstanding;
                amountToApply -= billItem.amountOutstanding;
                itemsToApply.add(billItem);
            } else if (billItem.project == project
                && billItem.client == client
                && amountToApply > 0) {
                billItem.amountToApply = amountToApply;
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

        List<ZuoraAPI.DebitMemo> debitMemos = getOutstandingDebitMemos(zuoraAcctId);
        for (ZuoraAPI.DebitMemo debitMemo : debitMemos){
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
        return queriedInvoices.records;
    }

    public static ZuoraAPI.InvoiceWithItems getInvoiceItems(ZuoraAPI.Invoice invoice) {
        HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('GET','/v1/invoices/' + invoice.Id +'/items',null,false);
        QueryResultInvoiceItems itemsQuery =
            (QueryResultInvoiceItems)JSON.deserialize(response.getBody(), QueryResultInvoiceItems.class);
        ZuoraAPI.InvoiceWithItems invoiceRecord = new ZuoraAPI.InvoiceWithItems();
        invoiceRecord.invoice = invoice;
        invoiceRecord.items = itemsQuery.invoiceItems;
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
                RatePlanCharge invRatePlanCharge = queryResult.records[0];
                OutstandingItem newItem = new OutstandingItem();
                newItem.amountOutstanding = invItem.balance;
                newItem.effectiveDate = invoiceWithBalance.invoice.invoiceDate;
                newItem.project = invRatePlanCharge.Project_Zcustom;
                newItem.client = invRatePlanCharge.ClientOwner_Zcustom;
                newItem.id = invItem.id;
                newItem.parentId = invoiceWithBalance.invoice.id;
                newItem.isInvoiceItem = true;
                itemsWithBalance.add(newItem);
            }
        }
        return itemsWithBalance;
    }

    public static List<ZuoraAPI.DebitMemo> getOutstandingDebitMemos(String zAcctId) {
        HttpResponse response = ZuoraAPIHelper.callJSONEndpoint('GET','/v1/debitmemos/',null,false);
        String responseBody = response.getBody();
        responseBody = responseBody.replace('__c','_Zcustom');
        QueryResultDebitMemo result =
            (QueryResultDebitMemo)JSON.deserialize(responseBody, QueryResultDebitMemo.class);
        List<ZuoraAPI.DebitMemo> debitMemosWithBalance = new List<ZuoraAPI.DebitMemo>();

        for (ZuoraAPI.DebitMemo debitMemo : result.debitmemos){
            if (debitMemo.balance > 0 && debitMemo.accountId == zAcctId){
                debitMemosWithBalance.add(debitMemo);
            }
        }
        return debitMemosWithBalance;
    }

    public static ZuoraAPI.DebitMemoWithItems getDebitMemoItems(ZuoraAPI.DebitMemo debitMemo) {
        HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('GET','/v1/debitmemos/' + debitMemo.id +'/items',null,false);
        String responseBody = response.getBody().replace('__c','_Zcustom');
        QueryResultDebitMemoItem itemsQuery =
            (QueryResultDebitMemoItem)JSON.deserialize(responseBody, QueryResultDebitMemoItem.class);
        ZuoraAPI.DebitMemoWithItems debitMemoRecord = new ZuoraAPI.DebitMemoWithItems();
        debitMemoRecord.debitMemo = debitMemo;
        debitMemoRecord.items = itemsQuery.items;
        return debitMemoRecord;
    }

    public static List<OutstandingItem> convertDebitMemoItems(ZuoraAPI.DebitMemoWithItems debitMemoWithBalance){
        List<OutstandingItem> itemsWithBalance = new List<OutstandingItem>();
        for (ZuoraAPI.DebitMemoItem debitItem : debitMemoWithBalance.items){
            if (debitItem.balance > 0){
                OutstandingItem newItem = new OutstandingItem();
                newItem.amountOutstanding = debitItem.balance;
                newItem.effectiveDate = debitMemoWithBalance.debitMemo.debitMemoDate;
                newItem.project = debitMemoWithBalance.debitMemo.Project_Zcustom;
                newItem.client = debitMemoWithBalance.debitMemo.ClientOwner_Zcustom;
                newItem.id = debitItem.id;
                newItem.parentId = debitMemoWithBalance.debitMemo.id;
                newItem.isInvoiceItem = false;
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
            if (item.effectiveDate > compareToItem.item.effectiveDate) {
                // Set return value to a positive value.
                returnValue = 1;
            } else if (item.effectiveDate < compareToItem.item.effectiveDate) {
                // Set return value to a negative value.
                returnValue = -1;
            }
            return returnValue;
        }
    }
}