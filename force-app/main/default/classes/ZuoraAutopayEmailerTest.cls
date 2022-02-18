@IsTest
public with sharing class ZuoraAutopayEmailerTest {

    private static ZuoraAutopayEmailer emailer = new ZuoraAutopayEmailer();
    private static Boolean testWithGoodData = true;

    @IsTest
    private static void testEnrollmentProperties() {
        useMocks();
        emailer.dateOverride = Date.newInstance(2021, 07, 29); // 3rd from last day of month
        emailer.execute(null);
        Zuora__CustomerAccount__c acc = getCustomerAccounts(true)[0];
        MarketingJourneyEnrollmentDetail enrollment = emailer.enrollments[0];
        System.assertEquals(ZuoraAutopayEmailer.MC_EVENT_KEY, enrollment.EventDefinitionKey, 'Wrong Entry Event Key');
        System.assertEquals(acc.Zuora__Account__r.Send_Bills_Contact__c, enrollment.ContactId, 'Wrong contact id');
        for (FlowMap property : enrollment.EventProperties) {
            if (property.key == 'WithdrawalDate') {
                System.assertEquals('08/01/2021', property.value, 'Wrong withdrawal date');
            } else if (property.key == 'AmountDue') {
                System.assertEquals(String.valueOf(acc.Zuora__Balance__c), property.value, 'Wrong zuora balance');
            }
        }
        System.assertEquals(true, emailer.isValidEmailEnrollment(enrollment), 'Enrollment failed validation');
    }

    @IsTest
    private static void testGoodAutopayEmailSend() {
        useMocks();
        emailer.dateOverride = Date.newInstance(2021, 07, 29); // 3rd from last day of month, should send emails
        Test.setMock(HttpCalloutMock.class, new MarketingJourneyEnrollerTest.MarketingJourneyEnrollerSuccess());
        String cronExp = '0 0 12 26-29 * ?';
        Test.startTest();
            System.schedule('Zuora Autopay Emailer', cronExp, emailer);
            emailer.execute(null); // need to call this explicitly in Tests
            // The testing framework doesn't seem to fire queueables enqueued from within schedulables on Test.stopTest();
        Test.stopTest();
        List<Error_Log__c> logs = [SELECT Id, Message__c FROM Error_Log__c];
        System.assertEquals(2, logs.size(), 'Two logs should have been generated for callout success');
        System.assert(logs[1].Message__c.contains('Successful Marketing Cloud journey enrollment'), 'Second log should indicate success');
    }

    @IsTest
    private static void testDataMissingNoEmailsSent() {
        useMocks();
        testWithGoodData = false;
        emailer.dateOverride = Date.newInstance(2021, 07, 29); // 3rd from last day of month, should send emails
        String cronExp = '0 0 12 26-29 * ?';
        Test.startTest();
            System.schedule('Zuora Autopay Emailer', cronExp, emailer);
        Test.stopTest();
        List<Error_Log__c> logs = [SELECT Id, Message__c, Severity__c FROM Error_Log__c];
        System.assertEquals(1, logs.size(), 'Error should have been logged for ZuoraAutopayEmailer');
        System.assertEquals(Logger.ERROR, logs[0].Severity__c, 'Log severity should be ERROR');
        System.assert(logs[0].Message__c.contains('Invalid email merge field data for autopay reminder email'),
            'Log should specify that not enough data was present to send autopay reminder email for contact');
    }

    @IsTest
    private static void testWrongDateNoEmailsSent() {
        emailer.dateOverride = Date.newInstance(2021, 07, 27); // This isn't the 3rd from last day, should not run
        String cronExp = '0 0 12 26-29 * ?';
        Test.startTest();
            System.schedule('Zuora Autopay Emailer', cronExp, emailer);
        Test.stopTest();
        List<Error_Log__c> logs = [SELECT Id, Message__c, Severity__c FROM Error_Log__c];
        System.assertEquals(0, logs.size(), 'No emails should have been sent nor Logs logged due to invalid date');
    }

    @IsTest
    private static void testShouldRunToday() {
        System.assertEquals(true, emailer.shouldSendEmailsToday(Date.newInstance(2021,7,29)),
            'Helper method should indicate that emails should go out on the specified date');
        System.assertEquals(false, emailer.shouldSendEmailsToday(Date.newInstance(2021,7,28)),
            'Helper method should indicate that emails should NOT go out on the specified date');
        System.assertEquals(false, emailer.shouldSendEmailsToday(Date.newInstance(2020,2,26)),
            'Helper method should indicate that emails should NOT go out on leap year on 2/26');
        System.assertEquals(true, emailer.shouldSendEmailsToday(Date.newInstance(2020,2,27)),
            'Helper method should indicate that emails should go out on leap year on 2/27');
        System.assertEquals(false, emailer.shouldSendEmailsToday(Date.newInstance(2021,2,28)),
            'Helper method should indicate that emails should NOT go out (past the correct date');
    }

    private static void useMocks() {
        emailer.accountSelector = (ZuoraAccountSelector) Test.createStub(ZuoraAccountSelector.class, new MockZuoraAccountSelector());
    }

    private class MockZuoraAccountSelector implements StubProvider {
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, System.Type returnType,
            List<System.Type> listOfParamTypes, List<String> listOfParamNames, List<Object> listOfArgs)
        {
            if (stubbedMethodName == 'getAutopayAccountsWithBalanceForEmail' && testWithGoodData) {
                return getCustomerAccounts(true);
            } else if (stubbedMethodName == 'getAutopayAccountsWithBalanceForEmail' && !testWithGoodData) {
                return getCustomerAccounts(false);
            }
            return null;
        }
    }

    public static List<Zuora__CustomerAccount__c> getCustomerAccounts(Boolean setAllFields) {
        sfab_FabricatedSObject sendBillsContact = new sfab_FabricatedSObject(Contact.class);
        sendBillsContact.setField(Contact.Email, 'susan.testcase@gmail.com');
        sendBillsContact.setField(Contact.FirstName, 'Susan');

        sfab_FabricatedSObject zuoraAccount = new sfab_FabricatedSObject(Account.class);
        zuoraAccount.setField(Account.Client_Brand_Key__c, 'BluewaveLogo');
        zuoraAccount.setField(Account.Send_Bills_Contact__c, Util.getFakeId(Contact.SObjectType));
        zuoraAccount.setParent('Send_Bills_Contact__r', sendBillsContact);

        sfab_FabricatedSObject paymentMethod = new sfab_FabricatedSObject(Zuora__PaymentMethod__c.class);
        paymentMethod.setField(Zuora__PaymentMethod__c.Zuora__AchAccountNumberMask__c, '***123');
        paymentMethod.setField(Zuora__PaymentMethod__c.Zuora__CreditCardMaskNumber__c, null);

        sfab_FabricatedSObject customerAccount = new sfab_FabricatedSObject(Zuora__CustomerAccount__c.class);
        if (setAllFields) {
            customerAccount.setField(Zuora__CustomerAccount__c.Zuora__Balance__c, 58.44);
        }
        customerAccount.setField(Zuora__CustomerAccount__c.Zuora__Account__c, Util.getFakeId(Account.SObjectType));
        customerAccount.setParent('Zuora__Account__r', zuoraAccount);
        customerAccount.setParent('Zuora__Default_Payment_Method__r', paymentMethod);

        List<Zuora__CustomerAccount__c> accountList = new List<Zuora__CustomerAccount__c>();
        accountList.add((Zuora__CustomerAccount__c) customerAccount.toSObject());
        return accountList;
    }
}