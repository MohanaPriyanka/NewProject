/**
 * Created by mstackhouse on 8/23/2018.
 * Description: test for ReportSender
 *
 */


@IsTest
private class ReportSenderTest {
    @IsTest (SeeAllData=true)
    static void testCanSendReport() {
        Account clientAccount = new Account(Name = 'Client Account');
        insert clientAccount;

        Contact clientContact = new Contact(
            FirstName = 'First',
            Email = 'clientContact@bluewave-capital.com',
            LastName = 'Last',
            AccountId = clientAccount.Id
        );
        insert clientContact;

        User clientUser = new User (
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'CS Client Partner Login'].Id,
            FirstName = 'TEst99823323',
            LastName = 'Blue',
            Username = 'TEst99823323@bluewavesolar.com',
            Email = 'clientUser@test.com',
            Alias = 'TEst998',
            ContactId = clientContact.Id,
            CommunityNickname = 'TEst998',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'ISO-8859-1',
            LanguageLocaleKey = 'en_US'
        );

        Util.insertSObj(clientUser);

        Report report = [
            SELECT Id, DeveloperName
            FROM Report
            WHERE DeveloperName = 'LightningReportsTestReport'
            LIMIT 1
        ];


        List<String> recipients = new List<String>{'test@bluewavesolar.com'};
        String reportName = report.DeveloperName;
        ReportSender sender = new ReportSender(report.Id, reportName, new List<String>{}, recipients, 'requestor');

        String reportQuery = sender.getReportQuery();

        String expectedQuery = '/' + report.Id + '?csv=1';
        System.assertEquals(expectedQuery, reportQuery);

        sender.filters = new List<String>{'filter1', 'filter2', 'filter3'};

        String reportQuery2 = sender.getReportQuery();

        String expectedQuery2 = '/' + report.Id + '?csv=1' + '&pv0=filter1&pv1=filter2&pv2=filter3';
        System.assertEquals(expectedQuery2, reportQuery2);

        // test methods do not allow callouts to ApexPages.PageReference, so we have to fake the content
        Blob reportContent = Blob.valueOf('report content!');

        Messaging.EmailFileAttachment attachment = sender.getReportAttachment(reportContent);

        String today = Datetime.now().format('MM-dd-YYYY');
        System.assertEquals(reportName + '_' + today + '.csv', attachment.getFileName());

        Messaging.SingleEmailMessage email = sender.getEmailMessage(attachment);

        System.assertEquals(recipients, email.getToAddresses());
        System.assertEquals(1, email.getFileAttachments().size());
        System.assertEquals(attachment, email.getFileAttachments()[0]);

        OrgWideEmailAddress senderEmail = [
            SELECT Id, Address
            FROM OrgWideEmailAddress
            WHERE Address = 'noreply@bluewavesolar.com'
            LIMIT 1
        ];

        System.assertEquals(senderEmail.Id, email.getOrgWideEmailAddressId());
    }
}