@IsTest
public with sharing class ZuoraAutopayEmailerTest {

    private static ZuoraAutopayEmailer emailer = new ZuoraAutopayEmailer();
    private static Boolean testWithGoodData = true;

    @TestSetup
    private static void insertTestPrerequisites() {
        insert new System_Properties__c(Name = 'System', Log_Level__c = 'Fine');
    }

    @IsTest
    private static void testEnrollmentProperties() {
        useMocks();
        emailer.testDate = Date.newInstance(2021, 07, 28); // 3rd from last day of month
        emailer.execute(null);
        Zuora__CustomerAccount__c acc = (Zuora__CustomerAccount__c) JSON.deserialize(
            completeZuoraAccountRecordJSON, Zuora__CustomerAccount__c.class
        );
        MarketingJourneyEnrollmentDetail enrollment = emailer.enrollments[0];
        System.assertEquals(ZuoraAutopayEmailer.MC_EVENT_KEY, enrollment.EventDefinitionKey, 'Wrong Entry Event Key');
        System.assertEquals(acc.Zuora__Account__r.Send_Bills_Contact__c, enrollment.ContactId, 'Wrong contact id');
        for (FlowMap property : enrollment.EventProperties) {
            if (property.key == 'WithdrawalDate') {
                System.assertEquals('2021-08-01', property.value, 'Wrong withdrawal date');
            } else if (property.key == 'AmountDue') {
                System.assertEquals(String.valueOf(acc.Zuora__Balance__c), property.value, 'Wrong zuora balance');
            }
        }
        System.assertEquals(true, emailer.isValidEmailEnrollment(enrollment), 'Enrollment failed validation');
    }

    @IsTest
    private static void testGoodAutopayEmailSend() {
        useMocks();
        emailer.testDate = Date.newInstance(2021, 07, 28); // 3rd from last day of month, should send emails
        Test.setMock(HttpCalloutMock.class, new MarketingJourneyEnrollerTest.MarketingJourneyEnrollerSuccess());
        String cronExp = '0 0 12 25-28 * ?';
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
        emailer.testDate = Date.newInstance(2021, 07, 28); // 3rd from last day of month, should send emails
        String cronExp = '0 0 12 25-28 * ?';
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
        emailer.testDate = Date.newInstance(2021, 07, 27); // This isn't the 3rd from last day, should not run
        String cronExp = '0 0 12 25-28 * ?';
        Test.startTest();
            System.schedule('Zuora Autopay Emailer', cronExp, emailer);
        Test.stopTest();
        List<Error_Log__c> logs = [SELECT Id, Message__c, Severity__c FROM Error_Log__c];
        System.assertEquals(0, logs.size(), 'No emails should have been sent nor Logs logged due to invalid date');
    }

    @IsTest
    private static void testSchedulerMethod() {
        String jobId = ZuoraAutopayEmailer.scheduleJob();
        CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id = :jobId];
        System.assertEquals(ZuoraAutopayEmailer.CRON_EXP, ct.CronExpression, 'Cron expression incorrect for some reason');
        System.assertEquals(0, ct.TimesTriggered, 'Scheduled job should not have run yet');
        System.assert(ct.NextFireTime != null, 'Job should have future runs scheduled');
        System.assertEquals(0, [SELECT Id FROM Error_Log__c].size(), 'No error logs should have been logged for this tx');
    }

    private static void useMocks() {
        emailer.accountSelector = (ZuoraAccountSelector) Test.createStub(ZuoraAccountSelector.class, new MockZuoraAccountSelector());
    }

    private class MockZuoraAccountSelector implements StubProvider {
        public Object handleMethodCall(Object stubbedObject, String stubbedMethodName, System.Type returnType,
            List<System.Type> listOfParamTypes, List<String> listOfParamNames, List<Object> listOfArgs)
        {
            if (stubbedMethodName == 'getAutopayAccountsWithBalanceForEmail' && testWithGoodData) {
                Zuora__CustomerAccount__c customerAccount = (Zuora__CustomerAccount__c)
                    JSON.deserialize(completeZuoraAccountRecordJSON, Zuora__CustomerAccount__c.class);
                return new List<Zuora__CustomerAccount__c>{customerAccount};
            } else if (stubbedMethodName == 'getAutopayAccountsWithBalanceForEmail' && !testWithGoodData) {
                Zuora__CustomerAccount__c customerAccount = (Zuora__CustomerAccount__c)
                    JSON.deserialize(incompleteZuoraAccountRecordJSON, Zuora__CustomerAccount__c.class);
                return new List<Zuora__CustomerAccount__c>{customerAccount};
            }
            return null;
        }
    }

    public static final String completeZuoraAccountRecordJSON = '{'+
        '"attributes": {'+
            '"type": "Zuora__CustomerAccount__c",'+
            '"url": "/services/data/v51.0/sobjects/Zuora__CustomerAccount__c/a010a00000GuXjsAAF"'+
        '},'+
        '"Id":"a710a00000GvLjsAAF",'+
        '"Zuora__Account__c": "0010a00001duE59AAE",'+
        '"Zuora__Account__r": {'+
            '"attributes": {'+
                '"type": "Account",'+
                '"url": "/services/data/v51.0/sobjects/Account/0012a00001duE59AAE"'+
            '},'+
            '"Send_Bills_Contact__c": "0030a00002LHO3oAAH",'+
            '"Send_Bills_Contact__r": {'+
                '"attributes": {'+
                    '"type": "Contact",'+
                    '"url": "/services/data/v51.0/sobjects/Contact/0032a00002LHO3oAAH"'+
                '},'+
                '"FirstName": "Susan",'+
                '"Email": "susan.baldi555@gmail.com"'+
            '},'+
            '"Client_Brand_Key__c": "BluewaveLogo"'+
        '},'+
        '"Zuora__Default_Payment_Method__r": {'+
            '"attributes": {'+
                '"type": "Zuora__PaymentMethod__c",'+
                '"url": "/services/data/v51.0/sobjects/Zuora__PaymentMethod__c/a795c000000HYyxAAG"'+
            '},'+
            '"Zuora__AchAccountNumberMask__c": null,'+
            '"Zuora__CreditCardMaskNumber__c": "************4111"'+
        '},'+
        '"Zuora__Balance__c": 58.44'+
    '}';

    public static final String incompleteZuoraAccountRecordJSON = '{'+ // Missing zuora balance field data
        '"attributes": {'+
            '"type": "Zuora__CustomerAccount__c",'+
            '"url": "/services/data/v51.0/sobjects/Zuora__CustomerAccount__c/a010a00000GuXjsAAF"'+
        '},'+
        '"Id":"a710a00000GvLjsAAF",'+
        '"Zuora__Account__c": "0010a00001duE59AAE",'+
        '"Zuora__Account__r": {'+
            '"attributes": {'+
                '"type": "Account",'+
                '"url": "/services/data/v51.0/sobjects/Account/0012a00001duE59AAE"'+
            '},'+
            '"Send_Bills_Contact__c": "0030a00002LHO3oAAH",'+
            '"Send_Bills_Contact__r": {'+
                '"attributes": {'+
                    '"type": "Contact",'+
                    '"url": "/services/data/v51.0/sobjects/Contact/0032a00002LHO3oAAH"'+
                '},'+
                '"FirstName": "Susan",'+
                '"Email": "susan.baldi555@gmail.com"'+
            '},'+
            '"Client_Brand_Key__c": "BluewaveLogo"'+
        '},'+
        '"Zuora__Default_Payment_Method__r": {'+
            '"attributes": {'+
                '"type": "Zuora__PaymentMethod__c",'+
                '"url": "/services/data/v51.0/sobjects/Zuora__PaymentMethod__c/a795c000000HYyxAAG"'+
            '},'+
            '"Zuora__AchAccountNumberMask__c": null,'+
            '"Zuora__CreditCardMaskNumber__c": "************4111"'+
        '}'+
    '}';
}