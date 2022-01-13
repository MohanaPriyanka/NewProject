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
    private class UtilityAccountLogInfo {
        public Utility_Account_Log__c ual;
        public Utility_NMC_Tariff__c sizingMethod;
        public Decimal annualCostOfElectricity;
        public Decimal remainingCapacity;
        public Decimal remainingCost;
        public String subscriptionType;
        public Integer uasNumberCount;
        public UtilityAccountLogInfo(Utility_Account_Log__c ual) {
            this.ual = ual;
            this.sizingMethod = getUALSizingMethod(ual);
            this.annualCostOfElectricity = calculateAnnualAmount(ual.Annual_Cost_of_Electricity__c, ual.Annual_kWh__c, this.sizingMethod.Value_of_Net_Metering_Credit__c, COST);
            this.remainingCapacity = calculateAnnualAmount(ual.Annual_kWh__c, ual.Annual_Cost_of_Electricity__c, this.sizingMethod.Value_of_Net_Metering_Credit__c, CAPACITY);
            this.remainingCost = this.annualCostOfElectricity;
            this.subscriptionType = getUALSubscriptionType(ual);
            this.uasNumberCount = 1;
        }
    }

    private class SubscriptionAllocation {
        public Decimal ualSubscriptionTypeRemainingAmount;
        public Decimal ualUnusedTypeRemainingAmount;
        public Decimal opportunityRemainingAmount;
        public Decimal assignedAmount;
        public Decimal sizeRatio;
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
        if (type == CAPACITY) {
            annualAmount = amountToConvert / netMeteringCredit;
        }
        if (type == COST) {
            annualAmount = amountToConvert * netMeteringCredit;
        }

        return annualAmount;
    }

    private static String getUALSubscriptionType(Utility_Account_Log__c ual) {
        if (ual.Lead__c == null || ual.Lead__r.Product__c == null) {
            return null;
        }
        return ual.Lead__r.Product__r.Customer_Subscription_Type__c;
    }

    public static void generateSubscriptions(List<Utility_Account_Log__c> uals, List<Shared_Solar_System__c> sharedSolarSystems,
        List<Opportunity> opportunities, fflib_SObjectUnitOfWork uow) {
        for (Shared_Solar_System__c sss : sharedSolarSystems) {
            sssSubscriptionMap.put(sss.Id, new SSSSubscription(sss));
        }

        for (Utility_Account_Log__c ual : uals) {
            UtilityAccountLogInfo ualInfo = new UtilityAccountLogInfo(ual);
            createUAS(ualInfo, opportunities, uow);
        }
    }

    @TestVisible
    private static void createUAS(UtilityAccountLogInfo ualInfo, List<Opportunity> opportunities, fflib_SObjectUnitOfWork uow) {

        for (Opportunity opportunity : opportunities) {
            // Break loop if nothing left on UAL to allocate
            if (ualInfo.remainingCapacity <= 0 && ualInfo.remainingCost <= 0) {
                break;
            }
            createUASFromOpportunity(ualInfo, opportunity, uow);
        }
    }

    private static void createUASFromOpportunity(UtilityAccountLogInfo ualInfo, Opportunity opportunity, fflib_SObjectUnitOfWork uow) {
        SSSSubscription sssSubscription = sssSubscriptionMap.get(opportunity.Shared_Solar_System__c);
        if (sssSubscription == null) {
            return;
        }
        String subscriptionType = getUASSubscriptionType(ualInfo, sssSubscription);
        Decimal sizeRatio = getSizeRatio(ualInfo, sssSubscription.sizingMethod, subscriptionType);
//        SubscriptionAllocation opportunityInfo = setOpportunityInfo(ualInfo, sssSubscription, sizeRatio, subscriptionType);
        SubscriptionAllocation allocation = calculateUASAssignment(ualInfo, sssSubscription, sizeRatio, subscriptionType);
        // Don't create or update anything if there is nothing to assign
        if (allocation.assignedAmount <= 0) {
            return;
        }
        setAssignments(allocation, ualInfo, sssSubscription, subscriptionType);
        Utility_Account_Subscription__c uas = createUASObject(ualInfo, opportunity.Id, allocation.assignedAmount, subscriptionType);
        uow.registerNew(uas, Utility_Account_Subscription__c.Opportunity__c, opportunity);
        populateSizingMethod(ualInfo, uas, sssSubscription);
        ualInfo.uasNumberCount++;
        createSubscriptionOrder(uas, allocation.assignedAmount, uow, subscriptionType);
    }

    private static String getUASSubscriptionType(UtilityAccountLogInfo ual, SSSSubscription sssSubscription) {
        // If the lead is not assigned to a particular allocation metric use the opportunity's. This will happen if the lead is signed up for MA Hybrid and can be allocated using either capacity or cost.
        if (ual.subscriptionType == CAPACITY || ual.subscriptionType == COST) {
            return ual.subscriptionType;
        }
        return sssSubscription.customerSubscriptionType;
    }

    private static Decimal getSizeRatio(UtilityAccountLogInfo ual, String sizingMethod, String subscriptionType) {
        if (subscriptionType == CAPACITY && sizingMethod == 'Rate Class Ratio' && ual.sizingMethod.Size_Ratio__c != null) {
            return ual.sizingMethod.Size_Ratio__c;
        }
        return 1.0;
    }

    private static SubscriptionAllocation calculateUASAssignment(UtilityAccountLogInfo ualInfo, SSSSubscription sssSubscription, Decimal sizeRatio, String subscriptionType) {
        Decimal ualSubscriptionTypeRemainingAmount;
        Decimal ualUnusedTypeRemainingAmount;
        Decimal opportunityRemainingAmount;
        SubscriptionAllocation allocation = new SubscriptionAllocation();
        allocation.sizeRatio = sizeRatio;
        if (subscriptionType == CAPACITY) {
            ualSubscriptionTypeRemainingAmount = ualInfo.remainingCapacity;
            ualUnusedTypeRemainingAmount = ualInfo.remainingCost;
            opportunityRemainingAmount = (sssSubscription.maximumKWH / sizeRatio).setScale(2, RoundingMode.HALF_DOWN);
        }
        if (subscriptionType == COST) {
            ualSubscriptionTypeRemainingAmount = ualInfo.remainingCost;
            ualUnusedTypeRemainingAmount = ualInfo.remainingCapacity;
            opportunityRemainingAmount = sssSubscription.maximumCost;
        }
        allocation.assignedAmount = Math.min(ualSubscriptionTypeRemainingAmount, opportunityRemainingAmount);

        if (allocation.assignedAmount <= 0) {
            return allocation;
        }

        // subtract the assigned amount from the opportunity and ual totals
        allocation.opportunityRemainingAmount = opportunityRemainingAmount - allocation.assignedAmount;
        allocation.ualSubscriptionTypeRemainingAmount = ualSubscriptionTypeRemainingAmount - allocation.assignedAmount;
        // subtract an equal percentage of the total from the unused allocation field on the ual
        // get the ratio by dividing the assigned amount by the original opportunity remaining amount
        Decimal allocationRatio = allocation.assignedAmount / opportunityRemainingAmount;
        allocation.ualUnusedTypeRemainingAmount = ualUnusedTypeRemainingAmount - (ualUnusedTypeRemainingAmount * allocationRatio);
        return allocation;
    }

    private static void setAssignments(SubscriptionAllocation allocation, UtilityAccountLogInfo ualInfo, SSSSubscription sssSubscription, String subscriptionType) {
        if (subscriptionType == CAPACITY) {
            ualInfo.remainingCapacity = allocation.ualSubscriptionTypeRemainingAmount;
            ualInfo.remainingCost = allocation.ualUnusedTypeRemainingAmount;
            sssSubscription.maximumKWH = allocation.opportunityRemainingAmount * allocation.sizeRatio;
        }
        if (subscriptionType == COST) {
            ualInfo.remainingCost = allocation.ualSubscriptionTypeRemainingAmount;
            ualInfo.remainingCapacity = allocation.ualUnusedTypeRemainingAmount;
            sssSubscription.maximumCost = allocation.opportunityRemainingAmount;
        }
    }

    private static Utility_Account_Subscription__c createUASObject(UtilityAccountLogInfo ualInfo, Id opportunityId, Decimal assignedAmount, String subscriptionType) {

        Utility_Account_Subscription__c uas = new Utility_Account_Subscription__c(
            Name = ualInfo.ual.Name,
            Name_on_Account__c = ualInfo.ual.Name_on_Account__c,
            Opportunity__c = opportunityId,
            Utility_Account_Log__c = ualInfo.ual.Id,
            UAS_Number__c = ualInfo.uasNumberCount
        );

        if (subscriptionType == COST) {
            uas.Annual_Cost_of_Electricity__c = ualInfo.annualCostOfElectricity;
            uas.calculated_annual_cost_of_electricity__c = assignedAmount;
        }

        return uas;
    }

    @TestVisible
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

    private static void populateSizingMethod(UtilityAccountLogInfo ualInfo, Utility_Account_Subscription__c uas, SSSSubscription sssSubscription) {
        if (sssSubscription.sizingMethod == 'Rate Class Ratio' && ualInfo.ual.Utility_Rate_Class__c != null) {
            uas.Sizing_Method__c = ualInfo.sizingMethod.Id;
        } else {
            uas.Sizing_Method__c = sssSubscription.sss.Utility_NMC_Tariff__c;
        }
    }
}