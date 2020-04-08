/*************************************************************************************
 * Created By: peteryao on 9/12/19  
 *************************************************************************************/
@IsTest
public with sharing class ContentDocumentSelectorTest {
    @TestSetup
    public static void testSetup() {
        // I couldn't figure out how to mock the ContentDocumentSelector which returns a ContentDocument with
        // ContentVersion data. Deserializing JSON would results in various JSONExceptions.
        // So this will need to create the data
        ContentVersion cv = new ContentVersion(
            ContentLocation = 'S',
            VersionData = EncodingUtil.base64Decode('invoice body'),
            Title = 'InvoiceNumber.pdf',
            PathOnClient = '/InvoiceNumber.pdf'
        );
        insert cv;
        ContentVersion cv2 = new ContentVersion(
            ContentLocation = 'S',
            VersionData = EncodingUtil.base64Decode('longer invoice body should be sorted first'),
            Title = 'InvoiceNumber2.pdf',
            PathOnClient = '/InvoiceNumber2.pdf'
        );
        insert cv2;

        Shared_Solar_System__c sss1 = new Shared_Solar_System__c(
            Name = 'Test SSS',
            Total_System_Size_kWh_DC__c = 1445.86,
            Total_System_Size_kW_AC__c  = 996,
            Expected_Yield_kWh_kW__c = 1300
        );
        insert sss1;

        Transfer__c transfer = new Transfer__c(
            Shared_Solar_System__c = sss1.Id,
            Transfer_Type__c = 'Main',
            Attempted_kWh_Transfer__c = 73072.00,
            Attempted_Transfer__c =  12033.73,
            Transfer_Amount__c =  12033.73,
            Default_Credit_Value__c = 0.1848
        );
        insert transfer;
    }

    @IsTest
    private static void testSelectById() {
        List<ContentVersion> cvList = [
            SELECT Id, ContentDocumentId, ContentDocument.ContentSize
            FROM ContentVersion
            ORDER BY Title
        ];
        ContentVersion cv = cvList[0];
        ContentVersion cv2 = cvList[1];

        ContentDocumentSelector documentSelector = new ContentDocumentSelector();
        Test.startTest();
        List<ContentDocument> contentDocuments =
            documentSelector.selectById(new Set<Id>{cv.ContentDocumentId, cv2.ContentDocumentId});
        Test.stopTest();
        System.assertEquals(2, contentDocuments.size());
        System.assertEquals('InvoiceNumber2.pdf', contentDocuments[0].LatestPublishedVersion.Title);
        System.assertEquals('InvoiceNumber.pdf', contentDocuments[1].LatestPublishedVersion.Title);
    }

    @IsTest
    private static void testGetMostRecentTransferSheet(){
        List<ContentVersion> cvList = [
            SELECT Id, ContentDocumentId, ContentDocument.ContentSize
            FROM ContentVersion
            ORDER BY Title
        ];
        ContentVersion cv = cvList[0];
        cv.File_Category__c = 'Transfer Sheet';
        update cv;

        Transfer__c transfer = [
            SELECT Id
            FROM Transfer__c
            LIMIT 1
        ];

        ContentDocumentLink linkToTransfer = new ContentDocumentLink(
            LinkedEntityId = transfer.Id,
            ContentDocumentId = cv.ContentDocumentId,
            ShareType = 'V'
        );
        insert linkToTransfer;

        Test.startTest();
            ContentDocumentSelector documentSelector = new ContentDocumentSelector();
            ContentDocument doc = documentSelector.getMostRecentTransferSheet(transfer);
        Test.stopTest();

        System.assertEquals(cvList[0].ContentDocumentId, doc.Id);
    }

    @IsTest
    private static void testGetLeadDocsCreatedWithinRange() {
        Lead l1 = new Lead(
            FirstName = 'test',
            LastName = 'testerson',
            Company = 'test',
            Email = 'ttesterson@email.com',
            LeadSource = 'Switch'
        );
        Lead l2 = new Lead(
            FirstName = 'test2',
            LastName = 'testerson2',
            Company = 'test2',
            Email = 'ttesterson2@email.com',
            LeadSource = 'Switch'
        );
        insert new List<Lead>{l1, l2};

        List<ContentVersion> cvList = [SELECT Id, ContentDocumentId FROM ContentVersion];
        System.assertEquals(2, cvList.size());
        Test.setCreatedDate(cvList[1].ContentDocumentId, Datetime.now().addDays(-70));

        // this CDL should be returned by the selector
        ContentDocumentLink cdl1 = new ContentDocumentLink(
            ContentDocumentId = cvList[0].ContentDocumentId,
            LinkedEntityId = l1.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        // this CDL should NOT be returned by the selector due to visibility
        ContentDocumentLink cdl2 = new ContentDocumentLink(
            ContentDocumentId = cvList[0].ContentDocumentId,
            LinkedEntityId = l2.Id,
            ShareType = 'V',
            Visibility = 'InternalUsers'
        );
        // this CDL should NOT be returned by the selector due to parent CD created date
        ContentDocumentLink cdl3 = new ContentDocumentLink(
            ContentDocumentId = cvList[1].ContentDocumentId,
            LinkedEntityId = l2.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert new List<ContentDocumentLink>{cdl1, cdl2, cdl3};

        ContentDocumentSelector selector = new ContentDocumentSelector();
        Test.startTest();
            List<ContentDocument> cdList = selector.getLeadDocsCreatedWithinRange(Datetime.now().addDays(-1), Datetime.now().addDays(1));
        Test.stopTest();
        
        List<Error_Log__c> errList = [SELECT Id, Message__c FROM Error_Log__c];
        System.assert(errList.isEmpty(), 'There should be no errors');
        System.assertEquals(2, cdList.size(), 'Selector should have returned two Content Documents');
        System.assertEquals(1, cdList[0].ContentDocumentLinks.size(), 'Selector should have returned one Content Document Link');
        System.assertEquals(l1.Id, cdList[0].ContentDocumentLinks[0].LinkedEntityId, 'Selector should have returned the Content Document Link associated with Lead l1');
    }
}