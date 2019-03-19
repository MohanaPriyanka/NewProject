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
        System.debug(LoggingLevel.ERROR, customerCare.Address = 'customercare@bluewavesolar.com');
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

}