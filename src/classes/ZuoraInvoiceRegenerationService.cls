public class ZuoraInvoiceRegenerationService implements Database.Batchable<SObject>, Database.Stateful, Database.AllowsCallouts{
    public List<Zuora__ZInvoice__c> invoicesToUpdate;

    public void executeBatch() {
        if (invoicesToUpdate != null){
            Database.executeBatch(this, 45);
        }
    }

    public List<Zuora__ZInvoice__c> start(Database.BatchableContext bc) {
        return invoicesToUpdate;
    }

    public void execute(Database.BatchableContext bc, List<Zuora__ZInvoice__c> scope){
        regenerateInvoicePDFs(scope);
    }

    public static void regenerateInvoicePDFs(List<Zuora__ZInvoice__c> invoices){
        uploadToZuora(convertSFToZuoraInvoice(invoices));
    }
    public static void uploadToZuora (ZuoraAPI.ActionItems item) {
        HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('POST', '/v1/action/update', item, false);
        List<ZuoraAPI.SaveResult> results = (List<ZuoraAPI.SaveResult>) System.JSON.deserialize(response.getBody(), List<ZuoraAPI.SaveResult>.class);
        for (ZuoraAPI.SaveResult result : results){
            if (!result.Success){
                String customErrorMessage =
                    'Object: ' + String.valueOf(item) +
                        ' Zuora Error Message: ' + String.valueOf(result.Errors);
                Logger.logLater(
                    'ZuoraController',
                    'regeneratePDFs',
                    customErrorMessage,
                    Logger.ERROR
                );
            }
        }
        Logger.flushLogs();
    }

    public static ZuoraAPI.ActionItems convertSFToZuoraInvoice (List<Zuora__ZInvoice__c> sfInvoices){
        List<ZuoraAPI.Invoice> zuoraInvoices = new List<ZuoraAPI.Invoice>();
        for (Zuora__ZInvoice__c sfInvoice : sfInvoices){
            ZuoraAPI.Invoice zuoraInvoice = new ZuoraAPI.Invoice();
            zuoraInvoice.Id = sfInvoice.Zuora__ZuoraId__c;
            zuoraInvoice.RegenerateInvoicePDF = true;
            zuoraInvoices.add(zuoraInvoice);
        }

        ZuoraAPI.ActionItems item = new ZuoraAPI.ActionItems();
        item.type = 'Invoice';
        item.objects = zuoraInvoices;

        return item;
    }

    public void finish(Database.BatchableContext bc){
        // Need to have finish method in batch job
    }
}