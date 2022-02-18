/**
 * @description Backs into an Annual kWh or Cost amount to get to a desired Approved Change in Subscription
 * Tested By: SubscriptionTransferCalculatorTest
 */
public without sharing class SubscriptionTransferCalculator {
    /**
     * @description Backs into a New_Annual_kWh__c value that would result in the desired Approved_Change_in_Subscription__c
     * Will be off, because the desired amount has been previously rounded.
     * @param subscriptionType Either kWh or Electricity Cost ($)
     * @param sharedSolarSystem SSS with Total_System_Size_kWh_DC, Expected_Yield_kWh_kW__c and Utility__r.Number_of_Decimal_Places
     * @param sizingMethod  Sizing Method with Size_Ratio
     * @param previouskWDCSubscription The desired Approved_Change_in_Subscription__c
     * @param desiredApprovedChangeInSubscription The desired Approved_Change_in_Subscription__c
     * @return A New_Annual_kWh__c or New_Annual_Cost__c
     */
    public Decimal getAnnualkWhOrCost(String subscriptionType, Shared_Solar_System__c sharedSolarSystem, Utility_NMC_Tariff__c sizingMethod,
        Decimal previouskWDCSubscription, Decimal desiredApprovedChangeInSubscription) {
        if (subscriptionType == 'kWh') {
            return getAnnualkWh(sharedSolarSystem, sizingMethod, desiredApprovedChangeInSubscription, previouskWDCSubscription);
        } else {
            return getAnnualCost(sharedSolarSystem, sizingMethod, desiredApprovedChangeInSubscription, previouskWDCSubscription);
        }
    }

    @TestVisible
    private Decimal getAnnualkWh(Shared_Solar_System__c sharedSolarSystem, Utility_NMC_Tariff__c sizingMethod,
        Decimal desiredApprovedChangeInSubscription, Decimal previouskWDCSubscription) {
        Decimal systemChangekWDCSubscription = getSystemChangekWDCSubscription(
            sharedSolarSystem.Total_System_Size_kWh_DC__c,
            (Integer) sharedSolarSystem.Utility__r.Number_of_Decimal_Places__c,
            desiredApprovedChangeInSubscription,
            previouskWDCSubscription
        );
        Decimal newAnnualkWh =
            systemChangekWDCSubscription*sharedSolarSystem.Expected_Yield_kWh_kW__c/sizingMethod.Size_Ratio__c;
        return newAnnualkWh.setScale(2, RoundingMode.HALF_UP);
    }

    @TestVisible
    private Decimal getAnnualCost(Shared_Solar_System__c sharedSolarSystem, Utility_NMC_Tariff__c sizingMethod,
        Decimal desiredApprovedChangeInSubscription, Decimal previouskWDCSubscription) {
        Decimal systemChangekWDCSubscription = getSystemChangekWDCSubscription(
            sharedSolarSystem.Total_System_Size_kWh_DC__c,
            (Integer) sharedSolarSystem.Utility__r.Number_of_Decimal_Places__c,
            desiredApprovedChangeInSubscription,
            previouskWDCSubscription
        );
        Decimal newAnnualCost =
            systemChangekWDCSubscription*sharedSolarSystem.Expected_Yield_kWh_kW__c*sizingMethod.Value_of_NMC__c;
        return newAnnualCost.setScale(6, RoundingMode.HALF_UP);
    }


    private Decimal getSystemChangekWDCSubscription(Decimal totalSystemSize, Integer utilityNumberOfDecimalPlaces,
        Decimal desiredApprovedChangeInSubscription, Decimal previouskWDCSubscription) {
        Decimal systemChangekWDCRounded = desiredApprovedChangeInSubscription + previouskWDCSubscription;
        Decimal systemChangePercentShareOfSystem = systemChangekWDCRounded/totalSystemSize;
        systemChangePercentShareOfSystem =
            systemChangePercentShareOfSystem.setScale(utilityNumberOfDecimalPlaces + 2, RoundingMode.HALF_UP);
        Decimal systemChangekWDCSubscription = systemChangePercentShareOfSystem * totalSystemSize;
        return systemChangekWDCSubscription;
    }

}