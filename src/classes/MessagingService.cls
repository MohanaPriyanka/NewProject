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
    @TestVisible private static FeatureSelector featureSelector = new FeatureSelector();
    private static CustomLabelResolver labelResolver = new CustomLabelResolver();

    public static OrgWideEmailAddress getCustomerCareEmail() {
        if (customerCareEmail == null) {
            String brand = featureSelector.getSystemDefaults().Default_Client_Brand_Key__c;
            String customerCareBrandedAddress = 'customercare@bluewavesolar.com';
            if (brand == 'Perch') {
                customerCareBrandedAddress = 'customercare@perchenergy.com';
            }
            customerCareEmail = [
                SELECT Id, Address
                FROM OrgWideEmailAddress
                WHERE Address = :customerCareBrandedAddress
                LIMIT 1
            ];
        }
        return customerCareEmail;
    }

    @TestVisible
    private static Boolean createAndSendDynamicTemplateEmail(EmailEnvelope ee) {
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

        return createAndSendEmail(templateHtml, ee);
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
        EmailEnvelope ee = new EmailEnvelope();
        ee.orgWideEmail = orgWideEmail;
        ee.subjectLine = subjectLine;
        ee.addressList = addressList;
        ee.sobjectId = null;
        return createAndSendEmail(htmlBody, ee);
    }
    @SuppressWarnings('PMD.ApexCRUDViolation')
    private static Messaging.SendEmailResult[] createAndSendEmail(String htmlBody, EmailEnvelope ee) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        for (OrgWideEmailAddress senderEmail : [
            SELECT Id, Address
            FROM OrgWideEmailAddress
            WHERE Address = :ee.orgWideEmail
            LIMIT 1
        ]) {
            mail.setOrgWideEmailAddressId(senderEmail.Id);
        }
        mail.setSubject(ee.subjectLine);
        mail.setHtmlBody(htmlBody);
        mail.setToAddresses(ee.addressList);
        if (ee.sobjectId != null) {
            mail.setTargetObjectId(ee.sobjectId);
            mail.setSaveAsActivity(true);
        }
        return sendEmail(new List<Messaging.SingleEmailMessage>{
            mail
        });
    }

    public static Messaging.SendEmailResult[] sendEmail(List<Messaging.Email> emails) {
        List<Messaging.Email> emailsWithLabelsResolved = getEmailsWithLabelsResolved(emails);
        List<Messaging.SendEmailResult> sendEmailResults;
        if (emailsSent == null) {
            emailsSent = emailsWithLabelsResolved.clone();
        } else {
            emailsSent.addAll(emailsWithLabelsResolved.clone());
        }
        try {
            sendEmailResults = Messaging.sendEmail(emailsWithLabelsResolved, false);
        } catch (EmailException ee) {
            Logger.logNow('MessagingService', 'sendEmail', ee.getMessage());
        }
        Logger.flushLogs();
        return sendEmailResults;
    }

    @TestVisible
    private static List<Messaging.Email> getEmailsWithLabelsResolved(List<Messaging.Email> emails) {
        List<Messaging.Email> emailsWithLabelsResolved = new List<Messaging.Email>();
        for (Messaging.Email email : emails) {
            try {
                Messaging.SingleEmailMessage singleEmailMessage = (Messaging.SingleEmailMessage) email;
                singleEmailMessage.setSubject(labelResolver.resolve(singleEmailMessage.getSubject()));
                singleEmailMessage.setHtmlBody(labelResolver.resolve(singleEmailMessage.getHtmlBody()));
                singleEmailMessage.setPlainTextBody(labelResolver.resolve(singleEmailMessage.getPlainTextBody()));
                emailsWithLabelsResolved.add((Messaging.Email) singleEmailMessage);
            } catch (Util.BWException bwe) {
                Logger.logLater('MessagingService', 'getEmailsWithLabelsResolved', bwe.getMessage() + '\n' + bwe.getStackTraceString(), Logger.ERROR);
            }
        }
        return emailsWithLabelsResolved;
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