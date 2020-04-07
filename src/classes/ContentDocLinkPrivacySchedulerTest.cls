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
        Test.setCreatedDate(cv.Id, DateTime.now().addDays(-11));

        ContentDocumentSelector selector = new ContentDocumentSelector();
        Id cdId = selector.getDocumentIdFromVersionId(cv.Id);
        Test.setCreatedDate(cdId, DateTime.now().addDays(-11));
        ContentDocument cd = [SELECT Id, CreatedDate FROM ContentDocument WHERE Id = :cdId];

        Lead l = new Lead(
            FirstName = 'test',
            LastName = 'testerson',
            Company = 'test',
            Email = 'ttesterson@email.com',
            LeadSource = 'Switch'
        );
        insert l;
        

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
            String jobId = System.schedule('TestContentDocLinkPrivacyScheduler', cronExpress, sched);
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id = :jobId];
            System.assertEquals(cronExpress, ct.CronExpression);
            System.assertEquals(0, ct.TimesTriggered);
            System.assertEquals(dt, ct.NextFireTime);
        Test.stopTest();

        List<Error_Log__c> errList = [SELECT Id, Message__c FROM Error_Log__c];
        System.assert(errList.isEmpty(), 'There should be no errors');
        List<ContentDocumentLink> linkList = [SELECT Id, Visibility FROM ContentDocumentLink WHERE LinkedEntityId IN (SELECT Id FROM Lead)];
        System.assertEquals(1, linkList.size(), 'There should be only one Content Document Link');
        System.assertEquals('InternalUsers', linkList[0].Visibility, 'The visibility of the Content Document Link should be InternalUsers');
    }
}