/**
 * Created by rebeccanachison on 1/14/22.
 * Description: Helper class for CSUtilityAccountSubscriptionFactory
 * Tested by: CSUtilityAccountSubscriptionFactoryTest
 */

public with sharing class CSUASFactoryHelper {

    public class UtilityAccountLogWrapper {
        public Utility_Account_Log__c ual;
        public Utility_NMC_Tariff__c sizingMethod;
        public Decimal annualCostOfElectricity;
        public Decimal remainingCapacity;
        public Decimal remainingCost;
        public String subscriptionType;
        public Integer uasNumberCount;
        public UtilityAccountLogWrapper(Utility_Account_Log__c ual) {
            this.ual = ual;
            this.sizingMethod = getUALSizingMethod(ual);
            this.remainingCapacity = calculateAnnualAmount(ual.Annual_kWh__c, ual.Annual_Cost_of_Electricity__c, this.sizingMethod.Value_of_Net_Metering_Credit__c, 'CAPACITY');
            this.remainingCost = calculateAnnualAmount(ual.Annual_Cost_of_Electricity__c, ual.Annual_kWh__c, this.sizingMethod.Value_of_Net_Metering_Credit__c, 'COST');
            this.annualCostOfElectricity = this.remainingCost;
            this.subscriptionType = ual.Lead__r.Product__r.Customer_Subscription_Type__c;
            this.uasNumberCount = 1;
        }
    }

    public class SubscriptionAllocation {
        public Decimal ualRemainingAllocation;
        public Decimal sssRemainingSubscriptionAmount;
        public Decimal annualAmountAssigned;
        public Decimal allocationPercentage;
    }

    /**
     * @description Prevents us from having to constantly do null checks before using the sizing method values
     * @param ual UAL being used to generate UASs
     * @return ual's Sizing Method if it exists or an empty Sizing Method
     */
    private static Utility_NMC_Tariff__c getUALSizingMethod(Utility_Account_Log__c ual) {
        if (ual.Utility_Rate_Class__c == null || ual.Utility_Rate_Class__r.Utility_NMC_Tariff__c == null) {
            return new Utility_NMC_Tariff__c();
        }
        return ual.Utility_Rate_Class__r.Utility_NMC_Tariff__r;
    }

    /**
     * @description Calculates the annual capacity or annual cost for a ual using the net metering credit as a ratio for unit conversion
     * @param annualAmount the field to be calculated, returned as is if not null
     * @param amountToConvert the amount to convert to the desired units
     * @param netMeteringCredit the net metering credit from the ual's sizing method
     * @param type the unit type to convert to
     * @return the annual amount in the desired units
     */
    private static Decimal calculateAnnualAmount(Decimal annualAmount, Decimal amountToConvert, Decimal netMeteringCredit, String type) {
        // use annual amount value if it was already set
        if (annualAmount != null) {
            return annualAmount;
        }
        // we cannot calculate anything if there is no value for conversion or there is no net metering credit
        if (amountToConvert == null || netMeteringCredit == null || netMeteringCredit == 0) {
            return 0;
        }
        // use the net metering credit as a ratio if the value has not been calculated yet
        Decimal netMeteringRatio = type == 'CAPACITY' ? (1 / netMeteringCredit) : netMeteringCredit;
        return (amountToConvert * netMeteringRatio);
    }

    /**
     * @description Calculates the allocations for the subscription including the annual amount assigned and how much is left on the ual and sss to allocate
     * @param sssRemainingSubscriptionAmount the remaining amount on the sss that can be allocated to a single uas
     * @param ualRemainingAllocation the remaining amount on the ual to be allocated
     * @return SubscriptionAllocation object containing the annual amount to be assigned, how much is left on the sss to be allocated, how much is left on the ual for current unit type, and the percentage to subtract from the ual's alternate unit type. Ex if a ual has annual kWh = 1000 and we assign 100 kWh to this UAS then we want to subtract 10% from the remaining annual cost as well
     */
    public static SubscriptionAllocation calculateAllocations(Decimal sssRemainingSubscriptionAmount, Decimal ualRemainingAllocation) {
        // do not create subscription if there is nothing left to allocate
        if (sssRemainingSubscriptionAmount == 0 || ualRemainingAllocation == 0) {
            return null;
        }
        SubscriptionAllocation subscriptionAllocation = new SubscriptionAllocation();
        subscriptionAllocation.annualAmountAssigned = Math.min(sssRemainingSubscriptionAmount, ualRemainingAllocation);
        // deduct the annual assigned amount from the sssSubscription and ual totals
        subscriptionAllocation.sssRemainingSubscriptionAmount = sssRemainingSubscriptionAmount - subscriptionAllocation.annualAmountAssigned;
        subscriptionAllocation.ualRemainingAllocation = ualRemainingAllocation - subscriptionAllocation.annualAmountAssigned;
        // get the percentage of the ual's remaining amount assigned to this uas
        subscriptionAllocation.allocationPercentage = subscriptionAllocation.annualAmountAssigned / ualRemainingAllocation;
        return subscriptionAllocation;
    }

}