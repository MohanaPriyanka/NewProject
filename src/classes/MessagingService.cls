/**
 * Created By: Peter Yao
 * Description:  Class that allows us to not send emails if running tests, but instead,
 *               validate the emails that are intended to be sent.
 * Tested by: MessagingServiceTest
 **/

public class MessagingService {
    private static OrgWideEmailAddress customerCareEmail;
    private static Map<String, EmailTemplate> emailTemplateMap = new Map<String, EmailTemplate>();
    public static Messaging.Email[] emailsSent;

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

    public static Boolean createAndSendDynamicTemplateEmail(String emailTemplateName, String orgWideEmail, String subjectLine, List<String> addressList, String templateField, String replaceText) {
        EmailEnvelope ee = new EmailEnvelope();
        ee.emailTemplateName = emailTemplateName;
        ee.orgWideEmail = orgWideEmail;
        ee.subjectLine = subjectLine;
        ee.addressList = addressList;
        ee.replacementTexts = new List<ReplacementText>{new ReplacementText(templateField, replaceText)};
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

    public static String getHtmlWithReplacements (String templateName, Map<String, String> keyToValueMap) {
        String htmlValue = getHtml(templateName).HtmlValue;
        for (String key : keyToValueMap.keySet()) {
            htmlValue = htmlValue.replace(key, keyToValueMap.get(key)==null?'':keyToValueMap.get(key));
        }
        return htmlValue;
    }

    @TestVisible
    private static Boolean onlyUseActiveTemplates = true;
    public static EmailTemplate getHtml (String templateName) {
        if (emailTemplateMap.get(templateName) == null) {
            List<EmailTemplate> templates = [
                SELECT Id, HtmlValue, Body
                FROM EmailTemplate
                WHERE DeveloperName = :templateName
                AND (IsActive = TRUE OR IsActive = : onlyUseActiveTemplates)
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

    public static Messaging.SendEmailResult[] createAndSendEmail (String htmlBody, String orgWideEmail, String subjectLine, List<String> addressList) {
        return createAndSendEmail(htmlBody, orgWideEmail, subjectLine, addressList, null);
    }
    public static Messaging.SendEmailResult[] createAndSendEmail (String htmlBody, String orgWideEmail, String subjectLine, List<String> addressList, Id sobjectId) {
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        for (OrgWideEmailAddress senderEmail : [SELECT Id, Address 
                                                FROM OrgWideEmailAddress
                                                WHERE Address = : orgWideEmail 
                                                LIMIT 1]) {
          mail.setOrgWideEmailAddressId(senderEmail.Id); 
        }  
        mail.setSubject(subjectLine);
        mail.setHtmlBody(htmlBody);
        mail.setToAddresses(addressList);
        if (sobjectId != null) {
            mail.setTargetObjectId(sobjectId);
            mail.setSaveAsActivity(true);
        }
        return sendEmail(new List<Messaging.SingleEmailMessage>{mail}); 
    }

    public static Messaging.SendEmailResult[] sendEmail(Messaging.Email[] emails) {
        Messaging.SendEmailResult[] sendEmailResults;
        emailsSent = emails.clone();
        try {
            sendEmailResults = Messaging.sendEmail(emails, false);
        } catch (EmailException ee) {Logger.logNow('MessagingService', 'sendEmail', ee.getMessage());}
        return sendEmailResults;
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