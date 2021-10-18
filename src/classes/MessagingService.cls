/**
 * Created By: Peter Yao
 * Description:  Class that allows us to not send emails if running tests, but instead,
 *               validate the emails that are intended to be sent.
 * Tested by: MessagingServiceTest
 **/

public without sharing class MessagingService {
    private static OrgWideEmailAddress customerCareEmail;
    @TestVisible private static Map<String, EmailTemplate> emailTemplateMap = new Map<String, EmailTemplate>();
    @TestVisible private static Messaging.Email[] emailsSent;
    @TestVisible private static Boolean onlyUseActiveTemplates = true;

    public static OrgWideEmailAddress getCustomerCareEmail() {
        if (customerCareEmail == null) {
            customerCareEmail = [
                SELECT Id, Address
                FROM OrgWideEmailAddress
                WHERE Address = 'customercare@bluewavesolar.com'
                LIMIT 1
            ];
        }
        return customerCareEmail;
    }

    @TestVisible
    private static Boolean createAndSendDynamicTemplateEmail(String emailTemplateName, String orgWideEmail, String subjectLine, List<String> addressList, String templateField, String replaceText) {
        EmailEnvelope ee = new EmailEnvelope();
        ee.emailTemplateName = emailTemplateName;
        ee.orgWideEmail = orgWideEmail;
        ee.subjectLine = subjectLine;
        ee.addressList = addressList;
        ee.replacementTexts = new List<ReplacementText>{
            new ReplacementText(templateField, replaceText)
        };
        ee.sobjectId = null;
        Messaging.SendEmailResult[] result = sendEmailTemplate(ee);
        for (Messaging.SendEmailResult rr : result) {
            if (!rr.isSuccess()) {
                return false;
            }
        }
        return true;
    }

    public static Messaging.SendEmailResult[] sendEmailTemplate(EmailEnvelope ee) {
        EmailTemplate template = getHtml(ee.emailTemplateName);
        String templateHtml = template.HtmlValue;
        if (ee.replacementTexts != null) {
            for (ReplacementText rt : ee.replacementTexts) {
                templateHtml = templateHtml.replace(rt.pattern, rt.replacement);
            }
        }

        return createAndSendEmail(templateHtml, ee.orgWideEmail, ee.subjectLine, ee.addressList, ee.sobjectId);
    }

    public static String getHtmlWithReplacements(String templateName, Map<String, String> keyToValueMap) {
        String htmlValue = getHtml(templateName).HtmlValue;
        for (String key : keyToValueMap.keySet()) {
            htmlValue = htmlValue.replace(key, keyToValueMap.get(key) == null ? '' : keyToValueMap.get(key));
        }
        return htmlValue;
    }

    @SuppressWarnings('PMD.ApexCRUDViolation')
    public static EmailTemplate getHtml(String templateName) {
        if (emailTemplateMap.get(templateName) == null) {
            List<EmailTemplate> templates = [
                SELECT Id, HtmlValue, Body, Subject
                FROM EmailTemplate
                WHERE (DeveloperName = :templateName OR Name = :templateName)
                AND (IsActive = TRUE OR IsActive = :onlyUseActiveTemplates)
                LIMIT 1
            ];
            if (templates.isEmpty()) {
                throw new Util.BWException('Template (' + templateName + ') not found or not active');
            }
            emailTemplateMap.put(templateName, templates[0]);
        }
        return emailTemplateMap.get(templateName);
    }

    public static void safeAddCC(String ccEmail, List<String> ccEmails) {
        if (ccEmail != null) {
            ccEmails.add(ccEmail);
        }
    }

    public static Messaging.SendEmailResult[] createAndSendEmail(String htmlBody, String orgWideEmail, String subjectLine, List<String> addressList) {
        return createAndSendEmail(htmlBody, orgWideEmail, subjectLine, addressList, null);
    }
    @SuppressWarnings('PMD.ApexCRUDViolation')
    public static Messaging.SendEmailResult[] createAndSendEmail(String htmlBody, String orgWideEmail, String subjectLine, List<String> addressList, Id sobjectId) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        for (OrgWideEmailAddress senderEmail : [
            SELECT Id, Address
            FROM OrgWideEmailAddress
            WHERE Address = :orgWideEmail
            LIMIT 1
        ]) {
            mail.setOrgWideEmailAddressId(senderEmail.Id);
        }
        mail.setSubject(subjectLine);
        mail.setHtmlBody(htmlBody);
        mail.setToAddresses(addressList);
        if (sobjectId != null) {
            mail.setTargetObjectId(sobjectId);
            mail.setSaveAsActivity(true);
        }
        return sendEmail(new List<Messaging.SingleEmailMessage>{
            mail
        });
    }

    public static Messaging.SendEmailResult[] sendEmail(Messaging.Email[] emails) {
        Messaging.SendEmailResult[] sendEmailResults;
        if (emailsSent == null) {
            emailsSent = emails.clone();
        } else {
            emailsSent.addAll(emails.clone());
        }
        try {
            sendEmailResults = Messaging.sendEmail(emails, false);
        } catch (EmailException ee) {
            Logger.logNow('MessagingService', 'sendEmail', ee.getMessage());
        }
        return sendEmailResults;
    }

    /**
     * @description Registers Error Logs for unsuccessful SendEmailResults
     * @param sendEmailResults List of SendEmailResults from Messaging.sendEmail()
     * @param prefix A prefix to make it easier to identify the source of the email
     */
    public static void logErrors(List<Messaging.SendEmailResult> sendEmailResults, String prefix) {
        for (Messaging.SendEmailResult rr : sendEmailResults) {
            if (!rr.isSuccess()) {
                logErrorsIgnoringBounces(rr, prefix);
            }
        }
    }

    /**
     * @description We want to ignore bounces since they are handled by BouncedEmailCaseCreationScheduler
     * @param sendEmailResult SendEmailResult
     * @param prefix The class or method that is checking SendEmailResults
     */
    private static void logErrorsIgnoringBounces(Messaging.SendEmailResult sendEmailResult, String prefix) {
        for (Messaging.SendEmailError error : sendEmailResult.getErrors()) {
            if (error.getMessage() != null && !error.getMessage().contains('email address has bounced')) {
                Logger.logLater('MessagingService', 'logErrors', prefix + ': ' + error.getMessage(), Logger.ERROR);
            }
        }
    }

    public class EmailEnvelope {
        public String emailTemplateName;
        public String orgWideEmail;
        public String subjectLine;
        public List<String> addressList;
        public List<ReplacementText> replacementTexts;
        public Id sobjectId;
    }

    public class ReplacementText {
        public String pattern;
        public String replacement;

        public ReplacementText(String pattern, String replacement) {
            this.pattern = pattern;
            this.replacement = replacement;
        }
    }
}