/*************************************************************************************
 * Created By: Lindsay Holmes (Gears CRM) on 3 April 2020
 *************************************************************************************/

@IsTest
private class ContentDocLinkPrivacySchedulerTest {
    @TestSetup
    static void makeData(){
        ContentVersion cv = new ContentVersion(
            ContentLocation = 'S',
            VersionData = EncodingUtil.base64Decode('invoice body'),
            Title = 'test1.pdf',
            PathOnClient = '/test1.pdf'
        );
        insert cv;

        Lead l = new Lead(
            FirstName = 'test',
            LastName = 'testerson',
            Company = 'test',
            Email = 'ttesterson@email.com'
        );
        insert l;

        ContentDocumentSelector selector = new ContentDocumentSelector();
        Id cdId = selector.getDocumentIdFromVersionId(cv.Id);

        ContentDocumentLink cdl = new ContentDocumentLink(
            ContentDocumentId = cdId,
            LinkedEntityId = l.Id,
            ShareType = 'V',
            Visibility = 'AllUsers'
        );
        insert cdl;
    }
    
    @IsTest
    private static void testSchedulerDefaultMinMax() {
        Test.startTest();
            Datetime dt = Datetime.now().addDays(1);
            String cronExpress = dt.second() + ' '+ dt.minute() + ' ' + dt.hour() + ' ' + dt.day() + ' ' + dt.month() + ' ?';
            ContentDocLinkPrivacyScheduler sched = new ContentDocLinkPrivacyScheduler();
            System.assertEquals(Datetime.now().addDays(-60), sched.dt1);
            System.assertEquals(Datetime.now().addDays(-10), sched.dt2);
            String jobId = System.schedule('TestContentDocLinkPrivacyScheduler', cronExpress, sched);
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id = :jobId];
            System.assertEquals(cronExpress, ct.CronExpression);
            System.assertEquals(0, ct.TimesTriggered);
            System.assertEquals(dt, ct.NextFireTime);
        Test.stopTest();
    }
    
    @IsTest
    private static void testSchedulerWithDaysAgo() {
        Test.startTest();
            Datetime dt = Datetime.now().addDays(1);
            String cronExpress = dt.second() + ' '+ dt.minute() + ' ' + dt.hour() + ' ' + dt.day() + ' ' + dt.month() + ' ?';
            ContentDocLinkPrivacyScheduler sched = new ContentDocLinkPrivacyScheduler(-3, 12);
            System.assertEquals(Datetime.now().addDays(3), sched.dt1);
            System.assertEquals(Datetime.now().addDays(-12), sched.dt2);
            String jobId = System.schedule('TestContentDocLinkPrivacyScheduler', cronExpress, sched);
        Test.stopTest();

        List<ContentDocumentLink> linkList = [SELECT Id, Visibility FROM ContentDocumentLink WHERE LinkedEntityId IN (SELECT Id FROM Lead)];
        System.assertEquals(1, linkList.size(), 'There should be only one Content Document Link');
        System.assertEquals('InternalUsers', linkList[0].Visibility, 'The visibility of the Content Document Link should be InternalUsers');
    }
    
    @IsTest
    private static void testSchedulerWithDaysAgoSame() {
        Test.startTest();
            Datetime dt = Datetime.now().addDays(1);
            String cronExpress = dt.second() + ' '+ dt.minute() + ' ' + dt.hour() + ' ' + dt.day() + ' ' + dt.month() + ' ?';
            ContentDocLinkPrivacyScheduler sched = new ContentDocLinkPrivacyScheduler(0, 0);
            System.assertEquals(Datetime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0)), sched.dt1);
            System.assertEquals(Datetime.newInstance(Date.today(), Time.newInstance(23, 59, 59, 999)), sched.dt2);
            String jobId = System.schedule('TestContentDocLinkPrivacyScheduler', cronExpress, sched);
        Test.stopTest();

        List<ContentDocumentLink> linkList = [SELECT Id, Visibility FROM ContentDocumentLink WHERE LinkedEntityId IN (SELECT Id FROM Lead)];
        System.assertEquals(1, linkList.size(), 'There should be only one Content Document Link');
        System.assertEquals('InternalUsers', linkList[0].Visibility, 'The visibility of the Content Document Link should be InternalUsers');
    }
    
    @IsTest
    private static void testSchedulerWithDates() {
        Test.startTest();
            Datetime dt = Datetime.now().addDays(1);
            String cronExpress = dt.second() + ' '+ dt.minute() + ' ' + dt.hour() + ' ' + dt.day() + ' ' + dt.month() + ' ?';
            ContentDocLinkPrivacyScheduler sched = new ContentDocLinkPrivacyScheduler(Date.today().addDays(-5), Date.today());
            System.assertEquals(Datetime.now().addDays(-5), sched.dt1);
            System.assertEquals(Datetime.now(), sched.dt2);
            String jobId = System.schedule('TestContentDocLinkPrivacyScheduler', cronExpress, sched);
        Test.stopTest();

        List<ContentDocumentLink> linkList = [SELECT Id, Visibility FROM ContentDocumentLink WHERE LinkedEntityId IN (SELECT Id FROM Lead)];
        System.assertEquals(1, linkList.size(), 'There should be only one Content Document Link');
        System.assertEquals('InternalUsers', linkList[0].Visibility, 'The visibility of the Content Document Link should be InternalUsers');
    }
    
    @IsTest
    private static void testSchedulerWithDatesSame() {
        Test.startTest();
            Datetime dt = Datetime.now().addDays(1);
            String cronExpress = dt.second() + ' '+ dt.minute() + ' ' + dt.hour() + ' ' + dt.day() + ' ' + dt.month() + ' ?';
            ContentDocLinkPrivacyScheduler sched = new ContentDocLinkPrivacyScheduler(Date.today(), Date.today());
            System.assertEquals(Datetime.newInstance(Date.today(), Time.newInstance(0, 0, 0, 0)), sched.dt1);
            System.assertEquals(Datetime.newInstance(Date.today(), Time.newInstance(23, 59, 59, 999)), sched.dt2);
            String jobId = System.schedule('TestContentDocLinkPrivacyScheduler', cronExpress, sched);
        Test.stopTest();

        List<ContentDocumentLink> linkList = [SELECT Id, Visibility FROM ContentDocumentLink WHERE LinkedEntityId IN (SELECT Id FROM Lead)];
        System.assertEquals(1, linkList.size(), 'There should be only one Content Document Link');
        System.assertEquals('InternalUsers', linkList[0].Visibility, 'The visibility of the Content Document Link should be InternalUsers');
    }
    
    @IsTest
    private static void testSchedulerWithDatetimes() {
        Test.startTest();
            Datetime dt = Datetime.now().addDays(1);
            String cronExpress = dt.second() + ' '+ dt.minute() + ' ' + dt.hour() + ' ' + dt.day() + ' ' + dt.month() + ' ?';
            ContentDocLinkPrivacyScheduler sched = new ContentDocLinkPrivacyScheduler(Datetime.now().addDays(-5), Datetime.now().addDays(20));
            System.assertEquals(Datetime.now().addDays(-5), sched.dt1);
            System.assertEquals(Datetime.now().addDays(20), sched.dt2);
            String jobId = System.schedule('TestContentDocLinkPrivacyScheduler', cronExpress, sched);
        Test.stopTest();

        List<ContentDocumentLink> linkList = [SELECT Id, Visibility FROM ContentDocumentLink WHERE LinkedEntityId IN (SELECT Id FROM Lead)];
        System.assertEquals(1, linkList.size(), 'There should be only one Content Document Link');
        System.assertEquals('InternalUsers', linkList[0].Visibility, 'The visibility of the Content Document Link should be InternalUsers');
    }
}