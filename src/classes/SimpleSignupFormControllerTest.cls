/**
 * Created by PeterYao on 2/24/2020.
 */
@IsTest
public with sharing class SimpleSignupFormControllerTest {
    @TestSetup
    public static void testSetup() {
        ContentVersion cv = new ContentVersion(
            ContentLocation = 'S',
            VersionData = EncodingUtil.base64Decode('invoice body'),
            Title = 'InvoiceNumber.pdf',
            PathOnClient = '/InvoiceNumber.pdf'
        );
        insert cv;
        cv = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

        Product2 product = new Product2(
            Name = 'CS Product',
            Generic_Terms_Conga_Template__c = null
        );
        insert product;

        Lead lead = new Lead(
            FirstName = 'first',
            LastName = 'last',
            Company = 'Company',
            Email = 'foo@bar.com',
            Product__c = product.Id
        );
        insert lead;
        
        Account propertyAccount = new Account(
            Lead__c = lead.Id,
            Name = 'test account'
        );
        insert propertyAccount;

        Contract contract = new Contract(
            Lead__c = lead.Id,
            Product__c = product.Id,
            RecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('Customer_Contract').getRecordTypeId(),
            AccountId = propertyAccount.Id,
            Contract_Type__c = 'Generic',
            Customer_Signature_Date_Time__c = null
        );
        insert contract;

        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = contract.Id,
            ContentDocumentId = cv.ContentDocumentId,
            ShareType = 'V',
            // If not shared to all users, the guest user won't be able to see it
            Visibility = 'AllUsers'
        );
        insert cdl;
    }

    @IsTest
    private static void testContentDocSelector() {
        User guest = [SELECT Id FROM User WHERE Alias = 'guest' LIMIT 1];
        Lead lead = [SELECT Id, Email, (SELECT Id FROM Contracts__r) FROM Lead];
        List<ContentDocumentLink> contentDocumentLinks = [
            SELECT Id, ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :lead.Contracts__r[0].Id
        ];
        System.assertEquals(1, contentDocumentLinks.size(), 'Expected setup to create one content doc');
        Id contentDocId = contentDocumentLinks[0].ContentDocumentId;

        System.runAs(guest) {
            ContentDocumentSelector cds = new ContentDocumentSelector();
            System.assertEquals(0, cds.selectById(new Set<Id>{contentDocId}).size(),
                'Expected the selector to not find any docs because of sharing restriction');

            String cdlStr = SimpleSignupFormController.getContentDocumentLinksByLead(lead.Id, lead.Email, null);
            List<RestLead.RestContentDocument> rcdList = (List<RestLead.RestContentDocument>) JSON.deserialize(cdlStr, List<RestLead.RestContentDocument>.class);
            System.assertEquals(1, rcdList.size(),
                'Expected to find a single content document link shared to the guest user for this lead id');
            System.assertEquals(contentDocId, rcdList[0].id,
                'Expected to get the right content document id');
        }
    }

    @IsTest
    private static void testContentDocSelectorErrorHandling() {
        User guest = [SELECT Id FROM User WHERE Alias = 'guest' LIMIT 1];
        Lead testLead = [SELECT Id, Email, (SELECT Id FROM Contracts__r) FROM Lead];
        List<ContentDocumentLink> contentDocumentLinks = [
            SELECT Id, ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :testLead.Contracts__r[0].Id
        ];
        System.assertEquals(1, contentDocumentLinks.size(), 'Expected setup to create one content doc');
        Id contentDocId = contentDocumentLinks[0].ContentDocumentId;

        System.runAs(guest) {
            try {
                SimpleSignupFormController.getContentDocumentLinksByLead(testLead.Id, 'fakeemail', null);
                System.assert(false, 'Expected a fake email to generate an authorization exception');
            } catch (AuraHandledException ahe) {
                System.assert(ahe.getMessage().contains('did not match'), 'Exception should indicate the lead id and email did not match, but received ' + ahe.getMessage());
            }

            try {
                SimpleSignupFormController.getContentDistributionById(testLead.Id, 'fakeemail', contentDocId);
                System.assert(false, 'Expected a fake email to generate an authorization exception');
            } catch (AuraHandledException ahe) {
                System.assert(ahe.getMessage().contains('did not match'), 'Exception should indicate the lead id and email did not match, but received ' + ahe.getMessage());
            }

            try {
                System.assertEquals(null, SimpleSignupFormController.getContentDistributionById(testLead.Id, testLead.Email, contentDocId), 'Expected a Content Doc with no Content Distribution to return null');
            } catch (Exception ahe) {
                System.assert(false, 'Did not expect any exceptions when querying for a valid lead id, email, and docid combination, even when there are no Content Distribution records to return, but received ' +
                    ahe.getMessage() + '\n' + ahe.getStackTraceString());
            }
        }
    }


    @IsTest
    private static void testContentDistributionSuccess() {
        Lead testLead = [SELECT Id, Email FROM Lead];
        ContentVersion csaCV = new ContentVersion(
            ContentLocation = 'S',
            VersionData = EncodingUtil.base64Decode('SSF CSA body'),
            Title = 'Community Solar Agreement.pdf',
            PathOnClient = '/Community Solar Agreement.pdf'
        );
        insert csaCV;
        ContentDocumentSelector selector = new ContentDocumentSelector();
        String csaContentDocId = selector.getDocumentIdFromVersionId(csaCV.Id);

        String csaPath = SimpleSignupFormController.getContentDistributionById(testLead.Id, testLead.Email, csaContentDocId);
        System.assertNotEquals(null, csaPath, 'Expected SimpleSignupFormController.getContentDistributionById() to return one auto-generated ContentDistribution public link');

        ContentVersion sdfCV = new ContentVersion(
            ContentLocation = 'S',
            VersionData = EncodingUtil.base64Decode('SSF SDF body'),
            Title = 'Solar Disclosure Form.pdf',
            PathOnClient = '/Solar Disclosure Form.pdf'
        );
        insert sdfCV;
        String sdfContentDocId = selector.getDocumentIdFromVersionId(sdfCV.Id);

        String sdfPath = SimpleSignupFormController.getContentDistributionById(testLead.Id, testLead.Email, sdfContentDocId);
        System.assertNotEquals(null, sdfPath, 'Expected SimpleSignupFormController.getContentDistributionById() to return one auto-generated ContentDistribution public link');
    }


    @IsTest
    private static void testGetContentDocumentLinksByLead() {
        Lead testLead = [SELECT Id, Email, (SELECT Id FROM Contracts__r) FROM Lead];
        ContentVersion cv = new ContentVersion(
            ContentLocation = 'S',
            VersionData = EncodingUtil.base64Decode('ssf'),
            Title = 'ssf.pdf',
            PathOnClient = '/ssf.pdf'
        );
        insert cv;
        cv = [SELECT Id, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];
        Test.setCreatedDate(cv.ContentDocumentId, Datetime.now().addDays(-5));

        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = testLead.Contracts__r[0].Id,
            ContentDocumentId = cv.ContentDocumentId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;


        ContentDocumentSelector docSelector = new ContentDocumentSelector();
        List<ContentDocumentLink> cdlList = docSelector.selectByLinkedEntity(testLead.Contracts__r[0].Id);
        RestLead.RestContentDocument rcd1 = new RestLead.RestContentDocument(cdlList[0]);   // most recent
        RestLead.RestContentDocument rcd2 = new RestLead.RestContentDocument(cdlList[1]);   // oldest

        String retStr = SimpleSignupFormController.getContentDocumentLinksByLead(testLead.Id, testLead.Email, null);
        List<RestLead.RestContentDocument> retList = (List<RestLead.RestContentDocument>)JSON.deserialize(retStr, List<RestLead.RestContentDocument>.class);
        System.assertEquals(2, retList.size(), 'With no minimum start date, both CDLs should be returned');

        retStr = SimpleSignupFormController.getContentDocumentLinksByLead(testLead.Id, testLead.Email, JSON.serialize(new List<RestLead.RestContentDocument>{rcd2}));
        retList = (List<RestLead.RestContentDocument>)JSON.deserialize(retStr, List<RestLead.RestContentDocument>.class);
        System.assertEquals(1, retList.size(), 'Only one CDL should be returned, as the other was created before the minimum start date');
        System.assertEquals(rcd1.id, retList[0].id, 'The CDL returned should be the one with the created date of today');
    }


    @IsTest
    private static void testChangeOwnerOfUpload() {
        User user2 = new User(
            Username = 'testUserBlueWave@bluewavesolar.com',
            Email = 'testUserBlueWave@bluewavesolar.com',
            LastName = 'McTest',
            Alias = 'test',
            ProfileId = UserInfo.getProfileId(),
            TimeZoneSidKey = UserInfo.getTimeZone().toString(),
            LocaleSidKey = UserInfo.getLocale(),
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = UserInfo.getLocale()
        );
        insert user2;
        List<ContentDocument> contentDoc = [SELECT Id, OwnerId FROM ContentDocument];

        System.assertEquals(1, contentDoc.size(), 'Setup should return a single ContentDocument record');
        System.assertNotEquals(user2.Id, contentDoc[0].OwnerId, 'Setup should return a ContentRecord record NOT owned by the new test user');

        Test.startTest();
            SimpleSignupFormController.changeOwnerOfUpload(new Set<Id>{contentDoc[0].Id}, user2.Id);
        Test.stopTest();

        ContentDocument cd = [SELECT Id, OwnerId FROM ContentDocument WHERE Id = :contentDoc[0].Id LIMIT 1];
        System.assertEquals(user2.Id, cd.OwnerId, 'Method should have changed ContentDocument record owner to new test user');
    }


    @IsTest
    private static void testUnlinkDocsFromDummyRecord() {
        User backup = [SELECT Id FROM User WHERE Name = 'API' LIMIT 1];

        Custom_File_Upload_Share__c cfus = new Custom_File_Upload_Share__c(Name = 'test');
        insert cfus;

        List<ContentDocumentLink> existingCdlList = [SELECT Id, ContentDocumentId, ContentDocument.OwnerId FROM ContentDocumentLink WHERE LinkedEntityId IN (SELECT Id FROM Contract)];
        System.assertEquals(1, existingCdlList.size(), 'Setup should only return one ContentDocumentLink');
        System.assertNotEquals(backup.Id, existingCdlList[0].ContentDocument.OwnerId, 'Setup should return a ContentRecord record NOT owned by the new test user');
        String docId = existingCdlList[0].ContentDocumentId;

        ContentDocumentLink cdl = new ContentDocumentLink(ContentDocumentId = docId, LinkedEntityId = cfus.Id);
        insert cdl;

        String result = SimpleSignupFormController.unlinkDocsFromDummyRecord(new List<String>{docId}, 'Customer Utility Bill');

        System.assertEquals('OK', result, 'Method should return \'OK\' for successful operation');
        List<ContentDocumentLink> newCdlListToUser = [SELECT Id, LinkedEntityId, ContentDocument.LatestPublishedVersion.File_Category__c FROM ContentDocumentLink WHERE ContentDocumentId = :docId AND LinkedEntityId = :backup.Id];
        System.assertEquals(1, newCdlListToUser.size(), 'Doc should be linked to new user record');
        System.assertEquals('Customer Utility Bill', newCdlListToUser[0].ContentDocument.LatestPublishedVersion.File_Category__c, 'File category should match the category input to the method');
        List<ContentDocumentLink> newCdlListToContract = [SELECT Id, LinkedEntityId FROM ContentDocumentLink WHERE ContentDocumentId = :docId AND LinkedEntityId IN (SELECT Id FROM Custom_File_Upload_Share__c)];
        System.assert(newCdlListToContract.isEmpty(), 'Doc should no longer be linked to Custom File Upload Share record');
    }


    @IsTest private static void testUnlinkDocsMissingDummyRecord() {
        User backup = [SELECT Id FROM User WHERE Name = 'API' LIMIT 1];
        List<ContentDocumentLink> existingCdlList = [SELECT Id, ContentDocumentId, ContentDocument.OwnerId FROM ContentDocumentLink WHERE LinkedEntityId IN (SELECT Id FROM Contract)];
        System.assertEquals(1, existingCdlList.size(), 'Setup should only return one ContentDocumentLink');
        String docId = existingCdlList[0].ContentDocumentId;

        String result = SimpleSignupFormController.unlinkDocsFromDummyRecord(new List<String>{docId}, 'Customer Utility Bill');

        System.assertEquals(null, result, 'Missing dummy record should cause method to return null');
        List<Error_Log__c> errors = [SELECT Id, Message__c FROM Error_Log__c WHERE Class__c = 'SimpleSignupFormController' AND Method__c = 'unlinkDocsFromDummyRecord'];
        System.assert(!errors.isEmpty(), 'Missing dummy record, should have caused method to create Error Log records');
        ContentDocument contentDoc = [SELECT OwnerId FROM ContentDocument WHERE Id = :docId LIMIT 1];
        System.assertNotEquals(backup.Id, contentDoc.OwnerId, 'Missing dummy record prevents method from reparenting uploaded file');
    }
}