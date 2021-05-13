/**
 * Created by Kristin White
 * 
 * Tested by: MessagingServiceTest and InvocableMessagingServiceTest
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
        List<Contact> contactList = infoObject.getContactList();
        List<Id> contactIdList = infoObject.getContactIdList();
        Map<String, String> templateValues = infoObject.getReplacementMap();
        Boolean attachStatus = infoObject.attachmentStatus;
        OrgWideEmailAddress owa = MessagingService.getCustomerCareEmail();
        EmailTemplate emailTemplate = MessagingService.getHtml(templateName);
        String htmlBody = MessagingService.getHtmlWithReplacements(templateName, templateValues);
        List<Messaging.SingleEmailMessage> emailsToSend =  new List<Messaging.SingleEmailMessage>();
        
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
            new List<SObjectType>{Contract.SObjectType, Opportunity.SObjectType});
        
        for(Contact contact: contactList){
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setHtmlBody(htmlBody);
            mail.setOrgWideEmailAddressId(owa.Id);
            mail.setToAddresses(new List<String>{contact.Email});
            mail.setSubject(emailTemplate.Subject);
            mail.setTargetObjectId(contact.Id);
            mail.setSaveAsActivity(true);
            if(attachStatus){
                mail.setEntityAttachments(handleAttachments(contactIdList, contact, uow));
            }
            emailsToSend.add(mail);
        }
        
        uow.commitWork();
        MessagingService.sendEmail(emailsToSend);
        Logger.flushLogs();
    }
    
    private static List<String> handleAttachments(List<Id> contactIdList, Contact contact, fflib_SObjectUnitOfWork uow){
        List<String> attachmentList = new List<String>();
        ContractSelector contractSelector = new ContractSelector();
        ContentDocumentSelector documentSelector = new ContentDocumentSelector();
        
        Map<Id,Contract> contractMap = contractSelector.getContractsWithUnsentAddendumsById(contactIdList);
        MultiMap contactDocMap = documentSelector.selectCountersignedByLinkedEntities(contractMap);
        
        if(contactDocMap.keySet().contains(contact.Id)){
            attachmentList = CollectionUtil.toStrings(contactDocMap.getValues(contact.Id));
            
            Contract currentContract = contractSelector.getSingleContractWithUnsentAddendumsById(contact.Id);
            currentContract.Addendum_Sent_Date__c = Date.today();
            uow.registerDirty(currentContract);
        } else{
            Logger.logLater('InvocableMessagingService', 'sendEmailTemplate', 'Attachment not found for contact: ' + contact.Id);
        }
        
        return attachmentList;
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
        
        @InvocableVariable(
                label='Template Values'
                description='List of FlowMap objects, with the keys being replaced by the value. Include if there are values in the email template that need to be replaced.')
        public List<FlowMap> templateValues;

        @InvocableVariable(label='Include Disclosure Form Attachment? (true/false)'
                description='True if Disclosure Form should be attached to email; False otherwise')
        public Boolean attachmentStatus;
        
        @SuppressWarnings('PMD.EmptyStatementBlock')
        public EmailTemplateSendInfo(){
            // Invocable types need a no-arg constructor
        }
        public EmailTemplateSendInfo(String emailTemplateName, List<Contact>contactList){
            this.emailTemplateName = emailTemplateName;
            this.contactList = contactList;
            this.templateValues = new List<FlowMap>();
            this.attachmentStatus = false;
        }
        public EmailTemplateSendInfo(String emailTemplateName, List<Contact>contactList, List<FlowMap> templateValues){
            this.emailTemplateName = emailTemplateName;
            this.contactList = contactList;
            this.templateValues = templateValues;
            this.attachmentStatus = false;
        }
        public EmailTemplateSendInfo(
                String emailTemplateName, List<Contact>contactList,
                List<FlowMap> templateValues, Boolean attachStat){
            this.emailTemplateName = emailTemplateName;
            this.contactList = contactList;
            this.templateValues = templateValues;
            this.attachmentStatus = attachStat;
        }
        
        public String getTemplateName() {
            return this.emailTemplateName;
        }
        
        public List<Contact> getContactList() {
            return this.contactList;
        }
        
        public List<Id> getContactIdList() {
            List<Id> contactIdList = new List<Id>();
            for(Contact contact : this.contactList){
                contactIdList.add(contact.Id);
            }
            return contactIdList;
        }
        
        public List<FlowMap> getTemplateValues() {
            return this.templateValues;
        }

        public Boolean getAttachmentStatus() {
            return this.attachmentStatus;
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