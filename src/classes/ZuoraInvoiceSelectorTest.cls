/*************************************************************************************
 * Created By: peteryao on 2019-06-12  
 * Description: 
 * Test: 
 *************************************************************************************/
@IsTest
public with sharing class ZuoraInvoiceSelectorTest {
    @IsTest
    public static void testSelectForDownload() {
        List<Zuora__ZInvoice__c> zInvoices = ZuoraInvoiceSelector.getInvoicesToDownload();
        System.assertEquals(0, zInvoices.size());

        Zuora__ZInvoice__c zInvoice = new Zuora__ZInvoice__c(
            Zuora__ZuoraId__c = '12345'
        );
        insert zInvoice;

        zInvoices = ZuoraInvoiceSelector.getInvoicesToDownload();
        System.assertEquals(1, zInvoices.size());

        zInvoice.Downloaded_Date__c = System.today();
        update zInvoice;

        zInvoices = ZuoraInvoiceSelector.getInvoicesToDownload();
        System.assertEquals(0, zInvoices.size());
    }

    @IsTest
    public static void testSelectForDate() {
        List<Zuora__ZInvoice__c> zInvoices = ZuoraInvoiceSelector.getInvoicesToDownload();
        System.assertEquals(0, zInvoices.size());

        Zuora__ZInvoice__c zInvoice = new Zuora__ZInvoice__c(
            Zuora__ZuoraId__c = '12345',
            Zuora__InvoiceDate__c = Date.newInstance(2019,05,20)
        );
        insert zInvoice;

        zInvoices = ZuoraInvoiceSelector.getInvoicesByDate(Date.newInstance(2019,05,20));
        System.assertEquals(1, zInvoices.size());

        zInvoice.Zuora__InvoiceDate__c = Date.newInstance(2019,01,01);
        update zInvoice;

        zInvoices = ZuoraInvoiceSelector.getInvoicesByDate(Date.newInstance(2019,05,20));
        System.assertEquals(0, zInvoices.size());
    }
}