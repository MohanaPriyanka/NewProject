/**
 * Created by mstackhouse on 12/17/2018.
 * Description:
 * Test: CSUtilityAccountSubscriptionFactoryTest
 */


public with sharing class CSUtilityAccountSubscriptionFactory {

    public class UASOrder {
        public Utility_Account_Subscription__c uas;
        public Subscription_Order__c sOrder;
    }

    public static List<Utility_Account_Subscription__c> generateSubscriptions(
        List<Utility_Account_Log__c> uals,
        List<Shared_Solar_System__c> sharedSolarSystems,
        List<Opportunity> opportunities
    ) {
        return generateSubscriptions(uals, sharedSolarSystems, opportunities, null);
    }

    public static List<Utility_Account_Subscription__c> generateSubscriptions(
        List<Utility_Account_Log__c> uals,
        List<Shared_Solar_System__c> sharedSolarSystems,
        List<Opportunity> opportunities,
        List<UASOrder> uasOrders
    ) {
        Map<Id, Decimal> sssRemainingSubscriptionCostMap = new Map<Id, Decimal>();
        Map<Id, Decimal> sssRemainingSubscriptionCapacityMap = new Map<Id, Decimal>();

        for (Shared_Solar_System__c sss : sharedSolarSystems) {
            sssRemainingSubscriptionCostMap.put(sss.Id, sss.Maximum_Subscription_Cost__c);
            Decimal maximumSubscriptionkWh = calculateMaximumkWh(sss);
            sssRemainingSubscriptionCapacityMap.put(sss.Id, maximumSubscriptionkWh);
        }

        List<Utility_Account_Subscription__c> uases = new List<Utility_Account_Subscription__c>();

        for (Utility_Account_Log__c ual : uals) {
            if (ual.Lead__r.Product__r.Customer_Subscription_Type__c == 'kWh') {
                // we need to make copies of the map for each UAL, otherwise we don't create enough UASes
                Map<Id, Decimal> copyOfSSSRemainingSubscriptionCapacityMap = new Map<Id, Decimal>(sssRemainingSubscriptionCapacityMap);
                uases.addAll(createUASbyCapacity(ual, copyOfSSSRemainingSubscriptionCapacityMap, opportunities, uasOrders));
            } else if (ual.Lead__r.Product__r.Customer_Subscription_Type__c == 'Electricity Cost ($)') {
                // we need to make copies of the map for each UAL, otherwise we don't create enough UASes
                Map<Id, Decimal> copyOfSSSRemainingSubscriptionCostMap = new Map<Id, Decimal>(sssRemainingSubscriptionCostMap);
                uases.addAll(createUASbyCost(ual, copyOfSSSRemainingSubscriptionCostMap, opportunities, uasOrders));
            }
        }
        return uases;
    }


    public static List<Utility_Account_Subscription__c> createUASbyCapacity(
        Utility_Account_Log__c ual,
        Map<Id, Decimal> sssRemainingSubscriptionCapacityMap,
        List<Opportunity> opportunities
    ) {
        return createUASbyCapacity(ual, sssRemainingSubscriptionCapacityMap, opportunities, null);
    }

    public static List<Utility_Account_Subscription__c> createUASbyCapacity(
        Utility_Account_Log__c ual,
        Map<Id, Decimal> sssRemainingSubscriptionCapacityMap,
        List<Opportunity> opportunities,
        List<UASOrder> uasOrders
    ) {
        Integer uasNumberCounter = 1;
        Decimal remainingUALCapacityToAllocate = ual.Proposed_kWh__c;
        List<Utility_Account_Subscription__c> uases = new List<Utility_Account_Subscription__c>();

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
                    Utility_Account_Subscription__c uas = new Utility_Account_Subscription__c(
                        Name = ual.Name,
                        Name_on_Account__c = ual.Name_on_Account__c,
                        Opportunity__c = opp.Id,
                        Utility_Account_Log__c = ual.Id,
                        UAS_Number__c = uasNumberCounter,
                        Annual_kwh_subscription_future__c = annualElectricityCapacityAssigned
                    );
                    uasNumberCounter++;
                    uases.add(uas);
                    createSOByCapacity(uasOrders, uas, annualElectricityCapacityAssigned);
                }
            }
        }
        return uases;
    }


    public static List<Utility_Account_Subscription__c> createUASbyCost(
        Utility_Account_Log__c ual,
        Map<Id, Decimal> sssRemainingSubscriptionCostMap,
        List<Opportunity> opportunities
    ) {
        return createUASbyCost(ual, sssRemainingSubscriptionCostMap, opportunities, null);
    }

    public static List<Utility_Account_Subscription__c> createUASbyCost(
        Utility_Account_Log__c ual,
        Map<Id, Decimal> sssRemainingSubscriptionCostMap,
        List<Opportunity> opportunities,
        List<UASOrder> uasOrders
    ) {
        Integer uasNumberCounter = 1;
        Decimal remainingUALCostToAllocate = ual.Annual_Cost_of_Electricity__c;
        List<Utility_Account_Subscription__c> uases = new List<Utility_Account_Subscription__c>();

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
                    Utility_Account_Subscription__c uas = new Utility_Account_Subscription__c(
                        Name = ual.Name,
                        Name_on_Account__c = ual.Name_on_Account__c,
                        Opportunity__c = opp.Id,
                        Annual_Cost_of_Electricity__c = ual.Annual_Cost_of_Electricity__c,
                        Utility_Account_Log__c = ual.Id,
                        UAS_Number__c = uasNumberCounter,
                        calculated_annual_cost_of_electricity__c = annualElectricityCostAssigned,
                        Subscribed_Annual_Cost_of_Electricity__c = annualElectricityCostAssigned
                    );
                    uasNumberCounter++;
                    uases.add(uas);
                    createSOByCost(uasOrders, uas, annualElectricityCostAssigned);
                }
            }
        }
        return uases;
    }

    private static void createSOByCapacity(List<UASOrder> uasOrders, Utility_Account_Subscription__c uas, Decimal annualElectricityCapacityAssigned ) {
        if (uasOrders != null) {
            UASOrder order = new UASOrder();
            order.uas = uas;

            Subscription_Order__c so = new Subscription_Order__c(
                Type__c = 'Initial',
                Change_in_Annual_kWh__c = annualElectricityCapacityAssigned,
                Effective_Date__c = Date.today(),
                Approval_Status__c = 'Approved'
            );
            order.sOrder = so;
            uasOrders.add(order);
        }
    }

    private static void createSOByCost(List<UASOrder> uasOrders, Utility_Account_Subscription__c uas, Decimal annualElectricityCostAssigned) {
        if(uasOrders != null) {
            UASOrder order = new UASOrder();
            Subscription_Order__c so = new Subscription_Order__c(
                Type__c = 'Initial',
                Change_in_Annual_Cost__c = annualElectricityCostAssigned,
                Effective_Date__c = Date.today(),
                Approval_Status__c = 'Approved'
            );
            order.sOrder = so;
            order.uas = uas;
            uasOrders.add(order);
        }
    }


    public static Decimal calculateMaximumkWh(Shared_Solar_System__c sss) {
        return sss.Maximum_Subscription_Capacity_kW_DC__c * sss.Expected_Yield_kWh_kW__c;
    }

}