/**
 * Created by SarahRenfro on 3/5/2020.
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
    @IsTest
    public static void testSystemDefaults() {
        FeatureSelector featureSelector = new FeatureSelector();
        System_Default__mdt checkSystemDefault = featureSelector.getSystemDefaults();
        System.assertNotEquals(null, checkSystemDefault);
    }

    @IsTest
    public static void testFeatureServiceMock() {
        FeatureService featureService;
        Map<String, Boolean> featureFlagMap = new Map<String, Boolean>{'Relate_Debit_Memos_To_Invoices'=>false,'Multiple_Subscriptions'=>true};
        featureService = (FeatureService) Test.createStub(FeatureService.class, new FeatureService.Mock(featureFlagMap));
        System.assert(!featureService.isEnabled('Relate_Debit_Memos_To_Invoices'), 'Relate_Debit_Memos_To_Invoices should not be enabled');
        System.assert(featureService.isEnabled('Multiple_Subscriptions'), 'Multiple_Subscriptions should be enabled');
        try {
            featureService.isEnabled('Feature_Not_Set');
            System.assert(false, 'Asking for a feature that is not set should throw an exception');
        } catch (Util.BWException bwe) {
            System.assert(bwe.getMessage().contains('Feature needs to be set explicitly'), bwe.getMessage());
        }
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