/**
 * @description Created by peteryao on 8/5/20.
 * Tested By: ProductSelectorTest, CSUtilityAccountSubscriptionFactoryTest
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

    public Map<Id, Product2> selectProductsForSubscriptionCreation() {
        return new Map<Id, Product2>([
            SELECT Id, Program__c, Sizing_Method__c, Customer_Subscription_Type__c, (
                SELECT Id, Name, Size_Ratio__c, Utility_NMC_Tariff__r.Customer_Type__c,
                    Utility_NMC_Tariff__r.Minimum_kWh__c, Utility_NMC_Tariff__r.Maximum_kWh__c,
                    Utility_NMC_Tariff__r.Utility_Relationship__c, Utility_NMC_Tariff__c
                FROM Product_Tariffs__r
            )
            FROM Product2
            WHERE Product_Type__c = 'Community Solar'
        ]);
    }
}