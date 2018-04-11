/**
 * Created By: Peter Yao
 * Description:  Class that allows us to not send emails if running tests, but instead,
 *               validate the emails that are intended to be sent.
 * Tested by: PostSandboxRefresherTest
 **/

public class MessagingService {
    public static Messaging.Email[] emailsSent;

    @AuraEnabled 
    public static Boolean createAndSendDynamicTemplateEmail(String emailTemplateName, String orgWideEmail, String subjectLine, List<String> addressList, String templateField, String replaceText) {
        EmailTemplate template = getHtml(emailTemplateName);
        String templateHtml = template.HtmlValue;
        templateHtml = templateHtml.replace(templateField, replaceText);

        Messaging.SendEmailResult[] result = createAndSendEmail(templateHtml, orgWideEmail, subjectLine, addressList);
        for(Messaging.SendEmailResult rr : result){
            if(!rr.IsSuccess()){
                return false;
            }
        } 
        return true;
    }

    public static EmailTemplate getHtml (String templateDevName) {
        EmailTemplate template = [SELECT Id, HtmlValue, Body 
                                  FROM EmailTemplate 
                                  WHERE DeveloperName = : templateDevName];
        return template;
    }

    public static Messaging.SendEmailResult[] createAndSendEmail (String htmlBody, String orgWideEmail, String subjectLine, List<String> addressList) {  
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
}