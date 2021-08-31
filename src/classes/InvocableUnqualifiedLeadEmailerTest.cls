@IsTest
public class InvocableUnqualifiedLeadEmailerTest {

    public static Lead getFakeLead() {
        JSONGenerator leadJSON = JSON.createGenerator(false);
        leadJSON.writeStartObject();
        leadJSON.writeStringField('Id', Util.getFakeId(Lead.SObjectType));
        leadJSON.writeStringField('Email', 'test@email.com');
        leadJSON.writeStringField('FirstName', 'John');
        leadJSON.writeStringField('LastName', 'Smith');
        leadJSON.writeStringField('Name', 'John Smith');
        leadJSON.writeStringField('LASER_Credit_Score__c', '400');
        leadJSON.writeStringField('Credit_Report_Detail_1__c', 'test');
        leadJSON.writeStringField('Credit_Report_Detail_2__c', 'test');
        leadJSON.writeStringField('Credit_Report_Detail_3__c', 'test');
        leadJSON.writeStringField('Credit_Report_Detail_4__c', 'test');
        leadJSON.writeStringField('Credit_Report_Detail_4__c', 'test');
        leadJSON.writeStringField('Credit_Provider__c', 'Experian');
        leadJSON.writeStringField('Credit_Provider_Address__c', '1 Main Street');
        leadJSON.writeDateField('Date_of_Credit_Report__c', Date.today());
        leadJSON.writeEndObject();
        return (Lead) JSON.deserialize(leadJSON.getAsString(), Lead.class);
    }

    @IsTest
    public static void testLowFicoLeadManualUnqualification() {
        Lead lead = getFakeLead();
        lead.Unqualified_due_to_FICO__c = true;

        InvocableUnqualifiedLeadEmailer.sendUnqualifiedLeadAdverseActionEmail(new List<Lead>{lead});
        Messaging.SingleEmailMessage sentEmail = (Messaging.SingleEmailMessage) MessagingService.emailsSent[0];
        System.assertNotEquals(null, sentEmail, 'ACN should be automatically sent to customer');
        System.assert(!sentEmail.htmlBody.contains('{!Lead.FirstName}'), 'Merge field should be replaced with data from record');
    }

    @IsTest
    public static void testOtherManualUnqualification() {
        Lead lead = getFakeLead();
        lead.Unqualified_due_to_FICO__c = false;

        InvocableUnqualifiedLeadEmailer.sendUnqualifiedLeadAdverseActionEmail(new List<Lead>{lead});
        Messaging.SingleEmailMessage sentEmail = (Messaging.SingleEmailMessage) MessagingService.emailsSent[0];
        System.assertNotEquals(null, sentEmail, 'ACN should be automatically sent to customer');
        System.assert(!sentEmail.htmlBody.contains('{!Lead.FirstName}'), 'Merge field should be replaced with data from record');
    }
}