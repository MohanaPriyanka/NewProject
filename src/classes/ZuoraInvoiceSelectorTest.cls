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
            Zuora__Zuora_Id__c = '12345'
        );
        insert zInvoice;

        zInvoices = ZuoraInvoiceSelector.getInvoicesToDownload();
        System.assertEquals(1, zInvoices.size());

        zInvoice.Downloaded_Date__c = System.today();
        update zInvoice;

        zInvoices = ZuoraInvoiceSelector.getInvoicesToDownload();
        System.assertEquals(0, zInvoices.size());
    }
}