/*************************************************************************************
 * Created By: peteryao on 1/18/19  
 * Description: 
 * Test: 
 *************************************************************************************/
@IsTest
public with sharing class MessagingServiceTest {
    @IsTest
    public static void testGetCustomerCareEmail() {
        System_Default__mdt systemDefaultWithPerchBrandKey = new System_Default__mdt(
            Default_Client_Brand_Key__c = 'Perch'
        );
        MessagingService.featureSelector =
            (FeatureSelector) Test.createStub(FeatureSelector.class, new FeatureServiceTest.MockCustomFeatureSelector(systemDefaultWithPerchBrandKey));
        OrgWideEmailAddress customerCare = MessagingService.getCustomerCareEmail();
        System.assertEquals('customercare@perchenergy.com', customerCare.Address, 'Method should have selected customercare');
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
        MessagingService.EmailEnvelope ee = new MessagingService.EmailEnvelope();
        ee.orgWideEmail = 'customercare@bluewavesolar.com';
        ee.subjectLine = 'Subject';
        ee.addressList = new List<String>{'a@b.com', 'c@d.com'};
        ee.replacementTexts = new List<MessagingService.ReplacementText>{
            new MessagingService.ReplacementText('NameField', 'Peter')
        };
        ee.sobjectId = null;
        try {
            ee.emailTemplateName = 'MessagingServiceTest_Inactive_Template';
            MessagingService.createAndSendDynamicTemplateEmail(ee);
        } catch (Util.BWException bwe) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'Expected exception thrown on using an inactive email template');
        System.assertEquals(null, MessagingService.emailsSent);

        exceptionThrown = false;
        try {
            ee.emailTemplateName = 'MessagingServiceTest_Missing_Template';
            MessagingService.createAndSendDynamicTemplateEmail(ee);
        } catch (Util.BWException bwe) {
            exceptionThrown = true;
        }
        System.assert(exceptionThrown, 'Expected exception thrown on using a missing email template');
        System.assertEquals(null, MessagingService.emailsSent);

        exceptionThrown = false;
        try {
            ee.emailTemplateName = 'MessagingServiceTest_Active_Template';
            MessagingService.createAndSendDynamicTemplateEmail(ee);
        } catch (Util.BWException bwe) {
            exceptionThrown = true;
        }
        System.assert(!exceptionThrown, 'Unexpected exception thrown on using an active email template');
        // Because emails aren't enabled for tests
        // But Messaging Service should save a version of the email sent:
        System.assertEquals(1, MessagingService.emailsSent.size());

        exceptionThrown = false;
        MessagingService.onlyUseActiveTemplates = false;
        MessagingService.emailsSent = null;
        try {
            ee.emailTemplateName = 'MessagingServiceTest_Inactive_Template';
            MessagingService.createAndSendDynamicTemplateEmail(ee);
        } catch (Util.BWException bwe) {
            exceptionThrown = true;
        }
        System.assert(!exceptionThrown, 'Unexpected exception thrown on using an inactive email template ' +
            'with onlyUseActive set to false');
        // But Messaging Service should save a version of the email sent:
        System.assertEquals(1, MessagingService.emailsSent.size());

        MessagingService.emailsSent = null;
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        mail.setHtmlBody('Test of {!$Label.MissingLabel}');
        mail.setToAddresses(new List<String>{'a@b.com', 'c@d.com'});
        mail.setOrgWideEmailAddressId(MessagingService.getCustomerCareEmail().Id);
        Messaging.SingleEmailMessage mail2 = new Messaging.SingleEmailMessage();
        mail2.setHtmlBody('Test of {!$Label.Company_Name}');
        mail2.setToAddresses(new List<String>{'e@f.com'});
        mail2.setOrgWideEmailAddressId(MessagingService.getCustomerCareEmail().Id);

        MessagingService.sendEmail(new List<Messaging.Email>{mail, mail2});
        List<Error_Log__c> errorLogs = [
            SELECT Id, Message__c
            FROM Error_Log__c
            WHERE Severity__c = :Logger.ERROR
            AND Class__c = 'MessagingService'
        ];
        System.assertEquals(1, errorLogs.size(),
            'Expected one error log when finding a label the CustomLabelResolver could not be resolve, but got: ' + errorLogs);
        System.assert(errorLogs[0].Message__c.contains('Unknown label found'), errorLogs[0].Message__c);
        System.assertEquals(1, MessagingService.emailsSent.size(), 'Expected MessagingService to send one email');
        Messaging.SingleEmailMessage singleEmailMessage = (Messaging.SingleEmailMessage) MessagingService.emailsSent[0];
        System.assertEquals(singleEmailMessage.getToAddresses(), mail2.getToAddresses(), 'Expected mail2 to be sent to e@f.com');
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
        FlowMap tempInput1 = new FlowMap('<solar farm name>', 'testSolarFarm');
        FlowMap tempInput2 = new FlowMap('<season/year>', 'testSeason');
        templateValues.add(tempInput1);
        templateValues.add(tempInput2);
        
        InvocableMessagingService.EmailTemplateSendInfo testInfo = 
            new InvocableMessagingService.EmailTemplateSendInfo(
            'MessagingServiceTest_Active_Template', contactList, templateValues);
        List<InvocableMessagingService.EmailTemplateSendInfo> emailInfo = 
            new List<InvocablemessagingService.EmailTemplateSendInfo>();
        emailInfo.add(testInfo);
        
        InvocableMessagingService.sendEmailTemplate(emailInfo);
        
        System.assertEquals(2, MessagingService.emailsSent.size(), 'There should be one email sent for each contact in the contactList - in this case 2.');
    }
    
}