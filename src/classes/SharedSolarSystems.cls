/**
 * Created by SarahRenfro on 7/6/2020.
 * Description: Domain class for SSS
 * Test: CSUtilityAccountSubscriptionFactoryTest
 */

public inherited sharing class SharedSolarSystems {
    public List<Shared_Solar_System__c> records;
    @TestVisible
    private static FeatureService featureService = new FeatureService();

    public static Decimal calculateMaximumkWh(Shared_Solar_System__c sss, Utility_Account_Log__c ual){
        Decimal sssRemainingSubscriptionCapacity = sss.Maximum_Subscription_Capacity_kWDC__c * sss.Expected_Yield_kWh_kW__c;
        if (featureService.isEnabled('Sizing_Method') && sss.Product__r.Customer_Subscription_Type__c == 'kWh' ) {
            if (sss.Product__r.Sizing_Method__c == 'Rate Class Ratio' && ual != null && ual.Utility_Rate_Class__c != null) {
                sssRemainingSubscriptionCapacity = sssRemainingSubscriptionCapacity/ual.Utility_Rate_Class__r.Utility_NMC_Tariff__r.Size_Ratio__c;
            } else if (sss.Product__r.Sizing_Method__c == 'Project Ratio'){
                sssRemainingSubscriptionCapacity = sssRemainingSubscriptionCapacity/sss.Utility_NMC_Tariff__r.Size_Ratio__c;
            }
        }
        return sssRemainingSubscriptionCapacity.setScale(2, RoundingMode.HALF_DOWN);
    }

}