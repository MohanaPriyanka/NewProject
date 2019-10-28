/**
 * Created by PeterYao on 10/18/2019.
 */
@IsTest
public with sharing class UserStoryPromoterTest {
    private static UserStoryPromoter storyPromoter;

    static {
        storyPromoter = new UserStoryPromoter();
        storyPromoter.copadoSelector = (CopadoSelector) Test.createStub(CopadoSelector.class, new MockCopadoSelector());
        storyPromoter.copadoService = (CopadoService) Test.createStub(CopadoService.class, new MockCopadoService());
    }

    @TestSetup
    public static void testSetup() {
        System_Properties__c property = new System_Properties__c(Name = 'System', Log_Level__c = 'Fine');
        insert property;
    }

    @IsTest
    private static void testSchedulable() {
        Test.setMock(HttpCalloutMock.class, new CopadoMock());
        Test.startTest();
        Boolean caughtException = false;
        try {
            System.schedule('ScheduleApexClassTest', '0 0 0 1 1 ? *', storyPromoter);
        } catch (Exception e) {
            caughtException = true;
        }
        System.assert(!caughtException);
        Test.stopTest();
        List<Error_Log__c> errorLogs = [
            SELECT Message__c, Severity__c
            FROM Error_Log__c
        ];
        // I expected the Fine logs to be logged as well, but because startPromotion is @future (which it has to be
        // because a scheduleable can't do a callout), it isn't performed in this test context:
        // https://salesforce.stackexchange.com/a/70707/47356
        System.assertEquals(1, errorLogs.size(), 'Expected one log with the stories that are being added');
    }

    @IsTest
    private static void testCreatePromotionFromStories() {
        Test.setMock(HttpCalloutMock.class, new CopadoMock());
        Boolean caughtException = false;
        try {
            storyPromoter.createPromotionFromStories();
        } catch (Exception e) {
            caughtException = true;
        }
        System.assert(!caughtException);
    }

    @IsTest
    private static void testAddStoriesToPromotion() {
        copado__User_Story__c story1 = new copado__User_Story__c(
            Id = 'a6Y0a000000PCX9EAO',
            copado__Promotion_Test_Level__c = 'NoTestRun'
        );
        copado__User_Story__c story2 = new copado__User_Story__c(
            Id = 'a6Y0a000000QCX9EAO',
            copado__Promotion_Test_Level__c = 'NoTestRun'
        );
        copado__User_Story__c story3 = new copado__User_Story__c(
            Id = 'a6Y0a000000RCX9EAO',
            copado__Promotion_Test_Level__c = 'RunSpecifiedTests'
        );
        List<copado__User_Story__c> storiesToPromote = new List<copado__User_Story__c>{story1, story2, story3};
        copado__Promotion__c promotion = new copado__Promotion__c(
            Id = 'a5t0a000000Guna'
        );
        System.assertEquals('RunSpecifiedTests', storyPromoter.addStoriesToPromotion(storiesToPromote, promotion));
    }

    @IsTest
    private static void testCreatePromotion() {
        Boolean caughtException = false;
        try {
            copado__Promotion__c promotion = storyPromoter.createPromotion();
        } catch (Exception e) {
            caughtException = true;
        }
        System.assert(!caughtException);
    }

    @IsTest
    private static void testAddToPromotionList() {
        Id dev = 'a5a0a000000DeOYAA0';
        Id devCredential = 'a5n0a000000Cf62AAC';
        Id defaultProject = 'a5r0a000000TSsKAAW';
        Id uat = 'a5a0a000000EeOYAA0';
        Id uatCredential = 'a5n0a000000Df62AAC';
        copado__User_Story__c story1 = new copado__User_Story__c(
            copado__Environment__c = dev,
            copado__Org_Credential__c = devCredential,
            copado__Project__c = defaultProject
        );
        copado__User_Story__c story2 = new copado__User_Story__c(
            copado__Environment__c = dev,
            copado__Org_Credential__c = devCredential,
            copado__Project__c = defaultProject
        );
        copado__User_Story__c story3 = new copado__User_Story__c(
            copado__Environment__c = uat,
            copado__Org_Credential__c = uatCredential,
            copado__Project__c = defaultProject
        );
        List<copado__User_Story__c> storiesToPromote = new List<copado__User_Story__c>();

        List<Error_Log__c> errorLogs = [SELECT Message__c FROM Error_Log__c WHERE Severity__c = :Logger.ERROR];
        System.assertEquals(0, errorLogs.size());
        storyPromoter.addStoryToPromotionList(story1, storiesToPromote);
        Logger.flushLogs();
        System.assertEquals(1, storiesToPromote.size());
        errorLogs = [SELECT Message__c FROM Error_Log__c WHERE Severity__c = :Logger.ERROR];
        System.assertEquals(0, errorLogs.size());

        storyPromoter.addStoryToPromotionList(story2, storiesToPromote);
        Logger.flushLogs();
        System.assertEquals(2, storiesToPromote.size());
        errorLogs = [SELECT Message__c FROM Error_Log__c WHERE Severity__c = :Logger.ERROR];
        System.assertEquals(0, errorLogs.size());

        storyPromoter.addStoryToPromotionList(story3, storiesToPromote);
        Logger.flushLogs();
        System.assertEquals(2, storiesToPromote.size());
        errorLogs = [SELECT Message__c FROM Error_Log__c WHERE Severity__c = :Logger.ERROR];
        System.assertEquals(1, errorLogs.size());
    }

    @IsTest
    private static void testStartPromotion() {
        Test.setMock(HttpCalloutMock.class, new CopadoMock());
        List<Error_Log__c> errorLogs = [SELECT Message__c FROM Error_Log__c];
        System.assertEquals(0, errorLogs.size());
        Test.startTest();
        UserStoryPromoter.startPromotion('https://copado.herokuapp.com/json/v1/webhook/promotions/a5t0a000000GucDAAS/' +
            'process?testLevel=NoTestRun&api_key=2a1cd5&deploymentName=ERROR');
        Test.stopTest();
        errorLogs = [SELECT Message__c FROM Error_Log__c WHERE Severity__c = :Logger.ERROR];
        System.assertEquals(1, errorLogs.size());
        System.assert(errorLogs[0].Message__c.contains('some message'));
    }

    /*************
     *** MOCKS ***
     *************/

    public class MockCopadoService extends MockProvider {
        public MockCopadoService() {
        }

        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'insertPromotedUserStories' {
                    return null;
                } when 'insertPromotion' {
                    return new copado__Promotion__c();
                }
            }
            return null;
        }
    }

    public class MockCopadoSelector extends MockProvider {
        public MockCopadoSelector() {
        }

        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'getUserStoriesToPromote' {
                    String json = '[' +
                        '{"attributes":{"type":"copado__User_Story__c","url":"/services/data/v47.0/sobjects/copado__User_Story__c/a6Y0a000000PCXiEAO"},' +
                        '"Id":"a6Y0a000000PCXiEAO",' +
                        '"Name":"US-0000908",' +
                        '"copado__User_Story_Title__c":"W-015471: Update formula on External Cancellation Field",' +
                        '"copado__Promotion_Test_Level__c":"NoTestRun",' +
                        '"copado__Environment__c":"a5a0a000000DeNkAAK",' +
                        '"copado__Org_Credential__c":"a5n0a000000Cf0EAAS",' +
                        '"copado__Project__c":"a5r0a000000TSsKAAW"},' +
                        '{"attributes":{"type":"copado__User_Story__c","url":"/services/data/v47.0/sobjects/copado__User_Story__c/a6Y0a000000PCXTEA4"},' +
                        '"Id":"a6Y0a000000PCXTEA4",' +
                        '"Name":"US-0000905",' +
                        '"copado__User_Story_Title__c":"ProductEscalatorBugFix",' +
                        '"copado__Promotion_Test_Level__c":"NoTestRun",' +
                        '"copado__Environment__c":"a5a0a000000DeNkAAK",' +
                        '"copado__Org_Credential__c":"a5n0a000000Cf0EAAS",' +
                        '"copado__Project__c":"a5r0a000000TSsKAAW"}' +
                        ']';
                    return System.JSON.deserialize(json, List<copado__User_Story__c>.class);
                } when 'getProductionEnvironment' {
                    String json = '{"attributes":{"type":"copado__Environment__c","url":"/services/data/v47.0/sobjects/copado__Environment__c/a5a0a000000DeNfAAK"},' +
                        '"Id":"a5a0a000000DeNfAAK",' +
                        '"Name":"prod"}';
                    return System.JSON.deserialize(json, copado__Environment__c.class);
                } when 'getDefaultCredential' {
                    String json = '{"attributes":{"type":"copado__Org__c","url":"/services/data/v47.0/sobjects/copado__Org__c/a5n0a000000Cf6HAAS"},' +
                        '"Id":"a5n0a000000Cf6HAAS",' +
                        '"copado__Username__c":"jbattles@bluewavesolar.com"}';
                    return System.JSON.deserialize(json, copado__Org__c.class);
                }
            }
            return null;
        }
    }

    public class CopadoMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            String endpoint = req.getEndpoint();
            HttpResponse response = getJSON();
            if (endpoint.contains('ERROR')) {
                response.setBody('{"error": "some message"}');
            } else {
                response.setBody('{"ok":"Job has started!","copadoJobId":"d9ccd383-9b74-48db-8465-2ce086263c68","status":"initializing","isFinished":false}');
            }
            return response;
        }

        public HttpResponse getJSON() {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setStatusCode(200);
            return res;
        }
    }
}