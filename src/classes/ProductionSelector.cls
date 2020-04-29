/**
 * Created by SarahRenfro on 4/13/2020.
 *
 * Tested By: ProductionSelectorTest, BillPeriodServiceTest
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public inherited sharing class ProductionSelector {
    public List<Production__c> selectPendingVerificationProductions(Set<Id> bpIds) {
        return [
            SELECT Id, Name, Verification_Status__c, First_Date_Production_Billed__c
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

    public Map<Production__c, Bill_Period__c> selectProductionByBillPeriod(Map<Id, Bill_Period__c> bpMap) {
        Map<Production__c, Bill_Period__c> productionToBillPeriod = new Map<Production__c, Bill_Period__c>();
        List<Production__c> allProductions = [
            SELECT Id, Name, Verification_Status__c, First_Date_Production_Billed__c,
            (SELECT Id, Transfer__c, Transfer__r.Bill_Period__c
                FROM Transfer_Parts__r
                WHERE Transfer__r.Transfer_Type__c = 'Main'
                AND Transfer__r.Bill_Period__c IN :bpMap.keySet()
                LIMIT 1
            )
            FROM Production__c
            WHERE Id IN (
                SELECT Production__c
                FROM Transfer_Part__c
                WHERE Transfer__r.Transfer_Type__c = 'Main'
                AND Transfer__r.Bill_Period__c IN :bpMap.keySet()
            )
        ];

        for (Production__c prod : allProductions) {
            for (Transfer_Part__c part : prod.Transfer_Parts__r) {
                productionToBillPeriod.put(prod, bpMap.get(part.Transfer__r.Bill_Period__c));
            }
        }

        return productionToBillPeriod;
    }
}