/**
 * Test: ProductEscalatorTest
*/


public without sharing class ProductEscalatorSelector {
    public static Map<Id, List<Product_Escalator__c>> getProductEscalationMap(){
        Map<Id, List<Product_Escalator__c>> escalatorMap = new Map<Id, List<Product_Escalator__c>>();
        for (Product_Escalation_Schedule__c productSchedule : [
            SELECT Id, (
                SELECT Id, Product_Escalation_Schedule__c, New_NMC_Discount__c,
                    New_Solar_Electricity_Rate__c, Starting_Credit_Transfer__c
                FROM Product_Escalators__r
                ORDER BY Starting_Credit_Transfer__c DESC
            )
            FROM Product_Escalation_Schedule__c
        ]) {
            escalatorMap.put(productSchedule.Id, productSchedule.Product_Escalators__r);
        }
        return escalatorMap;
    }
}