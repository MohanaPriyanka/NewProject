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
    public class SSSSubscription {
        public Shared_Solar_System__c sss;
        public Decimal maximumkWh;
        public Decimal maximumCost;
        public String sizingMethod;
    }

    @TestVisible
    private static FeatureService featureService = new FeatureService();
    @TestVisible
    private static Map<Id, SSSSubscription> sssSubscriptionMap = new Map<Id, SSSSubscription>();

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

        for (Shared_Solar_System__c sss : sharedSolarSystems) {
            SSSSubscription sssSubscription = new SSSSubscription();
            sssSubscription.sss = sss;
            sssSubscription.sizingMethod = sss.Product__r.Sizing_Method__c;
            sssSubscription.maximumkWh = calculateMaximumkWh(sss, null);
            sssSubscription.maximumCost = sss.Maximum_Subscription_Cost__c;
            sssSubscriptionMap.put(sss.Id, sssSubscription);
        }

        List<Utility_Account_Subscription__c> uases = new List<Utility_Account_Subscription__c>();

        for (Utility_Account_Log__c ual : uals) {
            if (ual.Lead__r.Product__r.Customer_Subscription_Type__c == 'kWh') {
                uases.addAll(createUASbyCapacity(ual, opportunities, uasOrders));
            } else if (ual.Lead__r.Product__r.Customer_Subscription_Type__c == 'Electricity Cost ($)') {
                uases.addAll(createUASbyCost(ual, opportunities, uasOrders));
            }
        }
        return uases;
    }


    public static List<Utility_Account_Subscription__c> createUASbyCapacity(
        Utility_Account_Log__c ual,
        List<Opportunity> opportunities
    ) {
        return createUASbyCapacity(ual, opportunities, null);
    }

    public static List<Utility_Account_Subscription__c> createUASbyCapacity(
        Utility_Account_Log__c ual,
        List<Opportunity> opportunities,
        List<UASOrder> uasOrders
    ) {
        Integer uasNumberCounter = 1;
        Decimal remainingUALCapacityToAllocate;
        if (featureService.isEnabled('Sizing_Method')) {
            remainingUALCapacityToAllocate = ual.Annual_kWh__c;
        } else {
            remainingUALCapacityToAllocate = ual.Proposed_kWh__c;
        }
        List<Utility_Account_Subscription__c> uases = new List<Utility_Account_Subscription__c>();

        for (Opportunity opp : opportunities) {
            if (sssSubscriptionMap.containsKey((opp.Shared_Solar_System__c))) {
                SSSSubscription sssSubscription = sssSubscriptionMap.get(opp.Shared_Solar_System__c);
                Decimal sssRemainingSubscriptionCapacity = sssSubscription.maximumkWh;

                if (featureService.isEnabled('Sizing_Method') && sssSubscription.sizingMethod == 'Rate Class Ratio') {
                    sssRemainingSubscriptionCapacity = calculateMaximumkWh(sssSubscription.sss, ual);
                }
                Decimal annualElectricityCapacityAssigned = Math.min(remainingUALCapacityToAllocate, sssRemainingSubscriptionCapacity);
                System.debug(annualElectricityCapacityAssigned);
                System.debug(sssRemainingSubscriptionCapacity);
                if (annualElectricityCapacityAssigned > 0) {
                    //Deduct the assigned value from the sss remaining subscription cost and then put it back into the map
                    sssRemainingSubscriptionCapacity -= annualElectricityCapacityAssigned;
                    sssSubscription.maximumkWh = sssRemainingSubscriptionCapacity;

                    remainingUALCapacityToAllocate -= annualElectricityCapacityAssigned;
                    Utility_Account_Subscription__c uas = new Utility_Account_Subscription__c(
                        Name = ual.Name,
                        Name_on_Account__c = ual.Name_on_Account__c,
                        Opportunity__c = opp.Id,
                        Utility_Account_Log__c = ual.Id,
                        UAS_Number__c = uasNumberCounter,
                        Annual_kwh_subscription_future__c = annualElectricityCapacityAssigned
                    );

                    populateSizingMethod(ual, uas, sssSubscription);
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
        List<Opportunity> opportunities
    ) {
        return createUASbyCost(ual, opportunities, null);
    }

    public static List<Utility_Account_Subscription__c> createUASbyCost(
        Utility_Account_Log__c ual,
        List<Opportunity> opportunities,
        List<UASOrder> uasOrders
    ) {
        Integer uasNumberCounter = 1;
        Decimal remainingUALCostToAllocate = ual.Annual_Cost_of_Electricity__c;
        List<Utility_Account_Subscription__c> uases = new List<Utility_Account_Subscription__c>();

        for (Opportunity opp : opportunities) {
            if (sssSubscriptionMap.containsKey(opp.Shared_Solar_System__c)){
                SSSSubscription sssSubscription = sssSubscriptionMap.get(opp.Shared_Solar_System__c);
                Decimal sssRemainingSubscriptionCost = sssSubscription.maximumCost;
                Decimal annualElectricityCostAssigned = Math.min(remainingUALCostToAllocate, sssRemainingSubscriptionCost);
                System.debug(annualElectricityCostAssigned);
                System.debug(sssRemainingSubscriptionCost);
                if (annualElectricityCostAssigned > 0) {
                    //Deduct the assigned value from the sss remaining subscription cost and then put it back into the map
                    sssRemainingSubscriptionCost -= annualElectricityCostAssigned;
                    sssSubscription.maximumCost = sssRemainingSubscriptionCost;
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

                    populateSizingMethod(ual, uas, sssSubscription);
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
                New_Annual_kWh__c = annualElectricityCapacityAssigned,
                Effective_Date__c = System.now(),
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
                New_Annual_Cost__c = annualElectricityCostAssigned,
                Effective_Date__c = System.now(),
                Approval_Status__c = 'Approved'
            );
            order.sOrder = so;
            order.uas = uas;
            uasOrders.add(order);
        }
    }

    private static void populateSizingMethod(Utility_Account_Log__c ual, Utility_Account_Subscription__c uas, SSSSubscription sssSubscription) {
        if (!featureService.isEnabled('Sizing_Method')) {
            return;
        }
        if (sssSubscription.sizingMethod == 'Rate Class Ratio') {
            if (ual.Utility_Rate_Class__c != null) {
                uas.Sizing_Method__c = ual.Utility_Rate_Class__r.Utility_NMC_Tariff__c;
            } else {
                //CSAP does not populate the UAL's Rate Class before conversion. We do not want to throw an error.
                //We can default to the Sizing Method on the SSS and flag ops (case or comment?)
                uas.Sizing_Method__c = sssSubscription.sss.Utility_NMC_Tariff__c;
                uas.Subscription_Comment_c__c = 'Utility Account did not have a Rate Class assigned upon conversion. ' +
                    'Therefore this subscription was created using the default Sizing Method on the SSS.';
            }
        } else {
            uas.Sizing_Method__c = sssSubscription.sss.Utility_NMC_Tariff__c;
        }
    }

    public static Decimal calculateMaximumkWh(Shared_Solar_System__c sss, Utility_Account_Log__c ual){
        Decimal sssRemainingSubscriptionCapacity = sss.Maximum_Subscription_Capacity_kWDC__c * sss.Expected_Yield_kWh_kW__c;
        if (featureService.isEnabled('Sizing_Method') && sss.Billing_Method__c == 'kWh' ) {
            if (sss.Product__r.Sizing_Method__c == 'Rate Class Ratio' && ual != null && ual.Utility_Rate_Class__c != null) {
                sssRemainingSubscriptionCapacity = sssRemainingSubscriptionCapacity/ual.Utility_Rate_Class__r.Utility_NMC_Tariff__r.Size_Ratio__c;
            } else if (sss.Product__r.Sizing_Method__c == 'Project Ratio'){
                sssRemainingSubscriptionCapacity = sssRemainingSubscriptionCapacity/sss.Utility_NMC_Tariff__r.Size_Ratio__c;
            }
        }

        return sssRemainingSubscriptionCapacity.setScale(2);
    }

}