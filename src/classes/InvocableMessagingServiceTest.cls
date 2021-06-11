/**
 * Created by Kristin White
 */
@IsTest
public class InvocableMessagingServiceTest {
    @TestSetup
    public static void testSetup() {
        Contact contact1 = new Contact(
            Title = 'testContact01',
            LastName = 'testContactLastName'
        );
        insert contact1;
        
        Account account1 = new Account(
            Name = 'testAccount1',
            Send_Bills_Contact__c = contact1.Id
        );
        insert account1;
        
        Contract contract1 = new Contract(
            AccountId = account1.Id,
            Addendum_Sent_Date__c = NULL,
            Name = 'testContract1'
        );
        insert contract1;
        
        Product2 product1 = new Product2(
            Addendum_Template_Id__c = 'AddendumTestId',
            Name = 'testProd1'
        );
        insert product1;
        
        Opportunity opportunity1 = new Opportunity(
            ContractId = contract1.Id,
            Product__c = product1.Id,
            StageName = 'opp1StageName',
            Name = 'opp1Name',
            CloseDate = Date.today()
        );
        insert opportunity1;
        
        ContentVersion cv1 = new ContentVersion(
            Title = 'cv1Title.pdf',
            VersionData = EncodingUtil.base64Decode('df'),
            PathOnClient = '/Disclosure_Form.pdf',
            Signing_Status__c = 'Countersigned'
        );
        insert cv1;  
    }
    
    @IsTest
    public static void testSendEmailTemplate(){
        List<Contact> contactList = [SELECT Id, Title, Email FROM Contact WHERE Title = 'testContact01'];
        
        List<Contract> contractList = [
            SELECT Id, Name, AccountId, Account.Send_Bills_Contact__r.Id, Addendum_Sent_Date__c
            FROM Contract 
            WHERE Name = 'testContract1'
        ];
        List<ContentVersion> cvList = [
            SELECT Id, ContentDocumentId, ContentDocument.ContentSize, Signing_Status__c
            FROM ContentVersion
            WHERE Title = 'cv1Title.pdf'
            ORDER BY Title
        ];
        ContentVersion cv = cvList[0];
        ContentDocumentLink linkOne = new ContentDocumentLink(LinkedEntityId = contractList[0].Id, ContentDocumentId = cv.ContentDocumentId);
        insert linkOne;
        
        InvocableMessagingService.EmailTemplateSendInfo infoObj1 = new InvocableMessagingService.EmailTemplateSendInfo('Welcome Email', contactList);

        List<InvocableMessagingService.EmailTemplateSendInfo> sendInfoList = new List<InvocableMessagingService.EmailTemplateSendInfo>{infoObj1};
        InvocableMessagingService.sendEmailTemplate(sendInfoList);
        System.assertEquals(1, MessagingService.emailsSent.size());
        
        Contract resultContract1 = [
            SELECT Id, Name, AccountId, Account.Send_Bills_Contact__r.Id, Addendum_Sent_Date__c
            FROM Contract 
            WHERE Id =: contractList[0].Id];
        
        System.assertEquals(null, resultContract1.Addendum_Sent_Date__c, 'The Addendum Sent Date should still be null becuase there were no attachments in the previous send.');
        
        InvocableMessagingService.EmailTemplateSendInfo infoObj2 = new InvocableMessagingService.EmailTemplateSendInfo('Welcome Email', contactList, new List<FlowMap>());
        List<InvocableMessagingService.EmailTemplateSendInfo> sendInfoList2 = new List<InvocableMessagingService.EmailTemplateSendInfo>{infoObj2};
        InvocableMessagingService.sendEmailTemplate(sendInfoList2);
        System.assertEquals(1, MessagingService.emailsSent.size());
    }
    
}