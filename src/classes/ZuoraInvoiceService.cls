/*************************************************************************************
 * Created By: peteryao on 2019-06-12  
 * Description: Downloads invoice pdfs as Content attached to Zuora Invoice records which
 *    are previously synced by Z360
 * Test: ZuoraInvoiceServiceTest
 *************************************************************************************/

public with sharing class ZuoraInvoiceService {
    public List<Zuora__ZInvoice__c> sfdcZuoraInvoices;

    public ZuoraInvoiceService(List<Zuora__ZInvoice__c> sfdcZuoraInvoices) {
        this.sfdcZuoraInvoices = sfdcZuoraInvoices;
    }

    public void downloadPDFs() {
        if (sfdcZuoraInvoices.size() > Limits.getLimitCallouts()) {
            throw new Util.BWException('Call downloadPDFs with fewer than ' + Limits.getLimitCallouts() + ' invoices');
        }
        Map<String, Id> zuoraInvoiceIdToSFDCId = new Map<String, Id>();
        List<ZuoraAPI.Invoice> zuoraInvoices =
            queryZuoraForInvoicePDF(sfdcZuoraInvoices, zuoraInvoiceIdToSFDCId);

        Map<String, ContentVersion> zuoraInvoiceIdToConventVersion =
            insertContentVersions(zuoraInvoices);

        List<ContentDocumentLink> contentDocumentLinks =
            insertContentDocumentLinks(zuoraInvoices, zuoraInvoiceIdToConventVersion, zuoraInvoiceIdToSFDCId);

        updateZuoraInvoicesAsDownloaded(contentDocumentLinks);
        Logger.flushLogs();

        if (!sfdcZuoraInvoices.isEmpty()) {
            Logger.logNow('ZuoraInvoiceService', 'downloadPDFs', 'Queuing ' + sfdcZuoraInvoices.size() + ' invoices to download', Logger.DEBUG);
            if (!Test.isRunningTest()) {
                ZuoraInvoiceAsyncService asyncService = new ZuoraInvoiceAsyncService(sfdcZuoraInvoices);
                System.enqueueJob(asyncService);
            }
        }
    }

    @TestVisible
    private List<ZuoraAPI.Invoice> queryZuoraForInvoicePDF(List<Zuora__ZInvoice__c> sfdcZuoraInvoices, Map<String, Id> zuoraInvoiceIdToSFDCId) {
        List<ZuoraAPI.Invoice> zuoraInvoices = new List<ZuoraAPI.Invoice>();
        while (!sfdcZuoraInvoices.isEmpty()) {
            zuoraInvoiceIdToSFDCId.put(sfdcZuoraInvoices[0].Zuora__ZuoraId__c, sfdcZuoraInvoices[0].Id);
            // A 90k invoice takes ~300k of heap since it's base 64 encoded and we're saving to the log, so a 2MB invoice
            // would take 6MB?
            HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('GET', '/v1/object/invoice/' + sfdcZuoraInvoices[0].Zuora__ZuoraId__c, null, false);
            zuoraInvoices.add((ZuoraAPI.Invoice) System.JSON.deserialize(response.getBody(), ZuoraAPI.Invoice.class));
            response = null;
            // Anything that is left needs to be queued for download
            sfdcZuoraInvoices.remove(0);
            // Stop trying to get data when using half the heap, since we'll ne<<ed more heap to store the ConventVersion
            if (Limits.getHeapSize() > Limits.getLimitHeapSize() * .5 || Test.isRunningTest()) {
                break;
            }
        }
        return zuoraInvoices;
    }

    @TestVisible
    private void updateZuoraInvoicesAsDownloaded(List<ContentDocumentLink> contentDocumentLinks) {
        List<Zuora__ZInvoice__c> zuoraInvoicesToUpdate = new List<Zuora__ZInvoice__c>();
        for (ContentDocumentLink contentDocumentLink : contentDocumentLinks) {
            Zuora__ZInvoice__c zuoraInvoiceToUpdate = new Zuora__ZInvoice__c(
                Id = contentDocumentLink.LinkedEntityId,
                Downloaded_Date__c = System.today(),
                Content_Document_Id__c = contentDocumentLink.Id
            );
            zuoraInvoicesToUpdate.add(zuoraInvoiceToUpdate);
        }
        update zuoraInvoicesToUpdate;
    }

    @TestVisible
    private Map<String, ContentVersion> insertContentVersions(List<ZuoraAPI.Invoice> zuoraInvoices) {
        Map<String, ContentVersion> zuoraInvoiceIdToConventVersion = new Map<String, ContentVersion>();
        for (ZuoraAPI.Invoice zuoraInvoice : zuoraInvoices) {
            ContentVersion cv = new ContentVersion(
                ContentLocation = 'S',
                VersionData = EncodingUtil.base64Decode(zuoraInvoice.Body),
                Title = zuoraInvoice.InvoiceNumber + '.pdf',
                PathOnClient = zuoraInvoice.InvoiceNumber + '.pdf'
            );
            zuoraInvoiceIdToConventVersion.put(zuoraInvoice.Id, cv);
        }
        insert zuoraInvoiceIdToConventVersion.values();
        // We could return the map here, and it would have ContentVersion Ids, but it doesn't have the ContentDocumentId
        // that was created, so we have to query for that and put the updated version back in the map
        Map<Id, ContentVersion> contentVersionWithContentDocumentIdMap = new Map<Id, ContentVersion>([
            SELECT Id, ContentDocumentId, Title
            FROM ContentVersion
            WHERE Id IN :zuoraInvoiceIdToConventVersion.values()
        ]);
        for (String zuoraInvoiceId : zuoraInvoiceIdToConventVersion.keySet()) {
            ContentVersion contentVersionWithoutContentDocumentId = zuoraInvoiceIdToConventVersion.get(zuoraInvoiceId);
            ContentVersion contentVersionWithContentDocumentId = contentVersionWithContentDocumentIdMap.get(contentVersionWithoutContentDocumentId.Id);
            zuoraInvoiceIdToConventVersion.put(zuoraInvoiceId, contentVersionWithContentDocumentId);
        }
        return zuoraInvoiceIdToConventVersion;
    }

    private List<ContentDocumentLink> insertContentDocumentLinks(List<ZuoraAPI.Invoice> zuoraInvoices, Map<String, ContentVersion> zuoraInvoiceIdToConventVersion, Map<String, Id> zuoraInvoiceIdToSFDCId) {
        List<ContentDocumentLink> contentDocumentLinks = new List<ContentDocumentLink>();
        for (ZuoraAPI.Invoice zuoraInvoice : zuoraInvoices) {
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = zuoraInvoiceIdToConventVersion.get(zuoraInvoice.Id).ContentDocumentId;
            cdl.LinkedEntityId = zuoraInvoiceIdToSFDCId.get(zuoraInvoice.Id);
            cdl.ShareType = 'I';
            contentDocumentLinks.add(cdl);
        }
        insert contentDocumentLinks;
        return contentDocumentLinks;
    }
}