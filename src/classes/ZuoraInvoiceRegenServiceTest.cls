@isTest
public class ZuoraInvoiceRegenServiceTest {
    @testSetup public static void testDataSetup() {
        Zuora__ZInvoice__c invoiceOne = new Zuora__ZInvoice__c(
            Zuora__ZuoraId__c = 'zzz123_00001',
            Zuora__InvoiceDate__c = Date.newInstance(2019,05,20)
        );
        Zuora__ZInvoice__c invoiceTwo = new Zuora__ZInvoice__c(
            Zuora__ZuoraId__c = 'zzz123_00002',
            Zuora__InvoiceDate__c = Date.newInstance(2019,05,20)
        );
        Zuora__ZInvoice__c invoiceThree = new Zuora__ZInvoice__c(
            Zuora__ZuoraId__c = 'zzz123_00003',
            Zuora__InvoiceDate__c = Date.newInstance(2019,05,20)
        );
        Zuora__ZInvoice__c invoiceFour = new Zuora__ZInvoice__c(
            Zuora__ZuoraId__c = 'zzz123_00004',
            Zuora__InvoiceDate__c = Date.newInstance(2019,05,20)
        );
        Zuora__ZInvoice__c invoiceFromPastPeriod = new Zuora__ZInvoice__c(
            Zuora__ZuoraId__c = 'zzz123_00005',
            Zuora__InvoiceDate__c = Date.newInstance(2019,04,20)
        );
        insert new List<Zuora__ZInvoice__c>{invoiceOne, invoiceTwo, invoiceThree, invoiceFour, invoiceFromPastPeriod};
    }

    @IsTest
    public static void testInvoiceRegenLogic() {
        List<Zuora__ZInvoice__c> zInvoices = ZuoraInvoiceSelector.getInvoicesByDate(Date.newInstance(2019,05,20));
        System.assertEquals(4, zInvoices.size());
        system.debug(zInvoices);

        List<ZuoraAPI.Invoice> zuoraInvoices = ZuoraInvoiceRegenerationService.convertSFToZuoraInvoice(zInvoices);
        System.assertEquals(4,zuoraInvoices.size());
        ZuoraAPI.Invoice invOne;
        invOne = (ZuoraAPI.Invoice)zuoraInvoices[0];
        System.assert(invOne.RegenerateInvoicePDF);
    }

    @IsTest
    public static void testInvoiceRegenerationBatch() {
        List<Error_Log__c> beforeLogs = [
            SELECT Id, Message__c
            FROM Error_Log__c
            WHERE Class__c = 'ZuoraAPIHelper'
        ];
        System.assertEquals(0,beforeLogs.size());

        List<Zuora__ZInvoice__c> zInvoices = ZuoraInvoiceSelector.getInvoicesByDate(Date.newInstance(2019,05,20));
        System.assertEquals(4, zInvoices.size());

        Test.startTest();
        ZuoraInvoiceRegenerationService regen = new ZuoraInvoiceRegenerationService();
        regen.invoicesToUpdate = zInvoices;
        regen.executeBatch();
        Test.stopTest();

        List<Error_Log__c> afterLogs = [
            SELECT Id, Message__c
            FROM Error_Log__c
            WHERE Class__c = 'ZuoraAPIHelper'
        ];
        System.assertEquals(1,afterLogs.size());
    }

    @IsTest
    public static void testBillRun() {
        Date invoiceDate = Date.newInstance(2019,05,20);
        String responseString = ZuoraController.executeBillRun(invoiceDate);
        System.assert(responseString.contains('Success\":true'));
    }
}