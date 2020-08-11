/**
 * Created by SarahRenfro on 7/6/2020.
 * Description: Domain class for SSS
 * Test: CSUtilityAccountSubscriptionFactoryTest, SharedSolarSystemsTest
 */

public inherited sharing class SharedSolarSystems {
    private List<Shared_Solar_System__c> records;
    @TestVisible
    private static FeatureService featureService = new FeatureService();
    @TestVisible
    private static ProductSelector productSelector = new ProductSelector();

    public SharedSolarSystems(List<Shared_Solar_System__c> records) {
        this.records = records;
    }

    public static Decimal calculateMaximumkWh(Shared_Solar_System__c sss){
        Decimal sssRemainingSubscriptionCapacity = sss.Maximum_Subscription_Capacity_kWDC__c * sss.Expected_Yield_kWh_kW__c;
        if (featureService.isEnabled('Sizing_Method') && sss.Product__r.Customer_Subscription_Type__c == 'kWh'
                && sss.Product__r.Sizing_Method__c == 'Project Ratio') {
            sssRemainingSubscriptionCapacity = sssRemainingSubscriptionCapacity/sss.Utility_NMC_Tariff__r.Size_Ratio__c;
        }
        return sssRemainingSubscriptionCapacity.setScale(2, RoundingMode.HALF_DOWN);
    }

    public void calculateMaximumSubscriptionCapacityForSMART() {
        Set<Id> productIds = new Set<Id>();
        for (Shared_Solar_System__c sss : records) {
            productIds.add(sss.Product__c);
        }
        Map<Id, Product2> productsForConversionMap =
                new Map<Id, Product2>(productSelector.selectForACToDCConversion(productIds));
        if (productsForConversionMap.isEmpty()) {
            return;
        }
        for (Shared_Solar_System__c sss : records) {
            Product2 productForConversion = productsForConversionMap.get(sss.Product__c);
            if (productForConversion == null || sss.Total_System_Size_kWh_DC__c == null || sss.Total_System_Size_kW_AC__c == null) {
                continue;
            } else {
                sss.Maximum_Subscription_Capacity_kWDC__c =
                        productForConversion.Max_Subscription_kW_AC_for_DC_calc__c *
                                (sss.Total_System_Size_kWh_DC__c/sss.Total_System_Size_kW_AC__c);
            }
        }
    }

}