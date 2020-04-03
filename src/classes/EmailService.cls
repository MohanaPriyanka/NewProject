/**
 * Created by mstackhouse on 2/15/2019.
 * Description: Used to extend MessagingService with the specific emails we need to send through apex.
 *      Most of these emails use custom APEX replacement to build the HTML body and therefore need a
 *      little more logic than just selecting the email and sending it
 * Test: EmailServiceTest
 */


public without sharing class EmailService {
    @TestVisible
    private static OrgWideEmailAddress customerCareAddress = MessagingService.getCustomerCareEmail();
    @TestVisible
    private static EmailTemplate doerEmailTemplate;
    @TestVisible
    private static EmailTemplate standardEmailTemplate;
    @TestVisible
    private static EmailTemplate denialEmailTemplate;
    @TestVisible
    private static EmailTemplate coAppDenialEmailTemplate;
    @TestVisible
    private static EmailTemplate csCustomerRequestPaymentInfo;
    @TestVisible
    private static List<Messaging.SingleEmailMessage> emailsToSend = new List<Messaging.SingleEmailMessage>();

    public static String getCSCustomerRequestPaymentInfoHtml() {
        if (csCustomerRequestPaymentInfo == null) {
            csCustomerRequestPaymentInfo = [SELECT Id, HtmlValue, Body, TemplateType, Subject
            FROM EmailTemplate
            WHERE DeveloperName = 'X19_0227_CSAP_Payment_Email'
            LIMIT 1];
        }
        return csCustomerRequestPaymentInfo.HtmlValue;
    }

    public static Messaging.SendEmailResult[] sendMessages() {
        Messaging.SendEmailResult[] resilts = MessagingService.sendEmail(emailsToSend);
        emailsToSend = new List<Messaging.SingleEmailMessage>();
        return resilts;
    }

    public static void createCSCustomerRequestPaymentInfoEmails(List<Lead> leads) {
        emailsToSend = new List<Messaging.SingleEmailMessage>();
        for (Lead lead : leads) {
            String firstName = lead.FirstName;

            String continueApplicationUrl = lead.Continue_Application_Link__c;
            if (continueApplicationUrl == null) {
                continueApplicationUrl = Util.getCommunitySiteURL('Apply') + '/s/csap-payment?leadId=' + lead.Id;
            }

            String htmlbody = getCSCustomerRequestPaymentInfoHtml();
            String subject = csCustomerRequestPaymentInfo.Subject;
            htmlBody = htmlBody.replace('{!Lead.Continue_Application_Link__c}', continueApplicationUrl);
            htmlBody = htmlBody.replace('{!Lead.FirstName}', firstName);
            Messaging.SingleEmailMessage emailMessage =
                createCustomSingleMessage(subject, htmlBody, lead.Partner_Email__c, lead.Id);
            emailsToSend.add(emailMessage);
        }
    }

    private static Messaging.SingleEmailMessage createCustomSingleMessage(
            String subjectLine,
            String body,
            String partnerEmail,
            Id targetObjectId
    ) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setHtmlBody(body);
        mail.setOrgWideEmailAddressId(customerCareAddress.Id);

        if (partnerEmail != NULL) {
            String[] ccAddresses = new String[] {partnerEmail};
            mail.setccAddresses(ccAddresses);
        }

        mail.setSubject(subjectLine);
        mail.setTargetObjectId(targetObjectId);
        return mail;
    }
}