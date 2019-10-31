/*************************************************************************************
 * Created By: peteryao on 2019-06-12  
 * Description: Downloads invoice pdfs as Content attached to Zuora Invoice records which
 *    are previously synced by Z360
 * Test: ZuoraInvoiceServiceTest
 *************************************************************************************/

public with sharing class ZuoraInvoiceService {
    private CaseFactory caseFactory = new CaseFactory();
    private ContentDocumentSelector contentDocumentSelector = new ContentDocumentSelector();
    public List<Zuora__ZInvoice__c> sfdcZuoraInvoices;
    public Map<Id, Zuora__ZInvoice__c> invoiceMap;
    public String communityId;

    public ZuoraInvoiceService(List<Zuora__ZInvoice__c> sfdcZuoraInvoices) {
        this.sfdcZuoraInvoices = sfdcZuoraInvoices;
        Map<Id, Zuora__ZInvoice__c> invoiceMap = new Map<Id, Zuora__ZInvoice__c>();
        if (sfdcZuoraInvoices != null){
            for (Zuora__ZInvoice__c invoice : sfdcZuoraInvoices){
                invoiceMap.put(invoice.Id, invoice);
            }
        }
        this.invoiceMap = invoiceMap;
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

        updateZuoraInvoicesAsDownloaded(contentDocumentLinks, zuoraInvoiceIdToConventVersion, invoiceMap);
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
            zuoraInvoiceIdToSFDCId.put(sfdcZuoraInvoices[0].Zuora__Zuora_Id__c, sfdcZuoraInvoices[0].Id);
            // A 90k invoice takes ~300k of heap since it's base 64 encoded and we're saving to the log, so a 2MB invoice
            // would take 6MB?
            HttpResponse response = ZuoraAPIHelper.callJsonEndpoint('GET', '/v1/object/invoice/' + sfdcZuoraInvoices[0].Zuora__Zuora_Id__c, null, false);
            zuoraInvoices.add((ZuoraAPI.Invoice) System.JSON.deserialize(response.getBody(), ZuoraAPI.Invoice.class));
            response = null;
            // Anything that is left needs to be queued for download
            sfdcZuoraInvoices.remove(0);
            // Stop trying to get data when using half the heap, since we'll need more heap to store the ConventVersion
            if (Limits.getHeapSize() > Limits.getLimitHeapSize() * .5 || Test.isRunningTest()) {
                break;
            }
        }
        return zuoraInvoices;
    }

    @TestVisible
    // Since this should run as system to mark invoices as downloaded
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private void updateZuoraInvoicesAsDownloaded(List<ContentDocumentLink> contentDocumentLinks, Map<String, ContentVersion> invoiceToVersion,  Map<Id, Zuora__ZInvoice__c> zInvoices) {
        List<Zuora__ZInvoice__c> zuoraInvoicesToUpdate = new List<Zuora__ZInvoice__c>();
        for (ContentDocumentLink contentDocumentLink : contentDocumentLinks) {
            Zuora__ZInvoice__c zuoraInvoiceToUpdate = new Zuora__ZInvoice__c(
                Id = contentDocumentLink.LinkedEntityId,
                Downloaded_Date__c = System.today(),
                Content_Document_Id__c = contentDocumentLink.ContentDocumentId,
                Ready_for_Email_Send__c = true,
                Ready_for_Paper_Bill_Queue__c = true,
                Bill_Document_Content_Version_ID__c = invoiceToVersion.get(zInvoices.get(contentDocumentLink.LinkedEntityId).Zuora__Zuora_Id__c).Id
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
            zuoraInvoiceIdToConventVersion.put(zuoraInvoice.id, cv);
        }
        Util.insertSObjs(zuoraInvoiceIdToConventVersion.values());
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

    // Since we want this to run as system independent of user permissions
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private List<ContentDocumentLink> insertContentDocumentLinks(List<ZuoraAPI.Invoice> zuoraInvoices, Map<String, ContentVersion> zuoraInvoiceIdToConventVersion, Map<String, Id> zuoraInvoiceIdToSFDCId) {
        // 'ConnectApi methods are not supported in data siloed tests. Please use @IsTest(SeeAllData=true)'
        // To avoid having to use SeeAllData we don't cover the second Content Document Link in tests
        if (communityId == null && !Test.isRunningTest()){
            this.communityId = getCommunityId();
        }
        List<ContentDocumentLink> invoiceContentDocumentLinks = new List<ContentDocumentLink>();
        List<ContentDocumentLink> communityContentDocumentLinks = new List<ContentDocumentLink>();
        for (ZuoraAPI.Invoice zuoraInvoice : zuoraInvoices) {
            ContentDocumentLink cdl = new ContentDocumentLink();
            cdl.ContentDocumentId = zuoraInvoiceIdToConventVersion.get(zuoraInvoice.id).ContentDocumentId;
            cdl.LinkedEntityId = zuoraInvoiceIdToSFDCId.get(zuoraInvoice.id);
            cdl.ShareType = 'I';
            invoiceContentDocumentLinks.add(cdl);

            if (communityID != null) {
                ContentDocumentLink commLink = new ContentDocumentLink();
                commLink.LinkedEntityId = communityID;
                commLink.Visibility = 'AllUsers';
                commLink.ShareType = 'V';
                commLink.ContentDocumentId = zuoraInvoiceIdToConventVersion.get(zuoraInvoice.id).ContentDocumentId;
                communityContentDocumentLinks.add(commLink);
            }
        }
        communityContentDocumentLinks.addAll(invoiceContentDocumentLinks);
        insert communityContentDocumentLinks;
        return invoiceContentDocumentLinks;
    }

    public static void batchInvoicesToMail(List<Zuora__ZInvoice__c> invoicesToMail) {
        ZuoraInvoiceAsyncService asyncService = new ZuoraInvoiceAsyncService(ZuoraInvoiceAsyncService.OperationType.MAIL);
        asyncService.allInvoicesToMail = invoicesToMail;
        Database.executeBatch(asyncService, 100);
    }

    public void queueInvoicesToMail(List<Zuora__ZInvoice__c> invoices) {
        List<ContentMailerService.Param> contentParams = getAllContentParamsToQueue(invoices);
        if (!contentParams.isEmpty()) {
            ContentMailerAsyncService asyncService = new ContentMailerAsyncService(contentParams);
            System.enqueueJob(asyncService);
        }
    }

    // Since we want this to run as system independent of user permissions
    @SuppressWarnings('PMD.ApexCRUDViolation')
    @TestVisible
    private List<ContentMailerService.Param> getAllContentParamsToQueue(List<Zuora__ZInvoice__c> invoices) {
        Map<Id, Zuora__ZInvoice__c> invoiceByDocumentId = new Map<Id, Zuora__ZInvoice__c>();
        Set<Id> docIds = new Set<Id>();
        List<Case> invalidAddressCases = new List<Case>();

        for (Zuora__ZInvoice__c invoice : invoices) {
            if (invoiceAddressValid(invoice)) {
                docIds.add(invoice.Content_Document_Id__c);
                invoiceByDocumentId.put(invoice.Content_Document_Id__c, invoice);
            } else {
                invalidAddressCases.add(createCaseForInvalidAddress(invoice));
            }
        }

        if (!invalidAddressCases.isEmpty()) {
            insert invalidAddressCases;
        }

        List<ContentDocument> documents = contentDocumentSelector.selectById(docIds);

        List<ContentMailerService.Param> contentParams = new List<ContentMailerService.Param>();
        for (ContentDocument doc : documents) {
            Zuora__ZInvoice__c invoice = invoiceByDocumentId.get(doc.Id);
            ContentMailerService.Param contentParam = new ContentMailerService.Param();
            contentParam.contentDocumentId = doc.Id;
            contentParam.fileName = doc.LatestPublishedVersion.Title.replace(' ', '_') + '.pdf';
            contentParam.contentSize = doc.ContentSize;
            contentParam.linkedEntityId = invoice.Id;
            contentParam.recipientName = invoice.Zuora__BillingAccount__r.Zuora__Account__r.Name;
            contentParam.street = invoice.Zuora__BillingAccount__r.Zuora__Account__r.BillingStreet;
            contentParam.city = invoice.Zuora__BillingAccount__r.Zuora__Account__r.BillingCity;
            contentParam.state = invoice.Zuora__BillingAccount__r.Zuora__Account__r.BillingState;
            contentParam.postalCode = invoice.Zuora__BillingAccount__r.Zuora__Account__r.BillingPostalCode;
            contentParams.add(contentParam);
        }
        return contentParams;
    }

    @TestVisible
    private Boolean invoiceAddressValid(Zuora__ZInvoice__c invoice) {
        // Zuora__BillingAccount__r.Zuora__Account__r is the Property Account
        if (invoice.Zuora__BillingAccount__r.Zuora__Account__r != null
            && invoice.Zuora__BillingAccount__r.Zuora__Account__r.BillingStreet != null
            && invoice.Zuora__BillingAccount__r.Zuora__Account__r.BillingCity != null
            && invoice.Zuora__BillingAccount__r.Zuora__Account__r.BillingPostalCode != null
            && invoice.Zuora__BillingAccount__r.Zuora__Account__r.BillingState != null) {
            return true;
        } else {
            return false;
        }
    }

    @TestVisible
    private String getCommunityId(){
        String communityId;
        try {
            ConnectApi.CommunityPage comm = ConnectApi.Communities.getCommunities();
            for (ConnectApi.Community community : comm.communities) {
                if (community.name == 'BlueWave Member Portal') {
                    communityId = community.id;
                }
            }
        } catch (Exception excep) {
            Logger.logLater('ZuoraInvoiceService','getCommunityId',excep.getMessage());
        }
        return communityId;
    }

    @TestVisible
    private Case createCaseForInvalidAddress(Zuora__ZInvoice__c invoice) {
        Case newCase = caseFactory.getCase('Customer_Care');

        newCase.Subject = 'Cannot send bill to Community Solar customer.';
        newCase.Priority = 'Medium';
        newCase.Product_Line__c = 'Community Solar';
        newCase.Category__c = 'Billing-Issue';
        String description = 'The customer address is invalid, so bills cannot be sent to customer. Please update ' +
            'the address on the related Account. If the customer does not want to receive paper bills, ' +
            'please use the \'Opt Out of Paper Billing\' checkbox. [Auto-generated]' ;
        newCase.Description = description;
        newCase.Origin = 'Other';
        newCase.Case_Type__c = 'BlueWave';
        newCase.Disable_Followup_Email__c = true;
        newCase.AccountId = invoice.Zuora__BillingAccount__r.Zuora__Account__c;

        return newCase;
    }
}