/*************************************************************************************
 * Created By: peteryao on 1/18/19  
 * Description: 
 * Test: 
 *************************************************************************************/
@IsTest
public with sharing class MessagingServiceTest {
    @IsTest
    public static void testGetCustomerCareEmail() {
        OrgWideEmailAddress customerCare = MessagingService.getCustomerCareEmail();
        System.assertEquals('customercare@bluewavesolar.com', customerCare.Address, 'Method should have selected customercare');
    }

    @IsTest
    public static void testSafeAddCC() {
        List<String> ccEmails = new List<String>();
        MessagingService.safeAddCC(null, ccEmails);
        System.assertEquals(0, ccEmails.size());
        MessagingService.safeAddCC('cc@cc.com', ccEmails);
        System.assertEquals(1, ccEmails.size());
    }

    @IsTest
    public static void testSendEmail() {
        System.assertEquals(null, MessagingService.emailsSent);
        Boolean exceptionThrown = false;
        try {
            MessagingService.createAndSendDynamicTemplateEmail(
                'MessagingServiceTest_Inactive_Template',
                'customercare@bluewavesolar.com',
                'Subject',
                new List<String>{'a@b.com', 'c@d.com'},
                'NameField',
                'Peter'
            );
        } catch (Util.BWException bwe) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'Expected exception thrown on using an inactive email template');
        System.assertEquals(null, MessagingService.emailsSent);

        exceptionThrown = false;
        try {
            MessagingService.createAndSendDynamicTemplateEmail(
                'MessagingServiceTest_Missing_Template',
                'customercare@bluewavesolar.com',
                'Subject',
                new List<String>{'a@b.com', 'c@d.com'},
                'NameField',
                'Peter'
            );
        } catch (Util.BWException bwe) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'Expected exception thrown on using a missing email template');
        System.assertEquals(null, MessagingService.emailsSent);

        exceptionThrown = false;
        try {
            MessagingService.createAndSendDynamicTemplateEmail(
                'MessagingServiceTest_Active_Template',
                'customercare@bluewavesolar.com',
                'Subject',
                new List<String>{'a@b.com', 'c@d.com'},
                'NameField',
                'Peter'
            );
        } catch (Util.BWException bwe) {
            exceptionThrown = true;
        }
        System.assert(!exceptionThrown, 'Unexpected exception thrown on using an active email template');
        // Because emails aren't enabled for tests
        // But Messaging Service should save a version of the email sent:
        System.assertEquals(1, MessagingService.emailsSent.size());

        exceptionThrown = false;
        MessagingService.onlyUseActiveTemplates = false;
        try {
            MessagingService.createAndSendDynamicTemplateEmail(
                'MessagingServiceTest_Inactive_Template',
                'customercare@bluewavesolar.com',
                'Subject',
                new List<String>{'a@b.com', 'c@d.com'},
                'NameField',
                'Peter'
            );
        } catch (Util.BWException bwe) {
            exceptionThrown = true;
        }
        System.assert(!exceptionThrown, 'Unexpected exception thrown on using an inactive email template ' +
            'with onlyUseActive set to false');
        // But Messaging Service should save a version of the email sent:
        System.assertEquals(1, MessagingService.emailsSent.size());
    }

    @IsTest
    public static void testGetHtmlWithReplacements() {
        String replaced = MessagingService.getHtmlWithReplacements('MessagingServiceTest_Active_Template', new Map<String, String>{
            'NameField gets replaced' => 'The Replacement'
        });
        System.assert(replaced.contains('The Replacement'));
        System.assert(!replaced.contains('NameField gets replaced'));
    }

    @IsTest
    public static void testLogErrors() {
        // Unfortunately, we can't construct this type:
        // https://salesforce.stackexchange.com/questions/237458/messaging-sendemailresult-type-cannot-be-constructed
        String sendEmailResultJSON = '{"success":false,' +
            '"errors":[{"message":"Unknown error"}]}';

        Messaging.SendEmailResult failedMessageResult =
            (Messaging.SendEmailResult) JSON.deserialize(sendEmailResultJSON, Messaging.SendEmailResult.class);
        MessagingService.logErrors(new List<Messaging.SendEmailResult>{failedMessageResult}, null);
        System.assertEquals(1, Logger.logs.size(), 'Expected one error log to be registered');
        System.assert(Logger.logs.values()[0][0].message.contains('Unknown error'),
            'Expected the mock unknown error, but got: ' + Logger.logs.values()[0][0].message);

    }
    
    @IsTest
    public static void testInvocableMessagingService(){
        List<Contact> contactList = new List<Contact>();
        Contact contactA = new Contact(FirstName = 'Contact A', 
                                       LastName = 'Last', 
                                       Email = 'kwhiteA@bluewavesolar.com');
        Contact contactB = new Contact(FirstName = 'Contact B', 
                                       LastName = 'Last', 
                                       Email = 'kwhiteB@bluewavesolar.com');
        insert (new List<Contact>{contactA, contactB});
        contactList.add(contactA);
        contactList.add(contactB);
        
        List<FlowMap> templateValues = new List<FlowMap>();
        FlowMap tempInput1 = new FlowMap('', 'testSolarFarm');
        FlowMap tempInput2 = new FlowMap('', 'testSolarFarm');
        templateValues.add(tempInput1);
        templateValues.add(tempInput2);
        
        InvocableMessagingService.EmailTemplateSendInfo testInfo = 
            new InvocableMessagingService.EmailTemplateSendInfo(
            'Change in COD Date', contactList, templateValues);
        List<InvocableMessagingService.EmailTemplateSendInfo> emailInfo = 
            new List<InvocablemessagingService.EmailTemplateSendInfo>();
        emailInfo.add(testInfo);
        
        InvocableMessagingService.sendEmailTemplate(emailInfo);
        
        System.assertEquals(2, MessagingService.emailsSent.size(), 'There should be one email sent for each contact in the contactList - in this case 2.');
    }
}