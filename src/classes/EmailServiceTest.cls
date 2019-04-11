/**
 * Created by mstackhouse on 2/15/2019.
 * Description: 
 * Test: 
 */

@IsTest
public with sharing class EmailServiceTest {
    @IsTest
    public static void testGetCSCustomerRequestPaymentInfoHtml() {
        System.assertEquals(null, EmailService.csCustomerRequestPaymentInfo);

        String htmlTemplate = EmailService.getCSCustomerRequestPaymentInfoHtml();

        System.assertNotEquals(null, htmlTemplate);
        System.assertNotEquals(null, EmailService.csCustomerRequestPaymentInfo);
    }

    @IsTest
    public static void testCreateCSCustomerRequestPaymentInfoEmails() {
        Lead lead = getLeadForTest();
        Lead lead2 = getLeadForTest();
        List<Lead> leads = new List<Lead>{lead, lead2};
        insert leads;

        System.assertEquals(0, EmailService.emailsToSend.size());

        EmailService.createCSCustomerRequestPaymentInfoEmails(leads);

        System.assertEquals(2, EmailService.emailsToSend.size());

        Messaging.SingleEmailMessage message = EmailService.emailsToSend[0];
        String htmlBody = message.getHtmlBody();

        System.assert(htmlBody.contains(lead.FirstName), 'Lead first name should have been in body');
        System.assert(htmlBody.contains(lead.Id), 'Lead Id should have been in body');
        System.assert(htmlBody.contains('/s/csap'), 'link to application should be in body');

        EmailService.sendMessages();

        System.assertEquals(0, EmailService.emailsToSend.size());
    }

    private static Lead getLeadForTest() {
        Lead lead = new Lead(
            FirstName = 'Tester',
            LastName = 'Testcase',
            Company = 'Test',
            Email = 'testymctesterson@tester.com',
            Application_Type__c = 'Residential',
            Product_line__c = 'Community Solar',
            LASERCA__Home_Address__c = '55 Boston St.',
            LASERCA__Home_City__c = 'Boston',
            LASERCA__Home_State__c = 'MA',
            LASERCA__Home_Zip__c = '02052',
            Parcel_Zip__c = '02052',
            System_Assignment__c = 'Automatic - COD Date/Available Capacity',
            Status = 'Ready for Credit Check',
            Electricity_Provider__c = 'Eversource',
            Application_Source_Phase_1__c = 'CSAP 2.1 with Partner'
        );
        return lead;
    }
}