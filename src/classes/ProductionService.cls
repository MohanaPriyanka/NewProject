/**
 * Created by SarahRenfro on 6/3/2020.
 */

public with sharing class ProductionService {
    @TestVisible
    private static ProductionSelector productionSelector = new ProductionSelector();

    public void onDeleteProduction(List<Production__c> deletedProductions) {
        for (Production__c prod : deletedProductions) {
            if (prod.Verification_Status__c == 'Verified') {
                prod.addError('Production cannot be deleted if "Verified"');
            }
        }
    }

    public List<Production__c> verifyProductions(Set<Id> verifiedBillPeriods) {
        //Get all the transfer parts that are related to Main Transfers related to the Bill Periods
        List<Production__c> verifiedProductions = productionSelector.selectPendingVerificationProductions(verifiedBillPeriods);
        for (Production__c production : verifiedProductions) {
            production.Verification_Status__c = 'Verified';
        }

        return verifiedProductions;
    }

    public List<Production__c> markFirstBillDate(Map<Id, Bill_Period__c> completedBillPeriods) {
        Map<Production__c, Bill_Period__c> productionToBillPeriod = productionSelector.selectProductionByBillPeriod(completedBillPeriods);
        List<Production__c> billedProductions = new List<Production__c>();
        for (Production__c prod : productionToBillPeriod.keySet()) {
            if (prod.First_Date_Production_Billed__c == null) {
                prod.First_Date_Production_Billed__c = productionToBillPeriod.get(prod).Bill_Date__c;
                billedProductions.add(prod);
            }
        }

        return billedProductions;
    }
}