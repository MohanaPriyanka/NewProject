/*************************************************************************************
 * Created By: Lindsay Holmes (Gears CRM) on 3 April 2020
 *************************************************************************************/

@IsTest
private class ContentDocLinkPrivacySchedulerTest {
    @TestSetup
    static void makeData(){
        ContentVersion cv1 = new ContentVersion(
            ContentLocation = 'S',
            VersionData = EncodingUtil.base64Decode('invoice body1'),
            Title = 'test1.pdf',
            PathOnClient = '/test1.pdf'
        );
        insert cv1;

        ContentVersion cv2 = new ContentVersion(
            ContentLocation = 'S',
            VersionData = EncodingUtil.base64Decode('invoice body2'),
            Title = 'test2.pdf',
            PathOnClient = '/test2.pdf'
        );
        insert cv2;

        ContentVersion cv3 = new ContentVersion(
            ContentLocation = 'S',
            VersionData = EncodingUtil.base64Decode('invoice body3'),
            Title = 'test3.pdf',
            PathOnClient = '/test3.pdf'
        );
        insert cv3;


        Lead l1 = new Lead(
            FirstName = 'test1',
            LastName = 'testerson1',
            Company = 'test1',
            Email = 'ttesterson1@email.com',
            LeadSource = 'Switch'
        );
        insert l1;

        Lead l2 = new Lead(
            FirstName = 'test2',
            LastName = 'testerson2',
            Company = 'test2',
            Email = 'ttesterson2@email.com',
            LeadSource = 'Switch'
        );
        insert l2;

        List<ContentVersion> cvList = [SELECT Id, ContentDocumentId FROM ContentVersion];
        System.assertEquals(3, cvList.size());
        Test.setCreatedDate(cvList[0].ContentDocumentId, Datetime.now().addDays(-70));
        Test.setCreatedDate(cvList[1].ContentDocumentId, Datetime.now().addDays(-20));
        Test.setCreatedDate(cvList[2].ContentDocumentId, Datetime.now().addDays(-2));

        // this CDL should be returned by the selector
        ContentDocumentLink cdl1 = new ContentDocumentLink(
            ContentDocumentId = cvList[1].ContentDocumentId,
            LinkedEntityId = l1.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        // this CDL should NOT be returned by the selector due to visibility
        ContentDocumentLink cdl2 = new ContentDocumentLink(
            ContentDocumentId = cvList[1].ContentDocumentId,
            LinkedEntityId = l2.Id,
            ShareType = 'V',
            Visibility = 'InternalUsers'
        );
        // this CDL should NOT be returned by the selector due to parent CD created date
        ContentDocumentLink cdl3 = new ContentDocumentLink(
            ContentDocumentId = cvList[0].ContentDocumentId,
            LinkedEntityId = l1.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        // this CDL should NOT be returned by the selector due to parent CD created date
        ContentDocumentLink cdl4 = new ContentDocumentLink(
            ContentDocumentId = cvList[2].ContentDocumentId,
            LinkedEntityId = l1.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert new List<ContentDocumentLink>{cdl1, cdl2, cdl3, cdl4};
    }
    
    @IsTest
    private static void testSchedulerSuccess() {
        Test.startTest();
            Datetime dt = Datetime.now().addDays(1);
            String cronExpress = dt.second() + ' '+ dt.minute() + ' ' + dt.hour() + ' ' + dt.day() + ' ' + dt.month() + ' ?';
            ContentDocLinkPrivacyScheduler sched = new ContentDocLinkPrivacyScheduler();
            String jobId = System.schedule('TestContentDocLinkPrivacyScheduler', cronExpress, sched);
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id = :jobId];
            System.assertEquals(cronExpress, ct.CronExpression);
            System.assertEquals(0, ct.TimesTriggered);
            System.assertEquals(dt, ct.NextFireTime);
        Test.stopTest();

        System.assertEquals(0, [SELECT count() FROM Error_Log__c], 'There should be no errors');
        System.assertEquals(
            1, 
            [SELECT count() FROM ContentDocumentLink WHERE Visibility = 'InternalUsers' AND LinkedEntityId IN (SELECT Id FROM Lead WHERE LastName='testerson1')],
            'One CDL should have changed from AllUsers to InternalUsers'
        );
        System.assertEquals(
            1, 
            [SELECT count() FROM ContentDocumentLink WHERE Visibility = 'InternalUsers' AND LinkedEntityId IN (SELECT Id FROM Lead WHERE LastName='testerson2')],
            'One CDL should have remained unchanged with visibility InternalUsers'
        );
        System.assertEquals(
            2, 
            [SELECT count() FROM ContentDocumentLink WHERE Visibility = 'AllUsers' AND LinkedEntityId IN (SELECT Id FROM Lead WHERE LastName='testerson1')],
            'Two CDLs should have remained unchanged with visibility AllUsers due to CreatedDate of parent CD'
        );
    }
    
    @IsTest
    private static void testSchedulerFail() {
        // use MockContentService to generate exception and test catch block
        ContentDocLinkPrivacyScheduler sched = new ContentDocLinkPrivacyScheduler();
        MockContentService mockContentService = new MockContentService();
        sched.service = (ContentService)Test.createStub(ContentService.class, mockContentService);
        
        System.assertEquals(
            3, 
            [SELECT count() FROM ContentDocumentLink WHERE Visibility = 'AllUsers' AND LinkedEntityId IN (SELECT Id FROM Lead)], 
            'There should be three Content Document Links with AllUsers visibility'
        );

        Test.startTest();
            Datetime dt = Datetime.now().addDays(1);
            String cronExpress = dt.second() + ' '+ dt.minute() + ' ' + dt.hour() + ' ' + dt.day() + ' ' + dt.month() + ' ?';
            
            String jobId = System.schedule('TestContentDocLinkPrivacyScheduler', cronExpress, sched);
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id = :jobId];
            System.assertEquals(cronExpress, ct.CronExpression);
            System.assertEquals(0, ct.TimesTriggered);
            System.assertEquals(dt, ct.NextFireTime);
        Test.stopTest();

        System.assertNotEquals(0, [SELECT count() FROM Error_Log__c], 'There should be errors');
        System.assertEquals(
            3, 
            [SELECT count() FROM ContentDocumentLink WHERE Visibility = 'AllUsers' AND LinkedEntityId IN (SELECT Id FROM Lead)], 
            'There should be three Content Document Links with AllUsers visibility'
        );
    }


    @TestVisible
    private class MockContentService extends MockProvider {
        public MockContentService(){}

        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'makeContentDocLinksPrivate' {
                    throw new Util.BWException();
                }
            }
            return null;
        }

    }
}