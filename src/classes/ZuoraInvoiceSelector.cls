/*************************************************************************************
 * Created By: peteryao on 2019-06-12  
 * Description: 
 * Test: ZuoraInvoiceSelectorTest
 *************************************************************************************/
@SuppressWarnings('PMD.ApexCRUDViolation')
public with sharing class ZuoraInvoiceSelector {
    public static List<Zuora__ZInvoice__c> getInvoicesToDownload() {
        return [
            SELECT Id, Zuora__Zuora_Id__c,
                Zuora__BillingAccount__r.Zuora__Account__r.Bill_Delivery_Preference__c
            FROM Zuora__ZInvoice__c
            WHERE Downloaded_Date__c = NULL
        ];
    }

    public static List<Zuora__ZInvoice__c> getInvoicesToMail() {
        return [
            SELECT Id, Zuora__Zuora_Id__c,
                Zuora__BillingAccount__r.Zuora__Account__r.Name,
                Zuora__BillingAccount__r.Zuora__Account__r.BillingStreet,
                Zuora__BillingAccount__r.Zuora__Account__r.BillingCity,
                Zuora__BillingAccount__r.Zuora__Account__r.BillingState,
                Zuora__BillingAccount__r.Zuora__Account__r.BillingPostalCode,
                LetterStream_Insert__r.Letterstream_ID__c,
                Content_Document_Id__c
            FROM Zuora__ZInvoice__c
            WHERE Ready_for_Paper_Bill_Queue__c = TRUE
            AND Added_to_Paper_Bill_Queue__c = FALSE
            ORDER BY Id
        ];
    }

    public static List<Zuora__ZInvoice__c> getInvoicesByDate(Date invoiceDate) {
        return [
            SELECT Id, Zuora__ZuoraId__c, Zuora__Zuora_Id__c
            FROM Zuora__ZInvoice__c
            WHERE Zuora__InvoiceDate__c = : invoiceDate
        ];
    }

    public static List<Zuora__ZInvoice__c> getInvoicesForEmail() {
        return [
            SELECT Id, Name, Zuora__ZuoraId__c,
                Bill_Document_Content_Version_ID__c,
                Zuora__BillingAccount__r.Zuora__Account__r.Name,
                Zuora__BillingAccount__r.Zuora__Account__r.Id,
                Zuora__BillingAccount__r.Zuora__Account__r.Client_Brand_Key__c,
                Zuora__BillingAccount__r.Zuora__Account__r.Bill_Delivery_Preference__c,
                Zuora__BillingAccount__r.Zuora__Account__r.Send_Bills_Contact__r.Email,
                Zuora__BillingAccount__r.Zuora__Account__r.Additional_Contact__r.Email,
                LetterStream_Insert__r.Content_Version_ID__c
            FROM Zuora__ZInvoice__c
            WHERE Ready_For_Email_Send__c = true
        ];
    }

    public static String getOutstandingBalanceByAccountQuery(List<Zuora__CustomerAccount__c> billAccounts) {
        String queryString = 'SELECT Id as AccountId, ' +
            '(SELECT SUM(m.balance) ' +
                'FROM DebitMemo m ' +
                'WHERE m.accountid = acct.Id AND m.balance > 0) as MemoBalance, '+
            '(SELECT MIN(m.duedate) '+
                'FROM DebitMemo m ' +
                'WHERE m.accountid = acct.Id AND m.balance > 1) as MemoDueDate, ' +
            '(SELECT SUM(iv.balance) ' +
                'FROM Invoice iv ' +
                'WHERE iv.accountid = acct.Id AND iv.balance > 0) as InvoiceBalance, ' +
            '(SELECT MIN(iv.duedate) '+
                'FROM Invoice iv ' +
                'WHERE iv.accountid = acct.Id AND iv.balance > 1) as InvoiceDueDate ' +
            'FROM Account acct ';

        if (billAccounts != null){
            for (Integer i = 0;i < billAccounts.size(); i++){
                if (i == 0){
                    queryString += 'WHERE (Id = \'' + billAccounts[i].Zuora__Zuora_Id__c + '\'';
                } else {
                    queryString += 'OR Id = \'' + billAccounts[i].Zuora__Zuora_Id__c + '\'';
                }
            }
            queryString += ') ';
        }
        return queryString;
    }

    public static List<AggregateResult> getInvoiceSummary(Date minInvoiceDate) {
        List<AggregateResult> invoiceSummary = [
            SELECT COUNT(Id) numberOfRecords,
                Ready_for_Email_Send__c, Ready_For_Paper_Bill_Queue__c, Email_Sent__c CompletedBills, Added_To_Paper_Bill_Queue__c
            FROM Zuora__ZInvoice__c
            WHERE Zuora__InvoiceDate__c > : minInvoiceDate
            GROUP BY Ready_for_Email_Send__c, Ready_For_Paper_Bill_Queue__c, Email_Sent__c, Added_To_Paper_Bill_Queue__c
        ];
        return invoiceSummary;
    }

    public static String getInvoiceTotalQuery(Date startDate, Date endDate) {
        String queryString =
            'SELECT Id as AccountId, ' +

                '(SELECT SUM(dm.totalamount) ' +
                'FROM DebitMemo dm ' +
                'WHERE dm.accountid = acct.Id ' +
                'AND dm.memodate >= DATE \'' + String.valueOf(startDate) + '\' ' +
                'AND dm.memodate < DATE \'' + String.valueOf(endDate) + '\') as DebitMemoSum, ' +

                '(SELECT SUM(cm.totalamount) ' +
                'FROM CreditMemo cm ' +
                'WHERE cm.accountid = acct.Id ' +
                'AND cm.memodate >= DATE \'' + String.valueOf(startDate) + '\' ' +
                'AND cm.memodate < DATE \'' + String.valueOf(endDate) + '\') as CreditMemoSum, ' +

                '(SELECT SUM(py.Amount) ' +
                'FROM Payment py ' +
                'WHERE py.accountid = acct.Id ' +
                'AND py.EffectiveDate >= DATE \'' + String.valueOf(startDate) + '\' ' +
                'AND py.EffectiveDate < DATE \'' + String.valueOf(endDate) + '\') as PaymentSum, ' +

                '(SELECT MIN(iv.id) ' +
                'FROM Invoice iv ' +
                'WHERE iv.accountid = acct.Id ' +
                'AND iv.InvoiceDate > DATE \'' + String.valueOf(endDate) + '\') as LastInvoice ' +

            'FROM Account acct';
        return queryString;
    }

    public List<Zuora__ZInvoice__c> getAll(Set<Id> invoiceIds) {
        return [
            SELECT Id, Zuora__Account__c
            FROM Zuora__ZInvoice__c
            WHERE Id = :invoiceIds
        ];
    }

    public static String getLatestDueDateForAutopayAccounts() {
        Date today = System.today();
        String lastMonth = today.year() + '-' + (today.month() - 3) + '-' + today.day();
        return 'SELECT MAX(inv.DueDate) DueDate ' +
        'FROM Invoice inv ' +
        'INNER JOIN Account a ON inv.accountid = a.Id ' +
        'WHERE inv.Status = \'Posted\' ' +
        'AND a.autopay = TRUE ' +
        'AND inv.DueDate > DATE \''+ lastMonth + '\'';
    }
}