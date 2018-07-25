/**
 * Created by mstackhouse on 7/17/2018.
 * Description: 
 * Test: 
 */


public with sharing class LetterStreamService {
    public Http http = new Http();

    public String csv = 'UniqueDocId,PDFFileName,RecipientName1,RecipientAddr1,RecipientCity,RecipientState,' +
        'RecipientZip,SenderName1,SenderAddr1,SenderCity,SenderState,SenderZip,PageCount,Ink';

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
        Account_Bill__c testAccountBill = [
            SELECT Id, Parent_Account__r.Name, Parent_Account__r.BillingStreet,
                Parent_Account__r.BillingCity, Parent_Account__r.BillingState,
                Parent_Account__r.BillingPostalCode, Number_of_Pages_in_Template__c
            FROM Account_Bill__c
            WHERE Id = 'a1n4C0000009JmJQAU'
        ];

        Map<Id, Account_Bill__c> accountBillsByDocIds = new Map<Id, Account_Bill__c>();
        List<ContentDocument> documents = [
            SELECT Id, LatestPublishedVersion.Title, LatestPublishedVersion.VersionData
            FROM ContentDocument
            WHERE Id = '0694C000000PskrQAC'
            OR Id = '0694C000000Psl1QAC'
        ];

        for (ContentDocument doc : documents) {
            accountBillsByDocIds.put(doc.Id, testAccountBill);
        }

        Zippex lettersToSend = new Zippex();

        for (ContentDocument document : documents) {
            Account_Bill__c accountBill = accountBillsByDocIds.get(document.Id);
            addAccountBillToCSV(accountBill, document);
            String fileName = document.LatestPublishedVersion.Title + '.pdf';
            lettersToSend.addFile(fileName, document.LatestPublishedVersion.VersionData, null);
        }

        Blob csvBlob = Blob.valueOf(csv);

        lettersToSend.addFile('summary.csv', csvBlob, null);

        Messaging.EmailFileAttachment attachment = new Messaging.EmailFileAttachment();
        attachment.fileName = 'letters.zip';
        attachment.body = lettersToSend.getZipArchive();

        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setSubject('Sending Zip Files!!');
        mail.setHtmlBody('Wahoo');
        mail.setFileAttachments(new List<Messaging.EmailFileAttachment>{attachment});
        mail.setToAddresses(new List<String>{'mstackhouse@bluewavesolar.com'});
        Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{mail});
    }

    public void addAccountBillToCSV(Account_Bill__c accountBill, ContentDocument document) {
        csv += '\n';
        csv += (accountBill.Id + ',');
        csv += (document.LatestPublishedVersion.Title + ',');
        csv += (accountBill.Parent_Account__r.Name + ',');
        csv += (accountBill.Parent_Account__r.BillingStreet + ',');
        csv += (accountBill.Parent_Account__r.BillingCity + ',');
        csv += (accountBill.Parent_Account__r.BillingState + ',');
        csv += (accountBill.Parent_Account__r.BillingPostalCode + ',');
        csv += blueWaveAddress();
        csv += (accountBill.Number_of_Pages_in_Template__c + ',');
        csv += 'c';
    }

    public String blueWaveAddress() {
        String bwAddress = '';
        BW_Address__c address = [
            SELECT Id, Address_Line_One__c, Address_Line_Two__c
            FROM BW_Address__c
        ];

        bwAddress += (address.Address_Line_One__c + ',');
        bwAddress += 'Boston,';
        bwAddress += 'MA,';
        bwAddress += '02116,';
        return bwAddress;
    }
}
