@isTest
public class ZuoraInvoiceRegenServiceTest {
    @testSetup public static void testDataSetup() {
        Zuora__ZInvoice__c invoiceOne = new Zuora__ZInvoice__c(
            Zuora__ZuoraId__c = '00001',
            Zuora__InvoiceDate__c = Date.newInstance(2019,05,20)
        );
        Zuora__ZInvoice__c invoiceTwo = new Zuora__ZInvoice__c(
            Zuora__ZuoraId__c = '00002',
            Zuora__InvoiceDate__c = Date.newInstance(2019,05,20)
        );
        Zuora__ZInvoice__c invoiceThree = new Zuora__ZInvoice__c(
            Zuora__ZuoraId__c = '00003',
            Zuora__InvoiceDate__c = Date.newInstance(2019,05,20)
        );
        Zuora__ZInvoice__c invoiceFour = new Zuora__ZInvoice__c(
            Zuora__ZuoraId__c = '00004',
            Zuora__InvoiceDate__c = Date.newInstance(2019,05,20)
        );
        Zuora__ZInvoice__c invoiceFromPastPeriod = new Zuora__ZInvoice__c(
            Zuora__ZuoraId__c = '00005',
            Zuora__InvoiceDate__c = Date.newInstance(2019,04,20)
        );
        insert new List<Zuora__ZInvoice__c>{invoiceOne, invoiceTwo, invoiceThree, invoiceFour, invoiceFromPastPeriod};
    }

    @IsTest
    public static void testInvoiceRegenLogic() {
        List<Zuora__ZInvoice__c> zInvoices = ZuoraInvoiceSelector.getInvoicesByDate(Date.newInstance(2019,05,20));
        System.assertEquals(4, zInvoices.size());
        system.debug(zInvoices);

        ZuoraAPI.ActionItems item = ZuoraInvoiceRegenerationService.convertSFToZuoraInvoice(zInvoices);
        System.assertEquals('Invoice',item.type);
        System.assertEquals(4,item.objects.size());
        ZuoraAPI.Invoice invOne = (ZuoraAPI.Invoice)item.objects[0];
        System.assert(invOne.RegenerateInvoicePDF);
    }

    @IsTest
    public static void testInvoiceRegenerationBatch() {
        List<Zuora__ZInvoice__c> zInvoices = ZuoraInvoiceSelector.getInvoicesByDate(Date.newInstance(2019,05,20));
        System.assertEquals(4, zInvoices.size());

        ZuoraInvoiceRegenerationService.regenerateInvoicePDFs(zInvoices);
    }

    @IsTest
    public static void testBillRun() {
        Date invoiceDate = Date.newInstance(2019,05,20);
        String responseString = ZuoraController.executeBillRun(invoiceDate);

        System.assertEquals('Success',responseString);
    }
}