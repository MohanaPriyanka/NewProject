/**
 * @description : Created by mstackhouse on 12/17/2018.
 * Tested by: CSUtilityAccountSubscriptionFactoryTest
 */
public with sharing class CSUtilityAccountSubscriptionFactory {

    private static final String CAPACITY = 'kWh';
    private static final String COST = 'Electricity Cost ($)';

    @TestVisible
    private static Map<Id, SSSSubscription> sssSubscriptionMap = new Map<Id, SSSSubscription>();

    public class UASOrder {
        public Utility_Account_Subscription__c uas;
        public Subscription_Order__c sOrder;
    }

    public class SSSSubscription {
        public Shared_Solar_System__c sss;
        public String sizingMethod;
        public String customerSubscriptionType;
        public Decimal maximumkWh;
        public Decimal maximumCost;
        public SSSSubscription(Shared_Solar_System__c sss) {
            this.sss = sss;
            this.sizingMethod = sss.Product__r.Sizing_Method__c;
            this.customerSubscriptionType = sss.Product__r.Customer_Subscription_Type__c;
            this.maximumkWh = SharedSolarSystems.calculateMaximumkWh(sss);
            this.maximumCost = sss.Maximum_Subscription_Cost__c;
        }
    }

    private class SubscriptionAllocation {
        public Decimal ualCustomerTypeRemainingAmount;
        public Decimal ualUnusedCustomerTypeRemainingAmount;
        public Decimal opportunityRemainingAmount;
        public Decimal assignedAmount;
    }

    public static void generateSubscriptions(List<Utility_Account_Log__c> uals, List<Shared_Solar_System__c> sharedSolarSystems,
        List<Opportunity> opportunities, fflib_SObjectUnitOfWork uow) {
        for (Shared_Solar_System__c sss : sharedSolarSystems) {
            sssSubscriptionMap.put(sss.Id, new SSSSubscription(sss));
        }

        for (Utility_Account_Log__c ual : uals) {
//            if (ual.Lead__r.Product__r.Customer_Subscription_Type__c == 'kWh') {
//                createUASbyCapacity(ual, opportunities, uow);
//            } else if (ual.Lead__r.Product__r.Customer_Subscription_Type__c == 'Electricity Cost ($)') {
//                createUASbyCost(ual, opportunities, uow);
//            }
            createUAS(ual, opportunities, uow);
        }
    }

    @TestVisible
    private static void createUAS(Utility_Account_Log__c ual, List<Opportunity> opportunities, fflib_SObjectUnitOfWork uow) {
        Integer uasNumberCounter = 1;
        Decimal netMeteringCredit = getNetMeteringCredit(ual);
        Map<String, Decimal> ualRemainingAmountMap = new Map<String, Decimal>();
        ualRemainingAmountMap.put(CAPACITY, calculateAnnualAmount(ual.Annual_kWh__c ,ual, netMeteringCredit, CAPACITY));
        ualRemainingAmountMap.put(COST, calculateAnnualAmount(ual.Annual_Cost_of_Electricity__c, ual, netMeteringCredit, COST));

        for (Opportunity opportunity : opportunities) {
            // Break loop if nothing left on UAL to allocate
            if (ualRemainingAmountMap.get(CAPACITY) <= 0 && ualRemainingAmountMap.get(COST) <= 0) {
                break;
            }
            // Get the opportunity's Shared Solar System information
            SSSSubscription sssSubscription = sssSubscriptionMap.get(opportunity.Shared_Solar_System__c);
            if (sssSubscription == null) {
                continue;
            }
            // If the lead is not assigned to a particular allocation metric use the opportunity's
            String subscriptionType = ual.Lead__r.Product__r.Customer_Subscription_Type__c == CAPACITY || ual.Lead__r.Product__r.Customer_Subscription_Type__c == COST ? ual.Lead__r.Product__r.Customer_Subscription_Type__c : sssSubscription.customerSubscriptionType;

            Decimal sizeRatio = getSizeRatio(ual, sssSubscription.sizingMethod, subscriptionType);
            SubscriptionAllocation opportunityInfo = setOpportunityInfo(ualRemainingAmountMap, sssSubscription, sizeRatio, subscriptionType);
            SubscriptionAllocation allocation = calculateUASAssignment(opportunityInfo);
            if (allocation.assignedAmount <= 0) {
                continue;
            }

            if (subscriptionType == CAPACITY) {
                ualRemainingAmountMap.put(CAPACITY, allocation.ualCustomerTypeRemainingAmount);
                ualRemainingAmountMap.put(COST, allocation.ualUnusedCustomerTypeRemainingAmount);
                sssSubscription.maximumkWh = allocation.opportunityRemainingAmount * sizeRatio;
            }
            if (subscriptionType == COST) {
                ualRemainingAmountMap.put(COST, allocation.ualCustomerTypeRemainingAmount);
                ualRemainingAmountMap.put(CAPACITY, allocation.ualUnusedCustomerTypeRemainingAmount);
                sssSubscription.maximumCost = allocation.opportunityRemainingAmount;
            }

            Utility_Account_Subscription__c uas = createUASObject(ual, opportunity.Id, uasNumberCounter, allocation.assignedAmount, subscriptionType);
            uow.registerNew(uas, Utility_Account_Subscription__c.Opportunity__c, opportunity);
            populateSizingMethod(ual, uas, sssSubscription);
            uasNumberCounter++;
            createSubscriptionOrder(uas, allocation.assignedAmount, uow, subscriptionType);
        }
    }

    private static Decimal getNetMeteringCredit(Utility_Account_Log__c ual) {
        if (ual.Utility_Rate_Class__c == null || ual.Utility_Rate_Class__r.Utility_NMC_Tariff__c == null) {
            return null;
        }
        return ual.Utility_Rate_Class__r.Utility_NMC_Tariff__r.Value_of_Net_Metering_Credit__c;
    }

    private static Decimal getSizeRatio(Utility_Account_Log__c ual, String sizingMethod, String subscriptionType) {
        if (subscriptionType == CAPACITY && sizingMethod == 'Rate Class Ratio' && ual.Utility_Rate_Class__c != null && ual.Utility_Rate_Class__r.Utility_NMC_Tariff__c != null && ual.Utility_Rate_Class__r.Utility_NMC_Tariff__r.Size_Ratio__c != null) {
            return ual.Utility_Rate_Class__r.Utility_NMC_Tariff__r.Size_Ratio__c;
        }
        return 1.0;
    }

    private static Decimal calculateAnnualAmount(Decimal annualAmount, Utility_Account_Log__c ual, Decimal netMeteringCredit, String type) {
        // use annual amount value if it was already set
        if (annualAmount != null) {
            return annualAmount;
        }

        // if there is no value for either metric or there is no net metering credit we cannot calculate anything
        if ((ual.Annual_kWh__c == null && ual.Annual_Cost_of_Electricity__c == null) || netMeteringCredit == null || netMeteringCredit == 0) {
            return 0;
        }
        // use the net metering credit as a ratio if the value has not been calculated yet
        annualAmount = type == CAPACITY ? ual.Annual_Cost_of_Electricity__c / netMeteringCredit : ual.Annual_kWh__c * netMeteringCredit;

        return annualAmount;
    }

    private static SubscriptionAllocation setOpportunityInfo(Map<String,Decimal> ualRemainingAmountMap, SSSSubscription sssSubscription, Decimal sizeRatio, String subscriptionType) {
        SubscriptionAllocation opportunityInfo = new SubscriptionAllocation();
        if (subscriptionType == CAPACITY) {
            opportunityInfo.ualCustomerTypeRemainingAmount = ualRemainingAmountMap.get(CAPACITY);
            opportunityInfo.ualUnusedCustomerTypeRemainingAmount = ualRemainingAmountMap.get(COST);
            opportunityInfo.opportunityRemainingAmount =  (sssSubscription.maximumkWh / sizeRatio).setScale(2, RoundingMode.HALF_DOWN);
        }
        if (subscriptionType == COST) {
            opportunityInfo.ualCustomerTypeRemainingAmount = ualRemainingAmountMap.get(COST);
            opportunityInfo.ualUnusedCustomerTypeRemainingAmount = ualRemainingAmountMap.get(CAPACITY);
            opportunityInfo.opportunityRemainingAmount = sssSubscription.maximumCost;
        }
        return opportunityInfo;
    }

    private static SubscriptionAllocation calculateUASAssignment(SubscriptionAllocation opportunityInfo) {

        SubscriptionAllocation result = new SubscriptionAllocation();

        result.assignedAmount = Math.min(opportunityInfo.ualCustomerTypeRemainingAmount, opportunityInfo.opportunityRemainingAmount);

        // subtract the assigned amount from the opportunity and ual totals
        result.opportunityRemainingAmount = opportunityInfo.opportunityRemainingAmount - result.assignedAmount;
        result.ualCustomerTypeRemainingAmount = opportunityInfo.ualCustomerTypeRemainingAmount - result.assignedAmount;
        // subtract an equal percentage of the total from the unused allocation field on the ual
        Decimal allocationRatio = opportunityInfo.opportunityRemainingAmount != 0 ? result.assignedAmount / opportunityInfo.opportunityRemainingAmount : 0;
        result.ualUnusedCustomerTypeRemainingAmount = opportunityInfo.ualUnusedCustomerTypeRemainingAmount - (opportunityInfo.ualUnusedCustomerTypeRemainingAmount * allocationRatio);

        return result;

    }

    private static Utility_Account_Subscription__c createUASObject(Utility_Account_Log__c ual, Id opportunityId, Integer uasNumberCounter, Decimal assignedAmount, String subscriptionType) {

        Utility_Account_Subscription__c uas = new Utility_Account_Subscription__c(
            Name = ual.Name,
            Name_on_Account__c = ual.Name_on_Account__c,
            Opportunity__c = opportunityId,
            Utility_Account_Log__c = ual.Id,
            UAS_Number__c = uasNumberCounter
        );

        if (subscriptionType == COST) {
            uas.Annual_Cost_of_Electricity__c = ual.Annual_Cost_of_Electricity__c;
            uas.calculated_annual_cost_of_electricity__c = assignedAmount;
        }

        return uas;
    }

    private static void createSubscriptionOrder(Utility_Account_Subscription__c uas, Decimal assignedAmount, fflib_SObjectUnitOfWork uow, String subscriptionType) {
        Subscription_Order__c subscriptionOrder = new Subscription_Order__c(
            Type__c = 'Initial',
            Effective_Date__c = System.now(),
            Approval_Status__c = 'Approved'
        );
        if (subscriptionType == CAPACITY) {
            subscriptionOrder.New_Annual_kWh__c = assignedAmount;
        }
        if (subscriptionType == COST) {
            subscriptionOrder.New_Annual_Cost__c = assignedAmount;
        }
        uow.registerNew(subscriptionOrder, Subscription_Order__c.Utility_Account_Subscription__c, uas);
    }


//    public static void createUASbyCapacity(Utility_Account_Log__c ual, List<Opportunity> opportunities, fflib_SObjectUnitOfWork uow) {
//        Integer uasNumberCounter = 1;
//        Decimal remainingUALCapacityToAllocate;
//        remainingUALCapacityToAllocate = ual.Annual_kWh__c;
//
//        for (Opportunity opp : opportunities) {
//            if (sssSubscriptionMap.containsKey((opp.Shared_Solar_System__c))) {
//                SSSSubscription sssSubscription = sssSubscriptionMap.get(opp.Shared_Solar_System__c);
//                Decimal sizeRatio = 1.0;
//
//                Decimal sssRemainingSubscriptionCapacity = sssSubscription.maximumkWh;
//                if (sssSubscription.sizingMethod == 'Rate Class Ratio' && ual.Utility_Rate_Class__r.Utility_NMC_Tariff__c != null) {
//                    sizeRatio = ual.Utility_Rate_Class__r.Utility_NMC_Tariff__r.Size_Ratio__c;
//                    sssRemainingSubscriptionCapacity = (sssRemainingSubscriptionCapacity / sizeRatio).setScale(2, RoundingMode.HALF_DOWN);
//                }
//                Decimal annualElectricityCapacityAssigned = Math.min(remainingUALCapacityToAllocate, sssRemainingSubscriptionCapacity);
//                if (annualElectricityCapacityAssigned > 0) {
//                    //Deduct the assigned value from the sss remaining subscription cost and then put it back into the map
//                    sssRemainingSubscriptionCapacity -= annualElectricityCapacityAssigned;
//                    if (sssSubscription.sizingMethod == 'Rate Class Ratio') {
//                        sssSubscription.maximumkWh = sssRemainingSubscriptionCapacity * sizeRatio;
//                    }
//                    sssSubscription.maximumkWh = sssRemainingSubscriptionCapacity;
//                    remainingUALCapacityToAllocate -= annualElectricityCapacityAssigned;
//                    Utility_Account_Subscription__c uas = new Utility_Account_Subscription__c(
//                        Name = ual.Name,
//                        Name_on_Account__c = ual.Name_on_Account__c,
//                        Opportunity__c = opp.Id,
//                        Utility_Account_Log__c = ual.Id,
//                        UAS_Number__c = uasNumberCounter
//                    );
//                    uow.registerNew(uas, Utility_Account_Subscription__c.Opportunity__c, opp);
//                    populateSizingMethod(ual, uas, sssSubscription);
//                    uasNumberCounter++;
//                    createSOByCapacity(uas, annualElectricityCapacityAssigned, uow);
//                }
//            }
//        }
//    }

//    public static void createUASbyCost(Utility_Account_Log__c ual, List<Opportunity> opportunities, fflib_SObjectUnitOfWork uow) {
//        Integer uasNumberCounter = 1;
//        Decimal remainingUALCostToAllocate = ual.Annual_Cost_of_Electricity__c;
//
//        for (Opportunity opp : opportunities) {
//            if (sssSubscriptionMap.containsKey(opp.Shared_Solar_System__c)) {
//                SSSSubscription sssSubscription = sssSubscriptionMap.get(opp.Shared_Solar_System__c);
//                Decimal sssRemainingSubscriptionCost = sssSubscription.maximumCost;
//                Decimal annualElectricityCostAssigned = Math.min(remainingUALCostToAllocate, sssRemainingSubscriptionCost);
//                if (annualElectricityCostAssigned > 0) {
//                    //Deduct the assigned value from the sss remaining subscription cost and then put it back into the map
//                    sssRemainingSubscriptionCost -= annualElectricityCostAssigned;
//                    sssSubscription.maximumCost = sssRemainingSubscriptionCost;
//                    remainingUALCostToAllocate = remainingUALCostToAllocate - annualElectricityCostAssigned;
//                    Utility_Account_Subscription__c uas = new Utility_Account_Subscription__c(
//                        Name = ual.Name,
//                        Name_on_Account__c = ual.Name_on_Account__c,
//                        Opportunity__c = opp.Id,
//                        Annual_Cost_of_Electricity__c = ual.Annual_Cost_of_Electricity__c,
//                        Utility_Account_Log__c = ual.Id,
//                        UAS_Number__c = uasNumberCounter,
//                        calculated_annual_cost_of_electricity__c = annualElectricityCostAssigned
//                    );
//                    uow.registerNew(uas, Utility_Account_Subscription__c.Opportunity__c, opp);
//                    populateSizingMethod(ual, uas, sssSubscription);
//                    uasNumberCounter++;
//                    createSOByCost(uas, annualElectricityCostAssigned, uow);
//                }
//            }
//        }
//    }


//    @TestVisible
//    private static void createSOByCapacity(Utility_Account_Subscription__c uas, Decimal annualElectricityCapacityAssigned, fflib_SObjectUnitOfWork uow) {
//        Subscription_Order__c so = new Subscription_Order__c(
//            Type__c = 'Initial',
//            New_Annual_kWh__c = annualElectricityCapacityAssigned,
//            Effective_Date__c = System.now(),
//            Approval_Status__c = 'Approved'
//        );
//        uow.registerNew(so, Subscription_Order__c.Utility_Account_Subscription__c, uas);
//    }
//
//    @TestVisible
//    private static void createSOByCost(Utility_Account_Subscription__c uas, Decimal annualElectricityCostAssigned, fflib_SObjectUnitOfWork uow) {
//        Subscription_Order__c so = new Subscription_Order__c(
//            Type__c = 'Initial',
//            New_Annual_Cost__c = annualElectricityCostAssigned,
//            Effective_Date__c = System.now(),
//            Approval_Status__c = 'Approved'
//        );
//        uow.registerNew(so, Subscription_Order__c.Utility_Account_Subscription__c, uas);
//    }

    private static void populateSizingMethod(Utility_Account_Log__c ual, Utility_Account_Subscription__c uas, SSSSubscription sssSubscription) {
        if (sssSubscription.sizingMethod == 'Rate Class Ratio' && ual.Utility_Rate_Class__c != null) {
            uas.Sizing_Method__c = ual.Utility_Rate_Class__r.Utility_NMC_Tariff__c;
        } else {
            uas.Sizing_Method__c = sssSubscription.sss.Utility_NMC_Tariff__c;
        }
    }
}