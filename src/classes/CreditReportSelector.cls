/**
 * Created by SarahRenfro on 3/10/2021.
 * TestedBy: CSQualificationTestclass
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class CreditReportSelector {

    public List<LASERCA__Personal_Credit_Report__c> getCompletedPCRs(Set<Id> pcrIds) {
        return [
            SELECT Id, LASERCA__Lead__c, LASERCA__Lead__r.Personal_Credit_Report__c, LASERCA__Lead__r.Application_Complete_Date__c,
                Approval_Status__c,LASERCA__Contact__c, LASERCA__Sum_of_monthly_Personal_Debt__c, Lead_from_Contact__c,
                Maximum_Disbursement_Monthly__c, LASERCA__Credit_Score__c, LASERCA__Credit_Score_TransUnion__c
            FROM LASERCA__Personal_Credit_Report__c
            WHERE Id = :pcrIds
        ];
    }
}