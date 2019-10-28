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
        ZuoraAPIHelperTest.testSetup();
    }

    @IsTest
    public static void testInvoiceRegenLogic() {
        List<Zuora__ZInvoice__c> zInvoices = ZuoraInvoiceSelector.getInvoicesByDate(Date.newInstance(2019,05,20));
        System.assertEquals(4, zInvoices.size());

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

    @IsTest
    public static void testQueueDataQueryForTemplateFields(){
        List<Zuora_Data_Query__c> beforeQueries = [
            SELECT Id, Query__c
            FROM Zuora_Data_Query__c
        ];

        System.assertEquals(0,beforeQueries.size());

        Test.startTest();
            ZuoraController.queueDataQueryForTemplateFields(Date.newInstance(2019,10,01),Date.newInstance(2019,10,31));
        Test.stopTest();

        List<Zuora_Data_Query__c> afterQueries = [
            SELECT Id, Data_From_Zuora__c
            FROM Zuora_Data_Query__c
        ];

        System.assertEquals(1,afterQueries.size());
        System.assert(afterQueries[0].Data_From_Zuora__c.length() > 0);
    }

    @IsTest
    public static void testUpdateCustomTemplateFields(){
        String mockQueryResult =
            '[{"AccountId":"2c92c0f96dcf2f3e016dd5a9ae807f0e",' +
            '"DebitMemoSum":null,"CreditMemoSum":null,' +
            '"PaymentSum":null,"LastInvoice":null}, ' +
            '{"AccountId":"2c92c0f96dcf2f3e016dd5a9ae3b7f0b",' +
            '"DebitMemoSum":null,"CreditMemoSum":null,' +
            '"PaymentSum":749.080000,"LastInvoice":"2c92c0fa6dd8a85d016dd9d6d1ce1e9f"}, ' +
            '{"AccountId":"2c92c0f96dcf2f3e016dd5a9ae3b7f0b",' +
            '"DebitMemoSum":null,"CreditMemoSum":100.00000,' +
            '"PaymentSum":889.080000,"LastInvoice":"2c92c0fa6dd8a85d016dd9d6d1ce1e9f"}, ' +
            '{"AccountId":"2c92c0f96dcf2f3e016dd5a9ae697f0d",' +
            '"DebitMemoSum":123.000000,"CreditMemoSum":123.000000,' +
            '"PaymentSum":null,"LastInvoice":"2c92c0fb6dd8b653016dda565da8602a"}]';

        Test.startTest();
            ZuoraAPI.ActionItems actionItem = ZuoraController.updateCustomTemplateFields(mockQueryResult);
        Test.stopTest();

        System.assertEquals('Invoice',actionItem.type);
        System.assertEquals(3,actionItem.objects.size());

        ZuoraAPI.Invoice invoiceOne = (ZuoraAPI.Invoice)actionItem.objects[0];
        ZuoraAPI.Invoice invoiceTwo = (ZuoraAPI.Invoice)actionItem.objects[1];
        ZuoraAPI.Invoice invoiceThree = (ZuoraAPI.Invoice)actionItem.objects[2];

        System.assertEquals(0,invoiceOne.CustomTemplateMerge_1_Zcustom);
        System.assertEquals(749.08,invoiceOne.CustomTemplateMerge_2_Zcustom);
        System.assertEquals(100,invoiceTwo.CustomTemplateMerge_1_Zcustom);
        System.assertEquals(889.08,invoiceTwo.CustomTemplateMerge_2_Zcustom);
        System.assertEquals(246,invoiceThree.CustomTemplateMerge_1_Zcustom);
        System.assertEquals(0,invoiceThree.CustomTemplateMerge_2_Zcustom);
    }
}