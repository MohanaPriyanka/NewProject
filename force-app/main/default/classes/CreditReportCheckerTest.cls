@IsTest
private class CreditReportCheckerTest {

    private static Lead buildLead() {
        Lead leadToUpdate = new Lead (
            FirstName = 'Other',
            LastName = 'Testcase',
            Email = 'test@invalid.bluewavesolar.com',
            Company = 'System Testcase',
            LeadSource = 'Switch',
            Partner_Email__c = 'partner@testcase.com'
        );
        insert leadToUpdate;
        return leadToUpdate;
    }

    private static LASERCA__Personal_Credit_Report__c buildPCR(Id leadId) {
        LASERCA__Personal_Credit_Report__c pcr = new LASERCA__Personal_Credit_Report__c(
            LASERCA__Lead__c = leadId,
            LASERCA__Credit_Score__c = null,
            LASERCA__TransUnion_Score_Factor__c = 'Score Factor',
            LASERCA__TransUnion_Alert_Message__c = 'Alert',
            LASERCA__TransUnion_Indicator__c = true
        );
        insert pcr;
        return pcr;
    }

    @IsTest
    static void testConstructors() {
        // Setup data
        Lead lead = buildLead();
        LASERCA__Personal_Credit_Report__c pcr = buildPCR(lead.Id);
        Test.setCreatedDate(pcr.Id, Datetime.now().addMinutes(-5));

        // Run test
        Test.startTest();
        CreditReportChecker allHistoricalChecker = new CreditReportChecker(lead.Id);
        CreditReportChecker afterDatetimeChecker = new CreditReportChecker(lead.Id, Datetime.now());
        CreditReportChecker.LatestReportDetail crcDetail = SimpleSignupFormController.getLatestCreditReport(lead.Id, true, null);
        Test.stopTest();

        // Validate constructor which provides all historical PCRs
        System.assertEquals(true, allHistoricalChecker.latestReportNoMatch, 'Latest Credit Report should show no match');
        System.assertEquals(lead.Id, allHistoricalChecker.leadId, 'Invalid leadId property defined in class');
        System.assertEquals(1, allHistoricalChecker.reportList.size(), 'Invalid number of credit reports aggregated');
        System.assertEquals(pcr.LASERCA__Credit_Score__c, allHistoricalChecker.latestReport.LASERCA__Credit_Score__c,
            'Invalid credit score val');

        // Validate constructor which provides all PCRs after the specified datetime
        System.assertEquals(0, afterDatetimeChecker.reportList.size(), 'afterDatetimeChecker should return 0 rows');
        System.assertEquals(null, afterDatetimeChecker.latestReport,
            'afterDatetimeChecker should return null for this property');
        System.assertEquals(null, afterDatetimeChecker.latestReportNoMatch,
            'afterDatetimeChecker should return null for this property');

        // CreditReportChecker.LatestReportDetail class checks (instanced from SimpleSignupFormController method)
        System.assertEquals(true, crcDetail.noMatch, 'Detail class invalid noMatch value');
        System.assertEquals(pcr.LASERCA__TransUnion_Score_Factor__c, crcDetail.scoreFactor, 'Detail class invalid scoreFactor value');
        System.assertEquals(pcr.LASERCA__TransUnion_Alert_Message__c, crcDetail.alertMessage, 'Detail class invalid alertMessage value');
    }
}