/*************************************************************************************
 * Created By: peteryao on 9/12/19  
 * Description: Takes a list of Params, remainingContentToSend, that has a list of Content Document Ids and their
 *   content size and corresponding addresses, and:
 *   - figures out how to package the content to avoid heap limits
 *   - queries for the VersionData for that package's content
 *   - sends to LetterStream for mailing
 *   - marks the objects as being sent
 *   - re-queues any remaining content that couldn't fit in the package
 * Test: ContentMailerServiceTest
 *************************************************************************************/

public with sharing class ContentMailerService {
    @TestVisible
    private static ContentDocumentSelector contentDocumentSelector = new ContentDocumentSelector();
    @TestVisible
    private static LetterStreamService lss = new LetterStreamService();

    // Max size is 12Mb, but need to give buffer for csv file. So, 10 Mb * 1000 Kb/Mb * 1000 b/Kb
    @TestVisible
    private Integer maxPackageSize = 1*1000*1000;
    @TestVisible
    private static Integer calloutsMade = 0;

    public List<Param> remainingContentToSend;


    public ContentMailerService() {
    }

    public void mailContent() {
        List<Param> contentToSendThisTransaction = getContentForPackage();
        Map<Id, ContentDocument> contentDocumentMap = getContentMapWithVersionData(contentToSendThisTransaction);
        Zippex zippex = new Zippex();
        Set<Id> contentParentIds = new Set<Id>();
        for (Param param : contentToSendThisTransaction) {
            LetterStreamService.LetterParameters letterParams = new LetterStreamService.LetterParameters(param);
            lss.addLetterToCSV(letterParams);
            // Can't have ' in file names to letterstream
            String fileName = Util.prepForCSV(letterParams.fileName).replace('\'', '');
            zippex.addFile(fileName, contentDocumentMap.get(param.contentDocumentId).LatestPublishedVersion.VersionData, null);
            contentParentIds.add(param.linkedEntityId); // e.g. ZInvoice__c.Id
        }
        zippex.addFile(getJobName(), lss.getCSV(), null);
        checkHeapLimit();
        String responseXMLString = sendToLetterStream(zippex.getZipArchive());
        handleResponse(responseXMLString, contentParentIds, lss.csv);

        if (remainingContentToSend != null && remainingContentToSend.size() > 0) {
            System.enqueueJob(new ContentMailerAsyncService(remainingContentToSend));
        }
    }

    @TestVisible
    private List<Param> getContentForPackage() {
        List<Param> contentToSendThisTransaction = new List<Param>();
        Decimal packageSize = 0;
        while (!remainingContentToSend.isEmpty()) {
            contentToSendThisTransaction.add(remainingContentToSend[0]);
            packageSize += remainingContentToSend[0].contentSize;
            remainingContentToSend.remove(0);
            if (packageSize >= maxPackageSize) {
                // hit size limit for this package, but remainingContentToSend has the remaining content that should be queued
                break;
            }
        }
        return contentToSendThisTransaction;
    }

    private String sendToLetterStream(Blob letterPackage) {
        HttpRequest request = lss.buildRequestWithFile(letterPackage, 'filename.zip');
        // One minute timeout is conservative - we hit System.CalloutException: Read timed out at 10 seconds
        request.setTimeout(60000);
        HttpResponse response;
        if (Test.isRunningTest()) {
            response = new LetterStreamAPIMock().respond(request);
            calloutsMade++;
        } else {
            response = new Http().send(request);
        }
        Dom.Document responseXML = response.getBodyDocument();
        String responseXMLString = responseXML.toXmlString();
        String message = 'Request: ' + request.getEndpoint() + '\n' +
            'Response: ' + response.getBody();
        Logger.logLater('ContentMailerService', 'sendToLetterStream', message, Logger.FINE);
        return responseXMLString;
    }

    private String getJobName() {
        // This is used for the LetterStream batch id, and needs to be unique. Using the timestamp isn't enough since
        // we have jobs running in parallel
        String jobName = 'Job_' +
            Datetime.now().format('MM-dd-yyyy_HH:mm:ss:SSS') + '_' +
            String.valueOf((Integer) (Math.random() * 1000)) + '.csv';
        return jobName;
    }

    private void checkHeapLimit() {
        String heapLimitString = Util.getHeapLimit('Heap');
        Logger.logLater('ContentMailerService', 'sendContent', heapLimitString, Logger.FINE);
        List<String> heapLimitParts = heapLimitString.split(' ');
        Decimal used = Decimal.valueOf(heapLimitParts[2]);
        Decimal available = Decimal.valueOf(heapLimitParts[4]);
        Decimal percent = 100 * used / available;
        // A 2 MB doc and 5 100k docs gets us to 61% of heap - we'll exit if there's no heap left
        if (percent > 61) {
            throw new Util.BWException('Too much heap used: ' + heapLimitString);
        }
    }

    @TestVisible
    private Map<Id, ContentDocument> getContentMapWithVersionData(List<Param> contentToSend) {
        Set<Id> documentIds = new Set<Id>();
        for (Param param : contentToSend) {
            documentIds.add(param.contentDocumentId);
        }
        return new Map<Id, ContentDocument>(contentDocumentSelector.selectById(documentIds));
    }

    @TestVisible
    private void handleResponse(String responseXMLString, Set<Id> objectIds, String csv) {
        LetterStreamService lss = new LetterStreamService();
        // newJob gets inserted within here
        LetterStreamJob__c newJob = lss.parseLetterStreamResponse(responseXMLString);

        if (newJob == null) {
            String message = 'Job post failed for objects: (' + String.join(new List<Id>(objectIds), ',') + ') + \n';
            message += 'Response: \n' + responseXMLString + '\n';
            message += 'CSV: \n' + csv;
            Logger.logLater('ContentMailerService', 'execute', message, Logger.ERROR);
        } else {
            markObjectAsMailed(objectIds, newJob.Id);
        }
    }

    @TestVisible
    private void markObjectAsMailed(Set<Id> contentParentIds, Id newJobId) {
        List<SObject> sobjects = new List<SObject>();

        for (Id id : contentParentIds) {
            SObject sobj = id.getSobjectType().newSObject(id);
            sobj.put('Ready_for_Paper_Bill_Queue__c', false);
            sobj.put('Added_to_Paper_Bill_Queue__c', true);
            sobj.put('LetterStreamJob__c', newJobId);
            sobjects.add(sobj);
        }
        Util.updateSObjs(sobjects);
    }

    public class Param {
        public Id linkedEntityId; // e.g. ZInvoice__c.Id or Account_Bill__c.Id, to ensure that the contentDocument is only sent once
        public Id contentDocumentId; // the content that will be sent
        public Integer contentSize; // Used to figure out how many content docs to compress and send before hitting heap size
        public String fileName;
        public String recipientName;
        public String street;
        public String city;
        public String state;
        public String postalCode;
        public String extraInserts; // LetterStream only, pipe delimited ids, e.g. 1234|5678
    }
}