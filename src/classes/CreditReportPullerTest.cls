@IsTest
private with sharing class CreditReportPullerTest {
    @IsTest
    private static void systemTest() {
        CreditReportPuller.featureSelector = (FeatureSelector) Test.createStub(FeatureSelector.class, new MockedFeatureSelector());
        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Testcase',
            Company = 'Testcase',
            LASERCA__Home_Address__c = '1 Main',
            LASERCA__Home_City__c = 'Boston',
            LASERCA__Home_State__c = 'MA',
            LASERCA__Home_Zip__c = '02110'
        );
        insert testLead;
        testLead.Soft_Pull_Credit_Report__c = true;
        try {
            update testLead;
        } catch (Exception e) {
            System.assert(false, 'Expected to send request a credit report from LASERCA, ' +
                'but got this: ' + e.getMessage() + '\n' + e.getStackTraceString());
        }
    }

    @IsTest
    private static void testTransunionTestSSNs() {
        CreditReportPuller creditReportPuller = new CreditReportPuller();
        Lead lead = new Lead(
            FirstName = 'Does not matter',
            LastName = 'Smith'
        );
        System.assertEquals('000000000', creditReportPuller.getSSNForSoftpullTransunionRequest(lead),
            'Expected all zeros for SSN for non-testcases, since it does not matter for soft pulls');

        lead.LastName = 'Testcase';
        System.assertEquals('000000001', creditReportPuller.getSSNForSoftpullTransunionRequest(lead),
            'Expected SSN ending in 1 for testcases, indicating to TU to return a FICO of 741');

        lead.FirstName = 'Frozen';
        System.assertEquals('000000010', creditReportPuller.getSSNForSoftpullTransunionRequest(lead),
            'Expected SSN ending in 10 for frozen testcases, indicating to TU to return a credit report that has been frozen');

        lead.FirstName = 'Fail';
        System.assertEquals('000000008', creditReportPuller.getSSNForSoftpullTransunionRequest(lead),
            'Expected SSN ending in 08 for failure testcases, indicating to TU to return a credit report that has low FICO');
    }

    @IsTest
    private static void testExperianRequests() {
        CreditReportPuller creditReportPuller = new CreditReportPuller();

        System_Default__mdt systemDefault = new System_Default__mdt(
            Credit_Provider__c = 'CBCNEW',
            Credit_Login_Account_Username__c = 'productionuser',
            Test_Credit_Login_Account_Username__c = 'testuser'
        );

        Lead lead = new Lead(
            Id = Util.getFakeId(Lead.SObjectType),
            LastName = 'Testcase'
        );

        LASERCA.PullCreditReportAction.PullCreditReportActionRequest request = creditReportPuller.getRequest(lead, systemDefault);
        System.assertEquals('666390426', request.ssn, 'Expected to request a test SSN if the last name is Testcase and using CBCNEW');
        System.assertEquals('Burnia', request.lastName, 'Expected to map lastname Testcase to a Burnia, an experian test subject');
        System.assertEquals('testuser', request.loginAccount, 'Expected to use the test account for test pulls since there is no charge');

        lead.LastName = 'Smith';
        request = creditReportPuller.getRequest(lead, systemDefault);
        System.assertEquals('000000000', request.ssn, 'Expected to request all zeros if the last name is not testcase');
        System.assertEquals('Smith', request.lastName, 'Expected to send the applicant last name if it is not testcase');
        System.assertEquals('productionuser', request.loginAccount, 'Expected to use the production account for non-test pulls');
    }

    @IsTest
    private static void testTransunionRequests() {
        CreditReportPuller creditReportPuller = new CreditReportPuller();

        System_Default__mdt systemDefault = new System_Default__mdt(
            Credit_Provider__c = 'CREDITAPI',
            Credit_Login_Account_Username__c = 'productionuser'
        );

        Lead lead = new Lead(
            Id = Util.getFakeId(Lead.SObjectType),
            LastName = 'Testcase'
        );

        LASERCA.PullCreditReportAction.PullCreditReportActionRequest request = creditReportPuller.getRequest(lead, systemDefault);
        System.assertEquals('000000001', request.ssn, 'Expected to request a test SSN if the last name is Testcase and using CREDITAPI');
        System.assertEquals('productionuser', request.loginAccount, 'Expected to use the production account for TU test pulls');

        lead.LastName = 'Smith';
        request = creditReportPuller.getRequest(lead, systemDefault);
        System.assertEquals('000000000', request.ssn, 'Expected to request all zeros if the last name is not testcase');
        System.assertEquals('productionuser', request.loginAccount, 'Expected to use the production account for TU non-test pulls');
    }

    public class MockedFeatureSelector extends MockProvider {
        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'getSystemDefaults' {
                    return new System_Default__mdt(
                        Credit_Provider__c = 'CREDITAPI',
                        Credit_Login_Account_Username__c = 'bluewavesoft'
                    );
                }
            }
            return null;
        }
    }
}