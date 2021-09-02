/**
 * @description Created by SarahRenfro on 3/10/2021.
 * TestedBy: CSQualificationTestclass
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class CreditReportSelector {

    public List<LASERCA__Personal_Credit_Report__c> getCompletedPCRs(Set<Id> pcrIds) {
        return [
            SELECT Id, LASERCA__Lead__c, LASERCA__Lead__r.Personal_Credit_Report__c, LASERCA__Lead__r.Application_Complete_Date__c,
                LASERCA__Contact__c, Lead_from_Contact__c, LASERCA__Credit_Score__c
            FROM LASERCA__Personal_Credit_Report__c
            WHERE Id = :pcrIds
        ];
    }
}