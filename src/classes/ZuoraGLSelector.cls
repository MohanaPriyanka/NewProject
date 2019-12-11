/*************************************************************************************
Created By Jordan Pentaleri 08/2019
Tested By: ZuoraGLServiceTest
*************************************************************************************/

public with sharing class ZuoraGLSelector {
    public static String getInvoiceItems(Date startDate, Date endDate){
        String invoiceItemQuery =
            'SELECT rp.Project__c as Project, ' +
                'rp.ClientOwner__c as Client, ' +
                'iv.invoicedate as GLDate, ' +
                'a.accountnumber as CustomerAccount, ' +
                'it.chargeamount as Amount, ' +
                'iv.accountid as AccountId, ' +
                'it.id as ExternalId ' +
            'FROM InvoiceItem it ' +
            'INNER JOIN RatePlanCharge rp ON it.rateplanchargeid = rp.Id ' +
            'INNER JOIN Invoice iv ON it.invoiceid = iv.Id ' +
            'INNER JOIN Account a ON iv.accountid = a.Id ' +
            'WHERE it.chargeamount > 0';

        if (startDate != null && endDate != null){
            Datetime startTime = DateTime.newInstance(startDate.year(),startDate.month(),startDate.day());
            Datetime endTime = DateTime.newInstance(endDate.year(),endDate.month(),endDate.day());
            invoiceItemQuery += ' AND iv.invoicedate > TIMESTAMP \'' + String.valueOf(startTime)+ '\'';
            invoiceItemQuery += ' AND iv.invoicedate < TIMESTAMP \'' + String.valueOf(endTime)+ '\'';
        }
        return invoiceItemQuery;
    }

    public static String getCreditMemos(Date startDate, Date endDate){
        String creditMemoQuery =
            'SELECT m.Project__c as Project, ' +
                'm.ClientOwner__c as Client, ' +
                'm.memodate as GLDate, ' +
                'a.accountnumber as CustomerAccount, ' +
                'm.reasonCode as ReasonCode, ' +
                'm.totalamount as Amount, ' +
                'm.accountid as AccountId, ' +
                'm.Id as ExternalId ' +
            'FROM CreditMemo m ' +
            'INNER JOIN Account a ON m.accountid = a.Id';

        if (startDate != null && endDate != null){
            Datetime startTime = DateTime.newInstance(startDate.year(),startDate.month(),startDate.day());
            Datetime endTime = DateTime.newInstance(endDate.year(),endDate.month(),endDate.day());
            creditMemoQuery += ' WHERE m.memodate > TIMESTAMP \'' + String.valueOf(startTime)+ '\'';
            creditMemoQuery += ' AND m.memodate < TIMESTAMP \'' + String.valueOf(endTime)+ '\'';
        }
        return creditMemoQuery;
    }

    public static String getDebitMemos(Date startDate, Date endDate){
        String debitMemoQuery =
            'SELECT m.Project__c as Project, ' +
                'm.ClientOwner__c  as Client, ' +
                'm.memodate as GLDate, ' +
                'a.accountnumber as CustomerAccount, ' +
                'm.reasonCode as ReasonCode, ' +
                'm.totalamount as Amount, ' +
                'm.accountid as AccountId, ' +
                'm.Id as ExternalId, ' +
                'm.Gateway__c as Gateway, ' +
                'm.Lockbox__c as Lockbox, ' +
                'm.PaymentMethod__c as PaymentMethod, ' +
                'm.ArchivedChargentData__c as ArchivedChargentData ' +
                'FROM DebitMemo m ' +
                'INNER JOIN Account a ON m.accountid = a.Id';

        if (startDate != null && endDate != null){
            Datetime startTime = DateTime.newInstance(startDate.year(),startDate.month(),startDate.day());
            Datetime endTime = DateTime.newInstance(endDate.year(),endDate.month(),endDate.day());
            debitMemoQuery += ' WHERE m.memodate > TIMESTAMP \'' + String.valueOf(startTime)+ '\'';
            debitMemoQuery += ' AND m.memodate < TIMESTAMP \'' + String.valueOf(endTime)+ '\'';
        }
        return debitMemoQuery;
    }

    public static String getPaymentPartsDM(Date startDate, Date endDate){
        String payPartDebitMemoQuery = 'SELECT m.Project__c as Project, ' +
            'm.ClientOwner__c as Client, '+
            'a.accountnumber as CustomerAccount, ' +
            'p.amount as Amount, ' +
            'm.accountid as AccountId, ' +
            'p.createddate as GLDatetime, ' +
            'py.effectiveDate as GLDate, ' +
            'py.TransactionID__c as CRMId, ' +
            'py.Gateway as Gateway, ' +
            'py.Lockbox__c as Lockbox, ' +
            'pm.type as PaymentMethod, ' +
            'py.ArchivedChargentData__c as ArchivedChargentData, ' +
            'p.Id as ExternalId ' +
            'FROM PaymentPartItem p ' +
            'INNER JOIN PaymentPart pt ON p.paymentpartid = pt.Id ' +
            'INNER JOIN Payment py ON pt.paymentid = py.Id ' +
            'INNER JOIN PaymentMethod pm ON py.paymentmethodId = pm.Id ' +
            'INNER JOIN DebitMemoItem d ON p.debitmemoitemid = d.Id ' +
            'INNER JOIN DebitMemo m ON d.debitMemoId = m.Id ' +
            'INNER JOIN Account a ON m.accountid = a.Id';

        if (startDate != null && endDate != null){
            Datetime startTime = DateTime.newInstance(startDate.year(),startDate.month(),startDate.day());
            Datetime endTime = DateTime.newInstance(endDate.year(),endDate.month(),endDate.day());
            payPartDebitMemoQuery += ' WHERE py.effectiveDate > TIMESTAMP \'' + String.valueOf(startTime)+ '\'';
            payPartDebitMemoQuery += ' AND py.effectiveDate < TIMESTAMP \'' + String.valueOf(endTime)+ '\'';
            payPartDebitMemoQuery += ' AND py.Status = \'Processed\' ';
        } else {
            payPartDebitMemoQuery += ' WHERE py.Status = \'Processed\' ';
        }
        return payPartDebitMemoQuery;
    }

    public static String getPaymentPartsIV(Date startDate, Date endDate){
        String payPartInvoiceQuery = 'SELECT rp.Project__c as Project, ' +
            'rp.ClientOwner__c as Client, ' +
            'a.accountnumber as CustomerAccount, ' +
            'p.amount as Amount, ' +
            'iv.accountid as AccountId, ' +
            'p.createddate as GLDatetime, ' +
            'py.effectiveDate as GLDate, ' +
            'py.TransactionID__c as CRMId, ' +
            'py.Gateway as Gateway, ' +
            'py.Lockbox__c as Lockbox, ' +
            'pm.type as PaymentMethod, ' +
            'py.ArchivedChargentData__c as ArchivedChargentData, ' +
            'p.Id as ExternalId ' +
            'FROM PaymentPartItem p ' +
            'INNER JOIN PaymentPart pt ON p.paymentpartid = pt.Id ' +
            'INNER JOIN Payment py ON pt.paymentid = py.Id ' +
            'INNER JOIN PaymentMethod pm ON py.paymentmethodId = pm.Id ' +
            'INNER JOIN InvoiceItem it ON p.invoiceitemid = it.Id ' +
            'INNER JOIN RatePlanCharge rp ON it.rateplanchargeid = rp.Id ' +
            'INNER JOIN Invoice iv ON it.invoiceid = iv.Id '+
            'INNER JOIN Account a ON iv.accountid = a.Id';

        if (startDate != null && endDate != null){
            Datetime startTime = DateTime.newInstance(startDate.year(),startDate.month(),startDate.day());
            Datetime endTime = DateTime.newInstance(endDate.year(),endDate.month(),endDate.day());
            payPartInvoiceQuery += ' WHERE py.effectiveDate > TIMESTAMP \'' + String.valueOf(startTime)+ '\'';
            payPartInvoiceQuery += ' AND py.effectiveDate < TIMESTAMP \'' + String.valueOf(endTime)+ '\'';
            payPartInvoiceQuery += ' AND py.Status = \'Processed\' ';
        } else {
            payPartInvoiceQuery += ' WHERE py.Status = \'Processed\' ';
        }
        return payPartInvoiceQuery;
    }

    public static List<Journal_Entry__c> getSFJournalEntries(Date startDate, Date endDate, String queryType){
        List<Journal_Entry__c> journalEntries = [
            SELECT Id, External_Id__c, Date__c, Amount__c, Project__c, Client__c, Customer_Account__c,
                Paid_To_Client__c, Deposit_Account__c
            FROM Journal_Entry__c
            WHERE Date__c > : startDate
            AND Date__c < : endDate
            AND Query_Type__c = : queryType
        ];
        return journalEntries;
    }
}