/*************************************************************************************
Created By Jordan Pentaleri 08/2019
Tested By: ZuoraGLServiceTest
*************************************************************************************/
@SuppressWarnings('PMD.ApexCRUDViolation')
public with sharing class ZuoraGLSelector {
    private static FeatureService featureService = new FeatureService();
    public static String getInvoiceItems(Date startDate, Date endDate){
        if (startDate == null || endDate == null) {
            throw new Util.BWException('startDate and endDate are required to get invoice items');
        }
        Datetime startTime = Datetime.newInstance(startDate.year(),startDate.month(),startDate.day());
        Datetime endTime = Datetime.newInstance(endDate.year(),endDate.month(),endDate.day());
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
            'WHERE iv.invoicedate > TIMESTAMP \'' + String.valueOf(startTime)+ '\' ' +
            'AND iv.invoicedate < TIMESTAMP \'' + String.valueOf(endTime)+ '\'';
        // Catch-up invoice items are invoice items that Zuora creates for service periods that haven't been billed since
        // the start of the subscription to the charge date of the current invoice. For example, if a subscription starts
        // 1/1/2020 and we don't bill until 5/20/20, Zuora will create $0 invoice items for Jan, Feb, March, and April,
        // and then the non-$0 item for May. We avoid selecting the Jan-April items to stay within Salesforce's heap limit
        if (featureService.isEnabled('Exclude_Zuora_Catch_Up_Invoice_Items')) {
            invoiceItemQuery +=  ' AND (it.chargedate < DATE_ADD(\'MONTH\', 1, it.serviceenddate) OR it.chargeamount > 0)';
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
            'p.debitmemoitemid as AppliedRecordId, ' +
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
            payPartDebitMemoQuery += ' WHERE p.createddate > TIMESTAMP \'' + String.valueOf(startTime)+ '\'';
            payPartDebitMemoQuery += ' AND p.createddate < TIMESTAMP \'' + String.valueOf(endTime)+ '\'';
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
            'p.invoiceitemid as AppliedRecordId, ' +
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
            payPartInvoiceQuery += ' WHERE p.createddate > TIMESTAMP \'' + String.valueOf(startTime)+ '\'';
            payPartInvoiceQuery += ' AND p.createddate < TIMESTAMP \'' + String.valueOf(endTime)+ '\'';
            payPartInvoiceQuery += ' AND py.Status = \'Processed\' ';
        } else {
            payPartInvoiceQuery += ' WHERE py.Status = \'Processed\' ';
        }
        return payPartInvoiceQuery;
    }
}