/**
 * Created by SarahRenfro on 4/13/2020.
 *
 * Tested By: BillPeriodServiceTest
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public inherited sharing class ProductionSelector {
    public List<Production__c> selectPendingVerificationProductions(Set<Id> bpIds) {
        return [
            SELECT Id, Name, Verification_Status__c
            FROM Production__c
            WHERE Id IN (
                SELECT Production__c
                FROM Transfer_Part__c
                WHERE Transfer__r.Transfer_Type__c = 'Main'
                AND Transfer__r.Bill_Period__c IN :bpIds
            )
            AND Verification_Status__c = 'Pending Verification'
        ];
    }
}