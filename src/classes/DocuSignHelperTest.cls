@IsTest
public with sharing class DocuSignHelperTest {

    @TestSetup public static void setupTestData() {
        System_Properties__c sysProp = new System_Properties__c(
            Name = 'System',
            DocuSign_API_Account_ID__c = '123',
            DocuSign_Customer_Care_User__c = '123@123.com',
            DocuSign_Guest_User__c = '123@345.com',
            DocuSign_Guest_User_Credential__c = '234234',
            DocuSign_Integrator_Key__c = '123123-123123'
        );
        insert sysProp;

        LoanTestRecordWarehouse.partnerSetup();
        List<Lead> leads = LoanTestRecordWarehouse.getLoanHandlerLeadRecords();
        System.debug(LoggingLevel.ERROR, 'Limit tracking: ' + Limits.getQueries() + ' of ' + Limits.getLimitQueries());
        Lead leadToConvert;
        for (Lead lead : leads) {
            if (lead.FirstName == 'Retired') {
                leadToConvert = lead;
            }
        }
        Lead convertedLead = CAPController.convertLead(leadToConvert.Id, leadToConvert.Email);
        CAPController.createLoanAndEquipment(leadToConvert.Id, leadToConvert.Email);

        dsfs__DocuSign_Status__c newDocStat = new dsfs__DocuSign_Status__c(
            dsfs__Opportunity__c = convertedLead.ConvertedOpportunityId,
            dsfs__Envelope_Status__c = 'Sent'
        );
        insert newDocStat;

        dsfs__DocuSign_Recipient_Status__c newDRS = new dsfs__DocuSign_Recipient_Status__c(
            Name = 'TestCase',
            dsfs__Parent_Status_Record__c =newDocStat.Id,
            dsfs__DocuSign_Recipient_Id__c = 'D50030',
            dsfs__DocuSign_Recipient_Email__c = 'nobody@bluewavesolar.com',
            dsfs__Recipient_Status__c = 'Sent'
        );
        insert newDRS;
    }

    static testMethod void testLoanCreationAndUpdate() {
        Opportunity opp = [
            SELECT Id, Lead__c, Contract_Status__c, Partner_Sales_Agreement_Status__c, BlueWave_Signature_Status__c,
            (SELECT Id FROM Partner_Tasks__r WHERE (Name = 'Obtain Contract Signature' OR Name = 'Provide Sales Agreement')),
            (SELECT Id, dsfs__Envelope_Status__c FROM dsfs__R00N80000002fD9vEAE__r)
            FROM Opportunity
            WHERE Lead__r.FirstName = 'Retired'
        ];
        System.debug(LoggingLevel.ERROR, 'Limit tracking: ' + Limits.getQueries() + ' of ' + Limits.getLimitQueries());
        System.assertEquals(1, opp.dsfs__R00N80000002fD9vEAE__r.size());
        System.assertEquals('Sent', opp.dsfs__R00N80000002fD9vEAE__r[0].dsfs__Envelope_Status__c);
        System.assertEquals(null, DocuSignHelper.oppsToResend);
        System.assertEquals(null, DocuSignHelper.envelopesToVoid);

        opp.Contract_Status__c = 'Completed';
        opp.Partner_Sales_Agreement_Status__c = 'Completed';
        update opp;
        opp.Partner_Tasks__r[0].Status__c = 'Complete';
        opp.Partner_Tasks__r[0].Completion_Date__c = Date.today();
        opp.Partner_Tasks__r[1].Status__c = 'Complete';
        opp.Partner_Tasks__r[1].Completion_Date__c = Date.today();
        update opp.Partner_Tasks__r;
        Test.startTest();
        Test.setMock(WebServiceMock.class, new DocuSignAPIMockImpl());
        Test.setMock(HttpCalloutMock.class, new DocuSignAPIMockImpl());

        Lead lead = new Lead(
            Id = opp.Lead__c,
            Change_Order_Status__c = 'Customer Authorized'
        );
        update lead;
        // This should void the existing package and create a new one
        Test.stopTest();
        // We can't check DocuSign_Status__c results here, because DocuSign might not have written back to Salesforce
        // yet. So Partner Task assertions is the best we can do.
        System.assertEquals(1, DocuSignHelper.oppsToResend.size());
        System.assertEquals(1, DocuSignHelper.envelopesToVoid.size());
        System.assertEquals(1, DocuSignHelper.oppLoansSent.size());

        opp = [
            SELECT Id, Contract_Status__c, Partner_Sales_Agreement_Status__c, BlueWave_Signature_Status__c,
            (SELECT Id, dsfs__Envelope_Status__c FROM dsfs__R00N80000002fD9vEAE__r),
            (SELECT Id, Status__c, Completion_Date__c FROM Partner_Tasks__r WHERE (Name = 'Obtain Contract Signature' OR Name = 'Provide Sales Agreement'))
            FROM Opportunity
            WHERE Id = :opp.Id
        ];
        System.debug(LoggingLevel.ERROR, 'Limit tracking: ' + Limits.getQueries() + ' of ' + Limits.getLimitQueries());
        System.assertEquals('Sent', opp.Contract_Status__c);
        System.assertEquals(null, opp.Partner_Sales_Agreement_Status__c);
        System.assertEquals(2, opp.Partner_Tasks__r.size());
        System.assertEquals('Pending', opp.Partner_Tasks__r[0].Status__c);
        System.assertEquals(null, opp.Partner_Tasks__r[0].Completion_Date__c);
        System.assertEquals('Pending', opp.Partner_Tasks__r[1].Status__c);
        System.assertEquals(null, opp.Partner_Tasks__r[1].Completion_Date__c);
    }

    static testMethod void testVoidFromProcessBuilder() {
        Opportunity opp = [
            SELECT Id, Lead__c, Contract_Status__c, Partner_Sales_Agreement_Status__c, BlueWave_Signature_Status__c, (SELECT Id FROM Partner_Tasks__r WHERE (Name = 'Obtain Contract Signature' OR Name = 'Provide Sales Agreement')), (SELECT Id, dsfs__Envelope_Status__c FROM dsfs__R00N80000002fD9vEAE__r)
            FROM Opportunity
            WHERE Lead__r.FirstName = 'Retired'
        ];
        System.debug(LoggingLevel.ERROR, 'Limit tracking: ' + Limits.getQueries() + ' of ' + Limits.getLimitQueries());
        System.assertEquals(1, opp.dsfs__R00N80000002fD9vEAE__r.size());
        System.assertEquals('Sent', opp.dsfs__R00N80000002fD9vEAE__r[0].dsfs__Envelope_Status__c);
        System.assertEquals(null, DocuSignHelper.oppsToResend);
        System.assertEquals(null, DocuSignHelper.envelopesToVoid);

        opp.Contract_Status__c = 'Completed';
        opp.Partner_Sales_Agreement_Status__c = 'Completed';
        update opp;
        opp.Partner_Tasks__r[0].Status__c = 'Complete';
        opp.Partner_Tasks__r[0].Completion_Date__c = Date.today();
        opp.Partner_Tasks__r[1].Status__c = 'Complete';
        opp.Partner_Tasks__r[1].Completion_Date__c = Date.today();
        update opp.Partner_Tasks__r;
        Test.startTest();
        Test.setMock(WebServiceMock.class, new DocuSignAPIMockImpl());
        Test.setMock(HttpCalloutMock.class, new DocuSignAPIMockImpl());

        // TODO: call void
        Test.stopTest();
    }
}