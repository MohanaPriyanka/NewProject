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

            String cdlStr = SimpleSignupFormController.getContentDocumentLinksByLead(lead.Id, lead.Email, null);
            System.debug(cdlStr);
            List<RestLead.RestContentDocument> rcdList = (List<RestLead.RestContentDocument>) JSON.deserialize(cdlStr, List<RestLead.RestContentDocument>.class);
            System.assertEquals(1, rcdList.size(),
                'Expected to find a single content document link shared to the guest user for this lead id');
            System.assertEquals(contentDocId, rcdList[0].id,
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
                System.assertEquals(null, SimpleSignupFormController.getContentDistributionById(testLead.Id, testLead.Email, contentDocId), 'Expected a Content Doc with no Content Distribution to return null');
            } catch (Exception ahe) {
                System.assert(false, 'Did not expect any exceptions when querying for a valid lead id, email, and docid combination, even when there are no Content Distribution records to return, but received ' +
                    ahe.getMessage() + '\n' + ahe.getStackTraceString());
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


        ContentDocumentSelector docSelector = new ContentDocumentSelector();
        List<ContentDocumentLink> cdlList = docSelector.selectByLinkedEntity(testLead.Id);
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
}