/**
 * @author JeffParlin on 12/04/2020
 * @description Class structure to support checking credit report history/status of leads
 * <p>
 * Tested by CreditReportCheckerTest
 */
public without sharing class CreditReportChecker {

    public Id leadId;
    public LASERCA__Personal_Credit_Report__c latestReport;
    public Boolean latestReportNoMatch;
    public Datetime queryAfterDateTime;
    public List<LASERCA__Personal_Credit_Report__c> reportList;

    /**
     * @description Constructor 1: Loads relevant data on PCRs for lead id and PCR createdDate > specified date
     * @param leadId Lead to aggregate PCR information for
     * @param dt Used to query PCRs created after a certain datetime. Useful for new generation and polling in SSF.
     */
    public CreditReportChecker(Id leadId, Datetime dt) {
        this.leadId = leadId;
        this.queryAfterDateTime = dt;
        this.reportList = retrieveCreditReportsByLead();
        this.latestReport = !reportList.isEmpty() ? reportList[0] : null;
        this.latestReportNoMatch = isNoMatch(this.latestReport);
    }

    /**
     * @description Constructor 2: Loads relevant data on PCRs for lead id. Looks at all historical PCRs.
     * @param leadId Lead to aggregate PCR information for
     */
    public CreditReportChecker(Id leadId) {
        this.leadId = leadId;
        this.queryAfterDateTime = Datetime.newInstance(2000,1,1);
        this.reportList = retrieveCreditReportsByLead();
        this.latestReport = !reportList.isEmpty() ? reportList[0] : null;
        this.latestReportNoMatch = isNoMatch(this.latestReport);
    }

    /**
     * @description Outputs Detail object corresponding to truncated credit report information
     * @return Detail object
     */
    public LatestReportDetail getLatestReportDetail() {
        LatestReportDetail detail = new LatestReportDetail();
        detail.noMatch = latestReportNoMatch;
        detail.createdDate = latestReport?.CreatedDate;
        detail.scoreFactor = latestReport?.LASERCA__TransUnion_Score_Factor__c;
        detail.alertMessage = latestReport?.LASERCA__TransUnion_Alert_Message__c;
        return detail;
    }

    private Boolean isNoMatch(LASERCA__Personal_Credit_Report__c report) {
        if (report == null) {
            return null;
        } else {
            return report.LASERCA__Credit_Score__c == '9999' ? true : false;
        }
    }

    /**
     * @description Retrieve Personal Credit Reports (PCRs) for specified Lead created after specified date/time
     * @return List of PCRs
     */
    @TestVisible
    private List<LASERCA__Personal_Credit_Report__c> retrieveCreditReportsByLead() {
        return [
            SELECT Id, LASERCA__Credit_Score__c, LASERCA__TransUnion_Score_Factor__c,
                LASERCA__TransUnion_Alert_Message__c, CreatedDate
            FROM LASERCA__Personal_Credit_Report__c
            WHERE LASERCA__Lead__c =: leadId AND CreatedDate > :queryAfterDateTime
            ORDER BY CreatedDate DESC
        ];
    }

    /**
     * @description PII-scrubbed apex-defined object for API or SSF module retrieval of latest PCR data
     */
    public class LatestReportDetail {
        @AuraEnabled public Boolean noMatch;
        @AuraEnabled public String scoreFactor;
        @AuraEnabled public String alertMessage;
        @AuraEnabled public Datetime createdDate;
    }

}