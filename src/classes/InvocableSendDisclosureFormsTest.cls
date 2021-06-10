/**
 * Created by Kristin White
 */
@IsTest
public class InvocableSendDisclosureFormsTest {
    @TestSetup
    public static void testSetup() {
        ContentVersion cv1 = new ContentVersion(
            Title = 'cv1Title.pdf',
            VersionData = EncodingUtil.base64Decode('df'),
            PathOnClient = '/Disclosure_Form.pdf',
            Signing_Status__c = 'Countersigned'
        );
        insert cv1;
        Contact contact1 = new Contact(
            Title = 'testContact01',
            LastName = 'testContactLastName',
            Email = 'bizapptest@bluewavesolar.com'
        );
        insert contact1;
        Account account1 = new Account(
            Name = 'testAccount1',
            Send_Bills_Contact__c = contact1.Id
        );
        insert account1;
        Product2 product1 = new Product2(
            Addendum_Template_Id__c = 'AddendumTestId',
            Name = 'testProd1'
        );
        insert product1;
        Shared_Solar_System__c sss1 = new Shared_Solar_System__c(
            Name = 'testSSS1',
            Address__c = 'testAddress',
            City__c = 'Boston',
            State__c = 'MA',
            Zip_Code__c = '12345',
            Total_System_Size_kWh_DC__c = 10,
            Expected_Yield_kWh_kW__c = 1000
        );
        insert sss1;
        Opportunity opp1 = new Opportunity(
            Product__c = product1.Id,
            StageName = 'opp1StageName',
            Name = 'opp1Name',
            CloseDate = Date.today(),
            Shared_Solar_System__c = sss1.Id
        );
        insert opp1;
        Contract contract1 = new Contract(
            AccountId = account1.Id,
            Addendum_Sent_Date__c = NULL,
            Name = 'testContract1',
            Opportunity__c = opp1.Id,
            Product__c = product1.Id
        );
        insert contract1;
        opp1.ContractId = contract1.Id;
        update opp1;
    }
    
    @IsTest
    public static void testSendDisclosureFormEmail() {
        List<Contract> contractList = [
            SELECT Id, Name, AccountId, Account.Send_Bills_Contact__c, 
            Addendum_Sent_Date__c, Product__r.Addendum_Template_Id__c
            FROM Contract 
            WHERE Name = 'testContract1'
        ];
        List<Shared_Solar_System__c> sssList = [
            SELECT Id, Name, Address__c, City__c, State__c, Zip_Code__c, 
            Total_System_Size_kWh_DC__c, Expected_Yield_kWh_kW__c, Home_Electricity_Offset__c
            FROM Shared_Solar_System__c
            WHERE Name = 'testSSS1'
        ];
        InvocableSendDisclosureForms.EmailAttachmentInfo testInfo = 
            new InvocableSendDisclosureForms.EmailAttachmentInfo(contractList, sssList[0]);
        List<InvocableSendDisclosureForms.EmailAttachmentInfo> emailInfo = 
            new List<InvocableSendDisclosureForms.EmailAttachmentInfo>();
        emailInfo.add(testInfo);
        InvocableSendDisclosureForms.sendDisclosureFormEmail(emailInfo);
        System.assertEquals(1, MessagingService.emailsSent.size());
    }
    
}