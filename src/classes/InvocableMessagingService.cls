/**
 * Created by Kristin White
 * 
 * Tested by: MessagingServiceTest
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class InvocableMessagingService {
    /**
     * @description Sends the email template with the updated values to the contacts given
     * @param emailInfo is a list with one EmailTemplateSendInfo object 
     * The EmailTemplateSendInfo object has the name of the template, the values to replace in the template, 
     * and the contacts to send the email to.
     */
    @InvocableMethod(label='Invocable Messaging Service')
    public static void sendEmailTemplate(List<EmailTemplateSendInfo> emailInfo) {
        EmailTemplateSendInfo infoObject = emailInfo[0];
        String templateName = infoObject.getTemplateName();
        List<Contact> contactList = infoObject.getcontactList();
        Map<String, String> templateValues = infoObject.getReplacementMap();
        
        OrgWideEmailAddress owa = MessagingService.getCustomerCareEmail();
        EmailTemplate emailTemplate = MessagingService.getHtml(templateName);
        String htmlBody = MessagingService.getHtmlWithReplacements(templateName, templateValues);
        List<Messaging.SingleEmailMessage> emailsToSend =  new List<Messaging.SingleEmailMessage>();
        
        for(Contact contact: contactList){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setHtmlBody(htmlBody);
            mail.setOrgWideEmailAddressId(owa.Id);
            mail.setToAddresses(new List<String>{contact.Email});
            mail.setSubject(emailTemplate.Subject);
            mail.setTargetObjectId(contact.Id);
            mail.setSaveAsActivity(true);
            emailsToSend.add(mail);
        }
        MessagingService.sendEmail(emailsToSend);
    }
    
    public class EmailTemplateSendInfo {
        @InvocableVariable(label='Email Template Name' 
                           description='The name of the Email Template' 
                           required=true)
        public String emailTemplateName;
        
        @InvocableVariable(label='Contact List' 
                           description='A list of Contact objects to send the email to' 
                           required=true)
        public List<Contact> contactList;
        
        @InvocableVariable(label='Template Values' 
                           description='List of FlowMap objects, with the keys being replaced by the value')
        public List<FlowMap> templateValues;
        
        public EmailTemplateSendInfo(String emailTemplateName, List<Contact>contactList, List<FlowMap> templateValues){
            this.emailTemplateName = emailTemplateName;
            this.contactList = contactList;
            this.templateValues = templateValues;
        }
        
        public String getTemplateName() {
            return this.emailTemplateName;
        }
        
        public List<Contact> getContactList() {
            return this.contactList;
        }
        
        public List<FlowMap> getTemplateValues() {
            return this.templateValues;
        }
        
        public Map<String, String> getReplacementMap() {
            Map<String, String> valMap = new Map <String, String>();
            for(FlowMap pair: this.templateValues){
                valMap.put(pair.key, pair.value);
            }
            return valMap;
        }
    }
}