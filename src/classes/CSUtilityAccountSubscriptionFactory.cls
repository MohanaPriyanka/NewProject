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
        public Decimal maximumKWH;
        public Decimal maximumCost;
        public SSSSubscription(Shared_Solar_System__c sss) {
            this.sss = sss;
            this.sizingMethod = sss.Product__r.Sizing_Method__c;
            this.customerSubscriptionType = sss.Product__r.Customer_Subscription_Type__c;
            this.maximumKWH = SharedSolarSystems.calculateMaximumkWh(sss);
            this.maximumCost = sss.Maximum_Subscription_Cost__c;
        }
    }

    @TestVisible
    private class UtilityAccountLogWrapper {
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
            this.remainingCapacity = calculateAnnualAmount(ual.Annual_kWh__c, ual.Annual_Cost_of_Electricity__c, this.sizingMethod.Value_of_Net_Metering_Credit__c, CAPACITY);
            this.remainingCost = calculateAnnualAmount(ual.Annual_Cost_of_Electricity__c, ual.Annual_kWh__c, this.sizingMethod.Value_of_Net_Metering_Credit__c, COST);
            this.annualCostOfElectricity = this.remainingCost;
            this.subscriptionType = ual.Lead__r.Product__r.Customer_Subscription_Type__c;
            this.uasNumberCount = 1;
        }
    }

    private class SubscriptionAllocation {
        public Decimal ualRemainingAllocation;
        public Decimal sssRemainingSubscriptionAmount;
        public Decimal annualAmountAssigned;
        public Decimal allocationPercentage;
    }

    public static void generateSubscriptions(List<Utility_Account_Log__c> uals, List<Shared_Solar_System__c> sharedSolarSystems,
        List<Opportunity> opportunities, fflib_SObjectUnitOfWork uow) {
        for (Shared_Solar_System__c sss : sharedSolarSystems) {
            sssSubscriptionMap.put(sss.Id, new SSSSubscription(sss));
        }

        for (Utility_Account_Log__c ual : uals) {
            try {
                createUAS(ual, opportunities, uow);
            } catch (Exception e) {
                Logger.logNow('CSUtilityAccountSubscriptionFactory', 'generateSubscriptions', JSON.serialize(ual) + '\n' + e.getMessage() + '\n' + e.getStackTraceString(), Logger.ERROR);
                throw new Util.BWException();
            }
        }
    }

    @TestVisible
    private static void createUAS(Utility_Account_Log__c ual, List<Opportunity> opportunities, fflib_SObjectUnitOfWork uow) {
        UtilityAccountLogWrapper ualInfo = new UtilityAccountLogWrapper(ual);
        for (Opportunity opportunity : opportunities) {
            // Break loop if nothing left on UAL to allocate
            if (ualInfo.remainingCapacity <= 0 && ualInfo.remainingCost <= 0) {
                break;
            }
            createUASFromOpportunity(ualInfo, opportunity, uow);
        }
    }

    private static void createUASFromOpportunity(UtilityAccountLogWrapper ualInfo, Opportunity opportunity, fflib_SObjectUnitOfWork uow) {
        SSSSubscription sssSubscription = sssSubscriptionMap.get(opportunity.Shared_Solar_System__c);
        if (sssSubscription == null) {
            return;
        }
        String subscriptionType = ualInfo.subscriptionType == CAPACITY || ualInfo.subscriptionType == COST ? ualInfo.subscriptionType : sssSubscription.customerSubscriptionType;
        if (subscriptionType == CAPACITY) {
            createUASByCapacity(ualInfo, sssSubscription, opportunity, uow);
        }
        if (subscriptionType == COST) {
            createUASbyCost(ualInfo, sssSubscription, opportunity, uow);
        }
    }

    private static void createUASByCapacity(UtilityAccountLogWrapper ualInfo, SSSSubscription sssSubscription, Opportunity opportunity, fflib_SObjectUnitOfWork uow) {
        Decimal sizeRatio = sssSubscription.sizingMethod == 'Rate Class Ratio' && ualInfo.sizingMethod.Size_Ratio__c != null ? ualInfo.sizingMethod.Size_Ratio__c : 1.0;
        Decimal sssRemainingSubscriptionCapacity = (sssSubscription.maximumKWH / sizeRatio).setScale(2, RoundingMode.HALF_DOWN);
        SubscriptionAllocation subscriptionAllocation = calculateAllocations(sssRemainingSubscriptionCapacity, ualInfo.remainingCapacity);
        if (subscriptionAllocation == null) {
            return;
        }
        // update the totals using our calculations
        sssSubscription.maximumKWH = subscriptionAllocation.sssRemainingSubscriptionAmount * sizeRatio;
        ualInfo.remainingCapacity = subscriptionAllocation.ualRemainingAllocation;
        // keep the ual totals even by subtracting the same percentage from the ual remaining cost allocation
        ualInfo.remainingCost -= (ualInfo.remainingCost * subscriptionAllocation.allocationPercentage);
        Utility_Account_Subscription__c uas = createUASObject(ualInfo, opportunity.Id);
        uow.registerNew(uas, Utility_Account_Subscription__c.Opportunity__c, opportunity);
        populateSizingMethod(ualInfo, uas, sssSubscription);
        ualInfo.uasNumberCount++;
        createSOByCapacity(uas, subscriptionAllocation.annualAmountAssigned, uow);
    }

    private static void createUASbyCost(UtilityAccountLogWrapper ualInfo, SSSSubscription sssSubscription, Opportunity opportunity, fflib_SObjectUnitOfWork uow) {
        SubscriptionAllocation subscriptionAllocation = calculateAllocations(sssSubscription.maximumCost, ualInfo.remainingCost);
        if (subscriptionAllocation == null) {
            return;
        }
        sssSubscription.maximumCost = subscriptionAllocation.sssRemainingSubscriptionAmount;
        ualInfo.remainingCost = subscriptionAllocation.ualRemainingAllocation;
        ualInfo.remainingCapacity -= (ualInfo.remainingCapacity * subscriptionAllocation.allocationPercentage);
        Utility_Account_Subscription__c uas = createUASObject(ualInfo, opportunity.Id);
        uas.calculated_annual_cost_of_electricity__c = subscriptionAllocation.annualAmountAssigned;
        uas.Annual_Cost_of_Electricity__c = ualInfo.annualCostOfElectricity;
        uow.registerNew(uas, Utility_Account_Subscription__c.Opportunity__c, opportunity);
        populateSizingMethod(ualInfo, uas, sssSubscription);
        ualInfo.uasNumberCount++;
        createSOByCost(uas, subscriptionAllocation.annualAmountAssigned, uow);
    }

    private static SubscriptionAllocation calculateAllocations(Decimal sssRemainingSubscriptionAmount, Decimal ualRemainingAllocation) {
        // do not create subscription if there is nothing left to allocate
        if (sssRemainingSubscriptionAmount == 0 || ualRemainingAllocation == 0) {
            return null;
        }
        SubscriptionAllocation subscriptionAllocation = new SubscriptionAllocation();
        subscriptionAllocation.annualAmountAssigned = Math.min(sssRemainingSubscriptionAmount, ualRemainingAllocation);
        // deduct the annual assigned amount from the sssSubscription and ual totals
        subscriptionAllocation.sssRemainingSubscriptionAmount = sssRemainingSubscriptionAmount - subscriptionAllocation.annualAmountAssigned;
        subscriptionAllocation.ualRemainingAllocation = ualRemainingAllocation - subscriptionAllocation.annualAmountAssigned;
        subscriptionAllocation.allocationPercentage = subscriptionAllocation.annualAmountAssigned / ualRemainingAllocation;
        return subscriptionAllocation;
    }

    private static Utility_NMC_Tariff__c getUALSizingMethod(Utility_Account_Log__c ual) {
        if (ual.Utility_Rate_Class__c == null || ual.Utility_Rate_Class__r.Utility_NMC_Tariff__c == null) {
            return new Utility_NMC_Tariff__c();
        }
        return ual.Utility_Rate_Class__r.Utility_NMC_Tariff__r;
    }

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
        Decimal netMeteringRatio = type == CAPACITY ? (1 / netMeteringCredit) : netMeteringCredit;
        return (amountToConvert * netMeteringRatio);
    }

    private static Utility_Account_Subscription__c createUASObject(UtilityAccountLogWrapper ualInfo, Id opportunityId) {

        Utility_Account_Subscription__c uas = new Utility_Account_Subscription__c(
            Name = ualInfo.ual.Name,
            Name_on_Account__c = ualInfo.ual.Name_on_Account__c,
            Opportunity__c = opportunityId,
            Utility_Account_Log__c = ualInfo.ual.Id,
            UAS_Number__c = ualInfo.uasNumberCount
        );

        return uas;
    }

    private static void populateSizingMethod(UtilityAccountLogWrapper ualInfo, Utility_Account_Subscription__c uas, SSSSubscription sssSubscription) {
        if (sssSubscription.sizingMethod == 'Rate Class Ratio' && ualInfo.ual.Utility_Rate_Class__c != null) {
            uas.Sizing_Method__c = ualInfo.sizingMethod.Id;
        } else {
            uas.Sizing_Method__c = sssSubscription.sss.Utility_NMC_Tariff__c;
        }
    }

    @TestVisible
    private static void createSOByCapacity(Utility_Account_Subscription__c uas, Decimal annualElectricityCapacityAssigned, fflib_SObjectUnitOfWork uow) {
        Subscription_Order__c so = new Subscription_Order__c(
            Type__c = 'Initial',
            New_Annual_kWh__c = annualElectricityCapacityAssigned,
            Effective_Date__c = System.now(),
            Approval_Status__c = 'Approved'
        );
        uow.registerNew(so, Subscription_Order__c.Utility_Account_Subscription__c, uas);
    }

    @TestVisible
    private static void createSOByCost(Utility_Account_Subscription__c uas, Decimal annualElectricityCostAssigned, fflib_SObjectUnitOfWork uow) {
        Subscription_Order__c so = new Subscription_Order__c(
            Type__c = 'Initial',
            New_Annual_Cost__c = annualElectricityCostAssigned,
            Effective_Date__c = System.now(),
            Approval_Status__c = 'Approved'
        );
        uow.registerNew(so, Subscription_Order__c.Utility_Account_Subscription__c, uas);
    }

}