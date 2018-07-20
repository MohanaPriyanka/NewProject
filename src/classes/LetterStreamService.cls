/**
 * Created by mstackhouse on 7/17/2018.
 * Description: 
 * Test: 
 */


public with sharing class LetterStreamService {
    public Http http = new Http();

    public void downloadZipFiles() {
        // 1. Query for Account bills that need to be sent
        // 2. Collect ContentVersion files (Account_Bill.Bill_Attach_Version)
        // 3. Create batches of ContentVersion.Size where Total Size < 10 Mb
        //
        // for each batch (Map<ContentVersion ID, Account_Bill__c>, List<ContentVersion>):
        // 1. Create Zippex file
        // 2. Add ContentVersion.VersionData to zippex
        // 3. Zippex.addFile(String fileName, Blob fileData, null)
        // 4. Build CSV to LetterStream's specs
        // 5. Zippex.addFile(String csvName, Blob fileData, null)
        // 6. POST to LetterStream
        //      - If Failed, we need to re-queue / schedule for another time
        //      - If succeeded, record LetterStream job for Bills.
        Zippex lettersToSend = new Zippex();
        Blob downloadedZipFolder;
        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.body = downloadedZipFolder;

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setSubject('test file send');
        mail.setHtmlBody('Hello');
        mail.setFileAttachments(new List<Messaging.EmailFileAttachment>{attachment});
        mail.setToAddresses(new List<String>{'Mstackhouse@bluwavesolar.com'});
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
    }
}
