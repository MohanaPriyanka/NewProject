/**
 * @description Because tests don't create UASes through the CSSubscriptionEnroller (which uses
 * CSUtilityAccountSubscriptionFactory.generateSubscriptions to generate the UAS and Subscription Orders), they need to
 * create subscription orders explicitly. This class, which should only be used for tests, helps with that.
 */
@IsTest
public with sharing class TestSOCreator {
    private static fflib_SObjectUnitOfWork uow = new fflib_SObjectUnitOfWork(
        new List<Schema.SObjectType> {
            Subscription_Order__c.SObjectType
        }
    );

    public static void registerByCapacity(Utility_Account_Subscription__c uas, Decimal annualElectricityCapacityAssigned) {
        CSUtilityAccountSubscriptionFactory.createSOByCapacity(uas, annualElectricityCapacityAssigned, uow);
    }

    public static void registerByCost(Utility_Account_Subscription__c uas, Decimal annualElectricityCostAssigned) {
        CSUtilityAccountSubscriptionFactory.createSOByCost(uas, annualElectricityCostAssigned, uow);
    }

    public static void createByCapacity(Utility_Account_Subscription__c uas, Decimal annualElectricityCapacityAssigned) {
        CSUtilityAccountSubscriptionFactory.createSOByCapacity(uas, annualElectricityCapacityAssigned, uow);
        uow.commitWork();
    }

    public static void createByCost(Utility_Account_Subscription__c uas, Decimal annualElectricityCostAssigned) {
        CSUtilityAccountSubscriptionFactory.createSOByCost(uas, annualElectricityCostAssigned, uow);
        uow.commitWork();
    }

    public static void commitWork() {
        uow.commitWork();
        uow = new fflib_SObjectUnitOfWork(
            new List<Schema.SObjectType> {
                Subscription_Order__c.SObjectType
            }
        );
    }
}