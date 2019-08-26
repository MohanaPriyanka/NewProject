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
                'm.Id as ExternalId ' +
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
        Zuora_Setting__mdt zuoraSetting = ZuoraAPIHelper.getZuoraSetting();

        String payPartDebitMemoQuery = 'SELECT m.Project__c as Project, ';
        if (zuoraSetting.Zuora_Is_Live__c) {
            // Going forward, we will report on payments when they are applied:
            payPartDebitMemoQuery += 'p.createddate as GLDate, ';
        } else {
            // Historical Migration, we reported on transactions when they were made.
            payPartDebitMemoQuery += 'py.effectiveDate as GLDate, ';
        }
        payPartDebitMemoQuery +=
            'm.ClientOwner__c as Client, '+
            'a.accountnumber as CustomerAccount, ' +
            'p.amount as Amount, ' +
            'm.accountid as AccountId, ' +
            'p.Id as ExternalId ' +
            'FROM PaymentPartItem p ' +
            'INNER JOIN PaymentPart pt ON p.paymentpartid = pt.Id ' +
            'INNER JOIN Payment py ON pt.paymentid = py.Id ' +
            'INNER JOIN DebitMemoItem d ON p.debitmemoitemid = d.Id ' +
            'INNER JOIN DebitMemo m ON d.debitMemoId = m.Id ' +
            'INNER JOIN Account a ON m.accountid = a.Id';

        if (startDate != null && endDate != null){
            Datetime startTime = DateTime.newInstance(startDate.year(),startDate.month(),startDate.day());
            Datetime endTime = DateTime.newInstance(endDate.year(),endDate.month(),endDate.day());
            payPartDebitMemoQuery += ' WHERE m.memodate > TIMESTAMP \'' + String.valueOf(startTime)+ '\'';
            payPartDebitMemoQuery += ' AND m.memodate < TIMESTAMP \'' + String.valueOf(endTime)+ '\'';
        }
        return payPartDebitMemoQuery;
    }

    public static String getPaymentPartsIV(Date startDate, Date endDate){
        Zuora_Setting__mdt zuoraSetting = ZuoraAPIHelper.getZuoraSetting();

        String payPartInvoiceQuery = 'SELECT rp.Project__c as Project, ';
        if (zuoraSetting.Zuora_Is_Live__c) {
            // Going forward, we will report on payments when they are applied:
            payPartInvoiceQuery += 'p.createddate as GLDate, ';
        } else {
            // Historical Migration, we reported on transactions when they were made.
            payPartInvoiceQuery += 'py.effectiveDate as GLDate, ';
        }

        payPartInvoiceQuery +=
            'rp.ClientOwner__c as Client, ' +
            'a.accountnumber as CustomerAccount, ' +
            'p.amount as Amount, ' +
            'iv.accountid as AccountId, ' +
            'p.Id as ExternalId ' +
            'FROM PaymentPartItem p ' +
            'INNER JOIN PaymentPart pt ON p.paymentpartid = pt.Id ' +
            'INNER JOIN Payment py ON pt.paymentid = py.Id ' +
            'INNER JOIN InvoiceItem it ON p.invoiceitemid = it.Id ' +
            'INNER JOIN RatePlanCharge rp ON it.rateplanchargeid = rp.Id ' +
            'INNER JOIN Invoice iv ON it.invoiceid = iv.Id '+
            'INNER JOIN Account a ON iv.accountid = a.Id';

        if (startDate != null && endDate != null){
            Datetime startTime = DateTime.newInstance(startDate.year(),startDate.month(),startDate.day());
            Datetime endTime = DateTime.newInstance(endDate.year(),endDate.month(),endDate.day());
            payPartInvoiceQuery += ' WHERE iv.invoicedate > TIMESTAMP \'' + String.valueOf(startTime)+ '\'';
            payPartInvoiceQuery += ' AND iv.invoicedate < TIMESTAMP \'' + String.valueOf(endTime)+ '\'';
        }
        return payPartInvoiceQuery;
    }
}