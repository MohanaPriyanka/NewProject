/**
 * Created by peteryao on 8/5/20.
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public inherited sharing class ProductSelector {
    public List<Product2> selectForACToDCConversion(Set<Id> ids) {
        return [
            SELECT Id, Name, Max_Subscription_kW_AC_for_DC_calc__c
            FROM Product2
            WHERE Id = :ids
            AND Max_Subscription_kW_AC_for_DC_calc__c != NULL
        ];
    }
}