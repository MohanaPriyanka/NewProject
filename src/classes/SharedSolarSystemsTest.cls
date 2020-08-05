/**
 * Created by peteryao on 8/5/20.
 */
@IsTest
public with sharing class SharedSolarSystemsTest {
    @IsTest
    private static void testRecalculateMaximumSubscriptionCapacityForNonSMART() {
        SharedSolarSystems.productSelector = (ProductSelector) Test.createStub(ProductSelector.class, new MockProductSelector(true));
        List<Shared_Solar_System__c> sharedSolarSystems = new List<Shared_Solar_System__c>{new Shared_Solar_System__c()};
        try {
            new SharedSolarSystems(sharedSolarSystems).recalculateMaximumSubscriptionCapacityForSMART();
            System.assert(true, 'We should not have thrown an exception trying to calculate max capacity with null values');
        } catch (Exception e) {
            System.assert(false, e.getMessage() + '\n' + e.getStackTraceString());
        }
    }

    @IsTest
    private static void testRecalculateMaximumSubscriptionCapacityIncludingSMART() {
        SharedSolarSystems.productSelector = (ProductSelector) Test.createStub(ProductSelector.class, new MockProductSelector(false));
        Shared_Solar_System__c smartSystem = new Shared_Solar_System__c(
            Name = 'SMART',
            Product__c = Util.getFakeId(Product2.SObjectType),
            Total_System_Size_kWh_DC__c = 100,
            Total_System_Size_kW_AC__c = 50
        );
        Shared_Solar_System__c smartSystemNoDC = new Shared_Solar_System__c(
            Name = 'SMART No DC',
            Product__c = Util.getFakeId(Product2.SObjectType),
            Total_System_Size_kW_AC__c = 50
        );
        Shared_Solar_System__c nonSMARTSystem = new Shared_Solar_System__c(
            Name = 'Dumb',
            Product__c = Util.incrementFakeId(smartSystem.Product__c),
            Total_System_Size_kWh_DC__c = 100,
            Total_System_Size_kW_AC__c = 50
        );
        List<Shared_Solar_System__c> sharedSolarSystems = new List<Shared_Solar_System__c>{smartSystem, smartSystemNoDC, nonSMARTSystem};
        try {
            new SharedSolarSystems(sharedSolarSystems).recalculateMaximumSubscriptionCapacityForSMART();
        } catch (Exception e) {
            System.assert(false, e.getMessage() + '\n' + e.getStackTraceString());
        }
        for (Shared_Solar_System__c sss : sharedSolarSystems) {
            if (sss.Name == 'SMART') {
                System.assertEquals(25 * (100/50), sss.Maximum_Subscription_Capacity_kWDC__c, 'Expected to set Max Capacity for SMART');
            }
            if (sss.Name == 'Dumb' || sss.Name == 'SMART No DC') {
                System.assertEquals(null, sss.Maximum_Subscription_Capacity_kWDC__c, 'Expected to have to set Max Capacity manually');
            }
        }
    }

    /*************
      *** MOCKS ***
      *************/
    public class MockProductSelector extends MockProvider {
        private Boolean returnEmpty;
        public MockProductSelector(Boolean returnEmpty) {
            this.returnEmpty = returnEmpty;
        }
        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName {
                when 'selectForACToDCConversion' {
                    if (returnEmpty) {
                        return new List<Product2>();
                    } else {
                        Product2 smartProduct = new Product2(
                            Id = Util.getFakeId(Product2.SObjectType),
                            Max_Subscription_kW_AC_for_DC_calc__c = 25
                        );
                        return new List<Product2>{smartProduct};
                    }
                }
            }
            return null;
        }
    }

}