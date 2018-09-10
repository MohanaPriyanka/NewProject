/**
 * Created by mstackhouse on 8/23/2018.
 * Description: Can be used to pull a report and email it to a list of recipients.
 *
 * More information about constructing this method:
 * Get full report in csv format: https://codecracksblog.wordpress.com/2017/04/11/how-to-exportcsvexcel-salesforce-reports-using-apex-and-send-email/
 * Change Report Filters by URL: https://success.salesforce.com/answers?id=90630000000hWv2AAE

 * Test: ReportSenderTest
 */

public without sharing class ReportSender implements Queueable, Database.AllowsCallouts {
    public String reportId;
    public String reportName;
    public List<String> filters;
    public List<String> recipients;
    public String requestor;

    public ReportSender(String reportId, String reportName, List<String> filters, List<String> recipients, String requestor) {
        this.reportId = reportId;
        this.reportName = reportName;
        // order of the filters is important, they need to be in the order shown in the report UI
        this.filters = filters;
        this.recipients = recipients;
        this.requestor = requestor;
    }

    public void execute(QueueableContext context) {
        String reportQuery = getReportQuery();
        ApexPages.PageReference report = new ApexPages.PageReference(reportQuery);
        Messaging.EmailFileAttachment emailFileAttachment = getReportAttachment(report.getContent());
        Messaging.SingleEmailMessage email = getEmailMessage(emailFileAttachment);
        MessagingService.sendEmail(new List<Messaging.SingleEmailMessage>{email});
    }

    @TestVisible
    private Messaging.SingleEmailMessage getEmailMessage(Messaging.EmailFileAttachment emailFileAttachment) {
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        OrgWideEmailAddress senderEmail = [
            SELECT Id, Address
            FROM OrgWideEmailAddress
            WHERE Address = 'noreply@bluewavesolar.com'
            LIMIT 1
        ];
        EmailTemplate template = [
            SELECT Id, HtmlValue, Body, Subject
            FROM EmailTemplate
            WHERE DeveloperName = 'Bill_Report_Request'
        ];
        email.setOrgWideEmailAddressId(senderEmail.Id);
        email.setToAddresses(recipients);
        email.setFileAttachments(new List<Messaging.EmailFileAttachment>{
            emailFileAttachment
        });
        String templateBody = template.HtmlValue;
        templateBody = templateBody.replace('{!requestor}', requestor);
        email.setHtmlBody(templateBody);
        email.setSubject(template.Subject);
        return email;
    }

    @TestVisible
    private Messaging.EmailFileAttachment getReportAttachment(Blob reportContent) {
        Messaging.EmailFileAttachment emailFileAttachment = new Messaging.EmailFileAttachment();
        String today = Datetime.now().format('MM-dd-YYYY');
        emailFileAttachment.setFileName(reportName.replace(' ', '_') + '_' + today + '.csv');

        emailFileAttachment.setBody(reportContent);
        emailFileAttachment.setContentType('text/csv');

        return emailFileAttachment;
    }

    @TestVisible
    private String getReportQuery() {
        String reportQuery = '/' + reportId + '?csv=1';
        Integer i = 0;
        for (String filter : filters ) {
            reportQuery += '&pv' + i + '=' + filter;
            i += 1;
        }

        return reportQuery;
    }
}
