@IsTest
public class LightningReportsControllerTest {
    @IsTest (SeeAllData=true)
    public static void testSummaryReportResponse() {
        String reportId = [SELECT Id, DeveloperName
                           FROM Report
                           WHERE DeveloperName = 'LightningReportsTestReport'].get(0).Id;

        // this test simulates the doInit process flow in the LightningReportController.js
        Test.startTest();

        Id asyncReportId = LightningReportsController.getAsyncReport(reportId);
        System.assertNotEquals(null, asyncReportId);

        Test.stopTest();

        Reports.ReportInstance reportInstance = Reports.ReportManager.getReportInstance(asyncReportId);
        System.assertNotEquals(null, reportInstance);

        Boolean reportComplete = LightningReportsController.checkAsyncReport(asyncReportId);
        while (!reportComplete) {
            reportComplete = LightningReportsController.checkAsyncReport(asyncReportId);
        }

        LightningReportsController.ReportResponse response;
        response = LightningReportsController.getAsyncReportResponseWithoutRows(asyncReportId);
        System.assertEquals('summary', response.reportType);

        Datetime today = Datetime.now();
        Datetime twoMonthsAgo = today.addMonths(-2);

        // In case there are lead records created outside of the lead insert above
        List<AggregateResult> leadAggregateResults = [
            SELECT LastName, SUM(Annual_Income_Currency__c) annualIncome
            FROM Lead
            WHERE LastName = 'TestLightningReports'
            GROUP BY LastName
        ];

        LightningReportsController.SummaryReportGroup srgWithoutRows = response.sumResp.groupMap.values()[0];
        System.assert(srgWithoutRows.fieldDataList.isEmpty());
        System.assertEquals(srgWithoutRows.fieldAggregateList.get(0).label, 'Annual Income');
        // $200,000.00 should contain 200,000.0
        String message = 'Test may have failed because there is no TestLightningReports lead. Run PostSandboxRefresher.setupDataForReportTest() to create a new lead';
        System.assert(srgWithoutRows.fieldAggregateList.get(0).value.contains(((Decimal)leadAggregateResults[0].get('annualIncome')).format()), message);

        LightningReportsController.SummaryReportGroup srgWithRows = new LightningReportsController.SummaryReportGroup();
        srgWithRows = LightningReportsController.getAsyncSummaryReportGroup((String) asyncReportId, '0');
        System.assert(!srgWithRows.fieldDataList.isEmpty());

        System.assertEquals(srgWithRows.fieldAggregateList.get(0).label, 'Annual Income');
        System.assert(srgWithoutRows.fieldAggregateList.get(0).value.contains(((Decimal)leadAggregateResults[0].get('annualIncome')).format()));
    }

    @IsTest (SeeAllData=true)
    public static void testLookForPreviouslyRequestedReports() {
        Account clientAccount = new Account(Name = 'Client Account');
        insert clientAccount;

        Contact clientContact = new Contact(FirstName = 'First',
            Email = 'clientContact@bluewave-capital.com',
            LastName = 'Last',
            AccountId = clientAccount.Id);
        insert clientContact;

        User clientUser = new User (ProfileId = [SELECT Id FROM Profile WHERE Name = 'CS Client Partner Login'].Id,
            FirstName = 'Test',
            LastName = 'BFG_User',
            Username = 'communityuser@test.com',
            Email = 'communityuser@test.com',
            Alias = 'bfg_usr',
            ContactId = clientContact.Id,
            CommunityNickname = 'bfg_usr',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'ISO-8859-1',
            LanguageLocaleKey = 'en_US');
        Util.insertSObj(clientUser);

        String reportId = [SELECT Id, DeveloperName
        FROM Report
        WHERE DeveloperName = 'LightningReportsTestReport'].get(0).Id;

        Lead lead = new Lead(FirstName='Cole',
            LastName='TestLightningReports',
            Company='Cole Swain',
            Annual_Income_Currency__c = 100000,
            Parent_Account__c = clientAccount.Id);
        insert lead;

        User bfgUser = new User (ProfileId = [SELECT Id from Profile WHERE Name = 'BFG Standard User'].Id,
            FirstName = 'Test',
            LastName = 'BFG_User',
            Username = 'LightningReportsController@test.com',
            Email = 'bfguser@test.com',
            Alias = 'bfg_usr',
            CommunityNickname = 'LightningReportsController',
            TimeZoneSidKey = 'America/New_York',
            LocaleSidKey = 'en_US',
            EmailEncodingKey = 'ISO-8859-1',
            LanguageLocaleKey = 'en_US');
        insert bfgUser;

        Id userId1 = UserInfo.getUserId();
        Id firstInstance = LightningReportsController.getAsyncReport(reportId);

        Id secondInstance = LightningReportsController.getAsyncReport(reportId);
        Test.startTest();

        Id thirdInstance;
        Id userId2;
        System.runAs(bfgUser) {
            userId2 = UserInfo.getUserId();
            thirdInstance = LightningReportsController.getAsyncReport(reportId);
        }
        Test.stopTest();

        System.assertNotEquals(userId1, userId2);
        System.assertEquals(firstInstance, secondInstance);
        System.assertNotEquals(firstInstance, thirdInstance);
    }
}