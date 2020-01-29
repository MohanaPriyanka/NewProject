/**
 * Created by SarahRenfro on 1/29/2020.
 */

@IsTest
@TestVisible
private class FeatureServiceTest {
    @IsTest
    public static void testIsEnabled() {
        useMocks(true);
        FeatureService featureService = new FeatureService();
        Boolean checkFeature = featureService.isEnabled(null);

        System.assertEquals(true, checkFeature);
    }

    @IsTest
    public static void testNotEnabled() {
        useMocks(false);
        FeatureService featureService = new FeatureService();
        Boolean checkFeature = featureService.isEnabled(null);

        System.assertEquals(false, checkFeature);

    }

    @IsTest
    public static void testFeatureSelector() {
        FeatureSelector featureSelector = new FeatureSelector();
        Custom_Feature_Enablement__mdt checkFeature = featureSelector.getCustomFeature('Subscription_Orders');
        System.assertNotEquals(null, checkFeature);
    }


    private static void useMocks(Boolean featureOn) {
        FeatureService.featureSelector = (FeatureSelector) Test.createStub(FeatureSelector.class, new MockCustomFeatureSelector(featureOn));
    }


    public class MockCustomFeatureSelector extends MockProvider {
        private Boolean featureOn;

        public MockCustomFeatureSelector(Boolean featureOn) {
            this.featureOn = featureOn;
        }

        public override Object handleMethodCall(MethodCall methodCall) {
            switch on methodCall.stubbedMethodName{
                when 'getCustomFeature' {
                    Custom_Feature_Enablement__mdt feature = new Custom_Feature_Enablement__mdt(
                        Feature_is_Enabled__c = featureOn
                    );
                    return feature;
                }
            }
            return null;
        }
    }
}