/**
 * Created by Kristin White
 * 
 * Tested by: MessagingServiceTest and InvocableSendDisclosureFormTest
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class InvocableSendDisclosureForms {
    /**
     * @description Sends the 'Project Assignment (Hybrid MA Product)' email template with the updated values and required attached documents to the contact related to the given contract
     * @param emailInfo is a list with one EmailAttachmentInfo object 
     * The EmailAttachmentInfo object has the list of contracts to send emails to and the related Shared Solar System
     */
    @InvocableMethod(label='Invocable Send Disclosure Forms')
    public static void sendDisclosureFormEmail(List<EmailAttachmentInfo> emailInfo) {
        EmailAttachmentInfo infoObject = emailInfo[0];
        String templateName = 'Project Assignment (Hybrid MA Product)';
        Shared_Solar_System__c sss = infoObject.getSSS();
        Map<Id, Contract> contractMap = infoObject.getContractMap();
        Map<String, String> templateValues = getProjectAssignmentTemplateValues(sss);
        OrgWideEmailAddress owa = MessagingService.getCustomerCareEmail();
        EmailTemplate emailTemplate = MessagingService.getHtml(templateName);
        String htmlBody = MessagingService.getHtmlWithReplacements(templateName, templateValues);
        List<Messaging.SingleEmailMessage> emailsToSend =  new List<Messaging.SingleEmailMessage>();
        ContractSelector contractSelector = new ContractSelector();
        ContentDocumentSelector documentSelector = new ContentDocumentSelector();
        
        fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
            new List<SObjectType>{Contract.SObjectType});
        
        Map<Id,Contract> contractsForSend = contractSelector.getContractsForAddendumMapById(contractMap.keySet());
        MultiMap contactDocMap = documentSelector.selectCountersignedByLinkedEntities(contractsForSend);
        Map<Id,Contact> contractToContactMap = ContactSelector.selectMultipleSendBillsContactByContracts(contractsForSend.keySet());
        
        for(Contract contract: contractsForSend.values()){
            if(contract.Addendum_Sent_Date__c != null || contract.Product__r.Addendum_Template_Id__c == null){
                Logger.logLater('InvocableSendDisclosureForms', 'sendDisclosureFormEmail', 'Contract either has an Addendum Sent Date or does not have a related Product Addendum Template Id for contract: ' + contract.Id);
            }
            Contact currentContact = contractToContactMap.get(contract.Id);
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            mail.setHtmlBody(htmlBody);
            mail.setOrgWideEmailAddressId(owa.Id);
            mail.setToAddresses(new List<String>{currentContact.Email});
            mail.setSubject(emailTemplate.Subject);
            mail.setTargetObjectId(currentContact.Id);
            mail.setSaveAsActivity(true);
            mail.setEntityAttachments(registerContractsForAttachmentsSent(contract, currentContact, contactDocMap, uow));
            emailsToSend.add(mail);
        }
        uow.commitWork();
        MessagingService.sendEmail(emailsToSend);
        Logger.flushLogs();
    }
    
    private static List<String> registerContractsForAttachmentsSent(Contract recievedContract, Contact contact, MultiMap contactDocMap, fflib_SObjectUnitOfWork uow){
        List<String> attachmentList = new List<String>();
        if(contactDocMap.keySet().contains(contact.Id)){
            attachmentList = CollectionUtil.toStrings(contactDocMap.getValues(contact.Id));
            recievedContract.Addendum_Sent_Date__c = Date.today();
            uow.registerDirty(recievedContract);
        } else{
            Logger.logLater('InvocableSendDisclosureForms', 'registerContractsForAttachmentsSent', 'Attachment not found for contact: ' + contact.Id);
        }
        return attachmentList;
    }
    
    public static Map<String, String> getProjectAssignmentTemplateValues(Shared_Solar_System__c sss){
        Map<String, String> valMap = new Map <String, String>();
        valMap.put('%%SSSName%%', sss.Name);
        valMap.put('%%SSSAddress%%', sss.Address__c);
        valMap.put('%%SSSCity%%', sss.City__c);
        valMap.put('%%SSSState%%', sss.State__c);
        valMap.put('%%SSSZip%%', sss.Zip_Code__c);
        valMap.put('%%SSSKwDC%%', sss.Total_System_Size_kWh_DC__c.toPlainString());
        valMap.put('%%SSSHomeOffset%%', sss.Home_Electricity_Offset__c.toPlainString());
        return valMap;
    }
    
    public class EmailAttachmentInfo {
        @InvocableVariable(label='Contract List' 
                           description='A list of Contract objects to send the email to' 
                           required=true)
        public List<Contract> contracts;
        
        @InvocableVariable(label='Related Shared Solar System' 
                           description='The Shared Solar System object for the Project Assignment (Hybrid MA Product) email template values'
                           required=true)
        public Shared_Solar_System__c sss;
        
        @SuppressWarnings('PMD.EmptyStatementBlock')
        public EmailAttachmentInfo(){
            // Invocable types need a no-arg constructor
        }
        public EmailAttachmentInfo(List<Contract> givenContractList, Shared_Solar_System__c givenSSS){
            this.contracts = givenContractList;
            this.sss = givenSSS;
        }
        
        public Shared_Solar_System__c getSSS() {
            return this.sss;
        }
        
        public List<Contract> getContractList() {
            return this.contracts;
        }
        
        public Map<Id, Contract> getContractMap() {
            return new Map<Id, Contract>(this.contracts);
        }
    }
    
}