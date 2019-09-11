/*************************************************************************************
 * Created By: peteryao on 2019-06-12  
 * Description: 
 * Test: ZuoraInvoiceSelectorTest
 *************************************************************************************/

public with sharing class ZuoraInvoiceSelector {
    public static List<Zuora__ZInvoice__c> getInvoicesToDownload() {
        return [
            SELECT Id, Zuora__ZuoraId__c
            FROM Zuora__ZInvoice__c
            WHERE Downloaded_Date__c = NULL
        ];
    }

    public static List<Zuora__ZInvoice__c> getInvoicesByDate(Date invoiceDate) {
        return [
            SELECT Id, Zuora__ZuoraId__c
            FROM Zuora__ZInvoice__c
            WHERE Zuora__InvoiceDate__c = : invoiceDate
        ];
    }
}