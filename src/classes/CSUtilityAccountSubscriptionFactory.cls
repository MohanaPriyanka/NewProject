/**
 * @description : Created by mstackhouse on 12/17/2018.
 * Tested by: CSUtilityAccountSubscriptionFactoryTest
 * Helper Class: CSUASFactoryHelper
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
        CSUASFactoryHelper.UtilityAccountLogWrapper ualInfo = new CSUASFactoryHelper.UtilityAccountLogWrapper(ual);
        for (Opportunity opportunity : opportunities) {
            // Break loop if nothing left on UAL to allocate
            if (ualInfo.remainingCapacity <= 0 && ualInfo.remainingCost <= 0) {
                break;
            }
            createUASFromOpportunity(ualInfo, opportunity, uow);
        }
    }

    private static void createUASFromOpportunity(CSUASFactoryHelper.UtilityAccountLogWrapper ualInfo, Opportunity opportunity, fflib_SObjectUnitOfWork uow) {
        SSSSubscription sssSubscription = sssSubscriptionMap.get(opportunity.Shared_Solar_System__c);
        if (sssSubscription == null) {
            return;
        }
        // Use the lead's customer subscription type if it exists, otherwise use the opportunity/sss's (as in the case of a lead signed up to an MA Hybrid product)
        String subscriptionType = ualInfo.subscriptionType == CAPACITY || ualInfo.subscriptionType == COST ? ualInfo.subscriptionType : sssSubscription.customerSubscriptionType;
        if (subscriptionType == CAPACITY) {
            createUASByCapacity(ualInfo, sssSubscription, opportunity, uow);
        }
        if (subscriptionType == COST) {
            createUASbyCost(ualInfo, sssSubscription, opportunity, uow);
        }
    }

    private static void createUASByCapacity(CSUASFactoryHelper.UtilityAccountLogWrapper ualInfo, SSSSubscription sssSubscription, Opportunity opportunity, fflib_SObjectUnitOfWork uow) {
        Decimal sizeRatio = sssSubscription.sizingMethod == 'Rate Class Ratio' && ualInfo.sizingMethod.Size_Ratio__c != null ? ualInfo.sizingMethod.Size_Ratio__c : 1.0;
        Decimal sssRemainingSubscriptionCapacity = (sssSubscription.maximumKWH / sizeRatio).setScale(2, RoundingMode.HALF_DOWN);
        CSUASFactoryHelper.SubscriptionAllocation subscriptionAllocation = CSUASFactoryHelper.calculateAllocations(sssRemainingSubscriptionCapacity, ualInfo.remainingCapacity);
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

    private static void createUASbyCost(CSUASFactoryHelper.UtilityAccountLogWrapper ualInfo, SSSSubscription sssSubscription, Opportunity opportunity, fflib_SObjectUnitOfWork uow) {
        CSUASFactoryHelper.SubscriptionAllocation subscriptionAllocation = CSUASFactoryHelper.calculateAllocations(sssSubscription.maximumCost, ualInfo.remainingCost);
        if (subscriptionAllocation == null) {
            return;
        }
        // update the totals using our calculations
        sssSubscription.maximumCost = subscriptionAllocation.sssRemainingSubscriptionAmount;
        ualInfo.remainingCost = subscriptionAllocation.ualRemainingAllocation;
        // keep the ual totals even by subtracting the same percentage from the ual remaining capacity allocation
        ualInfo.remainingCapacity -= (ualInfo.remainingCapacity * subscriptionAllocation.allocationPercentage);
        Utility_Account_Subscription__c uas = createUASObject(ualInfo, opportunity.Id);
        uas.calculated_annual_cost_of_electricity__c = subscriptionAllocation.annualAmountAssigned;
        uas.Annual_Cost_of_Electricity__c = ualInfo.annualCostOfElectricity;
        uow.registerNew(uas, Utility_Account_Subscription__c.Opportunity__c, opportunity);
        populateSizingMethod(ualInfo, uas, sssSubscription);
        ualInfo.uasNumberCount++;
        createSOByCost(uas, subscriptionAllocation.annualAmountAssigned, uow);
    }

    private static Utility_Account_Subscription__c createUASObject(CSUASFactoryHelper.UtilityAccountLogWrapper ualInfo, Id opportunityId) {

        Utility_Account_Subscription__c uas = new Utility_Account_Subscription__c(
            Name = ualInfo.ual.Name,
            Name_on_Account__c = ualInfo.ual.Name_on_Account__c,
            Opportunity__c = opportunityId,
            Utility_Account_Log__c = ualInfo.ual.Id,
            UAS_Number__c = ualInfo.uasNumberCount
        );

        return uas;
    }

    private static void populateSizingMethod(CSUASFactoryHelper.UtilityAccountLogWrapper ualInfo, Utility_Account_Subscription__c uas, SSSSubscription sssSubscription) {
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