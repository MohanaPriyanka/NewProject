/**
 * @description Created by SarahRenfro on 3/10/2021.
 * TestedBy: CSQualificationTestclass, CreditReportCheckerTest
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class CreditReportSelector {

    public List<LASERCA__Personal_Credit_Report__c> getCompletedPCRs(Set<Id> pcrIds) {
        return [
            SELECT Id, LASERCA__Lead__c, LASERCA__Lead__r.Personal_Credit_Report__c, LASERCA__Lead__r.Application_Complete_Date__c,
                 LASERCA__Credit_Score__c
            FROM LASERCA__Personal_Credit_Report__c
            WHERE Id = :pcrIds
        ];
    }

    public List<LASERCA__Personal_Credit_Report__c> retrieveCreditReportsByLead(Id leadId, Datetime queryAfterDateTime) {
        return [
            SELECT Id, LASERCA__Credit_Score__c, LASERCA__TransUnion_Score_Factor__c,
                LASERCA__TransUnion_Alert_Message__c, LASERCA__Experian_Alert_Message__c,
                LASERCA__Experian_Score_Factor__c, LASERCA__TransUnion_Indicator__c,
                LASERCA__Experian_Indicator__c, CreatedDate
            FROM LASERCA__Personal_Credit_Report__c
            WHERE LASERCA__Lead__c = :leadId AND CreatedDate > :queryAfterDateTime
            ORDER BY CreatedDate DESC
        ];
    }
}