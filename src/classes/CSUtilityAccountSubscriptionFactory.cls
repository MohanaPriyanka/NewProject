/**
 * Created by mstackhouse on 12/17/2018.
 * Description: 
 * Test: CSUtilityAccountSubscriptionFactoryTest
 */


public with sharing class CSUtilityAccountSubscriptionFactory {
    public static List<Utility_Account_Subscription__c> generateSubscriptions(
        List<Utility_Account_Log__c> uals,
        List<Shared_Solar_System__c> sharedSolarSystems,
        List<Opportunity> opportunities
    ) {
        Map<Id, Decimal> sssRemainingSubscriptionCostMap = new Map<Id, Decimal>();
        Map<Id, Decimal> sssRemainingSubscriptionCapacityMap = new Map<Id, Decimal>();

        for (Shared_Solar_System__c sss : sharedSolarSystems) {
            sssRemainingSubscriptionCostMap.put(sss.Id, sss.Maximum_Subscription_Cost__c);
            Decimal maximumSubscriptionkWh = calculateMaximumkWh(sss);
            sssRemainingSubscriptionCapacityMap.put(sss.Id, maximumSubscriptionkWh);
        }

        List<Utility_Account_Subscription__c> UASes = new List<Utility_Account_Subscription__c>();

        for (Utility_Account_Log__c ual : uals) {
            if (ual.Lead__r.Product__r.Customer_Subscription_Type__c == 'kWh') {
                // we need to make copies of the map for each UAL, otherwise we don't create enough UASes
                Map<Id, Decimal> copyOfSSSRemainingSubscriptionCapacityMap = new Map<Id, Decimal>(sssRemainingSubscriptionCapacityMap);
                UASes.addAll(createUASbyCapacity(ual, copyOfSSSRemainingSubscriptionCapacityMap, opportunities));
            } else if (ual.Lead__r.Product__r.Customer_Subscription_Type__c == 'Electricity Cost ($)') {
                // we need to make copies of the map for each UAL, otherwise we don't create enough UASes
                Map<Id, Decimal> copyOfSSSRemainingSubscriptionCostMap = new Map<Id, Decimal>(sssRemainingSubscriptionCostMap);
                UASes.addAll(createUASbyCost(ual, copyOfSSSRemainingSubscriptionCostMap, opportunities));
            }
        }
        return UASes;
    }

    public static List<Utility_Account_Subscription__c> createUASbyCapacity(
        Utility_Account_Log__c ual,
        Map<Id, Decimal> sssRemainingSubscriptionCapacityMap,
        List<Opportunity> opportunities
    ) {
        Integer uasNumberCounter = 1;
        Decimal remainingUALCapacityToAllocate = ual.Proposed_kWh__c;
        List<Utility_Account_Subscription__c> UASes = new List<Utility_Account_Subscription__c>();

        for (Opportunity opp : opportunities) {
            if (sssRemainingSubscriptionCapacityMap.containsKey(opp.Shared_Solar_System__c)){
                Decimal sssRemainingSubscriptionCapacity = sssRemainingSubscriptionCapacityMap.get(opp.Shared_Solar_System__c);
                Decimal annualElectricityCapacityAssigned = Math.min(remainingUALCapacityToAllocate, sssRemainingSubscriptionCapacity);
                System.debug(annualElectricityCapacityAssigned);
                System.debug(sssRemainingSubscriptionCapacity);
                if (annualElectricityCapacityAssigned > 0) {
                    //Deduct the assigned value from the sss remaining subscription cost and then put it back into the map
                    sssRemainingSubscriptionCapacity -= annualElectricityCapacityAssigned;
                    sssRemainingSubscriptionCapacityMap.put(opp.Shared_Solar_System__c, sssRemainingSubscriptionCapacity);

                    remainingUALCapacityToAllocate -= annualElectricityCapacityAssigned;
                    UASes.add(new Utility_Account_Subscription__c(
                        Name = ual.Name,
                        Name_on_Account__c = ual.Name_on_Account__c,
                        Opportunity__c = opp.Id,
                        Utility_Account_Log__c = ual.Id,
                        UAS_Number__c = uasNumberCounter,
                        Annual_kwh_subscription_future__c = annualElectricityCapacityAssigned
                    ));
                    uasNumberCounter++;
                }
            }
        }
        return UASes;
    }

    public static List<Utility_Account_Subscription__c> createUASbyCost(
        Utility_Account_Log__c ual,
        Map<Id, Decimal> sssRemainingSubscriptionCostMap,
        List<Opportunity> opportunities
    ) {
        Integer uasNumberCounter = 1;
        Decimal remainingUALCostToAllocate = ual.Annual_Cost_of_Electricity__c;
        List<Utility_Account_Subscription__c> UASes = new List<Utility_Account_Subscription__c>();

        for (Opportunity opp : opportunities) {
            if (sssRemainingSubscriptionCostMap.containsKey(opp.Shared_Solar_System__c)){
                Decimal sssRemainingSubscriptionCost = sssRemainingSubscriptionCostMap.get(opp.Shared_Solar_System__c);
                Decimal annualElectricityCostAssigned = Math.min(remainingUALCostToAllocate, sssRemainingSubscriptionCost);
                System.debug(annualElectricityCostAssigned);
                System.debug(sssRemainingSubscriptionCost);
                if (annualElectricityCostAssigned > 0) {
                    //Deduct the assigned value from the sss remaining subscription cost and then put it back into the map
                    sssRemainingSubscriptionCost -= annualElectricityCostAssigned;
                    sssRemainingSubscriptionCostMap.put(opp.Shared_Solar_System__c, sssRemainingSubscriptionCost);

                    remainingUALCostToAllocate = remainingUALCostToAllocate - annualElectricityCostAssigned;
                    UASes.add(new Utility_Account_Subscription__c(
                        Name = ual.Name,
                        Name_on_Account__c = ual.Name_on_Account__c,
                        Opportunity__c = opp.Id,
                        Annual_Cost_of_Electricity__c = ual.Annual_Cost_of_Electricity__c,
                        Utility_Account_Log__c = ual.Id,
                        UAS_Number__c = uasNumberCounter,
                        calculated_annual_cost_of_electricity__c = annualElectricityCostAssigned,
                        Subscribed_Annual_Cost_of_Electricity__c = annualElectricityCostAssigned
                    ));
                    uasNumberCounter++;
                }
            }
        }
        return UASes;
    }

    public static Decimal calculateMaximumkWh(Shared_Solar_System__c sss) {
        return sss.Maximum_Subscription_Capacity_kW_DC__c * sss.Expected_Yield_kWh_kW__c;
    }

}
