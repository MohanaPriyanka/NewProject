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
        public String sizingMethod;
        public Decimal maximumkWh;
        public Decimal maximumCost;
        public SSSSubscription(Shared_Solar_System__c sss) {
            this.sss = sss;
            this.sizingMethod = sss.Product__r.Sizing_Method__c;
            this.maximumkWh = SharedSolarSystems.calculateMaximumkWh(sss, null);
            this.maximumCost = sss.Maximum_Subscription_Cost__c;
        }
    }

    @TestVisible
    private static FeatureService featureService = new FeatureService();
    @TestVisible
    private static Map<Id, SSSSubscription> sssSubscriptionMap = new Map<Id, SSSSubscription>();


    public static void generateSubscriptions(
        List<Utility_Account_Log__c> uals,
        List<Shared_Solar_System__c> sharedSolarSystems,
        List<Opportunity> opportunities,
        fflib_SObjectUnitOfWork uow
    ) {
        for (Shared_Solar_System__c sss : sharedSolarSystems) {
            sssSubscriptionMap.put(sss.Id, new SSSSubscription(sss));
        }

        for (Utility_Account_Log__c ual : uals) {
            if (ual.Lead__r.Product__r.Customer_Subscription_Type__c == 'kWh') {
                createUASbyCapacity(ual, opportunities, uow);
            } else if (ual.Lead__r.Product__r.Customer_Subscription_Type__c == 'Electricity Cost ($)') {
                createUASbyCost(ual, opportunities, uow);
            }
        }
    }


    public static void createUASbyCapacity(
        Utility_Account_Log__c ual,
        List<Opportunity> opportunities,
        fflib_SObjectUnitOfWork uow
    ) {
        Integer uasNumberCounter = 1;
        Decimal remainingUALCapacityToAllocate;
        if (featureService.isEnabled('Sizing_Method')) {
            remainingUALCapacityToAllocate = ual.Annual_kWh__c;
        } else {
            remainingUALCapacityToAllocate = ual.Proposed_kWh__c;
        }

        for (Opportunity opp : opportunities) {
            if (sssSubscriptionMap.containsKey((opp.Shared_Solar_System__c))) {
                SSSSubscription sssSubscription = sssSubscriptionMap.get(opp.Shared_Solar_System__c);
                Decimal sssRemainingSubscriptionCapacity = sssSubscription.maximumkWh;

                if (featureService.isEnabled('Sizing_Method') && sssSubscription.sizingMethod == 'Rate Class Ratio') {
                    sssRemainingSubscriptionCapacity = SharedSolarSystems.calculateMaximumkWh(sssSubscription.sss, ual);
                }
                Decimal annualElectricityCapacityAssigned = Math.min(remainingUALCapacityToAllocate, sssRemainingSubscriptionCapacity);
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
                    uow.registerNew(uas, Utility_Account_Subscription__c.Opportunity__c, opp);
                    populateSizingMethod(ual, uas, sssSubscription);
                    uasNumberCounter++;
                    createSOByCapacity(uas, annualElectricityCapacityAssigned, uow);
                }
            }
        }
    }



    public static void createUASbyCost(
        Utility_Account_Log__c ual,
        List<Opportunity> opportunities,
        fflib_SObjectUnitOfWork uow
    ) {
        Integer uasNumberCounter = 1;
        Decimal remainingUALCostToAllocate = ual.Annual_Cost_of_Electricity__c;

        for (Opportunity opp : opportunities) {
            if (sssSubscriptionMap.containsKey(opp.Shared_Solar_System__c)){
                SSSSubscription sssSubscription = sssSubscriptionMap.get(opp.Shared_Solar_System__c);
                Decimal sssRemainingSubscriptionCost = sssSubscription.maximumCost;
                Decimal annualElectricityCostAssigned = Math.min(remainingUALCostToAllocate, sssRemainingSubscriptionCost);
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
                    uow.registerNew(uas, Utility_Account_Subscription__c.Opportunity__c, opp);
                    populateSizingMethod(ual, uas, sssSubscription);
                    uasNumberCounter++;
                    createSOByCost(uas, annualElectricityCostAssigned, uow);
                }
            }
        }
    }


    private static void createSOByCapacity(Utility_Account_Subscription__c uas, Decimal annualElectricityCapacityAssigned, fflib_SObjectUnitOfWork uow) {
        if(featureService.isEnabled('Subscription_Orders')) {
            Subscription_Order__c so = new Subscription_Order__c(
                Type__c = 'Initial',
                New_Annual_kWh__c = annualElectricityCapacityAssigned,
                Effective_Date__c = System.now(),
                Approval_Status__c = 'Approved'
            );
            
            uow.registerNew(so, Subscription_Order__c.Utility_Account_Subscription__c, uas);
        }
    }

    private static void createSOByCost(Utility_Account_Subscription__c uas, Decimal annualElectricityCostAssigned, fflib_SObjectUnitOfWork uow) {
        if(featureService.isEnabled('Subscription_Orders')) {
            Subscription_Order__c so = new Subscription_Order__c(
                Type__c = 'Initial',
                New_Annual_Cost__c = annualElectricityCostAssigned,
                Effective_Date__c = System.now(),
                Approval_Status__c = 'Approved'
            );

            uow.registerNew(so, Subscription_Order__c.Utility_Account_Subscription__c, uas);
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
}