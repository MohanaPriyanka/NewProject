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
        try{
            uploadToZuora(convertSFToZuoraInvoice(invoices));
        } catch(Exception excep) {
            Logger.logLater('ZuoraInvoiceRegenerationService', 'regenerateInvoicePDFs', String.valueOf(invoices) + excep.getMessage() + '\n' + excep.getStackTraceString());
        }
    }
    public static void uploadToZuora (List<ZuoraAPI.Invoice> zuoraInvoices) {
        for (ZuoraAPI.Invoice zInvoice : zuoraInvoices) {
            HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('PUT', '/v1/object/invoice/' + zInvoice.Id, zInvoice, false);
            ZuoraAPI.SaveResult result = (ZuoraAPI.SaveResult) System.JSON.deserialize(response.getBody(), ZuoraAPI.SaveResult.class);
            if (!result.Success) {
                String customErrorMessage = 'Object: ' + String.valueOf(zInvoice) + ' Zuora Error Message: ' + String.valueOf(result.Errors);
                Logger.logLater('ZuoraController', 'regeneratePDFs', customErrorMessage, Logger.ERROR);
            }
        }
        Logger.flushLogs();
    }


    public static List<ZuoraAPI.Invoice> convertSFToZuoraInvoice (List<Zuora__ZInvoice__c> sfInvoices){
        List<ZuoraAPI.Invoice> zuoraInvoices = new List<ZuoraAPI.Invoice>();

        for (Zuora__ZInvoice__c sfInvoice : sfInvoices){
            ZuoraAPI.Invoice zuoraInvoice = new ZuoraAPI.Invoice();
            zuoraInvoice.Id = sfInvoice.Zuora__ZuoraId__c;
            zuoraInvoice.RegenerateInvoicePDF = true;
            zuoraInvoices.add(zuoraInvoice);
        }

        return zuoraInvoices;
    }

    public void finish(Database.BatchableContext bc){
        // Need to have finish method in batch job
    }
}