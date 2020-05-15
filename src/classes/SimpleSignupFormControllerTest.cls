/**
 * Created by PeterYao on 2/24/2020.
 */
@IsTest
public with sharing class SimpleSignupFormControllerTest {
    @TestSetup
    public static void testSetup() {
        User guest = [SELECT Id FROM User WHERE Alias = 'guest' LIMIT 1];
        ContentVersion cv = new ContentVersion(
            ContentLocation = 'S',
            VersionData = EncodingUtil.base64Decode('invoice body'),
            Title = 'InvoiceNumber.pdf',
            PathOnClient = '/InvoiceNumber.pdf'
        );
        insert cv;
        cv = [SELECT Id, Title, ContentDocumentId FROM ContentVersion WHERE Id = :cv.Id];

        Lead lead = new Lead(
            FirstName = 'first',
            LastName = 'last',
            Company = 'Company',
            Email = 'foo@bar.com'
        );
        insert lead;

        ContentDocumentLink cdl = new ContentDocumentLink(
            LinkedEntityId = lead.Id,
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
        Lead lead = [SELECT Id, Email FROM Lead];
        List<ContentDocumentLink> contentDocumentLinks = [
            SELECT Id, ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :lead.Id
        ];
        System.assertEquals(1, contentDocumentLinks.size(), 'Expected setup to create one content doc');
        Id contentDocId = contentDocumentLinks[0].ContentDocumentId;

        System.assertNotEquals(null, SimpleSignupFormController.getContentDocumentDataById(lead.Id, lead.Email, contentDocId),
            'Expected to get some base64 encoded data back from the controller running without sharing');

        System.runAs(guest) {
            ContentDocumentSelector cds = new ContentDocumentSelector();
            System.assertEquals(0, cds.selectById(new Set<Id>{contentDocId}).size(),
                'Expected the selector to not find any docs because of sharing restriction');

            contentDocumentLinks = SimpleSignupFormController.getContentDocumentLinksByLead(lead.Id, lead.Email, null);
            System.assertEquals(1, contentDocumentLinks.size(),
                'Expected to find a single content document link shared to the guest user for this lead id');
            System.assertEquals(contentDocId, contentDocumentLinks[0].ContentDocumentId,
                'Expected to get the right content document id');
            System.assertNotEquals(null, SimpleSignupFormController.getContentDocumentDataById(lead.Id, lead.Email, contentDocId),
                'Expected to get some base64 encoded data back from the controller running without sharing');
        }
    }

    @IsTest
    private static void testContentDocSelectorErrorHandling() {
        User guest = [SELECT Id FROM User WHERE Alias = 'guest' LIMIT 1];
        Lead testLead = [SELECT Id, Email FROM Lead];
        List<ContentDocumentLink> contentDocumentLinks = [
            SELECT Id, ContentDocumentId
            FROM ContentDocumentLink
            WHERE LinkedEntityId = :testLead.Id
        ];
        System.assertEquals(1, contentDocumentLinks.size(), 'Expected setup to create one content doc');
        Id contentDocId = contentDocumentLinks[0].ContentDocumentId;

        System.runAs(guest) {
            try {
                SimpleSignupFormController.getContentDocumentDataById(Util.getFakeId(Lead.SObjectType), testLead.Email, contentDocId);
                System.assert(false, 'Expected a fake lead id to generate an authorization exception');
            } catch (AuraHandledException ahe) {
                System.assert(ahe.getMessage().contains('did not match'), 'Exception should indicate the lead id and email did not match, but received ' + ahe.getMessage());
            }

            try {
                SimpleSignupFormController.getContentDocumentDataById(testLead.Id, 'fakeemail', contentDocId);
                System.assert(false, 'Expected a fake email to generate an authorization exception');
            } catch (AuraHandledException ahe) {
                System.assert(ahe.getMessage().contains('did not match'), 'Exception should indicate the lead id and email did not match, but received ' + ahe.getMessage());
            }

            try {
                SimpleSignupFormController.getContentDocumentDataById(testLead.Id, testLead.Email, Util.getFakeId(ContentDocument.SObjectType));
                System.assert(false, 'Expected a fake document to not be linked to the lead');
            } catch (AuraHandledException ahe) {
                System.assert(ahe.getMessage().contains('not related'), 'Exception should indicate a document was not related, but received ' + ahe.getStackTraceString());
            }

            try {
                SimpleSignupFormController.getContentDocumentLinksByLead(testLead.Id, 'fakeemail', null);
                System.assert(false, 'Expected a fake email to generate an authorization exception');
            } catch (AuraHandledException ahe) {
                System.assert(ahe.getMessage().contains('did not match'), 'Exception should indicate the lead id and email did not match, but received ' + ahe.getMessage());
            }

            try {
                SimpleSignupFormController.getContentDocumentDataById(testLead.Id, testLead.Email, contentDocId);
            } catch (Exception ahe) {
                System.assert(false, 'Did not expect any exceptions when querying for a valid lead id, email, and docid combination, but received ' +
                    ahe.getMessage() + '\n' + ahe.getStackTraceString());
            }

            try {
                SimpleSignupFormController.getContentDistributionById(testLead.Id, 'fakeemail', contentDocId);
                System.assert(false, 'Expected a fake email to generate an authorization exception');
            } catch (AuraHandledException ahe) {
                System.assert(ahe.getMessage().contains('did not match'), 'Exception should indicate the lead id and email did not match, but received ' + ahe.getMessage());
            }

            try {
                SimpleSignupFormController.getContentDistributionById(testLead.Id, testLead.Email, contentDocId);
                System.assert(false, 'Expected a Content Doc with no Content Distribution to generate an exception');
            } catch (Exception ahe) {
                System.assert(ahe.getMessage().contains('Did not find any content distributions '), 'Exception should indicate that there are no Content Distribution records for that Content Doc ID, but received ' + ahe.getMessage());
            }
        }


        ContentDocumentLink cdl = new ContentDocumentLink(Id = contentDocumentLinks[0].Id, Visibility = 'InternalUsers');
        update cdl;
        System.runAs(guest) {
            try {
                SimpleSignupFormController.getContentDocumentDataById(testLead.Id, testLead.Email, contentDocId);
                System.assert(false, 'Expected a doc hidden from guest users to generate an exception');
            } catch (AuraHandledException ahe) {
                System.assert(ahe.getMessage().contains('Did not find any'), 'Exception should indicate that no documents were related to the Lead, but received ' + ahe.getStackTraceString());
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
        Lead testLead = [SELECT Id, Email FROM Lead];
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
            LinkedEntityId = testLead.Id,
            ContentDocumentId = cv.ContentDocumentId,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;

        List<ContentDocumentLink> retList = SimpleSignupFormController.getContentDocumentLinksByLead(testLead.Id, testLead.Email, null);
        System.assertEquals(2, retList.size(), 'With no minimum start date, both CDLs should be returned');
        retList = SimpleSignupFormController.getContentDocumentLinksByLead(testLead.Id, testLead.Email, Datetime.now().addDays(-1));
        System.assertEquals(1, retList.size(), 'Only one CDL should be returned, as the other was created before the minimum start date');
        System.assertNotEquals(cdl.Id, retList[0].Id, 'The CDL returned should be the one with the created date of today');
    }
}